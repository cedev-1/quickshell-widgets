pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property int fontSize: 14
    property int cornerRadius: 10
    property string fontFamily: "JetBrainsMono Nerd Font"
    property string terminal: "kitty"
    property int rows: 8

    property bool opened: false
    property string query: ""
    property int selected: 0

    readonly property real unit: fontSize / 14

    readonly property var results: {
        var q = query.trim().toLowerCase();
        var apps = DesktopEntries.applications.values;
        var scored = [];

        for (var i = 0; i < apps.length; i++) {
            var e = apps[i];
            if (e.noDisplay)
                continue;

            var name = (e.name || "").toLowerCase();
            var score = 0;

            if (q === "") {
                score = 1;
            } else if (name.startsWith(q)) {
                score = 4;
            } else if (name.indexOf(q) >= 0) {
                score = 3;
            } else {
                var extra = ((e.genericName || "") + " " + (e.comment || "") + " " + Array.prototype.join.call(e.keywords, " ")).toLowerCase();
                if (extra.indexOf(q) >= 0)
                    score = 2;
            }

            if (score > 0)
                scored.push({ entry: e, score: score });
        }

        scored.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return scored.map(s => s.entry);
    }

    function open(): void {
        query = "";
        selected = 0;
        opened = true;
    }

    function close(): void {
        opened = false;
    }

    function launch(entry): void {
        if (!entry)
            return;

        if (entry.runInTerminal)
            Quickshell.execDetached([terminal, "-e"].concat(Array.from(entry.command)));
        else
            entry.execute();

        close();
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            if (root.opened)
                root.close();
            else
                root.open();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: win

            required property var modelData

            readonly property bool onFocusedScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name === modelData.name : true

            screen: modelData
            visible: root.opened && onFocusedScreen
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            color: "transparent"

            WlrLayershell.namespace: "quickshell-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            onVisibleChanged: {
                if (visible) {
                    input.text = "";
                    input.forceActiveFocus();
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#33000000"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle {
                id: panel

                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.2
                width: 640 * root.unit
                height: searchBox.height + (list.height > 0 ? list.height + 8 * root.unit : 0) + 16 * root.unit
                radius: root.cornerRadius
                color: "#e6000000"

                MouseArea {
                    anchors.fill: parent
                }

                Rectangle {
                    id: searchBox

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 8 * root.unit
                    height: 48 * root.unit
                    radius: root.cornerRadius
                    color: "#26ffffff"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16 * root.unit
                        visible: input.text.length === 0
                        text: "Search applications"
                        font.family: root.fontFamily
                        font.pixelSize: 16 * root.unit
                        color: "#8cffffff"
                    }

                    TextInput {
                        id: input

                        anchors.fill: parent
                        anchors.leftMargin: 16 * root.unit
                        anchors.rightMargin: 16 * root.unit
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.fontFamily
                        font.pixelSize: 16 * root.unit
                        color: "#ffffff"
                        selectionColor: "#ffffff"
                        selectedTextColor: "#000000"
                        clip: true

                        onTextChanged: {
                            root.query = text;
                            root.selected = 0;
                        }

                        Keys.onPressed: event => {
                            var ctrl = event.modifiers & Qt.ControlModifier;
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                            } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                                root.selected = Math.min(root.results.length - 1, root.selected + 1);
                            } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                                root.selected = Math.max(0, root.selected - 1);
                            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                root.launch(root.results[root.selected]);
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }
                    }
                }

                ListView {
                    id: list

                    anchors.top: searchBox.bottom
                    anchors.topMargin: 8 * root.unit
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8 * root.unit
                    anchors.rightMargin: 8 * root.unit
                    height: Math.min(root.results.length, root.rows) * 48 * root.unit
                    clip: true
                    interactive: false
                    model: root.results
                    currentIndex: root.selected
                    highlightMoveDuration: 0

                    delegate: Rectangle {
                        id: item

                        required property var modelData
                        required property int index
                        readonly property bool current: index === root.selected

                        width: list.width
                        height: 48 * root.unit
                        radius: root.cornerRadius
                        color: current ? "#ffffff" : "transparent"

                        IconImage {
                            id: icon

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12 * root.unit
                            implicitSize: 28 * root.unit
                            source: Quickshell.iconPath(item.modelData.icon, "application-x-executable")
                        }

                        Text {
                            id: nameText

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: icon.right
                            anchors.leftMargin: 12 * root.unit
                            text: item.modelData.name
                            font.family: root.fontFamily
                            font.pixelSize: 15 * root.unit
                            font.weight: Font.DemiBold
                            color: item.current ? "#000000" : "#ffffff"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: nameText.right
                            anchors.leftMargin: 12 * root.unit
                            anchors.right: parent.right
                            anchors.rightMargin: 12 * root.unit
                            text: item.modelData.genericName || item.modelData.comment || ""
                            elide: Text.ElideRight
                            font.family: root.fontFamily
                            font.pixelSize: 13 * root.unit
                            color: item.current ? "#99000000" : "#8cffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: root.selected = item.index
                            onClicked: root.launch(item.modelData)
                        }
                    }
                }
            }
        }
    }
}
