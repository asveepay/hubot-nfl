# Description:
#   Pulls this week's NFL games (and scores).
#
# Dependencies:
#   "moment": "^2.6.0"
#
# Commands:
#   hubot football - Pulls this week's games
#   hubot football <team abbreviation> - Pulls today's game for a given team (ex. SF, NYY).
#
# Author:
#   asveepay

moment = require 'moment'

module.exports = (robot) =>
  robot.respond /football( (.*))?/i, (msg) ->
    team = if msg.match[1] then msg.match[1].toUpperCase().trim() else false
    today = moment()

    url = "http://www.nfl.com/liveupdate/scorestrip/ss.json"
    #url = "http://www.nfl.com/liveupdate/scores/scores.json" # new url
    msg.http(url).get() (err, res, body) =>
      return msg.send "Unable to pull today's scoreboard. ERROR:#{err}" if err
      return msg.send "Unable to pull today's scoreboard: #{res.statusCode + ':\n' + body}" if res.statusCode != 200

      gameday = JSON.parse(body)
      games = gameday.gms

      games.sort (a, b) ->
        if a.q == 'F'
          return -1
        else if a.t < b.t
          return 1

        return 0

      emit = []
      for game in games
        # setup
        awayTeamName = game.vnn
        homeTeamName = game.hnn
        gamekey = game.eid
        # Final scores
        if game.q == 'F' && !team
          emit.push("#{awayTeamName} (#{game.vs}) vs #{homeTeamName} (#{game.hs}) FINAL")

        # In-progress games
        else if game.q != 'P'
          emit.push("getting game data for #{game_url}")

        # Pre-game settings
        else
          if displayGame(game, team)
            msg.send("displayGame was true")
            game_url = "http://www.nfl.com/liveupdate/game-center/2016081955/2016081955_gtd.json"
            #game_url = "http://www.nfl.com/liveupdate/game-center/#{gamekey}/#{gamekey}_gtd.json"
            msg.http().get() (err, res, body) ->
              gamedata = JSON.parse(body)
              #msg.send("checking team")
              emit.push("not team")
              emit.push("#{awayTeamName} (#{game.vs}) vs #{homeTeamName} (#{game.hs}) #{gamedata.clock} #{gamedata.qtr}")
              emit.push("#{team} #{game.hnn.toUpperCase()} #{game.vnn.toUpperCase()}")
                    #continue
              emit.push("continuing")

#original DO NOT DELETE!
#            emit.push("#{awayTeamName} vs #{homeTeamName} #{game.d} #{game.t} EST")

      if emit.length >= 1
        return msg.send emit.join("\n")

      msg.send "Sorry, I couldn't find any games today for #{team}."

longestTeamName = (away, home) ->
  if away.length > home.length
    return away
  else
    return home

padTeamName = (team1, team2) ->
  if team1.length < team2.length
    return team1 + Array((team2.length - team1.length) + 1).join(' ')
  else
    return team1

displayGame = (game, team) ->
  if !team || (team == game.hnn.toUpperCase().trim() || team == game.vnn.toUpperCase())
    return true

  return false

getGameData = (game) ->
  game_url = "http://www.nfl.com/liveupdate/game-center/2016081955/2016081955_gtd.json"
  #game_url = "http://www.nfl.com/liveupdate/game-center/#{gamekey}/#{gamekey}_gtd.json"
  msg.http().get() (err, res, body) ->
    return gamedata = JSON.parse(body)
    # msg.send "got back #{gamedata['2016081955']}"
    # for key, value of gamedata['2016081955']
    #   msg.send("gd key: #{key} value: #{value}")
