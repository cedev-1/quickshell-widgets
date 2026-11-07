// shell.qml - QuickShell entry point
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    // Set by the NixOS module through environment variables
    readonly property string position: Quickshell.env("CLOCK_POSITION") || "bottom-right"
    readonly property int fontSize: parseInt(Quickshell.env("CLOCK_FONT_SIZE")) || 84

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData

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

            DesktopClock {
                id: clock
                clockScale: fontSize / 84
                bgEnabled: false

                readonly property bool isCenter: position === "center"
                anchors {
                    margins: 30
                    centerIn: isCenter ? parent : undefined
                    left: !isCenter && position.endsWith("left") ? parent.left : undefined
                    right: !isCenter && position.endsWith("right") ? parent.right : undefined
                    top: !isCenter && position.startsWith("top") ? parent.top : undefined
                    bottom: !isCenter && position.startsWith("bottom") ? parent.bottom : undefined
                }
            }
        }
    }
}
