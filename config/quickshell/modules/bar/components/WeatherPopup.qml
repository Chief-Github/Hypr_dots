// ────────────────────────────────────────────
//   Made by Chief-Github
//   https://github.com/Chief-Github/Hypr_dots
// ────────────────────────────────────────────

import QtQuick 6.10
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../../services" as QsServices

PanelWindow {
    id: popupWindow

    property bool shouldShow: false
    property string location: "London"
    readonly property var pywal: QsServices.Pywal

    readonly property color cSurface: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 0.48)
    readonly property color cSurfaceContainer: Qt.rgba(pywal.background.r, pywal.background.g, pywal.background.b, 0.58)
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: Qt.rgba(cText.r, cText.g, cText.b, 0.6)
    readonly property color cBorder: Qt.rgba(cText.r, cText.g, cText.b, 0.08)

    // Current conditions
    property int   currentTempNum: -999
    property string currentTemp:    "--"
    property string feelsLike:      "--"
    property string humidity:       "--"
    property string windSpeed:      "--"
    property string windDir:        ""
    property string uvIndex:        "--"
    property string visibility:     "--"
    property string pressure:       "--"
    property string conditionDesc:  "--"
    property string conditionIcon:  "?"

    // Forecast [{day, icon, min, max, minNum, maxNum}]
    property var forecast: []
    // Today's hourly [{time, temp, icon}]
    property var todayHourly: []
    // Sunrise / sunset
    property string sunriseStr: ""
    property string sunsetStr:  ""
    property real   sunProgress: -1
    property string dayLengthStr: ""
    // Moon
    property string moonPhase:    ""
    property int    moonIllumNum: 0
    property string moonriseStr:  ""
    property string moonsetStr:   ""
    property bool   moonIsWaxing: true

    function parseSunTime(str) {
        if (!str || str.trim() === "") return -1
        const parts = str.trim().split(/[\s:]+/)
        if (parts.length < 2) return -1
        let h = parseInt(parts[0]) || 0, m = parseInt(parts[1]) || 0
        const ap = (parts[2] || "").toUpperCase()
        if (ap === "PM" && h !== 12) h += 12
        if (ap === "AM" && h === 12) h = 0
        return h * 60 + m
    }

    // Temperature-based tint for the hero card
    readonly property color tempAccent: {
        const t = currentTempNum
        if (t === -999) return Qt.rgba(0, 0, 0, 0)
        if (t <= 0)  return Qt.rgba(0.35, 0.55, 0.95, 0.20)
        if (t <= 10) return Qt.rgba(0.25, 0.75, 0.90, 0.16)
        if (t <= 20) return Qt.rgba(0.30, 0.80, 0.55, 0.13)
        if (t <= 28) return Qt.rgba(0.95, 0.65, 0.20, 0.16)
        return Qt.rgba(0.95, 0.35, 0.25, 0.20)
    }

    // Forecast bar scaling
    readonly property int forecastMin: {
        let mn = 999
        for (const d of forecast) mn = Math.min(mn, d.minNum)
        return forecast.length ? mn : 0
    }
    readonly property int forecastMax: {
        let mx = -999
        for (const d of forecast) mx = Math.max(mx, d.maxNum)
        return forecast.length ? mx : 30
    }
    readonly property int forecastRange: Math.max(1, forecastMax - forecastMin)

    function weatherIcon(desc) {
        const s = (desc || "").toLowerCase()
        if (s.includes("thunder") || s.includes("storm")) return "⚡"
        if (s.includes("snow") || s.includes("blizzard"))  return "❄"
        if (s.includes("rain") || s.includes("drizzle") || s.includes("shower")) return "☂"
        if (s.includes("fog") || s.includes("mist"))       return "🌫"
        if (s.includes("overcast"))                        return "☁"
        if (s.includes("cloud"))                           return "⛅"
        if (s.includes("sun") || s.includes("clear"))     return "☀"
        return "?"
    }

    function dayName(dateStr) {
        const p = dateStr.split("-")
        const d = new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
        const today = new Date()
        const tom = new Date(today); tom.setDate(today.getDate() + 1)
        if (d.getDate() === today.getDate() && d.getMonth() === today.getMonth()) return "Today"
        if (d.getDate() === tom.getDate()   && d.getMonth() === tom.getMonth())   return "Tomorrow"
        return ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][d.getDay()]
    }

    function fmtTime(t) {
        const h = Math.floor(parseInt(t) / 100)
        if (h === 0)  return "12am"
        if (h < 12)  return h + "am"
        if (h === 12) return "12pm"
        return (h - 12) + "pm"
    }

    function fetch() {
        weatherProc.buf = ""
        weatherProc.running = true
    }

    onShouldShowChanged: {
        if (shouldShow) {
            mouseHasEntered = false
            closeTimer.stop()
            fetch()
            heroCard.opacity = 0;     heroCard._dy = 12
            sunArcCard.opacity = 0;   sunArcCard._dy = 12
            statsCard.opacity = 0;    statsCard._dy = 12
            forecastCard.opacity = 0; forecastCard._dy = 12
            hourlyCard.opacity = 0;   hourlyCard._dy = 12
            moonCard.opacity = 0;     moonCard._dy = 12
            cardEntryAnim.restart()
            sunDrawIn.restart()
        }
    }

    property bool mouseHasEntered: false

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                popupWindow.mouseHasEntered = true
                closeTimer.stop()
            } else if (popupWindow.mouseHasEntered && popupWindow.shouldShow) {
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 100
        onTriggered: {
            if (!hoverHandler.hovered && popupWindow.mouseHasEntered && popupWindow.shouldShow)
                popupWindow.shouldShow = false
        }
    }

    Process {
        id: weatherProc
        property string buf: ""
        command: ["curl", "-sf", "--max-time", "10", `wttr.in/${popupWindow.location}?format=j1`]
        running: false
        stdout: SplitParser { onRead: data => { weatherProc.buf += data } }
        onExited: {
            try {
                const j = JSON.parse(weatherProc.buf)
                const cc = j.current_condition[0]
                popupWindow.currentTempNum  = parseInt(cc.temp_C)
                popupWindow.currentTemp     = cc.temp_C + "°C"
                popupWindow.feelsLike       = cc.FeelsLikeC + "°C"
                popupWindow.humidity        = cc.humidity + "%"
                popupWindow.windSpeed       = cc.windspeedKmph + " km/h"
                popupWindow.windDir         = cc.winddir16Point || ""
                popupWindow.uvIndex         = (cc.uvIndex !== undefined ? cc.uvIndex : "--") + ""
                popupWindow.visibility      = cc.visibility + " km"
                popupWindow.pressure        = cc.pressure + " hPa"
                popupWindow.conditionDesc   = cc.weatherDesc[0].value
                popupWindow.conditionIcon   = popupWindow.weatherIcon(popupWindow.conditionDesc)

                const fc = []
                for (const day of j.weather) {
                    const mid = day.hourly[Math.floor(day.hourly.length / 2)]
                    fc.push({
                        day:    popupWindow.dayName(day.date),
                        icon:   popupWindow.weatherIcon(mid.weatherDesc[0].value),
                        min:    day.mintempC + "°",
                        max:    day.maxtempC + "°",
                        minNum: parseInt(day.mintempC),
                        maxNum: parseInt(day.maxtempC)
                    })
                }
                popupWindow.forecast = fc

                if (j.weather.length > 0) {
                    popupWindow.todayHourly = j.weather[0].hourly.map(h => ({
                        time: popupWindow.fmtTime(h.time),
                        temp: h.tempC + "°",
                        icon: popupWindow.weatherIcon(h.weatherDesc[0].value)
                    }))
                    const ast = j.weather[0].astronomy && j.weather[0].astronomy[0]
                    if (ast) {
                        popupWindow.sunriseStr = ast.sunrise || ""
                        popupWindow.sunsetStr  = ast.sunset  || ""
                        const srM = popupWindow.parseSunTime(ast.sunrise)
                        const ssM = popupWindow.parseSunTime(ast.sunset)
                        if (srM >= 0 && ssM > srM) {
                            const now = new Date()
                            const nowM = now.getHours() * 60 + now.getMinutes()
                            popupWindow.sunProgress = (nowM - srM) / (ssM - srM)
                            const d = ssM - srM
                            popupWindow.dayLengthStr = Math.floor(d/60) + "h " + (d%60) + "m daylight"
                        }
                        popupWindow.moonPhase    = ast.moon_phase || ""
                        popupWindow.moonIllumNum = parseInt(ast.moon_illumination || "0") || 0
                        const mr = ast.moonrise || "", ms = ast.moonset || ""
                        popupWindow.moonriseStr  = (mr && !mr.startsWith("No")) ? mr : "--"
                        popupWindow.moonsetStr   = (ms && !ms.startsWith("No")) ? ms : "--"
                        const mp = (ast.moon_phase || "").toLowerCase()
                        popupWindow.moonIsWaxing = mp.includes("waxing") || mp.includes("new") || mp.includes("first")
                    }
                }
            } catch(e) {
                console.log("WeatherPopup parse error:", e)
            }
            weatherProc.buf = ""
        }
    }

    ParallelAnimation {
        id: cardEntryAnim
        SequentialAnimation {
            PauseAnimation { duration: 60 }
            ParallelAnimation {
                NumberAnimation { target: heroCard;     property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutQuad }
                NumberAnimation { target: heroCard;     property: "_dy";     from: 12; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 140 }
            ParallelAnimation {
                NumberAnimation { target: sunArcCard;   property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutQuad }
                NumberAnimation { target: sunArcCard;   property: "_dy";     from: 12; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 220 }
            ParallelAnimation {
                NumberAnimation { target: statsCard;    property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutQuad }
                NumberAnimation { target: statsCard;    property: "_dy";     from: 12; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 300 }
            ParallelAnimation {
                NumberAnimation { target: forecastCard; property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutQuad }
                NumberAnimation { target: forecastCard; property: "_dy";     from: 12; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 380 }
            ParallelAnimation {
                NumberAnimation { target: hourlyCard;   property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutQuad }
                NumberAnimation { target: hourlyCard;   property: "_dy";     from: 12; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 460 }
            ParallelAnimation {
                NumberAnimation { target: moonCard;     property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutQuad }
                NumberAnimation { target: moonCard;     property: "_dy";     from: 12; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { right: 12; top: 12 }
    implicitWidth: 310
    implicitHeight: Math.min(contentCol.implicitHeight + 24, 560)
    color: "transparent"
    visible: shouldShow || container.opacity > 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "popup"

    FocusScope {
        id: container
        anchors.fill: parent
        scale: 0.94
        opacity: 0
        transformOrigin: Item.TopRight

        states: State {
            name: "visible"
            when: popupWindow.shouldShow
            PropertyChanges { target: container; opacity: 1; scale: 1.0 }
        }
        transitions: [
            Transition {
                to: "visible"
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutQuad }
                    NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                }
            },
            Transition {
                from: "visible"
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; duration: 120; easing.type: Easing.InQuad }
                    NumberAnimation { property: "scale"; to: 0.94; duration: 120 }
                }
            }
        ]

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: cSurface
            border.color: cBorder
            border.width: 1
            clip: true

            Flickable {
                id: mainFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: contentCol.implicitHeight + 70
                flickableDirection: Flickable.VerticalFlick
                clip: true
                maximumFlickVelocity: 1200
                boundsBehavior: Flickable.StopAtBounds

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: mainFlick.width
                        height: mainFlick.height
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0;  color: Qt.rgba(1, 1, 1, Math.max(0, 1 - mainFlick.contentY / 40)) }
                            GradientStop { position: 0.05; color: "#ffffffff" }
                            GradientStop { position: 0.78; color: "#ffffffff" }
                            GradientStop { position: 1.0;  color: "#00000000" }
                        }
                    }
                }

                Column {
                    id: contentCol
                    width: parent.width - 24
                    x: 12; y: 12
                    spacing: 10

                    // ── Header ────────────────────────────────────────────
                    Item {
                        width: parent.width; height: 28
                        Text {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            text: "Weather · " //+ popupWindow.location
                            color: cPrimary
                            font.pixelSize: 13; font.weight: Font.Bold; font.family: "Inter"
                        }
                        Rectangle {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            width: 28; height: 28; radius: 14
                            color: refreshHover.containsMouse ? Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.15) : "transparent"
                            Text { anchors.centerIn: parent; text: "↻"; font.pixelSize: 16; color: cPrimary }
                            HoverHandler { id: refreshHover }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: popupWindow.fetch() }
                        }
                    }

                    // ── Hero card ─────────────────────────────────────────
                    Rectangle {
                        id: heroCard
                        property real _dy: 12
                        opacity: 0
                        transform: Translate { y: heroCard._dy }
                        width: parent.width
                        height: heroCol.implicitHeight + 28
                        radius: 12
                        color: cSurfaceContainer
                        border.color: cBorder; border.width: 1
                        clip: true

                        // Temperature-tinted shimmer overlay
                        Rectangle {
                            anchors.fill: parent; radius: parent.radius
                            color: popupWindow.tempAccent
                        }

                        // ── Animated weather scene ────────────────────────
                        Canvas {
                            id: wxCanvas
                            anchors.fill: parent
                            clip: true
                            opacity: 0.45

                            readonly property string wType: {
                                const s = popupWindow.conditionDesc.toLowerCase()
                                if (s.includes("thunder") || s.includes("storm")) return "thunder"
                                if (s.includes("snow") || s.includes("blizzard"))  return "snow"
                                if (s.includes("rain") || s.includes("drizzle") || s.includes("shower")) return "rain"
                                if (s.includes("fog") || s.includes("mist"))       return "fog"
                                if (s.includes("overcast"))                        return "overcast"
                                if (s.includes("cloud"))                           return "cloud"
                                if (s.includes("sun") || s.includes("clear"))     return "sun"
                                return "none"
                            }

                            property var pts: []
                            property real sunAngle: 0
                            property real flashAlpha: 0

                            function init() {
                                pts = []
                                const w = width, h = height
                                if (wType === "rain" || wType === "thunder") {
                                    for (let i = 0; i < 28; i++)
                                        pts.push({ x: Math.random()*w, y: Math.random()*h,
                                                   spd: 5 + Math.random()*4,
                                                   len: 7 + Math.random()*7,
                                                   a: 0.25 + Math.random()*0.45 })
                                } else if (wType === "snow") {
                                    for (let i = 0; i < 22; i++)
                                        pts.push({ x: Math.random()*w, y: Math.random()*h,
                                                   r: 1.5 + Math.random()*2,
                                                   vy: 0.4 + Math.random()*0.8,
                                                   phase: Math.random()*Math.PI*2,
                                                   a: 0.5 + Math.random()*0.5 })
                                } else if (wType === "cloud" || wType === "overcast") {
                                    const n = wType === "overcast" ? 5 : 3
                                    for (let i = 0; i < n; i++)
                                        pts.push({ x: (i/n)*w*1.4 - w*0.2,
                                                   y: 14 + Math.random()*38,
                                                   sc: 0.6 + Math.random()*0.7,
                                                   vx: 0.15 + Math.random()*0.25,
                                                   a: wType==="overcast" ? 0.18+Math.random()*0.12 : 0.12+Math.random()*0.10 })
                                } else if (wType === "fog") {
                                    for (let i = 0; i < 5; i++)
                                        pts.push({ x: -width*0.3 + i*width*0.15,
                                                   y: 10 + i*18,
                                                   vx: 0.2 + Math.random()*0.2,
                                                   a: 0.08 + Math.random()*0.08 })
                                }
                                requestPaint()
                            }

                            function step() {
                                const w = width, h = height
                                if (wType === "sun") {
                                    sunAngle = (sunAngle + 0.25) % 360
                                } else if (wType === "rain" || wType === "thunder") {
                                    if (wType === "thunder") {
                                        flashAlpha = Math.max(0, flashAlpha - 0.05)
                                        if (Math.random() < 0.003) flashAlpha = 0.35
                                    }
                                    for (const p of pts) {
                                        p.x -= 0.6; p.y += p.spd
                                        if (p.y > h) { p.y = -p.len; p.x = Math.random()*w }
                                    }
                                } else if (wType === "snow") {
                                    for (const p of pts) {
                                        p.phase += 0.018; p.y += p.vy
                                        p.x += Math.sin(p.phase) * 0.4
                                        if (p.y > h) { p.y = -p.r; p.x = Math.random()*w }
                                    }
                                } else if (wType === "cloud" || wType === "overcast") {
                                    for (const p of pts) {
                                        p.x += p.vx
                                        if (p.x > w + 60*p.sc) p.x = -60*p.sc
                                    }
                                } else if (wType === "fog") {
                                    for (const p of pts) {
                                        p.x += p.vx
                                        if (p.x > w) p.x = -w*0.6
                                    }
                                }
                                requestPaint()
                            }

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                if (wType === "none") return

                                if (wType === "sun") {
                                    drawSun(ctx)
                                    return
                                }
                                if (wType === "thunder" && flashAlpha > 0) {
                                    ctx.fillStyle = "rgba(200,220,255," + flashAlpha + ")"
                                    ctx.fillRect(0, 0, width, height)
                                }
                                for (const p of pts) {
                                    ctx.globalAlpha = p.a
                                    if (wType === "rain" || wType === "thunder") {
                                        ctx.strokeStyle = "white"; ctx.lineWidth = 1; ctx.lineCap = "round"
                                        ctx.beginPath()
                                        ctx.moveTo(p.x, p.y)
                                        ctx.lineTo(p.x - 0.6*p.len/p.spd*p.spd*0.12, p.y + p.len)
                                        ctx.stroke()
                                    } else if (wType === "snow") {
                                        ctx.fillStyle = "white"
                                        ctx.beginPath(); ctx.arc(p.x, p.y, p.r, 0, Math.PI*2); ctx.fill()
                                    } else if (wType === "cloud" || wType === "overcast") {
                                        drawCloud(ctx, p.x, p.y, p.sc)
                                    } else if (wType === "fog") {
                                        const gr = ctx.createLinearGradient(p.x, p.y, p.x + width*0.8, p.y)
                                        gr.addColorStop(0,   "rgba(255,255,255,0)")
                                        gr.addColorStop(0.25,"rgba(255,255,255," + p.a + ")")
                                        gr.addColorStop(0.75,"rgba(255,255,255," + p.a + ")")
                                        gr.addColorStop(1,   "rgba(255,255,255,0)")
                                        ctx.fillStyle = gr
                                        ctx.fillRect(p.x, p.y - 7, width*0.8, 14)
                                    }
                                }
                                ctx.globalAlpha = 1
                            }

                            function drawCloud(ctx, x, y, sc) {
                                ctx.fillStyle = "white"
                                ctx.beginPath()
                                ctx.arc(x,          y,          18*sc, Math.PI*0.5, Math.PI*1.5)
                                ctx.arc(x+8*sc,     y-12*sc,    11*sc, Math.PI,     0)
                                ctx.arc(x+20*sc,    y-10*sc,    14*sc, Math.PI,     0)
                                ctx.arc(x+32*sc,    y-4*sc,     10*sc, Math.PI*1.5, Math.PI*0.5)
                                ctx.lineTo(x, y+18*sc)
                                ctx.closePath()
                                ctx.fill()
                            }

                            function drawSun(ctx) {
                                const cx = width*0.78, cy = height*0.38
                                const rays = 8, iR = 13, oR = 24
                                var glow = ctx.createRadialGradient(cx,cy,0,cx,cy,44)
                                glow.addColorStop(0, "rgba(255,225,100,0.45)")
                                glow.addColorStop(1, "rgba(255,225,100,0)")
                                ctx.globalAlpha = 1; ctx.fillStyle = glow
                                ctx.beginPath(); ctx.arc(cx,cy,44,0,Math.PI*2); ctx.fill()
                                ctx.strokeStyle = "rgba(255,225,100,0.75)"
                                ctx.lineWidth = 2.5; ctx.lineCap = "round"
                                for (let i = 0; i < rays; i++) {
                                    const a = (sunAngle + i*360/rays)*Math.PI/180
                                    ctx.globalAlpha = 0.75
                                    ctx.beginPath()
                                    ctx.moveTo(cx+Math.cos(a)*iR, cy+Math.sin(a)*iR)
                                    ctx.lineTo(cx+Math.cos(a)*oR, cy+Math.sin(a)*oR)
                                    ctx.stroke()
                                }
                                ctx.globalAlpha = 0.85; ctx.fillStyle = "rgba(255,235,130,0.85)"
                                ctx.beginPath(); ctx.arc(cx,cy,iR-2,0,Math.PI*2); ctx.fill()
                                ctx.globalAlpha = 1
                            }

                            Timer {
                                interval: 33
                                running: wxCanvas.visible && wxCanvas.wType !== "none"
                                repeat: true
                                onTriggered: wxCanvas.step()
                            }
                            onWTypeChanged: Qt.callLater(init)
                            Component.onCompleted: Qt.callLater(init)
                        }

                        Column {
                            id: heroCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                            spacing: 6

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 14

                                Text {
                                    text: popupWindow.conditionIcon
                                    font.pixelSize: 48; font.family: "Noto Color Emoji"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Column {
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: popupWindow.currentTemp
                                        color: cText
                                        font.pixelSize: 36; font.weight: Font.Bold; font.family: "Inter"
                                        font.letterSpacing: -1
                                    }
                                    Text {
                                        text: popupWindow.conditionDesc
                                        color: cSubText
                                        font.pixelSize: 12; font.family: "Inter"
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Feels like " + popupWindow.feelsLike
                                color: Qt.rgba(cText.r, cText.g, cText.b, 0.40)
                                font.pixelSize: 11; font.family: "Inter"
                            }
                        }
                    }

                    // ── Sun arc card ──────────────────────────────────────
                    Rectangle {
                        id: sunArcCard
                        property real _dy: 12
                        opacity: 0
                        transform: Translate { y: sunArcCard._dy }
                        width: parent.width
                        height: 114
                        radius: 12
                        color: cSurfaceContainer
                        border.color: cBorder; border.width: 1
                        clip: true
                        visible: popupWindow.sunriseStr !== ""

                        // Sky tint based on time of day
                        readonly property color skyTint: {
                            const t = popupWindow.sunProgress
                            if (t < 0 || t > 1) return Qt.rgba(0.08, 0.05, 0.22, 0.22)
                            if (t < 0.12)       return Qt.rgba(0.85, 0.45, 0.12, 0.18)
                            if (t > 0.88)       return Qt.rgba(0.90, 0.30, 0.10, 0.18)
                            return Qt.rgba(0.10, 0.28, 0.75, 0.16)
                        }
                        Rectangle { anchors.fill: parent; radius: parent.radius; color: sunArcCard.skyTint }

                        // Arc canvas
                        Canvas {
                            id: sunCanvas
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 80

                            property real drawT: 0
                            property real pulseR: 0

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                const cx = width / 2, cy = height
                                const r = Math.min(height - 8, width * 0.46)
                                const t = Math.max(0, Math.min(1, popupWindow.sunProgress))

                                // Full-day dashed arc
                                ctx.setLineDash([3, 6])
                                ctx.strokeStyle = "rgba(255,255,255,0.18)"
                                ctx.lineWidth = 2
                                ctx.beginPath()
                                ctx.arc(cx, cy, r, Math.PI, 2*Math.PI, false)
                                ctx.stroke()
                                ctx.setLineDash([])

                                // Elapsed arc (draw-in animated)
                                if (drawT > 0 && popupWindow.sunProgress >= 0) {
                                    const elapsed = Math.PI + drawT * Math.min(t, 1) * Math.PI
                                    const grad = ctx.createLinearGradient(cx - r, 0, cx + r, 0)
                                    grad.addColorStop(0, "rgba(255,170,50,0.6)")
                                    grad.addColorStop(1, "rgba(255,230,100,0.9)")
                                    ctx.strokeStyle = grad
                                    ctx.lineWidth = 2.5
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, r, Math.PI, elapsed, false)
                                    ctx.stroke()
                                }

                                // Sun dot + glow
                                if (popupWindow.sunProgress >= 0 && popupWindow.sunProgress <= 1) {
                                    const sa = Math.PI + t * Math.PI
                                    const sx = cx + Math.cos(sa) * r
                                    const sy = cy + Math.sin(sa) * r

                                    const glow = ctx.createRadialGradient(sx, sy, 0, sx, sy, 16 + pulseR)
                                    glow.addColorStop(0,   "rgba(255,220,80,0.90)")
                                    glow.addColorStop(0.45,"rgba(255,190,50,0.35)")
                                    glow.addColorStop(1,   "rgba(255,190,50,0)")
                                    ctx.fillStyle = glow
                                    ctx.beginPath(); ctx.arc(sx, sy, 16 + pulseR, 0, Math.PI*2); ctx.fill()

                                    ctx.fillStyle = "rgba(255,235,110,1)"
                                    ctx.beginPath(); ctx.arc(sx, sy, 5, 0, Math.PI*2); ctx.fill()
                                    ctx.fillStyle = "white"
                                    ctx.beginPath(); ctx.arc(sx, sy, 2.5, 0, Math.PI*2); ctx.fill()
                                }

                                // Moon icon when sun is down
                                if (popupWindow.sunProgress < 0 || popupWindow.sunProgress > 1) {
                                    ctx.font = "22px serif"
                                    ctx.textAlign = "center"
                                    ctx.globalAlpha = 0.6
                                    ctx.fillText("🌙", cx, cy - r + 18)
                                    ctx.globalAlpha = 1
                                }
                            }

                            NumberAnimation {
                                id: sunDrawIn
                                target: sunCanvas; property: "drawT"
                                from: 0; to: 1; duration: 1300; easing.type: Easing.OutCubic
                                running: false
                            }

                            SequentialAnimation {
                                running: sunCanvas.visible; loops: Animation.Infinite
                                NumberAnimation { target: sunCanvas; property: "pulseR"; from: 0; to: 8; duration: 1400; easing.type: Easing.OutSine }
                                NumberAnimation { target: sunCanvas; property: "pulseR"; from: 8; to: 0; duration: 1400; easing.type: Easing.InSine }
                            }

                            Timer {
                                interval: 40; repeat: true; running: sunCanvas.visible
                                onTriggered: sunCanvas.requestPaint()
                            }
                        }

                        // Labels
                        Text {
                            anchors { left: parent.left; bottom: parent.bottom; leftMargin: 12; bottomMargin: 8 }
                            text: "↑ " + popupWindow.sunriseStr
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.65)
                            font.pixelSize: 11; font.family: "Inter"; font.weight: Font.Medium
                        }
                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                            text: popupWindow.dayLengthStr
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.35)
                            font.pixelSize: 10; font.family: "Inter"
                        }
                        Text {
                            anchors { right: parent.right; bottom: parent.bottom; rightMargin: 12; bottomMargin: 8 }
                            text: popupWindow.sunsetStr + " ↓"
                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.65)
                            font.pixelSize: 11; font.family: "Inter"; font.weight: Font.Medium
                        }
                    }

                    // ── Stats — 2-column chip grid ────────────────────────
                    Rectangle {
                        id: statsCard
                        property real _dy: 12
                        opacity: 0
                        transform: Translate { y: statsCard._dy }
                        width: parent.width
                        height: statsRow.implicitHeight + 20
                        radius: 12
                        color: cSurfaceContainer
                        border.color: cBorder; border.width: 1

                        Row {
                            id: statsRow
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            spacing: 8

                            // Left column
                            Column {
                                width: (parent.width - 8) / 2
                                spacing: 8
                                Repeater {
                                    model: [
                                        { label: "Humidity",  value: popupWindow.humidity },
                                        { label: "UV Index",  value: popupWindow.uvIndex },
                                        { label: "Pressure",  value: popupWindow.pressure }
                                    ]
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width
                                        height: chipContent.implicitHeight + 14
                                        radius: 8
                                        color: Qt.rgba(cText.r, cText.g, cText.b, 0.04)
                                        border.color: cBorder; border.width: 1
                                        Column {
                                            id: chipContent
                                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; topMargin: 7 }
                                            spacing: 2
                                            Text { text: modelData.label; color: cSubText; font.pixelSize: 10; font.family: "Inter" }
                                            Text {
                                                text: modelData.value; color: cText
                                                font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                                                width: parent.width; elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }

                            // Right column
                            Column {
                                width: (parent.width - 8) / 2
                                spacing: 8
                                Repeater {
                                    model: [
                                        { label: "Wind",       value: popupWindow.windSpeed + (popupWindow.windDir ? "  " + popupWindow.windDir : "") },
                                        { label: "Visibility", value: popupWindow.visibility }
                                    ]
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width
                                        height: chipContent2.implicitHeight + 14
                                        radius: 8
                                        color: Qt.rgba(cText.r, cText.g, cText.b, 0.04)
                                        border.color: cBorder; border.width: 1
                                        Column {
                                            id: chipContent2
                                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; topMargin: 7 }
                                            spacing: 2
                                            Text { text: modelData.label; color: cSubText; font.pixelSize: 10; font.family: "Inter" }
                                            Text {
                                                text: modelData.value; color: cText
                                                font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                                                width: parent.width; elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Forecast with temp-range bars ─────────────────────
                    Rectangle {
                        id: forecastCard
                        property real _dy: 12
                        opacity: 0
                        transform: Translate { y: forecastCard._dy }
                        width: parent.width
                        height: forecastCol.implicitHeight + 20
                        radius: 12
                        color: cSurfaceContainer
                        border.color: cBorder; border.width: 1
                        visible: popupWindow.forecast.length > 0

                        Column {
                            id: forecastCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            spacing: 10

                            Text {
                                text: "3-Day Forecast"
                                color: cPrimary
                                font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                            }

                            Repeater {
                                model: popupWindow.forecast

                                Column {
                                    required property var modelData
                                    required property int index
                                    width: forecastCol.width
                                    spacing: 8

                                    Row {
                                        width: parent.width
                                        spacing: 0

                                        Text {
                                            text: modelData.day
                                            width: 78; color: cSubText
                                            font.pixelSize: 12; font.family: "Inter"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.icon
                                            font.pixelSize: 14; font.family: "Noto Color Emoji"
                                            width: 24
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.min
                                            width: 30; horizontalAlignment: Text.AlignRight
                                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.45)
                                            font.pixelSize: 11; font.family: "Inter"; font.weight: Font.Medium
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        // Temperature range bar
                                        Item {
                                            width: parent.width - 78 - 24 - 30 - 30 - 8
                                            height: 6
                                            anchors.verticalCenter: parent.verticalCenter

                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                x: 6; width: parent.width - 12
                                                height: 6; radius: 3
                                                color: Qt.rgba(cText.r, cText.g, cText.b, 0.08)
                                            }
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                x: 6 + (modelData.minNum - popupWindow.forecastMin) / popupWindow.forecastRange * (parent.width - 12)
                                                width: Math.max(10, (modelData.maxNum - modelData.minNum) / popupWindow.forecastRange * (parent.width - 12))
                                                height: 6; radius: 3
                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0.0; color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.55) }
                                                    GradientStop { position: 1.0; color: Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.90) }
                                                }
                                            }
                                        }
                                        Text {
                                            text: modelData.max
                                            width: 30; horizontalAlignment: Text.AlignRight
                                            color: cText
                                            font.pixelSize: 11; font.family: "Inter"; font.weight: Font.Bold
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle {
                                        visible: index < popupWindow.forecast.length - 1
                                        width: parent.width; height: 1; color: cBorder
                                    }
                                }
                            }
                        }
                    }

                    // ── Today's hourly (horizontal scroll) ────────────────
                    Rectangle {
                        id: hourlyCard
                        property real _dy: 12
                        opacity: 0
                        transform: Translate { y: hourlyCard._dy }
                        width: parent.width
                        height: hourlyInner.implicitHeight + 20
                        radius: 12
                        color: cSurfaceContainer
                        border.color: cBorder; border.width: 1
                        visible: popupWindow.todayHourly.length > 0
                        clip: true

                        Column {
                            id: hourlyInner
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            spacing: 8

                            Text {
                                text: "Today by the Hour"
                                color: cPrimary
                                font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                            }

                            Flickable {
                                width: parent.width
                                height: hourlyRow.implicitHeight
                                contentWidth: hourlyRow.implicitWidth
                                flickableDirection: Flickable.HorizontalFlick
                                clip: true
                                maximumFlickVelocity: 1200
                                boundsBehavior: Flickable.StopAtBounds

                                Row {
                                    id: hourlyRow
                                    spacing: 6

                                    Repeater {
                                        model: popupWindow.todayHourly
                                        Rectangle {
                                            required property var modelData
                                            width: 52
                                            height: chip.implicitHeight + 16
                                            radius: 8
                                            color: Qt.rgba(cText.r, cText.g, cText.b, 0.04)
                                            border.color: cBorder; border.width: 1

                                            Column {
                                                id: chip
                                                anchors.centerIn: parent
                                                spacing: 3

                                                Text {
                                                    text: modelData.time
                                                    color: cSubText; font.pixelSize: 10; font.family: "Inter"
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }
                                                Text {
                                                    text: modelData.icon
                                                    font.pixelSize: 18; font.family: "Noto Color Emoji"
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }
                                                Text {
                                                    text: modelData.temp
                                                    color: cText; font.pixelSize: 12; font.weight: Font.Bold; font.family: "Inter"
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Moon phase card ───────────────────────────────────
                    Rectangle {
                        id: moonCard
                        property real _dy: 12
                        opacity: 0
                        transform: Translate { y: moonCard._dy }
                        width: parent.width
                        height: moonRow.implicitHeight + 45
                        radius: 12
                        color: cSurfaceContainer
                        border.color: cBorder; border.width: 1
                        visible: popupWindow.moonPhase !== ""

                        Column {
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            spacing: 5

                            Text {
                                text: "Moon Phase"
                                color: cPrimary
                                font.pixelSize: 11; font.weight: Font.Bold; font.family: "Inter"
                            }

                            Row {
                                id: moonRow
                                width: parent.width
                                spacing: 16

                                // Canvas-drawn moon
                                Canvas {
                                    id: moonCanvas
                                    width: 62; height: 62
                                    anchors.verticalCenter: parent.verticalCenter

                                    property real glowR: 0

                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        const cx = width / 2, cy = height / 2, r = 26
                                        const illum = Math.max(0, Math.min(1, popupWindow.moonIllumNum / 100))
                                        const isWaxing = popupWindow.moonIsWaxing

                                        // Outer glow
                                        const gl = ctx.createRadialGradient(cx, cy, r - 2, cx, cy, r + 8 + glowR)
                                        gl.addColorStop(0, "rgba(190,198,230,0.22)")
                                        gl.addColorStop(1, "rgba(190,198,230,0)")
                                        ctx.fillStyle = gl
                                        ctx.beginPath(); ctx.arc(cx, cy, r + 8 + glowR, 0, Math.PI*2); ctx.fill()

                                        // Clip to moon circle
                                        ctx.save()
                                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.clip()

                                        // Dark background
                                        ctx.fillStyle = "rgba(14, 16, 38, 0.97)"
                                        ctx.fillRect(cx - r - 1, cy - r - 1, (r + 1) * 2, (r + 1) * 2)

                                        if (illum >= 0.99) {
                                            // Full moon
                                            ctx.fillStyle = "rgba(210, 218, 240, 0.97)"
                                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.fill()
                                        } else if (illum > 0.01) {
                                            // Lit half
                                            ctx.fillStyle = "rgba(210, 218, 240, 0.97)"
                                            ctx.save()
                                            ctx.translate(cx, cy)
                                            ctx.beginPath()
                                            ctx.arc(0, 0, r, -Math.PI/2, Math.PI/2, !isWaxing)
                                            ctx.closePath(); ctx.fill()
                                            ctx.restore()

                                            // Terminator ellipse via scale trick
                                            const rx = r * Math.abs(1 - 2 * illum)
                                            if (rx > 0.5) {
                                                const isCresc = illum < 0.5
                                                ctx.fillStyle = isCresc
                                                    ? "rgba(14, 16, 38, 0.97)"
                                                    : "rgba(210, 218, 240, 0.97)"
                                                const drawLeft = (isCresc && !isWaxing) || (!isCresc && isWaxing)
                                                ctx.save()
                                                ctx.translate(cx, cy)
                                                ctx.scale(rx / r, 1)
                                                ctx.beginPath()
                                                ctx.arc(0, 0, r, -Math.PI/2, Math.PI/2, drawLeft)
                                                ctx.closePath(); ctx.fill()
                                                ctx.restore()
                                            }
                                        }

                                        ctx.restore()
                                    }

                                    SequentialAnimation {
                                        running: moonCanvas.visible; loops: Animation.Infinite
                                        NumberAnimation { target: moonCanvas; property: "glowR"; from: 0; to: 6; duration: 1800; easing.type: Easing.OutSine }
                                        NumberAnimation { target: moonCanvas; property: "glowR"; from: 6; to: 0; duration: 1800; easing.type: Easing.InSine }
                                    }
                                    Timer {
                                        interval: 50; repeat: true; running: moonCanvas.visible
                                        onTriggered: moonCanvas.requestPaint()
                                    }
                                }

                                // Details
                                Column {
                                    width: moonRow.width - 62 - moonRow.spacing
                                    spacing: 5
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: popupWindow.moonPhase
                                        color: cText
                                        font.pixelSize: 13; font.weight: Font.Bold; font.family: "Inter"
                                    }
                                    Text {
                                        text: popupWindow.moonIllumNum + "% illuminated"
                                        color: cSubText
                                        font.pixelSize: 11; font.family: "Inter"
                                    }
                                    Rectangle { width: 120; height: 1; color: cBorder }
                                    Row {
                                        spacing: 6
                                        Text { text: "↑"; color: cSubText; font.pixelSize: 11; font.family: "Inter" }
                                        Text { text: popupWindow.moonriseStr; color: cText; font.pixelSize: 11; font.family: "Inter" }
                                    }
                                    Row {
                                        spacing: 6
                                        Text { text: "↓"; color: cSubText; font.pixelSize: 11; font.family: "Inter" }
                                        Text { text: popupWindow.moonsetStr; color: cText; font.pixelSize: 11; font.family: "Inter" }
                                    }
                                }
                            }
                        }
                    }

                }  // end contentCol
            }  // end Flickable
        }  // end outer Rectangle
    }  // end FocusScope
}
