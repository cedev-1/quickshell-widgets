import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property real unit: 1
    property string fontFamily: "JetBrainsMono Nerd Font"
    property bool gpu: false
    property bool active: false

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: row

        anchors.fill: parent
        spacing: 32 * root.unit

        FrameCalendar {
            Layout.alignment: Qt.AlignTop
            unit: root.unit
            fontFamily: root.fontFamily
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6 * root.unit

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.family: root.fontFamily
                font.pixelSize: 64 * root.unit
                font.weight: Font.Bold
                color: "#ffffff"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd").toUpperCase()
                font.family: root.fontFamily
                font.pixelSize: 16 * root.unit
                font.letterSpacing: 4
                color: "#cccccc"
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "d MMMM").toUpperCase()
                font.family: root.fontFamily
                font.pixelSize: 14 * root.unit
                font.letterSpacing: 3
                color: "#8cffffff"
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            active: root.active

            sourceComponent: Stats {
                statsScale: 0.9 * root.unit
                gpuEnabled: root.gpu
            }
        }
    }
}
