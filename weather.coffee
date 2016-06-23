rp     = require 'request-promise'
moment = require 'moment'

getWeatherData = (request, mockResults=true) ->
  key      = process.env.DARK_SKY_API_KEY
  mockdata = process.env.MOCK_DATA or false
  
  query = request.query
  latitude  = query?.latitude           or '0'
  longitude = query?.longitude          or '0'
  time      = parseInt(query?.time, 10) or moment().valueOf()
  forecastURL = "https://api.forecast.io/forecast/#{key}/#{latitude},#{longitude}"
  
  time0 = moment(time)
  time1 = moment(time).subtract(1, 'day')
  time2 = moment(time).subtract(2, 'day')
  
  promises = []
  
  if mockdata or not key
    time2Json = require './data/time2.json'
    time1Json = require './data/time1.json'
    time0Json = require './data/time0.json'
    promises = [time2Json, time1Json, time0Json]
  else
    urls = [
        "#{forecastURL},#{time2.format('X')}"
        "#{forecastURL},#{time1.format('X')}"
        forecastURL
    ]
    # console.log urls
    
    options =
      json: true
      qs:
        exclude: 'minutely,hourly,alerts,flags'

    urls.forEach (url) ->
      promises.push(rp url, options)
        
  Promise.all promises

extractFields = (data) ->
  object =
    time:    data?.time
    summary: data?.summary
    icon:    data?.icon
    
    precipProbability: data?.precipProbability
    
    temperature:         data?.temperature
    apparentTemperature: data?.apparentTemperature
    
    temperatureMin: data?.temperatureMin
    temperatureMax: data?.temperatureMax
    
    apparentTemperatureMin: data?.apparentTemperatureMin
    apparentTemperatureMax: data?.apparentTemperatureMax
    
module.exports = (request, response) ->
  ipAddress = request.clientIp
  console.log "#{ipAddress} GET /weather"
  start = new Date()
  promise = getWeatherData request
  
  results = 
    currently: null
    daily: []
    
  promise.then (weatherData) ->
    console.log "GET WEATHER: #{new Date()-start}ms"
    # results.weatherData = weatherData
    
    [time2Json, time1Json, time0Json] = weatherData
    
    results.summary = time0Json.daily.summary
    results.currently = extractFields time0Json.currently
    results.daily.push extractFields(time2Json.daily.data[0])
    results.daily.push extractFields(time1Json.daily.data[0])

    time0Json.daily.data.forEach (data) ->
      results.daily.push extractFields(data)
    
    response.format
      html: () ->
        console.log 'HTML'
        response.render 'weather.jade',
          json: results
      json: () ->
        console.log 'JSON'
        response.send results
  