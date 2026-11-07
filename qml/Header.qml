pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property var screen
    property real headerScale: 1.0
    property int cornerRadius: 10
    property string fontFamily: "JetBrainsMono Nerd Font"
    property bool atBottom: false
    property bool showTitle: true

    property alias leftIsland: leftIsland
    property alias centerIsland: centerIsland
    property alias rightIsland: rightIsland

    readonly property real islandHeight: 40 * headerScale
    readonly property real gap: 8 * headerScale
    readonly property real sideMargin: 12 * headerScale
    readonly property color islandColor: "#99000000"
    readonly property int textSize: Math.round(12 * headerScale)

    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? -1
    readonly property string title: Hyprland.activeToplevel?.title ?? ""

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

    Rectangle {
        id: leftIsland

        readonly property bool shown: root.showTitle && root.title !== ""

        anchors.left: parent.left
        anchors.leftMargin: root.sideMargin
        anchors.top: root.atBottom ? undefined : parent.top
        anchors.bottom: root.atBottom ? parent.bottom : undefined
        height: root.islandHeight
        width: shown ? Math.min(titleMetrics.width + 32 * root.headerScale, 500 * root.headerScale) : 0
        visible: shown
        radius: root.cornerRadius
        color: root.islandColor

        TextMetrics {
            id: titleMetrics
            text: root.title
            font.family: root.fontFamily
            font.pixelSize: root.textSize
            font.weight: Font.DemiBold
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 16 * root.headerScale
            anchors.rightMargin: 16 * root.headerScale
            verticalAlignment: Text.AlignVCenter
            text: root.title
            elide: Text.ElideRight
            font.family: root.fontFamily
            font.pixelSize: root.textSize
            font.weight: Font.DemiBold
            color: "#ffffff"
        }
    }

    Rectangle {
        id: centerIsland

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: root.atBottom ? undefined : parent.top
        anchors.bottom: root.atBottom ? parent.bottom : undefined
        height: root.islandHeight
        width: wsRow.implicitWidth + 28 * root.headerScale
        radius: root.cornerRadius
        color: root.islandColor

        Row {
            id: wsRow
            anchors.centerIn: parent
            spacing: 4 * root.headerScale

            Repeater {
                model: root.workspaces

                Rectangle {
                    id: pill

                    required property var modelData
                    readonly property int wsId: modelData.id
                    readonly property bool active: root.activeWorkspace === wsId

                    width: pillText.implicitWidth + 24 * root.headerScale
                    height: root.islandHeight - 10 * root.headerScale
                    radius: root.cornerRadius
                    color: active ? "#ffffff" : (hover.containsMouse ? "#26ffffff" : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        id: pillText
                        anchors.centerIn: parent
                        text: pill.wsId
                        font.family: root.fontFamily
                        font.pixelSize: root.textSize
                        font.weight: Font.DemiBold
                        color: pill.active ? "#000000" : (hover.containsMouse ? "#ffffff" : "#8cffffff")

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
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

    Rectangle {
        id: rightIsland

        anchors.right: parent.right
        anchors.rightMargin: root.sideMargin
        anchors.top: root.atBottom ? undefined : parent.top
        anchors.bottom: root.atBottom ? parent.bottom : undefined
        height: root.islandHeight
        width: clockText.implicitWidth + 32 * root.headerScale
        radius: root.cornerRadius
        color: root.islandColor

        Text {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "ddd dd MMM HH:mm")
            font.family: root.fontFamily
            font.pixelSize: root.textSize
            font.weight: Font.DemiBold
            color: "#ffffff"
        }
    }
}
