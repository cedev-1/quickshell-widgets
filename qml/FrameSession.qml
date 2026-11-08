pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Item {
    id: root

    property real unit: 1
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int cornerRadius: 14
    property var commands: ({})

    property int selected: 0

    readonly property real buttonWidth: 88 * unit
    readonly property real buttonHeight: 72 * unit

    readonly property var items: {
        var all = [
            { icon: "", label: "Lock", command: commands.lock },
            { icon: "", label: "Logout", command: commands.logout },
            { icon: "", label: "Sleep", command: commands.suspend },
            { icon: "", label: "Reboot", command: commands.reboot },
            { icon: "", label: "Shutdown", command: commands.shutdown }
        ];
        return all.filter(i => i.command !== undefined && i.command !== "");
    }

    signal closeRequested

    function run(index): void {
        var item = items[index];
        if (!item)
            return;
        Quickshell.execDetached(["sh", "-c", item.command]);
        closeRequested();
    }

    implicitWidth: buttonWidth
    implicitHeight: items.length * buttonHeight + Math.max(0, items.length - 1) * 8 * unit

    focus: true
    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: event => {
        var ctrl = event.modifiers & Qt.ControlModifier;
        if (event.key === Qt.Key_Escape) {
            closeRequested();
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || (ctrl && event.key === Qt.Key_P)) {
            selected = Math.max(0, selected - 1);
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || (ctrl && event.key === Qt.Key_N)) {
            selected = Math.min(items.length - 1, selected + 1);
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            run(selected);
        } else {
            return;
        }
        event.accepted = true;
    }

    Column {
        spacing: 8 * root.unit

        Repeater {
            model: root.items

            Rectangle {
                id: button

                required property var modelData
                required property int index
                readonly property bool current: index === root.selected

                width: root.buttonWidth
                height: root.buttonHeight
                radius: root.cornerRadius
                color: current ? "#ffffff" : "#1affffff"

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6 * root.unit

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.modelData.icon
                        font.family: root.fontFamily
                        font.pixelSize: 24 * root.unit
                        color: button.current ? "#000000" : "#ffffff"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.modelData.label
                        font.family: root.fontFamily
                        font.pixelSize: 11 * root.unit
                        font.weight: Font.DemiBold
                        color: button.current ? "#99000000" : "#8cffffff"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: root.selected = button.index
                    onClicked: root.run(button.index)
                }
            }
        }
    }
}
