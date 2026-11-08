import QtQuick
import Quickshell

Item {
    id: root

    property real unit: 1
    property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property int year: clock.date.getFullYear()
    readonly property int month: clock.date.getMonth()
    readonly property int today: clock.date.getDate()
    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()
    readonly property real cell: 32 * unit

    implicitWidth: cell * 7
    implicitHeight: title.implicitHeight + 8 * unit + cell * 7

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: title

        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(clock.date, "MMMM yyyy").toUpperCase()
        font.family: root.fontFamily
        font.pixelSize: 14 * root.unit
        font.weight: Font.Bold
        font.letterSpacing: 3
        color: "#ffffff"
    }

    Grid {
        anchors.top: title.bottom
        anchors.topMargin: 8 * root.unit
        columns: 7

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]

            Text {
                required property string modelData

                width: root.cell
                height: root.cell
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                font.family: root.fontFamily
                font.pixelSize: 12 * root.unit
                font.weight: Font.Bold
                color: "#8cffffff"
            }
        }

        Repeater {
            model: 42

            Item {
                id: day

                required property int index
                readonly property int number: index - root.offset + 1
                readonly property bool valid: number >= 1 && number <= root.daysInMonth
                readonly property bool isToday: valid && number === root.today

                width: root.cell
                height: root.cell

                Rectangle {
                    anchors.centerIn: parent
                    width: root.cell - 4 * root.unit
                    height: width
                    radius: width / 2
                    visible: day.isToday
                    color: "#ffffff"
                }

                Text {
                    anchors.centerIn: parent
                    visible: day.valid
                    text: day.number
                    font.family: root.fontFamily
                    font.pixelSize: 13 * root.unit
                    font.weight: Font.DemiBold
                    color: day.isToday ? "#000000" : "#ffffff"
                }
            }
        }
    }
}
