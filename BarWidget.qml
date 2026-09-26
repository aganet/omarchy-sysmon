import QtQuick
import Quickshell.Io
import qs.Ui

// CPU %, memory % and network rates (bits per second) read from /proc inside the
// shell: three tiny file reads per tick, no subprocess, no state file.
BarWidget {
  id: root
  moduleName: "anegio.sysmon"

  property string label: ""
  property real prevTotal: -1   // -1: no previous sample yet
  property real prevIdle: 0
  property real prevRx: 0
  property real prevTx: 0
  property real prevMs: 0

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView { id: stat; path: "/proc/stat";    blockAllReads: true; printErrors: false }
  FileView { id: mem;  path: "/proc/meminfo"; blockAllReads: true; printErrors: false }
  FileView { id: net;  path: "/proc/net/dev"; blockAllReads: true; printErrors: false }

  // Bits per second in SI units, the way speed tests and ISP plans quote it.
  function rate(bytesPerSec) {
    var bps = bytesPerSec * 8
    if (bps < 1e3) return Math.floor(bps) + " bps"
    if (bps < 1e6) return Math.floor(bps / 1e3) + " Kbps"
    return (bps / 1e6).toFixed(1) + " Mbps"
  }

  function sample() {
    stat.reload(); mem.reload(); net.reload()
    var now = Date.now()

    // "cpu user nice system idle iowait irq softirq steal ..."
    var c = stat.text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number)
    var total = c.reduce(function(a, b) { return a + b }, 0)
    var idle = c[3] + c[4]
    var cpu = "--"
    if (prevTotal >= 0) {
      var dt = total - prevTotal, di = idle - prevIdle
      if (dt > 0) cpu = Math.floor((dt - di) * 100 / dt)
    }

    var m = mem.text()
    var memTotal = Number((m.match(/^MemTotal:\s+(\d+)/m) || [0, 0])[1])
    var memAvail = Number((m.match(/^MemAvailable:\s+(\d+)/m) || [0, 0])[1])
    var memPct = memTotal > 0 ? Math.floor((memTotal - memAvail) * 100 / memTotal) : 0

    // Sum every interface except lo. After the name: rx bytes is field 1, tx bytes field 9.
    var rx = 0, tx = 0
    var lines = net.text().split("\n")
    for (var i = 2; i < lines.length; i++) {
      var f = lines[i].trim().split(/[:\s]+/)
      if (f.length < 10 || f[0] === "lo") continue
      rx += Number(f[1]); tx += Number(f[9])
    }
    var down = "0 bps", up = "0 bps"
    var ms = now - prevMs
    if (prevTotal >= 0 && ms > 200) {
      // Counters reset when an interface goes down; clamp so the rate never goes negative.
      down = rate(Math.max(0, rx - prevRx) * 1000 / ms)
      up = rate(Math.max(0, tx - prevTx) * 1000 / ms)
    }

    prevTotal = total; prevIdle = idle; prevRx = rx; prevTx = tx; prevMs = now
    label = "󰻠 " + cpu + "%  󰍛 " + memPct + "%  ↓" + down + " ↑" + up
  }

  Timer {
    interval: Math.max(1, Number(root.setting("interval", 2))) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.sample()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    tooltipText: "System"
    fontSize: 12
    horizontalMargin: 7.5
    verticalPadding: 6
    onPressed: function(mouseButton) {
      var command = String(root.setting("onClick", ""))
      if (command && root.bar) root.bar.run(command)
    }
  }
}
