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
    property string opencodeDb: ""
    property bool showClaude: true
    property bool showOpencode: true
    property int interval: 60000

    property real nowSeconds: Date.now() / 1000
    property var claude: null
    property var opencode: null
    property bool opencodeFailed: false

    readonly property var fiveHour: windowState(claude?.five_hour)
    readonly property var sevenDay: windowState(claude?.seven_day)

    implicitWidth: 360 * unit
    implicitHeight: column.implicitHeight

    function windowState(w) {
        if (!w || w.used_percentage === undefined)
            return null;
        var expired = w.resets_at !== undefined && w.resets_at <= nowSeconds;
        return {
            percent: expired ? 0 : w.used_percentage,
            caption: expired ? "window reset" : "resets in " + remaining(w.resets_at)
        };
    }

    function remaining(resetsAt) {
        if (resetsAt === undefined)
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

    function tokens(n) {
        if (n >= 1e9)
            return (n / 1e9).toFixed(1) + "B";
        if (n >= 1e6)
            return (n / 1e6).toFixed(1) + "M";
        if (n >= 1e3)
            return (n / 1e3).toFixed(1) + "k";
        return String(n);
    }

    function money(n) {
        return "$" + n.toFixed(2);
    }

    function parseClaude(text) {
        try {
            claude = JSON.parse(text);
        } catch (e) {
            claude = null;
        }
    }

    function parseOpencode(text) {
        try {
            var rows = JSON.parse(text);
            opencode = rows[0];
            opencodeFailed = false;
        } catch (e) {
            opencodeFailed = true;
        }
    }

    function refreshOpencode() {
        if (!showOpencode || opencodeDb === "" || ocProcess.running)
            return;
        var midnight = new Date();
        midnight.setHours(0, 0, 0, 0);
        var day = midnight.getTime();
        var week = Date.now() - 7 * 86400000;
        var total = "tokens_input + tokens_output + tokens_reasoning";
        ocProcess.command = ["sqlite3", "-readonly", "-json", opencodeDb,
            "SELECT " +
            "COALESCE(SUM(CASE WHEN time_updated >= " + day + " THEN cost END), 0) AS cost_day, " +
            "COALESCE(SUM(CASE WHEN time_updated >= " + day + " THEN " + total + " END), 0) AS tokens_day, " +
            "COUNT(CASE WHEN time_updated >= " + day + " THEN 1 END) AS sessions_day, " +
            "COALESCE(SUM(cost), 0) AS cost_week, " +
            "COALESCE(SUM(" + total + "), 0) AS tokens_week, " +
            "COUNT(*) AS sessions_week " +
            "FROM session WHERE time_updated >= " + week
        ];
        ocProcess.running = true;
    }

    FileView {
        path: root.showClaude ? root.claudeFile : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseClaude(text())
        onLoadFailed: root.claude = null
    }

    Process {
        id: ocProcess

        stdout: StdioCollector {
            onStreamFinished: root.parseOpencode(text)
        }

        onExited: code => {
            if (code !== 0)
                root.opencodeFailed = true;
        }
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
        onTriggered: root.refreshOpencode()
    }

    component SectionTitle: Text {
        font.family: root.fontFamily
        font.pixelSize: 11 * root.unit
        font.weight: Font.Bold
        font.letterSpacing: 3
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

    component StatLine: Item {
        id: line

        required property string label
        required property string value

        implicitWidth: root.implicitWidth
        implicitHeight: 22 * root.unit

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: line.label
            font.family: root.fontFamily
            font.pixelSize: 13 * root.unit
            font.weight: Font.DemiBold
            color: "#ffffff"
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: line.value
            font.family: root.fontFamily
            font.pixelSize: 12 * root.unit
            color: "#cccccc"
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

            Text {
                visible: root.fiveHour === null && root.sevenDay === null
                width: parent.width
                text: root.claude ? "No limit data in the last update." : "No data yet. Enable the statusline hook and send a message in Claude Code."
                wrapMode: Text.Wrap
                font.family: root.fontFamily
                font.pixelSize: 12 * root.unit
                color: "#8cffffff"
            }
        }

        Column {
            visible: root.showOpencode
            width: parent.width
            spacing: 6 * root.unit

            SectionTitle {
                text: "OPENCODE"
            }

            StatLine {
                visible: root.opencode !== null
                label: "Today"
                value: root.opencode ? root.money(root.opencode.cost_day) + "  ·  " + root.tokens(root.opencode.tokens_day) + " tokens  ·  " + root.opencode.sessions_day + " sess." : ""
            }

            StatLine {
                visible: root.opencode !== null
                label: "7 days"
                value: root.opencode ? root.money(root.opencode.cost_week) + "  ·  " + root.tokens(root.opencode.tokens_week) + " tokens  ·  " + root.opencode.sessions_week + " sess." : ""
            }

            Text {
                visible: root.opencode === null
                width: parent.width
                text: root.opencodeFailed ? "OpenCode database unavailable." : "Loading..."
                font.family: root.fontFamily
                font.pixelSize: 12 * root.unit
                color: "#8cffffff"
            }
        }
    }
}
