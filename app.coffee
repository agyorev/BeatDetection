fs         = require 'fs'
http       = require 'http'
cheerio    = require 'cheerio'
express    = require 'express'
request    = require 'request'
bodyParser = require 'body-parser'

app = express()

app.set 'port', process.env.PORT or 8080

app.use bodyParser.json()
app.use bodyParser.urlencoded({extended: true})

app.use '/public', express.static(__dirname + '/public')

$ = cheerio.load fs.readFileSync(__dirname + '/index.html')

app.get '/', (req, res) ->
    res.send $.html()

app.post '/', (req, res) ->
    query = req.body.query

    url = 'https://api.spotify.com/v1/search?type=track&q=' + query.split(' ').join('+')
    request.get url, (error, response, body) ->
        if error
            console.log 'Error: ', error
            return res.send $.html()

        if response.statusCode isnt 200
            console.log 'Invalid status code: ', response.statusCode
            return res.send $.html()

        data = JSON.parse body

        if data.tracks.total is 0
            console.log 'Track not found!'
            return res.send $.html()

        artist     = data.tracks.items[0].artists[0].name
        track      = data.tracks.items[0].name
        previewUrl = data.tracks.items[0].preview_url
        albumCover = data.tracks.items[0].album.images[1].url

        $('#artist').text artist
        $('#track').text track
        $('#preview').text previewUrl
        $('#album-cover').attr 'src', albumCover

        $('#result').removeClass('hidden')
        res.send $.html()

server = app.listen app.get('port'), ->
    console.log "Started server, listening on port #{app.get('port')}"
