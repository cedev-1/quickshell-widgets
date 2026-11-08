import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property var targetScreen
    property string edge: "left"
    property int size: 0

    screen: targetScreen
    anchors {
        left: edge !== "right"
        right: edge !== "left"
        top: edge !== "bottom"
        bottom: edge !== "top"
    }
    implicitWidth: edge === "left" || edge === "right" ? size : 0
    implicitHeight: edge === "top" || edge === "bottom" ? size : 0
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: size
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "quickshell-frame-exclusion"
    WlrLayershell.layer: WlrLayer.Bottom
}
