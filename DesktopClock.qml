pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    implicitWidth: layout.implicitWidth + 40 * clockScale
    implicitHeight: layout.implicitHeight + 20 * clockScale

    property real clockScale: 1.0
    property bool bgEnabled: false

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 20 * clockScale

        RowLayout {
            spacing: 10 * clockScale

            Text {
                text: {
                    var h = clock.date.getHours();
                    return String(h).padStart(2, '0');
                }
                font.pointSize: 84 * clockScale
                font.weight: Font.Bold
                color: "#ffffff"
            }

            Text {
                text: ":"
                font.pointSize: 84 * clockScale
                color: "#aaaaaa"
                opacity: 0.8
                Layout.topMargin: -20 * clockScale
            }

            Text {
                text: {
                    var m = clock.date.getMinutes();
                    return String(m).padStart(2, '0');
                }
                font.pointSize: 84 * clockScale
                font.weight: Font.Bold
                color: "#ffffff"
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 4 * clockScale
            Layout.topMargin: 20 * clockScale
            Layout.bottomMargin: 20 * clockScale
            radius: 1000
            color: "#aaaaaa"
            opacity: 0.8
        }

        ColumnLayout {
            spacing: 0

            Text {
                text: {
                    var months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                                  "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"];
                    return months[clock.date.getMonth()];
                }
                font.pointSize: 18 * clockScale
                font.weight: Font.Bold
                font.letterSpacing: 4
                color: "#cccccc"
            }

            Text {
                text: String(clock.date.getDate())
                font.pointSize: 48 * clockScale
                font.weight: Font.Medium
                font.letterSpacing: 2
                color: "#ffffff"
            }

            Text {
                text: {
                    var days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];
                    return days[clock.date.getDay()];
                }
                font.pointSize: 18 * clockScale
                font.letterSpacing: 2
                color: "#cccccc"
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
