# Description:
#   Manage calendar events and remind of them ahead of time
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot add event "<title>" in <time> - Set a <title> event on <time>, <time> is in the format 1 day, 2 hours, 5 minutes etc.
#   hubot add daily event "<title>" in <time> - Set a recurring daily <title> event on <time>, <time> is in the format 1 day, 2 hours, 5 minutes etc. Time segments are optional, as are commas
#   hubot add weekly event "<title>" in <time> - Set a recurring weekly <title> event on <time>, <time> is in the format 1 day, 2 hours, 5 minutes etc. Time segments are optional, as are commas
#   hubot add monthly event "<title>" in <time> - Set a recurring monthly <title> event on <time>, <time> is in the format 1 day, 2 hours, 5 minutes etc. Time segments are optional, as are commas
#   hubot show events - Shows all events.
#   hubot remove event "<title>" - Removes <title> event.
#
# Author:
#   smartinez87

class Calendar
  constructor: (@robot) ->
    @cache = []
    @current_timeout = null

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.events
        @cache = @robot.brain.data.events
        @queue()

  add: (event) ->
    @cache.push event
    @cache.sort (a, b) -> a.due - b.due
    @robot.brain.data.events = @cache
    @queue()

  remove: (title) ->
    index = @cache.indexOf(title)
    event = @cache.splice(index, 1)
    @robot.brain.data.events = @cache
    @robot.send 'Successfully removed event.'
    @queue()

  addRecurring: (event) ->
    @cache.push event
    @cache.sort (a, b) -> a.due - b.due
    @robot.brain.data.events = @cache

  removeFirst: ->
    event = @cache.shift()
    @robot.brain.data.events = @cache
    switch event.frequency
      when 'once' then break
      when 'daily' then events.addRecurring(new Event event.title, (event.due + 86400), 'daily')
      when 'weekly' then events.addRecurring(new Event event.title, (event.due + 86400*7), 'weekly')
      when 'monthly' then events.addRecurring(new Event event.title, (event.due + 86400*28), 'monthly')
    return event

  queue: ->
    clearTimeout @current_timeout if @current_timeout
    if @cache.length > 0
      now = new Date().getTime()
      @removeFirst() until @cache.length is 0 or @cache[0].due > now
      if @cache.length > 0
        trigger = =>
          event = @removeFirst()
          @robot.send event.title + 'event starts NOW'
          @queue()
        @current_timeout = setTimeout trigger, @cache[0].due - now

class Event
  constructor: (@title, @time, @frequency) ->
    @time.replace(/^\s+|\s+$/g, '')

    periods =
      weeks:
        value: 0
        regex: "weeks?"
      days:
        value: 0
        regex: "days?"
      hours:
        value: 0
        regex: "hours?|hrs?"
      minutes:
        value: 0
        regex: "minutes?|mins?"
      seconds:
        value: 0
        regex: "seconds?|secs?"

    for period of periods
      pattern = new RegExp('^.*?([\\d\\.]+)\\s*(?:(?:' + periods[period].regex + ')).*$', 'i')
      matches = pattern.exec(@time)
      periods[period].value = parseInt(matches[1]) if matches

    @due = new Date().getTime()
    @due += ((periods.weeks.value * 604800) + (periods.days.value * 86400) + (periods.hours.value * 3600) + (periods.minutes.value * 60) + periods.seconds.value) * 1000

  dueDate: ->
    dueDate = new Date @due
    dueDate.toLocaleString()


module.exports = (robot) ->

  events = new Calendar robot

  robot.respond /add event "(.*)" in ((?:(?:\d+) (?:weeks?|days?|hours?|hrs?|minutes?|mins?|seconds?|secs?)[ ,]*(?:and)? +)+)/i, (msg) ->
    title = msg.match[1]
    time = msg.match[2]
    event = new Event title, time, 'once'
    events.add event
    msg.send title + 'event added on' + event.dueDate()

  robot.respond /add daily event "(.*)" in ((?:(?:\d+) (?:weeks?|days?|hours?|hrs?|minutes?|mins?|seconds?|secs?)[ ,]*(?:and)? +)+)/i, (msg) ->
    title = msg.match[1]
    time = msg.match[2]
    event = new Event title, time, 'daily'
    events.add event
    msg.send title + 'event added daily on' + event.dueDate()

  robot.respond /add weekly event "(.*)" in ((?:(?:\d+) (?:weeks?|days?|hours?|hrs?|minutes?|mins?|seconds?|secs?)[ ,]*(?:and)? +)+)/i, (msg) ->
    title = msg.match[1]
    time = msg.match[2]
    event = new Event title, time, 'weekly'
    events.add event
    msg.send title + 'event added weekly on' + event.dueDate()

  robot.respond /add monthly event "(.*)" in ((?:(?:\d+) (?:weeks?|days?|hours?|hrs?|minutes?|mins?|seconds?|secs?)[ ,]*(?:and)? +)+)/i, (msg) ->
    title = msg.match[1]
    time = msg.match[2]
    event = new Event title, time, 'monthly'
    events.add event
    msg.send title + 'event added monthly on' + event.dueDate()

  robot.respond /remove event "(.*)"/i, (msg) ->
    title = msg.match[1]
    events.remove title

  robot.respond /show events$/i, (msg) ->
    response = ""

    for own key, event of robot.brain.data.events
      response += "#{event.title} \n"

    msg.send response