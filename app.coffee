http       = require 'http'
express    = require 'express'
request    = require 'request'
bodyParser = require 'body-parser'

app = express()

app.set 'port', process.env.PORT or 8080

app.use bodyParser.json()
app.use bodyParser.urlencoded({extended: true})

app.get '/', (req, res) ->
    res.sendFile __dirname + '/index.html'

app.post '/', (req, res) ->
    query = req.body.query

    url = 'https://api.spotify.com/v1/search?type=track&q=' + query.split(' ').join('+')
    request.get url, (error, response, body) ->
        if error
            return console.log 'Error: ', error

        if response.statusCode isnt 200
            return console.log 'Invalid status code: ', response.statusCode

        data       = JSON.parse body
        artist     = data.tracks.items[0].artists[0].name
        track      = data.tracks.items[0].name
        previewUrl = data.tracks.items[0].preview_url
        albumCover = data.tracks.items[0].album.images[1].url

        res.send(artist + ' ' + track + ' ' + albumCover)

server = app.listen app.get('port'), ->
    console.log "Started server, listening on port #{app.get('port')}"
