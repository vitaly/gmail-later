/*
 * Installation:
 *
 * 1) run the 'setup' function. it will pre-create the labels
 * 2) setup trigger for processLabels every 5 min
 * 3) setup trigger for processReminders every 30 min
*/

function setup() {
  setupLabels_();
}

function processLabels() {
  forEachLabel_(LABELS, function (l) {
    var name = labelName_(l);
    var label = GmailApp.getUserLabelByName(name);

    if (!label) {
      return;
    }

    var ts = labelTimestamp_(l);

    Logger.log("moving " + l + "to " + ts)
  })
}

function processReminders() {
  //var labels = find_reminders_();
  //for (var i=0, l = labels.length; i < l; i++) {
    //var threads = labels[i].getThreads();
    //if (threads.length) {
      //GmailApp.moveThreadsToInbox(threads);
      //labels[i].removeFromThreads(threads);
      //labels[i].deleteLabel();
    //}
  //}
}

/* Helpers */

LABELS = [
  "1h", "2h", "4h", "8h", "8h", "1d", "2d", "3d", "4d", "5d", "6d", "7d", "8d", "9d", "10d",
  "1w", "2w", "3w", "4w",
  "1m", "2m", "3m", "4m", "5m", "6m", "7m", "8m", "9m", "10m", "11m",
  "1y"
]

function labelName_(l) {
  return "#later/" + l;
}

function forEachLabel_(labels, f) {
  for (i = 0, len = labels.length; i < len; i++) {
    f(labels[i]);
  }
}

function setupLabels_() {
  GmailApp.createLabel("#later");
  forEachLabel_(LABELS, function (l) {
    GmailApp.createLabel(label_name(l));
  })
}

H=3600 * 1000
D=24*H
W=7*D
M=30*D
Y=365*D

NOW = new Date()
NOW_TS = NOW.getTime()
DAY_START = new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate());
DAY_START_TS = DAY_START.getTime()

function labelTimestamp_(label) {
  match = /^(\d+)([hdwmy])$/.exec(label);

  if (!match) {
    Logger.log('no match');
    return;
  }

  n = match[1];
  x = match[2];

  Logger.log("n=" + n + " x=" +x);

  switch(match[2]) {
  case 'h':
    return NOW_TS + n*H;
  case 'd':
    return DAY_START_TS + n*D;
  case 'w':
    return DAY_START_TS + n*W;
  case 'm':
    return DAY_START_TS + n*M;
  case 'y':
    return DAY_START_TS + n*Y;
  }
}




/////////////////////

function is_outdated_reminder_label_(label, now) {
  var name = label.getName();
  var reminder = (name.match(new RegExp(/^\[Reminders\]\//)) || [])[0];

  if (!reminder) { return false; }

  var time = new Date(parseInt(name.substr(reminder.length), 10));
  return time < now;
}

function find_reminders_() {
  var all_labels = GmailApp.getUserLabels();
  var reminder_labels = [];
  var now = (new Date()).getTime();
  for (var i=0, l = all_labels.length; i < l; i++) {
    if (is_outdated_reminder_label_(all_labels[i], now) ) {
      reminder_labels.push(all_labels[i]);
    }
  }
  return reminder_labels;
}

function reassign_labels_(source_label, reminder_date) {
  var threads = source_label.getThreads();

  if (!threads.length) { return; }

  var target_label = GmailApp.createLabel("[Reminders]/" + reminder_date.getTime())
  target_label.addToThreads(threads);
  source_label.removeFromThreads(threads);
}

function map_reminders_(label_name, days) {
  var source_label = GmailApp.getUserLabelByName(label_name);

  if (!source_label) {
    return;
  }

  var time = new Date(new Date().getTime() + 60 * 60 * 24 * 1000 * days);
  var date = new Date(time.getFullYear(), time.getMonth(), time.getDate());

  reassign_labels_(source_label, date);
}

function map_later_() {
  var source_label = GmailApp.getUserLabelByName("#later");

  if (!source_label) {
    return;
  }

  var time = new Date(new Date().getTime() + 60 * 60 * 4 * 1000); // 4 hours

  reassign_labels_(source_label, time);
}