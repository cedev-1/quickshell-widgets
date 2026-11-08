pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property var modelData
    required property var controller

    readonly property real unit: controller.unit
    readonly property real edge: controller.edge
    readonly property real barWidth: controller.barWidth
    readonly property real rounding: controller.rounding
    readonly property color frameColor: "#0a0a0a"

    readonly property bool hasBar: controller.hasBar(modelData.name)
    readonly property bool barRight: controller.barPosition === "right"
    readonly property real barInset: hasBar ? barWidth : edge
    readonly property real leftInset: barRight ? edge : barInset
    readonly property real rightInset: barRight ? barInset : edge

    readonly property bool onFocusedScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name === modelData.name : true

    readonly property real pad: 24 * unit
    readonly property real panelWidth: dashboard.implicitWidth + pad * 2
    readonly property real panelHeight: dashboard.implicitHeight + pad * 2
    readonly property bool open: controller.dashboardScreen === modelData.name
    property real depth: open ? panelHeight : 0

    readonly property bool launcherOpen: controller.launcherEnabled && controller.launcherScreen === modelData.name
    readonly property real launcherPad: 16 * unit
    readonly property real launcherWidth: 640 * unit + launcherPad * 2
    readonly property real launcherTarget: launcherOpen ? launcherLoader.implicitHeight + launcherPad * 2 : 0
    property real launcherDepth: launcherTarget
    readonly property real launcherLeft: (holeLeft + holeRight) / 2 - launcherWidth / 2

    readonly property bool sessionOpen: controller.sessionEnabled && controller.sessionScreen === modelData.name
    readonly property bool sessionOnRight: !barRight
    readonly property real sessionPad: 16 * unit
    readonly property real sessionWidth: sessionLoader.implicitWidth + sessionPad * 2
    readonly property real sessionHeight: sessionLoader.implicitHeight + sessionPad * 2
    readonly property real sessionTop: (edge + holeBottom) / 2 - sessionHeight / 2
    property real sessionDepth: sessionOpen ? sessionWidth : 0
    readonly property bool overlayOpen: launcherOpen || sessionOpen

    readonly property real notifPad: 16 * unit
    readonly property real notifWidth: 360 * unit + notifPad * 2
    readonly property bool usageOpen: controller.usageEnabled && controller.usageScreen === modelData.name
    property bool usageVisible: false
    readonly property real notifTarget: Math.min((usageVisible ? usageLoader.implicitHeight : notifColumn.implicitHeight) + notifPad * 2, content.height * 0.55)
    readonly property bool notifShow: usageOpen || (onFocusedScreen && !controller.doNotDisturb && controller.notificationList.length > 0)
    property real notifHeight: 0
    property real notifDepth: 0
    readonly property real notifBottom: content.height - 90 * unit
    readonly property real notifOpenTop: notifBottom - notifHeight
    readonly property real notifProgress: notifWidth > 0 ? Math.max(0, Math.min(1, notifDepth / notifWidth)) : 0
    readonly property real notifAnchorY: hasBar && controller.usageEnabled ? bar.usageCenterY : notifBottom
    readonly property real notifEffBottom: notifAnchorY + (notifBottom - notifAnchorY) * notifProgress
    readonly property real notifEffTop: notifAnchorY + (notifOpenTop - notifAnchorY) * notifProgress
    readonly property real notifEffHeight: notifEffBottom - notifEffTop

    readonly property real holeLeft: leftInset
    readonly property real holeRight: content.width - rightInset
    readonly property real holeBottom: content.height - edge
    readonly property real panelLeft: (holeLeft + holeRight) / 2 - panelWidth / 2

    readonly property string framePath: {
        var W = content.width, H = content.height;
        var R = rounding, T = edge, L = barInset;
        var right = W - edge, bottom = H - edge;
        var mirror = barRight;

        function X(x) {
            return mirror ? W - x : x;
        }

        function arc(r, x, y, sweep) {
            return " A" + r + " " + r + " 0 0 " + (mirror ? 1 - sweep : sweep) + " " + X(x) + " " + y;
        }

        function hline(x) {
            return " H" + X(x);
        }

        var d = "M0 0 L" + W + " 0 L" + W + " " + H + " L0 " + H + " Z";
        d += " M" + X(L + R) + " " + T;

        if (depth > 0.5) {
            var hd = depth;
            var x0 = (L + right) / 2 - panelWidth / 2, x1 = x0 + panelWidth;
            var rf = Math.min(R, hd / 2);
            var rp = Math.min(R, hd / 2, panelWidth / 2);

            d += hline(x0 - rf);
            d += arc(rf, x0, T + rf, 1);
            d += " V" + (T + hd - rp);
            d += arc(rp, x0 + rp, T + hd, 0);
            d += hline(x1 - rp);
            d += arc(rp, x1, T + hd - rp, 0);
            d += " V" + (T + rf);
            d += arc(rf, x1 + rf, T, 1);
        }

        d += hline(right - R);
        d += arc(R, right, T + R, 1);

        if (sessionDepth > 0.5 && sessionHeight > 1) {
            var sd = sessionDepth, sh = sessionHeight;
            var sy = (T + bottom) / 2 - sh / 2;
            var sf = Math.min(R, sd / 2, sh / 2);

            d += " V" + (sy - sf);
            d += arc(sf, right - sf, sy, 1);
            d += hline(right - sd + sf);
            d += arc(sf, right - sd, sy + sf, 0);
            d += " V" + (sy + sh - sf);
            d += arc(sf, right - sd + sf, sy + sh, 0);
            d += hline(right - sf);
            d += arc(sf, right, sy + sh + sf, 1);
        }
        d += " V" + (bottom - R);
        d += arc(R, right - R, bottom, 1);

        if (launcherDepth > 0.5) {
            var ld = launcherDepth;
            var lx0 = (L + right) / 2 - launcherWidth / 2, lx1 = lx0 + launcherWidth;
            var lf = Math.min(R, ld / 2);
            var lp = Math.min(R, ld / 2, launcherWidth / 2);

            d += hline(lx1 + lf);
            d += arc(lf, lx1, bottom - lf, 1);
            d += " V" + (bottom - ld + lp);
            d += arc(lp, lx1 - lp, bottom - ld, 0);
            d += hline(lx0 + lp);
            d += arc(lp, lx0, bottom - ld + lp, 0);
            d += " V" + (bottom - lf);
            d += arc(lf, lx0 - lf, bottom, 1);
        }
        d += hline(L + R);
        d += arc(R, L, bottom - R, 1);

        if (notifDepth > 0.5 && notifEffHeight > 1) {
            var nd = notifDepth, pb = notifEffBottom, py = notifEffTop;
            var nrf = Math.min(R, nd / 2, notifEffHeight / 2);

            d += " V" + (pb + nrf);
            d += arc(nrf, L + nrf, pb, 1);
            d += hline(L + nd - nrf);
            d += arc(nrf, L + nd, pb - nrf, 0);
            d += " V" + (py + nrf);
            d += arc(nrf, L + nd - nrf, py, 0);
            d += hline(L + nrf);
            d += arc(nrf, L, py - nrf, 1);
        }

        d += " V" + (T + R);
        d += arc(R, L + R, T, 1);
        d += " Z";
        return d;
    }

    screen: modelData
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    color: "transparent"

    WlrLayershell.namespace: "quickshell-frame"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: overlayOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Timer {
        id: grabDelay

        property bool grabReady: false

        interval: 250
        running: win.overlayOpen
        onTriggered: grabReady = true
    }

    onOverlayOpenChanged: {
        if (!overlayOpen)
            grabDelay.grabReady = false;
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.overlayOpen && grabDelay.grabReady
        onCleared: {
            win.controller.closeLauncher();
            win.controller.closeSession();
        }
    }

    mask: Region {
        Region { item: leftArea }
        Region { item: rightArea }
        Region { item: topArea }
        Region { item: bottomArea }
        Region { item: cornerTopLeft }
        Region { item: cornerTopRight }
        Region { item: cornerBottomLeft }
        Region { item: cornerBottomRight }
        Region { item: panelArea }
        Region { item: notifArea }
        Region { item: launcherArea }
        Region { item: sessionArea }
        Region { item: outsideArea }
    }

    NumberAnimation {
        id: notifAnimation

        target: win
        property: "notifDepth"
        duration: 300
        easing.type: Easing.OutCubic
    }

    onUsageOpenChanged: {
        if (usageOpen)
            usageVisible = true;
        else if (notifShow)
            usageVisible = false;
    }

    onNotifDepthChanged: {
        if (notifDepth <= 0.5 && !usageOpen)
            usageVisible = false;
    }

    onNotifShowChanged: {
        notifAnimation.stop();
        notifAnimation.to = notifShow ? notifWidth : 0;
        notifAnimation.start();
        if (notifShow)
            notifHeight = notifTarget;
    }

    onNotifTargetChanged: {
        if (notifShow)
            notifHeight = notifTarget;
    }

    Behavior on depth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Behavior on sessionDepth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Behavior on launcherDepth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Behavior on notifHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Item {
        id: content

        anchors.fill: parent

        Item {
            id: outsideArea

            x: win.holeLeft
            y: win.edge
            width: win.usageOpen ? win.holeRight - win.holeLeft : 0
            height: win.usageOpen ? win.holeBottom - win.edge : 0

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: win.controller.closeUsage()
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.6
                shadowOpacity: 0.7
                shadowColor: "#000000"
            }

            ShapePath {
                fillColor: win.frameColor
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill

                PathSvg {
                    path: win.framePath
                }
            }
        }

        FrameBar {
            id: bar

            visible: win.hasBar
            showLogo: win.controller.barLogo
            showUsage: win.controller.usageEnabled
            onUsageRequested: win.controller.toggleUsage(win.modelData.name)
            showPower: win.controller.sessionEnabled
            onPowerRequested: win.controller.toggleSession(win.modelData.name)
            x: win.barRight ? parent.width - win.barWidth : 0
            y: 0
            width: win.barWidth
            height: parent.height
            unit: win.unit
            fontFamily: win.controller.fontFamily
        }

        Item {
            x: win.panelLeft
            y: win.edge
            width: win.panelWidth
            height: win.depth
            clip: true
            visible: win.depth > 1

            FrameDashboard {
                id: dashboard

                x: win.pad
                y: win.pad
                unit: win.unit
                fontFamily: win.controller.fontFamily
                gpu: win.controller.gpu
                active: win.depth > 1
            }
        }

        Item {
            x: win.barRight ? win.holeRight - win.notifDepth : win.holeLeft
            y: win.notifEffTop
            width: win.notifDepth
            height: win.notifEffHeight
            clip: true
            visible: win.notifDepth > 1

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Column {
                id: notifColumn

                visible: !win.usageVisible

                x: win.barRight ? win.notifPad + (win.notifWidth - win.notifDepth) : win.notifPad - (win.notifWidth - win.notifDepth)
                y: (win.notifOpenTop - win.notifEffTop) + win.notifPad
                spacing: 8 * win.unit

                Repeater {
                    model: win.controller.notificationList

                    NotificationCard {
                        unit: win.unit
                        cornerRadius: Math.round(win.rounding * 0.6)
                        fontFamily: win.controller.fontFamily
                        defaultTimeout: win.controller.notificationTimeout
                    }
                }
            }

            Loader {
                id: usageLoader

                x: win.barRight ? win.notifPad + (win.notifWidth - win.notifDepth) : win.notifPad - (win.notifWidth - win.notifDepth)
                y: (win.notifOpenTop - win.notifEffTop) + win.notifPad
                active: win.usageVisible

                sourceComponent: FrameUsage {
                    unit: win.unit
                    fontFamily: win.controller.fontFamily
                    claudeFile: win.controller.usageClaudeFile
                    opencodeFile: win.controller.usageOpencodeFile
                    opencodeCommand: win.controller.usageOpencodeCommand
                    opencodeWorkspace: win.controller.usageOpencodeWorkspace
                    showClaude: win.controller.usageClaude
                    showOpencode: win.controller.usageOpencode
                    interval: win.controller.usageInterval
                }
            }
        }

        Item {
            x: win.launcherLeft
            y: win.holeBottom - win.launcherDepth
            width: win.launcherWidth
            height: win.launcherDepth
            clip: true
            visible: win.launcherDepth > 1

            Loader {
                id: launcherLoader

                x: win.launcherPad
                anchors.bottom: parent.bottom
                anchors.bottomMargin: win.launcherPad
                active: win.launcherOpen || win.launcherDepth > 1

                sourceComponent: FrameLauncher {
                    unit: win.unit
                    fontFamily: win.controller.fontFamily
                    cornerRadius: Math.round(win.rounding * 0.6)
                    terminal: win.controller.launcherTerminal
                    rows: win.controller.launcherRows

                    onCloseRequested: win.controller.closeLauncher()
                }
            }
        }

        Item {
            x: win.sessionOnRight ? win.holeRight - win.sessionDepth : win.holeLeft
            y: win.sessionTop
            width: win.sessionDepth
            height: win.sessionHeight
            clip: true
            visible: win.sessionDepth > 1

            Loader {
                id: sessionLoader

                x: win.sessionOnRight ? win.sessionPad + (win.sessionWidth - win.sessionDepth) : win.sessionPad - (win.sessionWidth - win.sessionDepth)
                y: win.sessionPad
                active: win.sessionOpen || win.sessionDepth > 1

                sourceComponent: FrameSession {
                    unit: win.unit
                    fontFamily: win.controller.fontFamily
                    cornerRadius: Math.round(win.rounding * 0.6)
                    commands: win.controller.sessionCommands

                    onCloseRequested: win.controller.closeSession()
                }
            }
        }

        Item { id: leftArea; x: 0; y: 0; width: win.leftInset; height: parent.height }
        Item { id: rightArea; x: parent.width - win.rightInset; y: 0; width: win.rightInset; height: parent.height }
        Item { id: topArea; x: win.leftInset; y: 0; width: parent.width - win.leftInset - win.rightInset; height: win.edge }
        Item { id: bottomArea; x: win.leftInset; y: win.holeBottom; width: parent.width - win.leftInset - win.rightInset; height: win.edge }
        Item { id: cornerTopLeft; x: win.holeLeft; y: win.edge; width: win.rounding; height: win.rounding }
        Item { id: cornerTopRight; x: win.holeRight - win.rounding; y: win.edge; width: win.rounding; height: win.rounding }
        Item { id: cornerBottomLeft; x: win.holeLeft; y: win.holeBottom - win.rounding; width: win.rounding; height: win.rounding }
        Item { id: cornerBottomRight; x: win.holeRight - win.rounding; y: win.holeBottom - win.rounding; width: win.rounding; height: win.rounding }
        Item { id: notifArea; x: win.barRight ? win.holeRight - win.notifDepth : win.holeLeft; y: win.notifEffTop; width: win.notifDepth; height: win.notifEffHeight }
        Item { id: launcherArea; x: win.launcherLeft; y: win.holeBottom - win.launcherDepth; width: win.launcherWidth; height: win.launcherDepth + win.edge }
        Item { id: sessionArea; x: win.sessionOnRight ? win.holeRight - win.sessionDepth : win.holeLeft; y: win.sessionTop; width: win.sessionDepth; height: win.sessionHeight }

        Item {
            id: panelArea

            x: win.panelLeft
            y: 0
            width: win.panelWidth
            height: win.edge + win.depth

            HoverHandler {
                id: hover

                onHoveredChanged: {
                    if (hovered) {
                        closeTimer.stop();
                        if (win.controller.hoverOpen)
                            win.controller.openDashboard(win.modelData.name, true);
                    } else if (win.open && win.controller.dashboardByHover) {
                        closeTimer.restart();
                    }
                }
            }

            Timer {
                id: closeTimer

                interval: 350
                onTriggered: {
                    if (!hover.hovered)
                        win.controller.closeDashboard();
                }
            }
        }
    }
}
