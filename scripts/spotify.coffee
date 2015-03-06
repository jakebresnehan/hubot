# Description
#   Controls the tunes for Bilue
#
# Dependencies:
#   "sh": "0.0.3"
#   "spotify": "0.3.0"
#   "valid-url": "1.0.5"
#
# Configuration:
#   MUSICBOT_DEFAULT_PLAYLIST = default playlist spotify uri
#
# Commands:
#   musicbot play <1|2|3> - select a song from search results
#   musicbot play <query> - search a song and play the first result
#   musicbot play/pause - play or pause the current song
#   musicbot set playlist <uri> - set the playlist and play it
#   musicbot start playlist - play the current playlist
#   musicbot list playlist - display the current playlist
#   musicbot previous/next - skip to the previous or next song
#   musicbot current song - shows what song is currently playing
#   musicbot volume 0...100|up|down - change the volume
#   musicbot mute/unmute - mute or unmute the song
#   musicbot search <track|album|artist> <query - search for a track, album or artist
#
# Notes:
#   Runs using shell scripts to control the Spotify app
#
# Author:
#   Phill Farrugia <me@phillfarrugia.com> (https://github.com/phillfarrugia)

sh = require('sh')
spotify = require('spotify')

module.exports = (robot) ->

    options = {}
    options.commands = [
        "*play/pause*: play or pause the current song",
        "*previous/next*: skip to the previous or next song",
        "*set playlist <uri>*: setthe playlist and play it",
        "*start playlist*: play the current playlist",
        "*list playlist*: display the current playlist",
        "*play <query>*: search a song and play the first result",
        "*current song*: shows what song is current playing",
        "*volume 0...100|up|down*: change the volume",
        "*mute/unmute*: mute or unmute the song",
        "*search <track|album|artist> <query>*: search for a track, album or artist",
        "*play <1|2|3>*: select a song form search results"
    ]

    # starting volume in spotify
    options.volume = 100

    # default playlist
    options.playlist = process.env.MUSICBOT_DEFAULT_PLAYLIST

    # mute
    options.muted = false

    # show commands
    robot.respond /help$/i, (msg) ->
        msg.send options.commands.join("\n")

    # play/pause
    robot.respond /(play|start)$/i, (msg) ->
        msg.send "Playing the current song"
        sh('osascript -e \'tell app "Spotify" to playpause\'')

    robot.respond /(pause|stop)$/i, (msg) ->
        msg.send "Pausing the current song"
        sh('osascript -e \'tell app "Spotify" to playpause\'')

    # previous/next
    robot.respond /(previous|prev|play previous|play the previous song)$/i, (msg) ->
        sh('osascript -e \'tell app "Spotify" to previous track\'')
        song = sh('osascript ./scripts/current_song.scpt')
        song.result (obj) ->
            msg.send "Playing this song again: " + obj

    robot.respond /(next|play next|play the next song)$/i, (msg) ->
        sh('osascript -e \'tell app "Spotify" to next track\'')
        song = sh('osascript ./scripts/current_song.scpt')
        song.result (obj) ->
            msg.send "And now I'm playing " + obj

    # current song
    robot.respond /(current|song|track|current song|current track)$/i, (msg) ->
        song = sh('osascript ./scripts/current_song.scpt')
        song.result (obj) ->
          if obj.length > 1
            msg.send "The current song I'm playing is " + obj
          else
            msg.send "There's nothing playing"

    # volume
    robot.respond /volume$/i, (msg) ->
        msg.send "I'm reading " + options.volume

    robot.respond /volume (\d{1,2}(?!\d)|100|up|down)$/i, (msg) ->
        volume = msg.match[1]

        switch volume
            when "up"
                if options.volume <= 90
                    options.volume += 10
                    msg.send "Louder, louder!"
                else
                  msg.send "I can't go that loud"
            when "down"
                if options.volume >= 10
                    options.volume -= 10
                    msg.send "Ah, I was trying to say it, but nobody could hear me. Oh wait, I don't have a voice"
                else
                  msg.send "I can't go that loud"
            else
                if volume < options.volume
                    msg.send "Yes, this is too loud for me"
                else
                    msg.send "Turning up the volume! w00p w00p"
        options.volume = volume
        sh('osascript -e \'tell application "Spotify" to set sound volume to '+options.volume+'\'')

    # mute/unmute
    robot.respond /mute$/i, (msg) ->
        if !options.muted
            sh('osascript -e \'tell application "Spotify" to set sound volume to 0\'')
            msg.send "Shhh!"
            options.muted = !options.muted

    robot.respond /unmute$/i, (msg) ->
        if options.muted
            sh('osascript -e \'tell application "Spotify" to set sound volume to '+options.volume+'\'')
            msg.send "That was a quiet moment"
            options.muted = !options.muted

    # search
    robot.respond /search ?(track|song|album|artist)? (.*)$/i, (msg) ->
        query = msg.match[2]

        if msg.match[1]?
            switch msg.match[1]
                when "track" or "song" then type = "track"
                when "album" then type = "album"
                when "artist" then type = "artist"
        else
            type = "track"
        console.log query
        console.log type
        spotify.search
            type: type
            query: query
            (err, data) ->
                switch type
                    when "track"
                        if data.tracks.items.length is 1
                            song = data.tracks.items[0]
                            msg.send "Found it... use musicbot 1 for \"" + song.name + " by " + song.artists[0].name
                            options.result = {
                                first: data.tracks.items[0].uri
                            }
                        else if data.tracks.items.length is 2
                            result = [
                                "Use musicbot play 1 for \"" + data.tracks.items[0].name + " by " + data.tracks.items[0].artists[0].name,
                                "or use musicbot play 2 for \"" + data.tracks.items[1].name + " by " + data.tracks.items[1].artists[0].name
                            ]
                            msg.send result.join("\n")
                            options.result = {
                                first: data.tracks.items[0].uri,
                                second: data.tracks.items[1].uri
                            }
                        else if data.tracks.items.length > 2
                            result = [
                                "Use musicbot play 1 for \"" + data.tracks.items[0].name + "\" by " + data.tracks.items[0].artists[0].name,
                                "or use musicbot play 2 for \"" + data.tracks.items[1].name + "\" by " + data.tracks.items[1].artists[0].name,
                                "or use musicbot play 3 for \"" + data.tracks.items[2].name + "\" by " + data.tracks.items[2].artists[0].name
                            ]
                            msg.send result.join("\n")
                            options.result = {
                                first: data.tracks.items[0].uri,
                                second: data.tracks.items[1].uri,
                                third: data.tracks.items[2].uri
                            }
                    when "album"
                        album = data.albums.items[0]
                        if album
                            msg.send "Found a album by the name of " + album.name + ". Now, to continue the quiz... Can you name a song?"
                    when "artist"
                        artist = data.artists.items[0]
                        if artist
                            msg.send "Got it. I found " + artist.name + ". Another quiz question... Which album is the best?"

    # play <1|2|3>
    robot.respond /play ([1-3]{1,3})$/i, (msg) ->
        choice = msg.match[1]

        switch choice
            when "1"
                sh('open '+ options.result.first) if options.result? and options.result.first?
                msg.send "Okay sure, why not"
            when "2"
                sh('open ' + options.result.second) if options.result? and options.result.second?
                msg.send "Hah, this is my favourite song"
            when "3"
                sh('open ' + options.result.third) if options.result? and options.result.third?
                msg.send "Are you sure? Alright, I'll play it anyway"

    # play <uri>
    robot.respond /play (spotify.*)$/i, (msg) ->
        uri = msg.match[1]

        msg.send "Yeah sure, I can play that"
        sh('osascript -e \'tell application "Spotify" to play track \"' + uri + '\"\'')

    # playlist
    robot.respond /start playlist$/i, (msg) ->
        msg.send "Now it's time I do what I was made for. Playing your playlist."
        sh('osascript -e \'tell application "Spotify" to play track \"' + options.playlist + '\"\'')

    # playlist
    robot.respond /set playlist (spotify.*)$/i, (msg) ->
        options.playlist = msg.match[1]

        msg.send "I've set the playlist, kick back while I hit play"
        sh('osascript -e \'tell application "Spotify" to play track \"' + options.playlist + '\"\'')

    # list playlist
    robot.respond /list playlist$/i, (msg) ->
        msg.send "Current playlist is: " + options.playlist


    # play <query>
    robot.respond /play (.*)$/i, (msg) ->
        query = msg.match[1]

        spotify.search
          type: "track"
          query: msg.match[1]
          (err, data) ->
              unless err
                  song = data.tracks.items[0]
                  if song
                      sh('open ' + song.uri)
                      msg.send "Found it, now playing: \"" + song.name + " by " + song.artists[0].name + " from " + song.album.name


