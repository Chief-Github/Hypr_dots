// ─────────────────────────────────────────────────────────────
//  NotificationPopups.qml — simple notification toasts
//
//  How it works, in one breath:
//  services/Notifs.qml collects every notification into
//  `notifs.notifications` (newest first). This invisible window
//  is pinned to the top-right of the screen; it shows the ones
//  that aren't closed yet, and each card closes itself after a
//  timeout — or when you click or swipe it away.
//
//  Sizes/timing come from shell.json → "notifications".
// ─────────────────────────────────────────────────────────────

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications // for NotificationUrgency
import "../../../services" as QsServices
import "../../../config" as QsConfig

PanelWindow {
    id: root

    readonly property var notifs: QsServices.Notifs
    readonly property var pywal: QsServices.Pywal
    readonly property var cfg: QsConfig.Config.notifications

    // The notifications we actually show:
    //  - skip ones already closed
    //  - while Do Not Disturb is on, only critical ones get through
    //  - newest first, at most `maxVisible`
    readonly property var popups: (notifs.notifications || [])
        .filter(n => !!n && !n.closed)
        .filter(n => !notifs.dnd || n.urgency === NotificationUrgency.Critical)
        .slice(0, cfg.maxVisible)

    // Notifications hand us icons/images in four possible shapes.
    // Turn any of them into something Image {} can load:
    //   "firefox"                  → image://icon/firefox   (icon name)
    //   "/home/me/shot.png"        → file:///home/me/shot.png
    //   "file://…" or "image://…"  → already fine, pass through
    //   "image://icon//home/…"     → quickshell wrapped a file path as an
    //                                icon name (hyprshot does this) — unwrap
    function toImageSource(s) {
        if (!s) return ""
        if (s.startsWith("image://icon//"))
            return "file://" + s.slice("image://icon/".length)
        if (s.includes("://")) return s
        if (s.startsWith("/")) return "file://" + s
        return "image://icon/" + s
    }

    function urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return pywal.error
        if (u === NotificationUrgency.Low) return Qt.alpha(pywal.foreground, 0.5)
        return pywal.primary
    }

    // ── the window itself: a transparent strip, top-right ──
    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: cfg.margin; right: cfg.margin }
    visible: popups.length > 0
    color: "transparent"

    // Wayland clips everything to the window's rectangle, so a tilted
    // card's corners get chopped off at the edge. `slack` is invisible
    // padding above/below the cards that gives the rotation headroom.
    // (Cards therefore sit `margin + slack` below the bar.)
    readonly property int slack: 20
    implicitWidth: cfg.popupWidth
    implicitHeight: column.implicitHeight + slack * 2

    ColumnLayout {
        id: column
        y: root.slack
        width: parent.width
        spacing: root.cfg.spacing

        Repeater {
            model: root.popups

            // ── one notification card ──
            // The outer Item is the slot the column manages; the Rectangle
            // inside is what you actually see — and what the swipe drags
            // around. (The layout owns the Item's position, so the visible
            // card has to be a child to be free to move.)
            delegate: Item {
                id: card
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: cardBody.implicitHeight

                // swipe past this fraction of the width → dismissed
                readonly property real swipeThreshold: 0.3

                // fade in on arrival
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 180 } }

                // auto-close after the timeout (critical ones stay until
                // clicked). Hovering holds the card open — though moving the
                // mouse away starts the countdown over from zero.
                Timer {
                    interval: root.cfg.timeoutMs
                    running: card.modelData.urgency !== NotificationUrgency.Critical
                             && !dragArea.containsMouse
                    onTriggered: card.modelData.close()
                }

                // when a swipe commits: fly off in that direction, then close
                SequentialAnimation {
                    id: flyOut
                    property real toX: 0

                    NumberAnimation {
                        target: cardBody; property: "x"
                        to: flyOut.toX
                        duration: 200
                        easing.type: Easing.InQuad
                    }
                    ScriptAction { script: card.modelData.close() }
                }

                Rectangle {
                    id: cardBody
                    width: parent.width
                    implicitHeight: content.implicitHeight + 24
                    radius: 16
                    color: Qt.alpha(root.pywal.background, 0.5)
                    border.width: 1
                    border.color: Qt.alpha(root.pywal.foreground, 0.1)

                    // ── the fancy part ──
                    // The tilt follows the drag, so the card arcs like a
                    // flicked playing card instead of sliding flat.
                    // 0.06° per pixel of drag, capped at ±8° so the corners
                    // stay inside the window's slack padding.
                    rotation: Math.max(-8, Math.min(8, x * 0.06))

                    // …and thin out the further it gets from home
                    opacity: 1 - Math.abs(x) / (width * 1.5)

                    // let go before the threshold → boing back home
                    Behavior on x {
                        enabled: !dragArea.drag.active
                        SpringAnimation { spring: 4; damping: 0.3 }
                    }

                    // drag sideways to swipe; a plain click still dismisses
                    // (the action buttons sit on top of this, so they still win)
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        drag.target: cardBody
                        drag.axis: Drag.XAxis

                        onClicked: card.modelData.close()
                        onReleased: {
                            if (Math.abs(cardBody.x) > cardBody.width * card.swipeThreshold) {
                                flyOut.toX = (cardBody.x > 0 ? 1 : -1) * (cardBody.width + 80)
                                flyOut.start()
                            } else {
                                cardBody.x = 0 // the Behavior above makes this a spring
                            }
                        }
                    }

                    ColumnLayout {
                        id: content
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 8

                        // header: [icon] app name + summary
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Image {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                Layout.alignment: Qt.AlignTop
                                source: root.toImageSource(card.modelData.appIcon)
                                visible: card.modelData.appIcon.length > 0 && status !== Image.Error
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.appName || "Notification"
                                    color: Qt.alpha(root.pywal.foreground, 0.6)
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.summary
                                    color: root.urgencyColor(card.modelData.urgency)
                                    font.pixelSize: 14
                                    font.bold: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // body text, if any (may contain simple markup like <b>)
                        Text {
                            Layout.fillWidth: true
                            visible: card.modelData.body.length > 0
                            text: card.modelData.body
                            textFormat: Text.StyledText
                            color: Qt.alpha(root.pywal.foreground, 0.8)
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }

                        // image preview (screenshots, album art, …)
                        Image {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            source: root.toImageSource(card.modelData.image)
                            visible: card.modelData.image.length > 0 && status !== Image.Error
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        // action buttons ("Open", "Reply", …), if the app sent any.
                        // Unlabeled actions are hidden — they're the app's "default"
                        // action, which clicking the card triggers anyway.
                        RowLayout {
                            readonly property var labeled:
                                (card.modelData.actions || []).filter(a => (a.text || "").length > 0)
                            visible: labeled.length > 0
                            spacing: 6

                            Repeater {
                                model: parent.labeled

                                delegate: Rectangle {
                                    id: actionPill
                                    required property var modelData

                                    implicitWidth: actionLabel.implicitWidth + 20
                                    implicitHeight: 26
                                    radius: 13
                                    color: Qt.alpha(root.pywal.primary, 0.15)

                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: actionPill.modelData.text || actionPill.modelData.identifier
                                        color: root.pywal.primary
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            actionPill.modelData.invoke()
                                            card.modelData.close()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
