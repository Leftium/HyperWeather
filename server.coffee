express          = require 'express'
coffeeMiddleware = require 'coffee-middleware'
engines          = require 'consolidate'
bodyParser       = require 'body-parser'
requestIp        = require 'request-ip'
rp               = require 'request-promise'
moment           = require 'moment'

# Only country-level data without extra data files :(
# geoip            = require 'geoip-lite'

app = express()
# Send heartbeat requests a simple response
app.head '/', (request, response) ->
  response.send 'OK'


app.engine 'jade', engines.jade

app.use express.static('public')
app.use requestIp.mw()

# sets up coffee-script support
app.use coffeeMiddleware
  bare: true
  src: 'public'
require 'coffee-script/register'

weatherHandler = require './weather.coffee'
app.get '/weather', weatherHandler

app.get '/about', (request, response) ->
  response.render 'about.jade'


app.get '/', (request, response) ->
  ipAddress = request.clientIp
  console.log "#{ipAddress} GET /"
  # console.log request

  # geocode IP address
  url = "http://freegeoip.net/json/#{ipAddress}"
  
  if process.env.MOCK_GEOIP
    console.log "WARNING: MOCK_GEOIP"
    promise = new Promise (resolve, reject) ->
      resolve
        ip: "211.41.254.66"
        country_code: ""
        country_name: ""
        region_code: ""
        region_name: ""
        city: "Honolulu",
        zip_code: ""
        time_zone: "Asia/Seoul"
        # latitude: 17.73563003540039
        # longitude: -64.7479476928711
        latitude: 21.30694007873535
        longitude: -157.85833740234375
        metro_code: 0
  else        
    promise = rp url,
      json: true
  
  start = new Date()
  promise.then (data) ->
    console.log "GEOCODE IP ADRESS: #{(new Date()-start)}ms"
    # geo = geoip.lookup ipAddress
    # console.log data
    # console.log geo

    response.render 'index.jade',
      latitude:  data.latitude
      longitude: data.longitude
      location:  data.city or data.region_name or data.country_name

# listen for requests :)
listener = app.listen process.env.PORT, () ->
  console.log "Your app is listening on port #{listener.address().port}"
