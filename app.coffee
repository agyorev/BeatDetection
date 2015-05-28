http       = require 'http'
express    = require 'express'
request    = require 'request'
bodyParser = require 'body-parser'

app = express()

app.set 'port', process.env.PORT or 8080

app.use bodyParser.json()

app.get '/', (req, res) ->
    res.sendFile __dirname + '/index.html'

server = app.listen app.get('port'), ->
    console.log "Started server, listening on port #{app.get('port')}"
