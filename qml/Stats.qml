pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real statsScale: 1.0
    property bool gpuEnabled: false
    property int interval: 2000

    implicitWidth: layout.implicitWidth + 40 * statsScale
    implicitHeight: layout.implicitHeight + 20 * statsScale

    // Values (fractions are 0..1, sizes in bytes, temps in °C, -1 = unknown)
    property real cpu: 0
    property real cpuTemp: -1
    property real memUsed: 0
    property real memTotal: 1
    property real diskUsed: 0
    property real diskTotal: 1
    property real gpu: 0
    property real gpuMemUsed: 0
    property real gpuMemTotal: 1
    property real gpuTemp: -1

    property real _prevTotal: 0
    property real _prevIdle: 0

    function gib(bytes) {
        return (bytes / 1073741824).toFixed(1);
    }

    function pct(f) {
        return Math.round(f * 100) + "%";
    }

    function withTemp(base, t) {
        return t >= 0 ? base + "  " + Math.round(t) + "°C" : base;
    }

    function parseStat(t) {
        var p = t.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        var idle = p[3] + (p[4] || 0);
        var total = 0;
        for (var i = 0; i < 8 && i < p.length; i++)
            total += p[i];
        var dt = total - _prevTotal;
        var di = idle - _prevIdle;
        if (_prevTotal > 0 && dt > 0)
            cpu = 1 - di / dt;
        _prevTotal = total;
        _prevIdle = idle;
    }

    function parseMem(t) {
        var tot = /MemTotal:\s+(\d+)/.exec(t);
        var av = /MemAvailable:\s+(\d+)/.exec(t);
        if (!tot || !av)
            return;
        memTotal = Number(tot[1]) * 1024;
        memUsed = memTotal - Number(av[1]) * 1024;
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root.parseStat(text())
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: root.parseMem(text())
    }

    Process {
        id: diskProc
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                var l = text.trim().split("\n")[1];
                if (!l)
                    return;
                var p = l.trim().split(/\s+/);
                root.diskUsed = Number(p[0]);
                root.diskTotal = Number(p[1]);
            }
        }
    }

    // First CPU-ish hwmon sensor (k10temp = AMD, coretemp = Intel), in millidegrees
    Process {
        id: tempProc
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do case \"$(cat $d/name 2>/dev/null)\" in k10temp|coretemp|zenpower) cat $d/temp1_input; break;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text);
                root.cpuTemp = isNaN(v) ? -1 : v / 1000;
            }
        }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split(",").map(Number);
                if (p.length < 4 || p.some(isNaN))
                    return;
                root.gpu = p[0] / 100;
                root.gpuMemUsed = p[1] * 1048576;
                root.gpuMemTotal = p[2] * 1048576;
                root.gpuTemp = p[3];
            }
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            if (!diskProc.running)
                diskProc.running = true;
            if (!tempProc.running)
                tempProc.running = true;
            if (root.gpuEnabled && !gpuProc.running)
                gpuProc.running = true;
        }
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 16 * root.statsScale

        StatRow {
            statsScale: root.statsScale
            label: "CPU"
            fraction: root.cpu
            value: root.withTemp(root.pct(root.cpu), root.cpuTemp)
        }

        StatRow {
            statsScale: root.statsScale
            label: "RAM"
            fraction: root.memUsed / root.memTotal
            value: root.gib(root.memUsed) + " / " + root.gib(root.memTotal) + " GiB"
        }

        StatRow {
            statsScale: root.statsScale
            label: "DISK"
            fraction: root.diskUsed / root.diskTotal
            value: root.gib(root.diskUsed) + " / " + root.gib(root.diskTotal) + " GiB"
        }

        StatRow {
            visible: root.gpuEnabled
            statsScale: root.statsScale
            label: "GPU"
            fraction: root.gpu
            value: root.withTemp(root.pct(root.gpu), root.gpuTemp)
        }

        StatRow {
            visible: root.gpuEnabled
            statsScale: root.statsScale
            label: "VRAM"
            fraction: root.gpuMemUsed / root.gpuMemTotal
            value: root.gib(root.gpuMemUsed) + " / " + root.gib(root.gpuMemTotal) + " GiB"
        }
    }
}
