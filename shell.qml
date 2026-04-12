// shell.qml - QuickShell entry point
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            property var modelData

            screen: modelData
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            color: "transparent"
            mask: Region {}

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            Row {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                x: -30
                y: -30
                spacing: 30

                DesktopClock {
                    clockScale: 1.0
                    bgEnabled: false
                }
            }
        }
    }
}
