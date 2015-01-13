This project is an installable Google App Script to "snooze" gmail messages.

# Installation:

- go to http://script.google.com
- create a new project
- paste the contents of gmail-later.js
- run the `setup` function. it will pre-create the labels
- setup a trigger for the `process` function every 15 minutes.

# Usage

To snooze an email, label it with one of the pre-created snooze labels and
archive it.

Snooze labels are pre-created under `#later/` labels 'folder' and are named
with a number and a letter, e.g. `1h`, `3d`, etc.

* Xh - X hours
* Xd - X days
* Xw - X weeks
* Xm - X months
* Xy - X years

The script trigger will process emails labeled with a snooze label and move
them into a reminder label.

Reminder labels looks like `#reminders/DATE - timestamp`.

Once the date is passed, the email will be moved back into your Inbox and the
reminder label will be removed.

# Hacking

 to build `.js` file from the source `.coffee` just run 'make'
> Note: it will start watching `.coffee` faile for changes and recompile `.js`
> on every save.
