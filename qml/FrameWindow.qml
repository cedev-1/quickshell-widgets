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

    readonly property real holeLeft: barWidth
    readonly property real holeRight: content.width - edge
    readonly property real holeBottom: content.height - edge
    readonly property real panelLeft: (holeLeft + holeRight) / 2 - panelWidth / 2

    readonly property string framePath: {
        var W = content.width, H = content.height;
        var R = rounding, T = edge, L = holeLeft;
        var right = holeRight, bottom = holeBottom;

        var d = "M0 0 L" + W + " 0 L" + W + " " + H + " L0 " + H + " Z";
        d += " M" + (L + R) + " " + T;

        if (depth > 0.5) {
            var hd = depth;
            var x0 = panelLeft, x1 = panelLeft + panelWidth;
            var rf = Math.min(R, hd / 2);
            var rp = Math.min(R, hd / 2, panelWidth / 2);

            d += " H" + (x0 - rf);
            d += " A" + rf + " " + rf + " 0 0 1 " + x0 + " " + (T + rf);
            d += " V" + (T + hd - rp);
            d += " A" + rp + " " + rp + " 0 0 0 " + (x0 + rp) + " " + (T + hd);
            d += " H" + (x1 - rp);
            d += " A" + rp + " " + rp + " 0 0 0 " + x1 + " " + (T + hd - rp);
            d += " V" + (T + rf);
            d += " A" + rf + " " + rf + " 0 0 1 " + (x1 + rf) + " " + T;
        }

        d += " H" + (right - R);
        d += " A" + R + " " + R + " 0 0 1 " + right + " " + (T + R);
        d += " V" + (bottom - R);
        d += " A" + R + " " + R + " 0 0 1 " + (right - R) + " " + bottom;
        d += " H" + (L + R);
        d += " A" + R + " " + R + " 0 0 1 " + L + " " + (bottom - R);

        if (notifDepth > 0.5 && notifHeight > 1) {
            var nd = notifDepth, pb = notifBottom, py = notifTop;
            var nrf = Math.min(R, nd / 2, notifHeight / 2);

            d += " V" + (pb + nrf);
            d += " A" + nrf + " " + nrf + " 0 0 1 " + (L + nrf) + " " + pb;
            d += " H" + (L + nd - nrf);
            d += " A" + nrf + " " + nrf + " 0 0 0 " + (L + nd) + " " + (pb - nrf);
            d += " V" + (py + nrf);
            d += " A" + nrf + " " + nrf + " 0 0 0 " + (L + nd - nrf) + " " + py;
            d += " H" + (L + nrf);
            d += " A" + nrf + " " + nrf + " 0 0 1 " + L + " " + (py - nrf);
        }

        d += " V" + (T + R);
        d += " A" + R + " " + R + " 0 0 1 " + (L + R) + " " + T;
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
        Region { item: barArea }
        Region { item: topArea }
        Region { item: bottomArea }
        Region { item: rightArea }
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
            x: 0
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
            x: win.holeLeft
            y: win.notifTop
            width: win.notifDepth
            height: win.notifHeight
            clip: true
            visible: win.notifDepth > 1

            Column {
                id: notifColumn

                x: win.notifPad - (win.notifWidth - win.notifDepth)
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

        Item { id: barArea; x: 0; y: 0; width: win.barWidth; height: parent.height }
        Item { id: topArea; x: win.barWidth; y: 0; width: parent.width - win.barWidth; height: win.edge }
        Item { id: bottomArea; x: win.barWidth; y: win.holeBottom; width: parent.width - win.barWidth; height: win.edge }
        Item { id: rightArea; x: win.holeRight; y: win.edge; width: win.edge; height: win.holeBottom - win.edge }
        Item { id: cornerTopLeft; x: win.holeLeft; y: win.edge; width: win.rounding; height: win.rounding }
        Item { id: cornerTopRight; x: win.holeRight - win.rounding; y: win.edge; width: win.rounding; height: win.rounding }
        Item { id: cornerBottomLeft; x: win.holeLeft; y: win.holeBottom - win.rounding; width: win.rounding; height: win.rounding }
        Item { id: cornerBottomRight; x: win.holeRight - win.rounding; y: win.holeBottom - win.rounding; width: win.rounding; height: win.rounding }
        Item { id: notifArea; x: win.holeLeft; y: win.notifTop; width: win.notifDepth; height: win.notifHeight }

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
