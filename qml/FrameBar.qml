pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    property real unit: 1
    property bool showLogo: true
    property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? -1

    readonly property var workspaces: {
        var out = [];
        var ws = Hyprland.workspaces.values;
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].id > 0)
                out.push(ws[i]);
        }
        out.sort((a, b) => a.id - b.id);
        return out;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        visible: root.showLogo
        anchors.top: parent.top
        anchors.topMargin: 14 * root.unit
        anchors.horizontalCenter: parent.horizontalCenter
        text: ""
        font.family: root.fontFamily
        font.pixelSize: 24 * root.unit
        color: "#ffffff"
    }

    Rectangle {
        anchors.centerIn: parent
        width: 38 * root.unit
        height: wsColumn.implicitHeight + 8 * root.unit
        radius: width / 2
        color: "#1affffff"

        Column {
            id: wsColumn

            anchors.centerIn: parent
            spacing: 4 * root.unit

            Repeater {
                model: root.workspaces

                Rectangle {
                    id: pill

                    required property var modelData
                    readonly property int wsId: modelData.id
                    readonly property bool active: root.activeWorkspace === wsId

                    width: 30 * root.unit
                    height: width
                    radius: width / 2
                    color: active ? "#ffffff" : (hover.containsMouse ? "#26ffffff" : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: pill.wsId
                        font.family: root.fontFamily
                        font.pixelSize: 13 * root.unit
                        font.weight: Font.DemiBold
                        color: pill.active ? "#000000" : (hover.containsMouse ? "#ffffff" : "#8cffffff")
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + pill.wsId + " })")
                    }
                }
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14 * root.unit
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2 * root.unit

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH")
            font.family: root.fontFamily
            font.pixelSize: 18 * root.unit
            font.weight: Font.Bold
            color: "#ffffff"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            font.family: root.fontFamily
            font.pixelSize: 18 * root.unit
            font.weight: Font.Bold
            color: "#aaaaaa"
        }
    }
}
