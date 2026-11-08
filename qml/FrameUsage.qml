pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real unit: 1
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int cornerRadius: 14
    property string claudeFile: ""
    property string opencodeFile: ""
    property string opencodeCommand: ""
    property string opencodeWorkspace: ""
    property bool showClaude: true
    property bool showOpencode: true
    property int interval: 300000

    property real nowSeconds: Date.now() / 1000
    property var claude: null
    property var opencode: null

    readonly property var fiveHour: windowState(claude?.five_hour?.used_percentage, claude?.five_hour?.resets_at, false)
    readonly property var sevenDay: windowState(claude?.seven_day?.used_percentage, claude?.seven_day?.resets_at, false)
    readonly property var goRolling: goWindow(opencode?.rolling)
    readonly property var goWeekly: goWindow(opencode?.weekly)
    readonly property var goMonthly: goWindow(opencode?.monthly)

    implicitWidth: 360 * unit
    implicitHeight: column.implicitHeight

    function windowState(percent, resetsAt, limited) {
        if (percent === undefined || percent === null)
            return null;
        var expired = resetsAt !== undefined && resetsAt !== null && resetsAt <= nowSeconds;
        var prefix = limited && !expired ? "limit reached  ·  " : "";
        return {
            percent: expired ? 0 : percent,
            caption: expired ? "window reset" : prefix + "resets in " + remaining(resetsAt)
        };
    }

    function goWindow(w) {
        if (!w || w.percent === undefined)
            return null;
        var resets = w.resetsAt ? Date.parse(w.resetsAt) / 1000 : undefined;
        return windowState(w.percent, resets, w.status === "rate-limited");
    }

    function remaining(resetsAt) {
        if (resetsAt === undefined || resetsAt === null || isNaN(resetsAt))
            return "?";
        var s = Math.max(0, resetsAt - nowSeconds);
        var d = Math.floor(s / 86400);
        var h = Math.floor((s % 86400) / 3600);
        var m = Math.floor((s % 3600) / 60);
        if (d > 0)
            return d + "d " + h + "h";
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    function ago(seconds) {
        var s = Math.max(0, nowSeconds - seconds);
        if (s < 90)
            return "just now";
        if (s < 5400)
            return Math.round(s / 60) + " min ago";
        if (s < 172800)
            return Math.round(s / 3600) + " h ago";
        return Math.round(s / 86400) + " d ago";
    }

    function parseJson(text) {
        try {
            return JSON.parse(text);
        } catch (e) {
            return null;
        }
    }

    function refreshOpencode() {
        if (!showOpencode || opencodeCommand === "" || fetchProcess.running)
            return;
        if (opencode && opencode.updated && nowSeconds - opencode.updated < 60 && !opencode.error)
            return;
        var command = [opencodeCommand];
        if (opencodeWorkspace !== "")
            command.push(opencodeWorkspace);
        fetchProcess.command = command;
        fetchProcess.running = true;
    }

    FileView {
        path: root.showClaude ? root.claudeFile : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.claude = root.parseJson(text())
        onLoadFailed: root.claude = null
    }

    FileView {
        path: root.showOpencode ? root.opencodeFile : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.opencode = root.parseJson(text())
        onLoadFailed: root.opencode = null
    }

    Process {
        id: fetchProcess
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.nowSeconds = Date.now() / 1000
    }

    Timer {
        interval: root.interval
        running: root.showOpencode
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.nowSeconds = Date.now() / 1000;
            root.refreshOpencode();
        }
    }

    component SectionTitle: Text {
        font.family: root.fontFamily
        font.pixelSize: 11 * root.unit
        font.weight: Font.Bold
        font.letterSpacing: 3
        color: "#8cffffff"
    }

    component Note: Text {
        width: parent.width
        wrapMode: Text.Wrap
        font.family: root.fontFamily
        font.pixelSize: 12 * root.unit
        color: "#8cffffff"
    }

    component UsageBar: Item {
        id: bar

        required property string label
        required property var info

        implicitWidth: root.implicitWidth
        implicitHeight: 40 * root.unit

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            text: bar.label
            font.family: root.fontFamily
            font.pixelSize: 13 * root.unit
            font.weight: Font.DemiBold
            color: "#ffffff"
        }

        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: bar.info ? Math.round(bar.info.percent) + "%" : "--"
            font.family: root.fontFamily
            font.pixelSize: 13 * root.unit
            font.weight: Font.Bold
            color: bar.info && bar.info.percent >= 90 ? "#ff9b9b" : "#ffffff"
        }

        Rectangle {
            id: track

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 2 * root.unit
            height: 6 * root.unit
            radius: height / 2
            color: "#33ffffff"

            Rectangle {
                width: bar.info ? track.width * Math.min(100, bar.info.percent) / 100 : 0
                height: parent.height
                radius: parent.radius
                color: bar.info && bar.info.percent >= 90 ? "#ff6b6b" : "#ffffff"

                Behavior on width {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: bar.info ? bar.info.caption : ""
            font.family: root.fontFamily
            font.pixelSize: 11 * root.unit
            color: "#8cffffff"
        }
    }

    Column {
        id: column

        width: root.implicitWidth
        spacing: 16 * root.unit

        Row {
            spacing: 10 * root.unit

            Text {
                text: "󰚩"
                font.family: root.fontFamily
                font.pixelSize: 22 * root.unit
                color: "#ffffff"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "AI USAGE"
                font.family: root.fontFamily
                font.pixelSize: 14 * root.unit
                font.weight: Font.Bold
                font.letterSpacing: 3
                color: "#ffffff"
            }
        }

        Column {
            visible: root.showClaude
            width: parent.width
            spacing: 10 * root.unit

            SectionTitle {
                text: root.claude ? "CLAUDE  ·  " + root.ago(root.claude.updated) : "CLAUDE"
            }

            UsageBar {
                label: "5 hours"
                info: root.fiveHour
                visible: root.fiveHour !== null
            }

            UsageBar {
                label: "Week"
                info: root.sevenDay
                visible: root.sevenDay !== null
            }

            Note {
                visible: root.fiveHour === null && root.sevenDay === null
                text: root.claude ? "No limit data in the last update." : "No data yet. Enable the statusline hook and send a message in Claude Code."
            }
        }

        Column {
            visible: root.showOpencode
            width: parent.width
            spacing: 10 * root.unit

            SectionTitle {
                text: root.opencode && root.opencode.updated ? "OPENCODE GO  ·  " + root.ago(root.opencode.updated) : "OPENCODE GO"
            }

            UsageBar {
                label: "5 hours"
                info: root.goRolling
                visible: root.goRolling !== null
            }

            UsageBar {
                label: "Week"
                info: root.goWeekly
                visible: root.goWeekly !== null
            }

            UsageBar {
                label: "Month"
                info: root.goMonthly
                visible: root.goMonthly !== null
            }

            Note {
                visible: root.goWeekly === null && !(root.opencode && root.opencode.error)
                text: "Loading..."
            }

            Note {
                visible: root.opencode !== null && root.opencode.error !== undefined
                text: root.opencode && root.opencode.error ? "Last refresh failed: " + root.opencode.error + ". Check your OpenCode Go key." : ""
                color: "#ff9b9b"
            }
        }
    }
}
