import Quickshell
import QtQuick

// Top-level Scope allows loading PanelWindow dynamically without rendering white artifacts
Scope {
    id: root

    // The starting layout, and the default LayoutState falls back to if this
    // is ever unset. Change per-session via Tab/Shift+Tab inside the picker
    // (see LayoutState.qml) instead of editing this file.
    Component.onCompleted: LayoutState.activeLayout = "shell-floating.qml"

    Loader {
        active: true
        source: Qt.resolvedUrl(LayoutState.activeLayout)
    }
}
