#
# * Installation:
# *
# * 1) run the 'setup' function. it will pre-create the labels
# * 2) setup trigger for processLabels every 5 min
# * 3) setup trigger for processReminders every 30 min
#
setup = ->
  setupLabels_()
processLabels = ->
  forEachLabel_ LABELS, (l) ->
    name = labelName_(l)
    label = GmailApp.getUserLabelByName(name)
    return  unless label
    ts = labelTimestamp_(l)
    Logger.log "moving " + l + "to " + ts

processReminders = ->
  labels = find_reminders_()
  i = 0
  l = labels.length

  #while i < l
  #  threads = labels[i].getThreads()
  #  if threads.length
  #    GmailApp.moveThreadsToInbox threads
  #    labels[i].removeFromThreads threads
  #    labels[i].deleteLabel()
  #  i++


# Helpers 

labelName_ = (l) ->
  "#later/" + l

forEachLabel_ = (labels, f) ->
  i = 0
  len = labels.length

  while i < len
    f labels[i]
    i++

setupLabels_ = ->
  GmailApp.createLabel "#later"
  forEachLabel_ LABELS, (l) ->
    GmailApp.createLabel label_name(l)

labelTimestamp_ = (label) ->
  match = /^(\d+)([hdwmy])$/.exec(label)
  unless match
    Logger.log "no match"
    return
  n = match[1]
  x = match[2]
  Logger.log "n=" + n + " x=" + x
  switch match[2]
    when "h"
      NOW_TS + n * H
    when "d"
      DAY_START_TS + n * D
    when "w"
      DAY_START_TS + n * W
    when "m"
      DAY_START_TS + n * M
    when "y"
      DAY_START_TS + n * Y

#///////////////////

is_outdated_reminder_label_ = (label, now) ->
  name = label.getName()
  reminder = (name.match(new RegExp(/^\[Reminders\]\//)) or [])[0]
  return false  unless reminder
  time = new Date(parseInt(name.substr(reminder.length), 10))
  time < now

find_reminders_ = ->
  all_labels = GmailApp.getUserLabels()
  reminder_labels = []
  now = (new Date()).getTime()
  i = 0
  l = all_labels.length

  while i < l
    reminder_labels.push all_labels[i]  if is_outdated_reminder_label_(all_labels[i], now)
    i++
  reminder_labels

reassign_labels_ = (source_label, reminder_date) ->
  threads = source_label.getThreads()
  return  unless threads.length
  target_label = GmailApp.createLabel("[Reminders]/" + reminder_date.getTime())
  target_label.addToThreads threads
  source_label.removeFromThreads threads

map_reminders_ = (label_name, days) ->
  source_label = GmailApp.getUserLabelByName(label_name)
  return  unless source_label
  time = new Date(new Date().getTime() + 60 * 60 * 24 * 1000 * days)
  date = new Date(time.getFullYear(), time.getMonth(), time.getDate())
  reassign_labels_ source_label, date

map_later_ = ->
  source_label = GmailApp.getUserLabelByName("#later")
  return  unless source_label
  time = new Date(new Date().getTime() + 60 * 60 * 4 * 1000) # 4 hours
  reassign_labels_ source_label, time

LABELS = ["1h", "2h", "4h", "8h", "8h", "1d", "2d", "3d", "4d", "5d", "6d", "7d", "8d", "9d", "10d", "1w", "2w", "3w", "4w", "1m", "2m", "3m", "4m", "5m", "6m", "7m", "8m", "9m", "10m", "11m", "1y"]

H = 3600 * 1000
D = 24 * H
W = 7 * D
M = 30 * D
Y = 365 * D

NOW = new Date()
NOW_TS = NOW.getTime()
DAY_START = new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate())
DAY_START_TS = DAY_START.getTime()
