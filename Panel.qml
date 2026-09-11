import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// rega.screentime — native screen-time bar widget + popup.
// Tracking: bin/screentime tick (15s samples of Hyprland active window,
// skipped while hyprlock runs). Data: ~/.local/share/omarchy/screentime/days/.
Panel {
  id: root
  moduleName: "rega.screentime"
  ipcTarget: "rega.screentime"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dimmed: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string binPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/rega.screentime/bin/screentime"

  property var kv: ({})
  property var summary: null
  property var week: []
  property var topApps: []
  property var topTabs: []
  property string todayTotal: "0m"
  property string weekTotal: "—"
  property string topAppName: ""

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function tick() {
    if (!tickProc.running) tickProc.running = true
  }

  function updateFromJson(raw) {
    var s = Model.parseSummary(raw)
    if (!s) return
    root.summary = s
    root.week = s.week
    root.topApps = s.top_apps
    root.topTabs = s.top_tabs
    root.todayTotal = s.total || "0m"
    root.weekTotal = s.week_total || "—"
    root.topAppName = (s.top_apps && s.top_apps.length > 0) ? s.top_apps[0].name : ""
    var flat = "total\t" + (s.total || "0m") + "\nweek_total\t" + (s.week_total || "—")
    root.kv = Model.parseKeyValue(flat)
  }

  function weekMax() {
    return Model.weekMax(root.week)
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root, direction)
    return false
  }

  onOpenedChanged: {
    if (opened) refresh()
  }

  Component.onCompleted: {
    refresh()
    tick()
  }

  // Sample active window every 15s (tick adds 15s when unlocked).
  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: false
    onTriggered: root.tick()
  }

  // Refresh totals every 30s while open, every 2min otherwise (cheap).
  Timer {
    interval: root.opened ? 30000 : 120000
    running: true
    repeat: true
    triggeredOnStart: false
    onTriggered: root.refresh()
  }

  Process {
    id: tickProc
    command: [root.binPath, "tick", "--interval", "15"]
    stdout: StdioCollector { waitForEnd: true }
    onExited: root.refresh()
  }

  Process {
    id: statusProc
    command: [root.binPath, "status", "--json"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.updateFromJson(text) }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "◷ " + root.todayTotal
    tooltipText: root.topAppName !== ""
      ? "Today " + root.todayTotal + " · top: " + root.topAppName + " · click for breakdown"
      : "Today " + root.todayTotal + " · click for breakdown"
    onPressed: function(b) {
      if (b === Qt.RightButton && root.bar) {
        root.bar.run(root.binPath + " status")
        return
      }
      root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(12)

        // Hero
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroTotal.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: "⏱"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(12)
            anchors.right: heroTotal.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              textFormat: Text.PlainText
              text: "Screen time"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: ("WEEK " + root.weekTotal).toUpperCase()
              color: root.dimmed
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.1
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: heroTotal
            textFormat: Text.PlainText
            text: root.todayTotal
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        PanelSeparator { foreground: root.foreground }

        // Week chart
        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.week.length > 0

          Text {
            textFormat: Text.PlainText
            text: "LAST 7 DAYS"
            color: root.dimmed
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.1
          }

          Row {
            width: parent.width
            spacing: Style.space(6)

            Repeater {
              model: root.week
              Item {
                required property var modelData
                required property int index
                width: (parent.width - Style.space(6) * 6) / 7
                height: 64

                property real frac: {
                  var m = root.weekMax()
                  if (m <= 0) return 0
                  return Math.min(1, Number(modelData.total_sec || 0) / m)
                }
                property bool isToday: index === root.week.length - 1

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: dayLabel.top
                  anchors.bottomMargin: 4
                  height: Math.max(4, 40 * parent.frac)
                  radius: 3
                  color: parent.isToday ? root.foreground : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
                }

                Text {
                  id: dayLabel
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  textFormat: Text.PlainText
                  text: Model.weekdayLabel(modelData.date)
                  color: parent.isToday ? root.foreground : root.dimmed
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: parent.isToday
                  horizontalAlignment: Text.AlignHCenter
                }
              }
            }
          }
        }

        // Top apps
        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: root.topApps.length > 0

          Text {
            textFormat: Text.PlainText
            text: "TOP APPS TODAY"
            color: root.dimmed
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.1
          }

          Repeater {
            model: root.topApps
            Item {
              required property var modelData
              width: parent.width
              implicitHeight: 20

              property real frac: {
                var top = (root.topApps.length > 0) ? Number(root.topApps[0].sec || 1) : 1
                if (top <= 0) return 0
                return Math.min(1, Number(modelData.sec || 0) / top)
              }

              Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * parent.frac
                height: 20
                radius: 5
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: modelData.name
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
                width: parent.width - 80
              }

              Text {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: modelData.time
                color: root.dimmed
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
          }
        }

        // Top browser tabs
        Column {
          width: parent.width
          spacing: Style.space(4)
          visible: root.topTabs.length > 0

          Text {
            textFormat: Text.PlainText
            text: "TOP TABS"
            color: root.dimmed
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.1
          }

          Repeater {
            model: root.topTabs
            Text {
              required property var modelData
              width: parent.width
              textFormat: Text.PlainText
              text: "· " + modelData.name + " — " + modelData.time
              color: root.dimmed
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              wrapMode: Text.NoWrap
            }
          }
        }

        PanelSeparator { foreground: root.foreground }

        Text {
          textFormat: Text.PlainText
          text: "Unlocked time · 15s samples · per-URL needs ActivityWatch browser extension"
          color: root.dimmed
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          width: parent.width
          wrapMode: Text.Wrap
        }
      }
    }
  }
}
