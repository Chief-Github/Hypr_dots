// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import Quickshell
import Quickshell.Wayland
import QtQuick 6.10
import "../../config" as QsConfig
import "../../services" as QsServices

Scope {
    readonly property var config: QsConfig.Config
    
    // Popup windows removed — popups are now hosted inline inside the bar PanelWindow
    
    // Control Center window
    Loader {
        id: controlCenterLoader
        source: "../controlcenter/ControlCenterWindow.qml"
        asynchronous: true
        
        property var controlCenter: item
        
        onStatusChanged: {
            QsServices.Logger.debug(
                "BarWrapper",
                `Control Center loader status: ${status === Loader.Ready ? "READY" : status === Loader.Loading ? "LOADING" : status === Loader.Error ? "ERROR" : "NULL"}`
            )
            if (status === Loader.Error) {
                QsServices.Logger.error("BarWrapper", "Control Center failed to load")
            }
            if (status === Loader.Ready) {
                QsServices.Logger.debug("BarWrapper", `Control Center loaded, item: ${item ? "EXISTS" : "NULL"}`)
            }
        }
    }

    //Loader {
    //    id: launcherLoader
    //    source: "../launcher/LauncherWindow.qml"
    //    asynchronous: true
//
    //    property var launcher: item
    //}

    Loader {
        id: brightnesPopupLoader
        source: "components/BrightnessPopupWindow.qml"
        asynchronous: true
    }

    Loader {
        id: mediaPlayerPopupLoader
        source: "components/MediaPlayerPopupWindow.qml"
        asynchronous: true
    }

    Loader {
        id: volumePopupLoader
        source: "components/VolumePopupWindow.qml"
        asynchronous: true
    }

    Loader {
        id: bluetoothPopupLoader
        source: "components/BluetoothPopupWindow.qml"
        asynchronous: true
    }

    Loader {
        id: networkPopupLoader
        source: "components/NetworkPopupWindow.qml"
        asynchronous: true
    }

    Loader {
        id: ipPopupLoader
        source: "components/IP-Popup.qml"
        asynchronous: true
    }

    Loader {
        id: btInfoPopupLoader
        source: "components/BTInfo-Popup.qml"
        asynchronous: true
    }

    Loader {
        id: sysInfoPopupLoader
        source: "components/SysInfoPopup.qml"
        asynchronous: true
    }

    Loader {
        id: weatherPopupLoader
        source: "components/WeatherPopup.qml"
        asynchronous: true
    }
    
    Loader {
        id: sidebarLoader
        source: "../sidebar/SidebarWindow.qml"
        asynchronous: true

        property var sidebar: item
    }

    Loader {
        id: dashboardLoader
        source: "../dashboard/DashboardWindow.qml"
        asynchronous: true

        property var dashboard: item
    }
    
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            
            property var modelData
            
            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            
            exclusiveZone: config.bar.height
            implicitHeight: config.bar.height
            color: "transparent"
            
            
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Bar content (fills window: bar strip at top, popup host below)
            Loader {
                id: barLoader
                anchors.fill: parent
                source: "Bar.qml"
                
                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.screen = Qt.binding(() => modelData)
                        item.barWindow = Qt.binding(() => window)
                        item.controlCenter = Qt.binding(() => controlCenterLoader.item)
//                        item.launcher = Qt.binding(() => launcherLoader.item)
                        item.sidebar = Qt.binding(() => sidebarLoader.item)
                        item.dashboard = Qt.binding(() => dashboardLoader.item)
                        item.brightnessPopup = Qt.binding(() => brightnesPopupLoader.item)
                        item.volumePopup = Qt.binding(() => volumePopupLoader.item)
                        item.mediaPlayerPopup = Qt.binding(() => mediaPlayerPopupLoader.item)
                        item.bluetoothPopup = Qt.binding(() => bluetoothPopupLoader.item)
                        item.networkPopup = Qt.binding(() => networkPopupLoader.item)
                        item.ipPopup = Qt.binding(() => ipPopupLoader.item)
                        item.btInfoPopup = Qt.binding(() => btInfoPopupLoader.item)
                        item.sysInfoPopup = Qt.binding(() => sysInfoPopupLoader.item)
                        item.weatherPopup = Qt.binding(() => weatherPopupLoader.item)
                    }
                }
            }
        }
    }
}
