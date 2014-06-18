_l = -> Logger.log.apply(Logger, arguments)

D = new Date()
NOW = D.getTime()
TODAY = new Date(D.getFullYear(), D.getMonth(), D.getDate()).getTime()

`
function setup() {
  InputLabel.root().create()
  InputLabel.createAll();
  ReminderLabel.root().create()
}

function process() {
  InputLabel.processAll();
  ReminderLabel.processAll();
}
`

class Label
  LABELS = {}

  constructor: ({@name, @instance})->

  create: ->
    _l "create #{@name}"
    @instance ||= @get() || GmailApp.createLabel(@name)

  delete: ->
    _l "removing #{@name}"
    @get()?.deleteLabel()

  get: ->
    @instance ||= GmailApp.getUserLabelByName(@name)

  threads: ->
    @get()?.getThreads()

  isEmpty: ->
    ! @threads().length

  moveTo: (to, {remove}={})->
    _l "         #{@name} -> #{to.name}"
    to.create().addToThreads @threads()
    @get().removeFromThreads @threads()
    @delete() if remove

  moveToInbox: ({remove}={})->
    _l "         #{@name} -> Inbox"
    GmailApp.moveThreadsToInbox @threads()
    @get().removeFromThreads @threads()
    @delete() if remove

  # Class methods
  @byName: (name, instance)->
    LABELS[name] ||= new @ {name, instance}

  @root: ->
    @byName(@ROOT)

  # this is not an instance method on Label, because then it would always
  # create instances of Label. This way it creates instances of @, which can be a derived class
  @at: (name)->
    @byName "#{@root().name}/#{name}"

  @forEach: (method)->
    for l in @all()
      l[method]()

  @childrenOf: (parent)->
    @byName(l.getName(), l) for l in GmailApp.getUserLabels() when l.getName().slice(0, parent.name.length + 1) == "#{parent.name}/"

H = 3600 * 1000
D = 24 * H
W = 7 * D
M = 30 * D
Y = 365 * D

pad = (n)->
  if n < 10
    "0#{n}"
  else
    n

formatTime = (t)->
    y = t.getFullYear()

    m = pad t.getMonth() + 1
    d = pad t.getDate()

    _h = pad t.getHours()
    _m = pad t.getMinutes()

    "#{y}-#{m}-#{d} #{_h}:#{_m}"

humanName = (ts)->
  "#{formatTime new Date(ts)} - #{ts}"

class InputLabel extends Label
  @ROOT = '#later'

  due_at: ->
    throw "no match" unless match = /^(?:.*\/)?(\d+)([hdwmy])$/.exec(@name)
    [_, n, x] = match
    switch x
      when "h" then NOW   + n * H
      when "d" then TODAY + n * D
      when "w" then TODAY + n * W
      when "m" then TODAY + n * M
      when "y" then TODAY + n * Y

  reminder: ->
    ReminderLabel.at humanName @due_at()

  process: ->
    return if @isEmpty()
    @moveTo @reminder()

  # Class methods
  IN = [
    "1h", "2h", "3h", "4h", "8h", "10h", "12h",
    "1d", "2d", "3d", "4d", "5d", "6d", "7d", "8d", "9d", "10d",
    "1w", "2w", "3w", "4w",
    "1m", "2m", "3m", "4m", "5m", "6m", "7m", "8m", "9m", "10m", "11m",
    "1y"
  ]

  @all: ->
    @in ||=
      @at(n) for n in IN

  @createAll: -> @forEach 'create'
  @processAll: -> @forEach 'process'

class ReminderLabel extends Label
  @ROOT = '#reminders'

  parent: ->
    unless match = /^(.*\/)/.exec(@name)
      _l "no parent match: #{@name}"
      return
    match[1]

  due_at: ->
    unless match = /^.*\/(?:[0-9: -]* - )([0-9]+)$/.exec(@name)
      _l "no match: #{@name}"
      return
    parseInt match[1], 10

  pastDue: ->
    (n = @due_at()) && (n < NOW)

  # Class methods
  @processAll: ->
    _l "processing at #{humanName NOW}"
    for l in @childrenOf(@root())
      _l l.name
      if l.pastDue()
        l.moveToInbox(remove: true)

#  @renameAll: ->
#    for l in @childrenOf(@root())
#      _l l.name
#      hname = humanName l.due_at()
#
#      unless hname == l.name
#        _l "                                      -> #{hname}"
#        to = @at hname
#        l.moveTo to, remove: true
