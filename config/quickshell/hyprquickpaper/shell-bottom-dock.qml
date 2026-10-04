import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQml.Models
import Quickshell.Wayland

PanelWindow {
    id: main
    implicitHeight: Screen.height
    implicitWidth: Screen.width
    color: "transparent"
    property int speed: 5000
    property string currentImagePath: ""
    property bool bgToggle: false

    readonly property var defaultVideoExtensions: ["mp4", "webm", "mov", "avi", "mkv", "gif", "m4v", "flv", "wmv", "mpeg", "3gp"]
    readonly property var videoExtensions: (configs.video_extensions && configs.video_extensions.length > 0)
        ? configs.video_extensions
        : defaultVideoExtensions

    function isVideoFile(fileName) {
        if (!fileName) return false;
        const lower = fileName.toLowerCase();
        for (let i = 0; i < videoExtensions.length; i++) {
            if (lower.endsWith("." + videoExtensions[i])) return true;
        }
        return false;
    }

    function getThumbnailSource(fileName) {
        if (!fileName) return "";
        let basePath = configs.cache_path.replace("~", Quickshell.env("HOME"));
        if (!basePath.endsWith("/")) basePath += "/";

        let thumbnailFileName = fileName;
        if (isVideoFile(fileName)) {
            const lastDot = fileName.lastIndexOf(".");
            if (lastDot > 0) {
                thumbnailFileName = fileName.substring(0, lastDot) + ".jpg";
            }
        }
        return "file://" + basePath + thumbnailFileName;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: 1

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        Quickshell.execDetached(["bash", Quickshell.shellPath("cache.sh"), Quickshell.shellDir]);
    }

    FileView {
        path: Quickshell.shellPath("config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures
            property string border_color
            property var video_extensions: []
        }
    }

    FileView {
        id: activeWallpaperFile
        path: Quickshell.env("HOME") + "/.cache/hyprquickpaper/current_wallpaper"
        watchChanges: false
    }

    // Qt.labs.folderlistmodel's FolderListModel only ever lists files
    // directly inside "folder" — it can't recurse into subfolders, and has
    // no video awareness. Shell out to `find` instead (same approach
    // cache.sh already uses to walk the tree for thumbnail generation).
    ListModel {
        id: folderModel
    }

    Process {
        id: scanProcess
        property string basePath: {
            let p = configs.wallpaper_path.replace("~", Quickshell.env("HOME"));
            return p.endsWith("/") ? p : p + "/";
        }
        command: {
            let exts = ["png", "jpg", "jpeg"].concat(main.videoExtensions);
            let expr = ["find", "-L", basePath, "-type", "f", "("];
            exts.forEach(function(ext, i) {
                if (i > 0) expr.push("-o");
                expr.push("-iname");
                expr.push("*." + ext);
            });
            expr.push(")");
            return expr;
        }
        // config.json is read asynchronously (FileView), so wallpaper_path
        // can still be empty the moment this component is created — that
        // would resolve basePath to "/" and kick off a `find /` across the
        // whole filesystem. Only start once it's actually loaded.
        running: basePath.length > 1
        // Force the scan to stop before this item is torn down (e.g. a Tab-cycled
        // layout swap) rather than leaving an in-flight callback racing destruction.
        Component.onDestruction: running = false
        stdout: StdioCollector {
            id: scanOutput
            waitForEnd: true
            onStreamFinished: {
                let entries = scanOutput.text.split("\n")
                    .filter(function(line) { return line.length > 0; })
                    .map(function(full) {
                        return { filePath: full, fileName: full.substring(full.lastIndexOf("/") + 1) };
                    });
                entries.sort(function(a, b) { return a.fileName.localeCompare(b.fileName); });

                folderModel.clear();
                for (let i = 0; i < entries.length; i++) {
                    folderModel.append(entries[i]);
                }
            }
        }
    }

    // Normalizes a config path: expands ~ and guarantees a trailing
    // slash, so direct string concatenation with a fileName never
    // produces a broken "...folderimage.png" path.
    function normalizedPath(rawPath) {
        let p = rawPath.replace("~", Quickshell.env("HOME"))
        if (!p.endsWith("/")) p += "/"
        return p
    }

    function updateBackground() {
        if (folderModel.count === 0) return
        const filePath = folderModel.get(pathView.currentIndex).filePath
        const fileName = folderModel.get(pathView.currentIndex).fileName
        // Full-quality source for the background — the original file
        // itself, NOT cache_path. cache_path holds downscaled thumbnails
        // generated for the small deck cards; reusing them here was why
        // the background looked degraded. Videos are the exception: an
        // Image element can't decode a video file at all, so fall back to
        // its cached still thumbnail instead.
        const fullPath = main.isVideoFile(fileName) ? main.getThumbnailSource(fileName) : "file://" + filePath
        currentImagePath = fullPath
        if (!bgToggle) {
            bgImageB.source = fullPath
            bgToggle = true
        } else {
            bgImageA.source = fullPath
            bgToggle = false
        }
    }

    // -----------------------------------------------------
    // LOSSLESS FULL-QUALITY BACKGROUND
    // -----------------------------------------------------
    Item {
        id: backgroundLayer
        anchors.fill: parent

        Image {
            id: bgImageA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            opacity: bgToggle ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

            onStatusChanged: {
                if (status === Image.Error) {
                    console.log("BG LOAD FAILED (bgImageA):", source)
                }
            }
        }

        Image {
            id: bgImageB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            opacity: bgToggle ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

            onStatusChanged: {
                if (status === Image.Error) {
                    console.log("BG LOAD FAILED (bgImageB):", source)
                }
            }
        }
    }

    // -----------------------------------------------------
    // UNIFORM-HEIGHT BOTTOM DOCK WITH CURVED CORNERS
    // -----------------------------------------------------
    PathView {
        id: pathView
        anchors.fill: parent
        focus: true
        interactive: false

        model: folderModel
        pathItemCount: 15
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5

        onCurrentIndexChanged: updateBackground()

        Timer {
            id: initTimer
            interval: 50
            repeat: false
            onTriggered: {
                if (folderModel.count === 0) return

                let rawText = activeWallpaperFile.text() ? activeWallpaperFile.text() : ""
                let activePath = rawText.trim()
                let matchedIndex = -1

                if (activePath.length > 0) {
                    for (let i = 0; i < folderModel.count; i++) {
                        let itemPath = folderModel.get(i).filePath
                        if (itemPath === activePath) {
                            matchedIndex = i
                            break
                        }
                    }
                }

                if (matchedIndex === -1) {
                    matchedIndex = Math.floor(folderModel.count / 2)
                }

                pathView.currentIndex = matchedIndex
                updateBackground()
            }
        }

        Connections {
            target: folderModel
            function onCountChanged() {
                initTimer.restart()
            }
        }

        function activateCurrent() {
            const path = folderModel.get(pathView.currentIndex).filePath;
            Quickshell.execDetached(["bash", Quickshell.shellPath("commands.sh"), path]);
            Qt.quit();
        }

        path: Path {
            startX: -main.width * 0.12
            startY: main.height - 180

            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 0.95 }
            PathAttribute { name: "itemZ"; value: 1 }
            PathPercent { value: 0.0 }

            PathLine { x: main.width * 0.5; y: main.height - 180 }
            PathAttribute { name: "itemScale"; value: 1.30 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathAttribute { name: "itemZ"; value: 100 }
            PathPercent { value: 0.5 }

            PathLine { x: main.width * 1.12; y: main.height - 180 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 0.95 }
            PathAttribute { name: "itemZ"; value: 1 }
            PathPercent { value: 1.0 }
        }

        delegate: Item {
            id: delegateItem
            width: 340
            height: 215

            // Capture the attached property here, at the delegate ROOT,
            // where PathView guarantees it resolves correctly. Nested
            // children below read delegateItem.isCurrent instead of
            // trying to resolve "PathView.isCurrentItem" themselves —
            // reading it directly from a nested grandchild was silently
            // evaluating false for every card, which is why the border
            // never distinguished the selected card regardless of color.
            property bool isCurrent: PathView.isCurrentItem

            scale: PathView.itemScale
            opacity: PathView.itemOpacity
            z: isCurrent ? 100 : PathView.itemZ

            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                    1, -0.22, 0, 0.22 * 215 / 2,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                )
            }

            // Card item wrapper
            Item {
                anchors.fill: parent

                // Inner Mask shape defining curved corners
                Rectangle {
                    id: mask
                    anchors.fill: parent
                    radius: 14
                    visible: false
                }

                // Background & Wallpaper Image
                Rectangle {
                    id: cardContent
                    anchors.fill: parent
                    color: "#1e1e2e"
                    visible: false

                    Text {
                        id: alt
                        text: "Loading..."
                        color: configs.border_color
                        anchors.centerIn: parent
                        font.pixelSize: 14
                    }

                    Image {
                        id: img
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        smooth: true

                        source: main.getThumbnailSource(fileName)
                        sourceSize.width: width
                        sourceSize.height: height

                        Timer {
                            id: retryTimer
                            interval: 1000
                            repeat: false
                            onTriggered: {
                                let s = img.source;
                                img.source = "";
                                img.source = s;
                            }
                        }

                        onStatusChanged: {
                            if (status === Image.Error) {
                                alt.text = "Caching";
                                retryTimer.start();
                            }
                        }
                    }
                }

                // Clipped rounded card result
                OpacityMask {
                    anchors.fill: parent
                    source: cardContent
                    maskSource: mask
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 8
                    width: 46
                    height: 18
                    radius: 4
                    color: "#cc000000"
                    border.width: 1
                    border.color: "#44ffffff"
                    z: 20
                    visible: main.isVideoFile(fileName)

                    Text {
                        anchors.centerIn: parent
                        text: "VIDEO"
                        color: "#ff6666"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }
                }

                // Selected border: a single rectangle whose border
                // color/width switch based on isCurrentItem. Kept to one
                // lean Rectangle (no extra negative-margin glow layers)
                // so it can't introduce any new failure surface.
                Rectangle {
                    id: selectedBorder
                    anchors.fill: parent
                    radius: 14
                    color: "transparent"
                    antialiasing: true
                    border.width: delegateItem.isCurrent ? 2 : 1
                    border.color: delegateItem.isCurrent
                        ? (configs.border_color.length > 0 ? configs.border_color : "#e6e6e6")
                        : "#33ffffff"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pathView.forceActiveFocus();
                    if (pathView.currentIndex === index) {
                        pathView.activateCurrent();
                    } else {
                        pathView.currentIndex = index;
                    }
                }
            }
        }

        Keys.onPressed: function (event) {
            const big = configs.number_of_pictures > 0 ? configs.number_of_pictures : 5;

            if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                pathView.incrementCurrentIndex();
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                pathView.decrementCurrentIndex();
            } else if (event.key === Qt.Key_U) {
                for (let i = 0; i < big; i++) pathView.incrementCurrentIndex();
            } else if (event.key === Qt.Key_D) {
                for (let i = 0; i < big; i++) pathView.decrementCurrentIndex();
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                pathView.activateCurrent();
            } else if (event.key === Qt.Key_Escape) {
                Qt.quit();
            } else {
                return;
            }
            event.accepted = true;
        }
    }
}
