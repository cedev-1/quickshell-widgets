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
    property bool notificationsEnabled: true
    property int notificationTimeout: 5000
    property int maxNotifications: 4

    property string dashboardScreen: ""
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
                size: root.barWidth
            }

            FrameExclusion {
                targetScreen: perScreen.modelData
                edge: "top"
                size: root.edge
            }

            FrameExclusion {
                targetScreen: perScreen.modelData
                edge: "right"
                size: root.edge
            }

            FrameExclusion {
                targetScreen: perScreen.modelData
                edge: "bottom"
                size: root.edge
            }
        }
    }
}
