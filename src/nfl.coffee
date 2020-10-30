# Description:
#   Pulls this week's NFL games (and scores).
#
# Dependencies:
#   "moment": "^2.6.0"
#   "axios":
#
# Commands:
#   hubot football - Pulls this week's games
#   hubot football <team abbreviation> - Pulls today's game for a given team (ex. SF, NYY).
#
# Author:
#   asveepay

moment = require 'moment'
axio = require 'axios'

module.exports = (robot) =>
  robot.respond /football( (.*))?/i, (msg) ->
    team = if msg.match[1] then msg.match[1].toUpperCase().trim() else false
    today = moment()
    api_url = "https://api.nfl.com/v3/shield"
    token_url = "https://api.nfl.com/v1/reroute&grant_type=client_credentials"
    COMMON_HEADERS = {
      "Origin" => "https://www.nfl.com",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:78.0) Gecko/20100101 Firefox/78.0",
      "Accept" => "*/*",
      "Accept-Language" => "en-US,en;q=0.5",
      "Connection" => "keep-alive",
      "TE" => "Trailers"
    }
    GET_TOKEN_HEADERS = {
      "Referer" => "https://www.nfl.com/scores/2020/REG1",
      "Content-Type" => "application/x-www-form-urlencoded",
      "X-Domain-Id" => "100",
      "Origin" => "https://www.nfl.com",
    }
    token = getAuthToken(token_url, {...GET_TOKEN_HEADERS, ...COMMON_HEADERS})


    msg.http(url).get() (err, res, body) ->
      return msg.send "Unable to pull today's scoreboard. ERROR:#{err}" if err
      return msg.send "Unable to pull today's scoreboard: #{res.statusCode + ':\n' + body}" if res.statusCode != 200

      games = JSON.parse(body).gms

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
        # Final scores
        if game.q == 'F'
          emit.push("#{awayTeamName} #{game.vs} vs #{homeTeamName} #{game.hs} FINAL")

        # In-progress games
        else if game.q != 'P'
          emit.push("#{awayTeamName} #{game.vs} @ #{homeTeamName} #{game.hs} Q: #{game.q}")

        # Pre-game settings
        else
          if displayGame(game, team)
            emit.push("#{awayTeamName} vs #{homeTeamName} #{game.d} #{game.t} EST")

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

getAuthToken = (url, headers) ->
  axios.post(
    url: url,
    {},
    headers: headers
  ).then((response) => {
    console.log(JSON.parse(response)['auth_token'])
  }).catch()

fetchGameData = (url, headers) ->
  axios.get(
    url: url,
    {}
    headers: headers
  ).then((response) => {
    console.log(JSON.parse(response))
  })
