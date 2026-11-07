import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string label: ""
    property string value: ""
    property real fraction: 0
    property real statsScale: 1.0

    implicitWidth: 340 * statsScale
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4 * root.statsScale

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.label
                font.pixelSize: 14 * root.statsScale
                font.weight: Font.Bold
                font.letterSpacing: 3
                color: "#cccccc"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.value
                font.pixelSize: 20 * root.statsScale
                font.weight: Font.Bold
                color: "#ffffff"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6 * root.statsScale
            radius: height / 2
            color: "#ffffff"
            opacity: 0.2

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.max(0, Math.min(1, root.fraction))
                radius: parent.radius
                color: "#ffffff"

                Behavior on width {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
