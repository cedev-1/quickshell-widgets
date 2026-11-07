import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property var modelData
    property string position: "top"
    property bool showTitle: true
    property int fontSize: 12
    property int cornerRadius: 10
    property string fontFamily: "JetBrainsMono Nerd Font"

    screen: modelData
    anchors {
        left: true
        right: true
        top: position !== "bottom"
        bottom: position === "bottom"
    }
    implicitHeight: header.islandHeight + header.gap
    color: "transparent"

    WlrLayershell.namespace: "quickshell-header"

    mask: Region {
        Region { item: header.leftIsland }
        Region { item: header.centerIsland }
        Region { item: header.rightIsland }
    }

    Header {
        id: header
        anchors.fill: parent
        screen: win.modelData
        headerScale: win.fontSize / 12
        cornerRadius: win.cornerRadius
        fontFamily: win.fontFamily
        atBottom: win.position === "bottom"
        showTitle: win.showTitle
    }
}
