pragma Singleton
import QtQuick

// Shared across shell.qml and every shell-*.qml layout so Tab/Shift+Tab can
// cycle the active layout live, from inside whichever layout is currently
// loaded, without each file needing a reference back to shell.qml's Loader.
//
// IMPORTANT: cycleLayout() is called from inside the currently-loaded
// layout's own Keys.onPressed. Reassigning activeLayout rebinds shell.qml's
// Loader.source, which destroys the very item that's still on the call
// stack handling this key event. Doing that synchronously segfaulted Qt's
// JS engine mid-teardown (SIGSEGV in QJSEngine::create) the first time this
// was tried. Fix: defer the actual swap with Qt.callLater so the key event
// fully finishes and control returns to the event loop before teardown
// starts, and debounce so holding/mashing Tab can't queue up overlapping
// swaps before the previous one has settled.
QtObject {
    id: root

    readonly property var layouts: [
        "shell-classic.qml",
        "shell-bottom-dock.qml",
        "shell-coverflow.qml",
        "shell-coverflow-clear.qml",
        "shell-coverflow-minimal.qml",
        "shell-floating.qml",
        "shell-floating-center-reflection.qml",
        "shell-floating-clean.qml",
        "shell-floating-clear.qml",
        "shell-floating-clear-clean.qml",
        "shell-floating-minimal.qml",
        "shell-floating-minimal-clean.qml",
        "shell-hexcomb.qml",
        "shell-grid-view.qml"
    ]

    property string activeLayout: "shell-floating.qml"
    property bool switching: false

    // QtObject has no default property, so a Timer can't be a bare child
    // here like it could inside an Item/PanelWindow — assign it to a
    // property instead.
    property Timer debounce: Timer {
        interval: 500
        onTriggered: root.switching = false
    }

    // step: 1 for next, -1 for previous
    function cycleLayout(step) {
        if (switching) return;
        switching = true;
        debounce.start();
        Qt.callLater(function() {
            let i = layouts.indexOf(activeLayout);
            if (i === -1) i = 0;
            const n = layouts.length;
            activeLayout = layouts[((i + step) % n + n) % n];
        });
    }
}
