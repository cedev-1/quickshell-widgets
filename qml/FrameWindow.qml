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

    readonly property real notifPad: 16 * unit
    readonly property real notifWidth: 360 * unit + notifPad * 2
    readonly property real notifTarget: Math.min(notifColumn.implicitHeight + notifPad * 2, content.height * 0.55)
    readonly property bool notifShow: onFocusedScreen && !controller.doNotDisturb && controller.notificationList.length > 0
    property real notifHeight: 0
    property real notifDepth: 0
    readonly property real notifBottom: content.height - 90 * unit
    readonly property real notifTop: notifBottom - notifHeight

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
        d += " V" + (bottom - R);
        d += arc(R, right - R, bottom, 1);
        d += hline(L + R);
        d += arc(R, L, bottom - R, 1);

        if (notifDepth > 0.5 && notifHeight > 1) {
            var nd = notifDepth, pb = notifBottom, py = notifTop;
            var nrf = Math.min(R, nd / 2, notifHeight / 2);

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
    }

    NumberAnimation {
        id: notifAnimation

        target: win
        property: "notifDepth"
        duration: 300
        easing.type: Easing.OutCubic
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

    Behavior on notifHeight {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Item {
        id: content

        anchors.fill: parent

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
            visible: win.hasBar
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
            y: win.notifTop
            width: win.notifDepth
            height: win.notifHeight
            clip: true
            visible: win.notifDepth > 1

            Column {
                id: notifColumn

                x: win.barRight ? win.notifPad + (win.notifWidth - win.notifDepth) : win.notifPad - (win.notifWidth - win.notifDepth)
                y: win.notifPad
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
        }

        Item { id: leftArea; x: 0; y: 0; width: win.leftInset; height: parent.height }
        Item { id: rightArea; x: parent.width - win.rightInset; y: 0; width: win.rightInset; height: parent.height }
        Item { id: topArea; x: win.leftInset; y: 0; width: parent.width - win.leftInset - win.rightInset; height: win.edge }
        Item { id: bottomArea; x: win.leftInset; y: win.holeBottom; width: parent.width - win.leftInset - win.rightInset; height: win.edge }
        Item { id: cornerTopLeft; x: win.holeLeft; y: win.edge; width: win.rounding; height: win.rounding }
        Item { id: cornerTopRight; x: win.holeRight - win.rounding; y: win.edge; width: win.rounding; height: win.rounding }
        Item { id: cornerBottomLeft; x: win.holeLeft; y: win.holeBottom - win.rounding; width: win.rounding; height: win.rounding }
        Item { id: cornerBottomRight; x: win.holeRight - win.rounding; y: win.holeBottom - win.rounding; width: win.rounding; height: win.rounding }
        Item { id: notifArea; x: win.barRight ? win.holeRight - win.notifDepth : win.holeLeft; y: win.notifTop; width: win.notifDepth; height: win.notifHeight }

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
