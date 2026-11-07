pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

WlSessionLockSurface {
    id: root

    required property var controller

    readonly property real sizeScale: Math.min(1, height / 1440)
    readonly property string userName: Quickshell.env("USER") || ""

    color: "black"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: content

        anchors.fill: parent
        focus: true
        opacity: 0

        Keys.onPressed: event => root.controller.handleKey(event)

        NumberAnimation on opacity {
            running: true
            to: 1
            duration: 400
            easing.type: Easing.OutCubic
        }

        Image {
            id: wallpaper

            anchors.fill: parent
            source: root.controller.wallpaper !== "" ? "file://" + root.controller.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
        }

        MultiEffect {
            anchors.fill: wallpaper
            source: wallpaper
            visible: root.controller.blur && wallpaper.status === Image.Ready
            blurEnabled: true
            blur: 1.0
            blurMax: 48
        }

        Rectangle {
            anchors.fill: parent
            color: "#66000000"
        }

        Column {
            anchors.centerIn: parent
            spacing: 14 * root.sizeScale

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10 * root.sizeScale

                Text {
                    text: Qt.formatDateTime(clock.date, "HH")
                    font.family: root.controller.fontFamily
                    font.pixelSize: 140 * root.sizeScale
                    font.weight: Font.Bold
                    color: "#ffffff"
                }

                Text {
                    text: ":"
                    font.family: root.controller.fontFamily
                    font.pixelSize: 140 * root.sizeScale
                    color: "#aaaaaa"
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "mm")
                    font.family: root.controller.fontFamily
                    font.pixelSize: 140 * root.sizeScale
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd • d MMM").toUpperCase()
                font.family: root.controller.fontFamily
                font.pixelSize: 20 * root.sizeScale
                font.weight: Font.DemiBold
                font.letterSpacing: 4
                color: "#cccccc"
            }

            Item {
                width: 1
                height: 30 * root.sizeScale
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                font.family: root.controller.fontFamily
                font.pixelSize: 16 * root.sizeScale
                font.weight: Font.DemiBold
                color: "#cccccc"
            }

            Rectangle {
                id: field

                anchors.horizontalCenter: parent.horizontalCenter
                width: 340 * root.sizeScale
                height: 52 * root.sizeScale
                radius: root.controller.cornerRadius
                color: "#99000000"
                border.width: 1
                border.color: root.controller.failure !== 0 ? "#ff6b6b" : "#33ffffff"

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }

                transform: Translate {
                    id: shake
                }

                SequentialAnimation {
                    id: shakeAnim

                    NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 14; duration: 80 }
                    NumberAnimation { target: shake; property: "x"; to: -8; duration: 70 }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
                }

                Connections {
                    target: root.controller

                    function onRejected(): void {
                        shakeAnim.restart();
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.controller.buffer.length === 0
                    text: root.controller.checking ? "Checking…" : "Password"
                    font.family: root.controller.fontFamily
                    font.pixelSize: 14 * root.sizeScale
                    color: "#8cffffff"
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8 * root.sizeScale

                    Repeater {
                        model: Math.min(root.controller.buffer.length, 24)

                        Rectangle {
                            width: 10 * root.sizeScale
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                text: {
                    switch (root.controller.failure) {
                    case 1: return "Incorrect password";
                    case 2: return "Authentication error";
                    case 3: return "Too many attempts, try again later";
                    default: return " ";
                    }
                }
                font.family: root.controller.fontFamily
                font.pixelSize: 14 * root.sizeScale
                color: "#ff9b9b"
            }
        }
    }
}
