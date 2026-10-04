// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root

    property string location: "London"
    property var weatherPopup

    property string temp: "--"
    property string condition: "--"
    property string icon: "?"

    implicitWidth: weatherRow.implicitWidth
    implicitHeight: weatherRow.implicitHeight

    function updateCondition(c) {
        const s = c.toLowerCase()
        if (s.includes("sun") || s.includes("clear"))    { root.icon = "☀" }
        else if (s.includes("thunder") || s.includes("storm")) { root.icon = "⚡" }
        else if (s.includes("snow") || s.includes("blizzard")) { root.icon = "❄" }
        else if (s.includes("rain") || s.includes("drizzle"))  { root.icon = "☂" }
        else if (s.includes("fog") || s.includes("mist"))      { root.icon = "🌫" }
        else if (s.includes("overcast"))                       { root.icon = "☁" }
        else if (s.includes("cloud"))                          { root.icon = "⛅" }
        else                                                   { root.icon = "?"; root.iconColor = Pywal.foreground }
    }

    function fetch() {
        weatherProc.running = true
    }

    Process {
        id: weatherProc
        command: ["curl", "-sf", "--max-time", "8", `wttr.in/${root.location}?format=%t+%C`]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim()
                const spaceIdx = trimmed.indexOf(" ")
                if (spaceIdx === -1) return
                root.temp      = trimmed.slice(0, spaceIdx)
                root.condition = trimmed.slice(spaceIdx + 1)
                console.log("weather condition:", root.condition)
                root.updateCondition(root.condition)
            }
        }
    }

    // Refresh every 10 minutes
    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetch()
    }

    Row {
        id: weatherRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: pywal.foreground
            font.pixelSize: 12
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.temp
            color: Pywal.foreground
            font.pixelSize: 12
            font.weight: Font.Medium
            font.family: "Inter"
            font.letterSpacing: 0.3
        }

        //Text {
        //    anchors.verticalCenter: parent.verticalCenter
        //    text: root.condition
        //    color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.6)
        //    font.pixelSize: 11
        //    font.family: "Inter"
        //}
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.weatherPopup) {
                if (root.weatherPopup.location !== undefined)
                    root.weatherPopup.location = root.location
                root.weatherPopup.shouldShow = !root.weatherPopup.shouldShow
            }
        }
    }
}
