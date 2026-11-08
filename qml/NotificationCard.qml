pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
    id: card

    required property var modelData
    required property real unit
    required property int cornerRadius
    required property string fontFamily
    required property int defaultTimeout

    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
    readonly property int timeout: modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : (critical ? 0 : defaultTimeout)
    readonly property string iconSource: {
        if (modelData.image !== "")
            return modelData.image;
        var icon = modelData.appIcon;
        if (icon === "")
            return "";
        return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true);
    }

    implicitWidth: 360 * unit
    implicitHeight: content.implicitHeight + 24 * unit
    radius: cornerRadius
    color: "#1affffff"
    border.width: critical ? 1 : 0
    border.color: "#ff6b6b"

    Timer {
        interval: card.timeout
        running: card.timeout > 0 && !hover.hovered
        onTriggered: card.modelData.expire()
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        onTapped: card.modelData.dismiss()
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.margins: 12 * card.unit
        spacing: 12 * card.unit

        IconImage {
            Layout.alignment: Qt.AlignTop
            visible: card.iconSource !== ""
            implicitSize: 40 * card.unit
            source: card.iconSource
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * card.unit

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.modelData.appName
                elide: Text.ElideRight
                font.family: card.fontFamily
                font.pixelSize: 11 * card.unit
                font.weight: Font.Bold
                font.letterSpacing: 2
                font.capitalization: Font.AllUppercase
                color: "#8cffffff"
            }

            Text {
                Layout.fillWidth: true
                text: card.modelData.summary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: card.fontFamily
                font.pixelSize: 14 * card.unit
                font.weight: Font.Bold
                color: "#ffffff"
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.modelData.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                font.family: card.fontFamily
                font.pixelSize: 13 * card.unit
                color: "#cccccc"
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4 * card.unit
                visible: card.modelData.actions.length > 0
                spacing: 6 * card.unit

                Repeater {
                    model: card.modelData.actions

                    Rectangle {
                        id: action

                        required property var modelData

                        width: label.implicitWidth + 24 * card.unit
                        height: 28 * card.unit
                        radius: card.cornerRadius
                        color: actionArea.containsMouse ? "#ffffff" : "#26ffffff"

                        Text {
                            id: label

                            anchors.centerIn: parent
                            text: action.modelData.text
                            font.family: card.fontFamily
                            font.pixelSize: 12 * card.unit
                            font.weight: Font.DemiBold
                            color: actionArea.containsMouse ? "#000000" : "#ffffff"
                        }

                        MouseArea {
                            id: actionArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                action.modelData.invoke();
                                card.modelData.dismiss();
                            }
                        }
                    }
                }
            }
        }
    }
}
