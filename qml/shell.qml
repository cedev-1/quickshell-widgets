pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property var components: csv("QS_COMPONENTS").length > 0 ? csv("QS_COMPONENTS") : ["clock"]

    function csv(name) {
        return (Quickshell.env(name) || "").split(",").filter(n => n.length > 0);
    }

    function number(name, fallback) {
        var v = parseInt(Quickshell.env(name));
        return isNaN(v) ? fallback : v;
    }

    function text(name, fallback) {
        return Quickshell.env(name) || fallback;
    }

    function screensFor(component) {
        var names = csv(component + "_SCREENS");
        if (names.length === 0)
            names = csv("QS_SCREENS");
        var out = [];
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i];
            if (names.length === 0 || names.indexOf(s.name) >= 0)
                out.push(s);
        }
        return out;
    }

    function modelFor(component, key) {
        return components.indexOf(component) >= 0 ? screensFor(key) : [];
    }

    Variants {
        model: root.modelFor("clock", "CLOCK")

        delegate: DesktopLayer {
            position: root.text("CLOCK_POSITION", "bottom-right")

            DesktopClock {
                anchors.fill: parent
                clockScale: root.number("CLOCK_FONT_SIZE", 84) / 84
                bgEnabled: false
            }
        }
    }

    Variants {
        model: root.modelFor("stats", "STATS")

        delegate: DesktopLayer {
            position: root.text("STATS_POSITION", "bottom-left")

            Stats {
                anchors.fill: parent
                statsScale: root.number("STATS_FONT_SIZE", 20) / 20
                gpuEnabled: root.text("STATS_GPU", "0") === "1"
                interval: root.number("STATS_INTERVAL", 2000)
            }
        }
    }

    Variants {
        model: root.modelFor("header", "HEADER")

        delegate: HeaderWindow {
            position: root.text("HEADER_POSITION", "top")
            showTitle: root.text("HEADER_SHOW_TITLE", "1") !== "0"
            fontSize: root.number("HEADER_FONT_SIZE", 12)
            cornerRadius: root.number("HEADER_RADIUS", 10)
            fontFamily: root.text("HEADER_FONT", "JetBrainsMono Nerd Font")
        }
    }

    LazyLoader {
        active: root.components.indexOf("lock") >= 0

        Lock {
            wallpaper: root.text("LOCK_WALLPAPER", "")
            blur: root.text("LOCK_BLUR", "1") !== "0"
            cornerRadius: root.number("LOCK_RADIUS", 10)
            fontFamily: root.text("LOCK_FONT", "JetBrainsMono Nerd Font")
            pamConfig: root.text("LOCK_PAM", "quickshell-lock")
            autoUnlock: root.number("LOCK_AUTOUNLOCK", 0)
        }
    }

    LazyLoader {
        active: root.components.indexOf("frame") >= 0

        Frame {
            targetScreens: root.screensFor("FRAME")
            fontSize: root.number("FRAME_FONT_SIZE", 14)
            thickness: root.number("FRAME_THICKNESS", 10)
            rounding: root.number("FRAME_ROUNDING", 24)
            fontFamily: root.text("FRAME_FONT", "JetBrainsMono Nerd Font")
            gpu: root.text("FRAME_GPU", "0") === "1"
            hoverOpen: root.text("FRAME_HOVER", "1") !== "0"
            barEnabled: root.text("FRAME_BAR", "1") !== "0"
            barLogo: root.text("FRAME_BAR_LOGO", "1") !== "0"
            barPosition: root.text("FRAME_BAR_POSITION", "left")
            barScreens: root.csv("FRAME_BAR_SCREENS")
            launcherEnabled: root.text("FRAME_LAUNCHER", "1") !== "0"
            launcherTerminal: root.text("FRAME_LAUNCHER_TERMINAL", "kitty")
            launcherRows: root.number("FRAME_LAUNCHER_ROWS", 8)
            notificationsEnabled: root.text("FRAME_NOTIFICATIONS", "1") !== "0"
            notificationTimeout: root.number("FRAME_NOTIFICATION_TIMEOUT", 5000)
        }
    }
}
