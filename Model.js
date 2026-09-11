// Shared formatting for rega.screentime. ES5-ish (var + function only).

function parseKeyValue(raw) {
  var next = {}
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var idx = lines[i].indexOf("\t")
    if (idx <= 0) continue
    next[lines[i].substring(0, idx)] = lines[i].substring(idx + 1).trim()
  }
  return next
}

function parseSummary(raw) {
  try {
    var d = JSON.parse(String(raw || "{}"))
    if (!d || typeof d !== "object") return null
    if (!(d.week instanceof Array)) d.week = []
    if (!(d.top_apps instanceof Array)) d.top_apps = []
    if (!(d.top_tabs instanceof Array)) d.top_tabs = []
    return d
  } catch (e) {
    return null
  }
}

function weekMax(week) {
  var m = 0
  for (var i = 0; i < (week || []).length; i++) {
    var v = Number(week[i] && week[i].total_sec || 0)
    if (v > m) m = v
  }
  return m
}

function weekdayLabel(iso) {
  var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
  try {
    var d = new Date(String(iso) + "T12:00:00")
    return days[d.getDay()]
  } catch (e) {
    return ""
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    parseKeyValue: parseKeyValue,
    parseSummary: parseSummary,
    weekMax: weekMax,
    weekdayLabel: weekdayLabel
  }
}
