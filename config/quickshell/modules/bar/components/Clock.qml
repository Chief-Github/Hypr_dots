import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import qs.services
import "../../../components/effects"

Item {
    id: root

    property var launcher
    property var controlCenter
    property var sidebar
    property var dashboard
    property bool timeHidden: false
    
    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight
    
    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8
        
        // Compact time display
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            
            // Hours
            Text {
                id: hoursText
                property string _live: root.timeHidden ? "xx" : Time.format("hh")
                property string _shown: _live
                property real _angle: 0

                text: _shown
                color: Pywal.foreground
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                font.letterSpacing: 0.3

                transform: Rotation {
                    origin.x: hoursText.width / 2
                    origin.y: hoursText.height / 2
                    axis { x: 1; y: 0; z: 0 }
                    angle: hoursText._angle
                }

                on_LiveChanged: hoursFlip.restart()

                SequentialAnimation {
                    id: hoursFlip
                    NumberAnimation { target: hoursText; property: "_angle"; to: 90; duration: 150; easing.type: Easing.InCubic }
                    ScriptAction { script: hoursText._shown = hoursText._live }
                    NumberAnimation { target: hoursText; property: "_angle"; from: -90; to: 0; duration: 150; easing.type: Easing.OutCubic }
                }
            }

            // Animated colon separator
            Text {
                id: colonSeparator
                text: ":"
                color: Pywal.primary
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            // Minutes
            Text {
                id: minutesText
                property string _live: root.timeHidden ? "xx" : Time.format("mm")
                property string _shown: _live
                property real _angle: 0

                text: _shown
                color: Pywal.foreground
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: "Inter"
                font.letterSpacing: 0.3

                transform: Rotation {
                    origin.x: minutesText.width / 2
                    origin.y: minutesText.height / 2
                    axis { x: 1; y: 0; z: 0 }
                    angle: minutesText._angle
                }

                on_LiveChanged: minutesFlip.restart()

                SequentialAnimation {
                    id: minutesFlip
                    NumberAnimation { target: minutesText; property: "_angle"; to: 90; duration: 150; easing.type: Easing.InCubic }
                    ScriptAction { script: minutesText._shown = minutesText._live }
                    NumberAnimation { target: minutesText; property: "_angle"; from: -90; to: 0; duration: 150; easing.type: Easing.OutCubic }
                }
            }
        }
        
        // Compact date
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Time.format("ddd d")
            color: Qt.rgba(Pywal.foreground.r, Pywal.foreground.g, Pywal.foreground.b, 0.6)
            font.pixelSize: 10
            font.weight: Font.Medium
            font.family: "Inter"
        }
    }

    Process {
        id: rofiProc
        command: ["rofi", "-show", "drun"]
    }
    Process {
        id: rmBootFile
        command: ["sh", "-c", "rm -f /tmp/.qs_boot_done"]
        running: false
        onExited: (code, status) => Quickshell.reload(false)
    }
    

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.dashboard)
                    root.dashboard.shouldShow = !root.dashboard.shouldShow
                return
            }
            if (mouse.button === Qt.MiddleButton) {
                rmBootFile.running = true
                return
            }
            root.timeHidden = !root.timeHidden
        }
    }
}
