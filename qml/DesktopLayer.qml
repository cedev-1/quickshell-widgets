import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property var modelData
    property string position: "bottom-right"
    default property alias content: box.data

    screen: modelData
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "quickshell-widgets"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    Item {
        id: box

        readonly property bool isCenter: win.position === "center"

        implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
        implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
        width: implicitWidth
        height: implicitHeight

        anchors {
            margins: 30
            centerIn: isCenter ? parent : undefined
            left: !isCenter && win.position.endsWith("left") ? parent.left : undefined
            right: !isCenter && win.position.endsWith("right") ? parent.right : undefined
            top: !isCenter && win.position.startsWith("top") ? parent.top : undefined
            bottom: !isCenter && win.position.startsWith("bottom") ? parent.bottom : undefined
        }
    }
}
