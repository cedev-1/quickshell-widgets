pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
    id: root

    property var targetScreens: []
    property int fontSize: 14
    property int thickness: 10
    property int rounding: 24
    property string fontFamily: "JetBrainsMono Nerd Font"
    property bool gpu: false
    property bool hoverOpen: true
    property bool barEnabled: true
    property bool barLogo: true
    property string barPosition: "left"
    property var barScreens: []
    property bool launcherEnabled: true
    property string launcherTerminal: "kitty"
    property int launcherRows: 8
    property bool sessionEnabled: true
    property var sessionCommands: ({})
    property bool usageEnabled: false
    property bool usageClaude: true
    property bool usageOpencode: true
    property string usageClaudeFile: ""
    property string usageOpencodeFile: ""
    property string usageOpencodeCommand: ""
    property string usageOpencodeWorkspace: ""
    property int usageInterval: 300000
    property bool notificationsEnabled: true
    property int notificationTimeout: 5000
    property int maxNotifications: 4

    property string dashboardScreen: ""
    property string launcherScreen: ""
    property string sessionScreen: ""
    property string usageScreen: ""
    property bool dashboardByHover: false
    property bool doNotDisturb: false

    readonly property real unit: fontSize / 14
    readonly property real edge: Math.round(thickness * unit)
    readonly property real barWidth: Math.round(56 * unit)

    readonly property var notificationList: {
        var server = serverLoader.item;
        if (!server)
            return [];
        var all = server.trackedNotifications.values.slice();
        all.reverse();
        return all.slice(0, maxNotifications);
    }

    function hasBar(screenName: string): bool {
        return barEnabled && (barScreens.length === 0 || barScreens.indexOf(screenName) >= 0);
    }

    function openDashboard(screenName: string, byHover: bool): void {
        dashboardScreen = screenName;
        dashboardByHover = byHover;
    }

    function closeDashboard(): void {
        dashboardScreen = "";
    }

    function toggleDashboard(): void {
        var name = Hyprland.focusedMonitor?.name ?? "";
        if (dashboardScreen === name)
            closeDashboard();
        else
            openDashboard(name, false);
    }

    function openLauncher(screenName: string): void {
        launcherScreen = screenName;
    }

    function closeLauncher(): void {
        launcherScreen = "";
    }

    function toggleLauncher(): void {
        var name = Hyprland.focusedMonitor?.name ?? "";
        if (launcherScreen === name)
            closeLauncher();
        else
            openLauncher(name);
    }

    function openSession(screenName: string): void {
        sessionScreen = screenName;
    }

    function closeSession(): void {
        sessionScreen = "";
    }

    function toggleSession(screenName: string): void {
        if (sessionScreen === screenName)
            closeSession();
        else
            openSession(screenName);
    }

    function toggleSessionOnFocused(): void {
        toggleSession(Hyprland.focusedMonitor?.name ?? "");
    }

    function toggleUsage(screenName: string): void {
        usageScreen = usageScreen === screenName ? "" : screenName;
    }

    function closeUsage(): void {
        usageScreen = "";
    }

    function clearNotifications(): void {
        var server = serverLoader.item;
        if (!server)
            return;
        var all = server.trackedNotifications.values.slice();
        for (var i = 0; i < all.length; i++)
            all[i].dismiss();
    }

    LazyLoader {
        id: serverLoader

        active: root.notificationsEnabled
        loading: true

        NotificationServer {
            actionsSupported: true
            bodySupported: true
            bodyMarkupSupported: true
            imageSupported: true

            onNotification: notification => {
                notification.tracked = true;
            }
        }
    }

    IpcHandler {
        target: "frame"

        function toggleDashboard(): void {
            root.toggleDashboard();
        }

        function closeDashboard(): void {
            root.closeDashboard();
        }

        function toggleLauncher(): void {
            root.toggleLauncher();
        }

        function closeLauncher(): void {
            root.closeLauncher();
        }

        function toggleSession(): void {
            root.toggleSessionOnFocused();
        }

        function closeSession(): void {
            root.closeSession();
        }

        function toggleUsage(): void {
            root.toggleUsage(Hyprland.focusedMonitor?.name ?? "");
        }

        function closeUsage(): void {
            root.closeUsage();
        }

        function clearNotifications(): void {
            root.clearNotifications();
        }

        function toggleDoNotDisturb(): void {
            root.doNotDisturb = !root.doNotDisturb;
        }

        function isDoNotDisturb(): bool {
            return root.doNotDisturb;
        }
    }

    Variants {
        model: root.targetScreens

        delegate: Scope {
            id: perScreen

            required property var modelData

            FrameWindow {
                modelData: perScreen.modelData
                controller: root
            }

            FrameExclusion {
                targetScreen: perScreen.modelData
                edge: "left"
                size: root.barPosition !== "right" && root.hasBar(perScreen.modelData.name) ? root.barWidth : root.edge
            }

            FrameExclusion {
                targetScreen: perScreen.modelData
                edge: "top"
                size: root.edge
            }

            FrameExclusion {
                targetScreen: perScreen.modelData
                edge: "right"
                size: root.barPosition === "right" && root.hasBar(perScreen.modelData.name) ? root.barWidth : root.edge
            }

            FrameExclusion {
                targetScreen: perScreen.modelData
                edge: "bottom"
                size: root.edge
            }
        }
    }
}
