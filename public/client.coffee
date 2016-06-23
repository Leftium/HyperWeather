$ () ->
  $('.json-link').click (e) ->
    e.preventDefault()
    $('.view.weather-data').removeClass 'hidden'
    
  $('.view.weather-data .close').click (e) ->
    $('.view.weather-data').addClass 'hidden'
  
  queryParams = 
    time: moment().valueOf()
    latitude: $('.info .latitude').text() or '42'
    longitude: $('.info .longitude').text() or '69'

  console.log queryParams
  start = new Date()
  $.getJSON '/weather', queryParams, (data) ->
    console.log "WEATHER: #{new Date()-start}ms"
    window.wd = data

    rendered = renderjson.set_icons('\u25BE', '\u25B8')
                         .set_show_to_level(4)(data)
                         
    $('.weather-data .data').append(rendered)
    
    makeData = () ->
      makeSeries = (name) ->
        returnValue =
          name: name
          data: []

      returnValue =
        labels: []
        series: [
          makeSeries 'apparent-high'
          makeSeries 'apparent-low'
          makeSeries 'high'
          makeSeries 'low'
          makeSeries 'current'
        ]
    
    sliceData = (data, length) ->
      data.labels = data.labels.slice 0, length
      data.series.forEach (series,i) ->
        data.series[i].data = data.series[i].data.slice 0, length
      data
    
    cdata = makeData()
    fdata = makeData()

    celsius = (f) -> 5/9 * (f - 32)
    
    data.daily.forEach (row, i)->
      #TODO: better check for today
      if i is 2
        cdata.labels.push ('<b>Today</b>')
        cdata.series[4].data[i] = celsius data.currently.apparentTemperature
        fdata.series[4].data[i] = data.currently.apparentTemperature
      else
        cdata.labels.push (moment(row.time*1000).format 'dd-DD')

        
      cdata.series[0].data.push celsius row.apparentTemperatureMax
      cdata.series[1].data.push celsius row.apparentTemperatureMin
      cdata.series[2].data.push celsius row.temperatureMax
      cdata.series[3].data.push celsius row.temperatureMin
      
      fdata.series[0].data.push row.apparentTemperatureMax
      fdata.series[1].data.push row.apparentTemperatureMin
      fdata.series[2].data.push row.temperatureMax
      fdata.series[3].data.push row.temperatureMin
    
    
    
    
    temperatureDiv = (f, div) ->
      c = celsius f
      div.html $('<span>').addClass('fahrenheit').html("#{Math.round f}&deg;F")
      div.append $('<span>').addClass('celsius').html("#{Math.round c}&deg;C")
      
    currentlyIcon = new Skycons({resizeClear: true})
    
    $currently = $('#currently').attr 'title', data.summary
    currentlyIcon.add($currently.find('.icon')[0], data.currently.icon)
    temperatureDiv data.currently.temperature, $currently.find('.temperature')
    temperatureDiv data.currently.temperature, $currently.find('.apparentTemperature')
    $currently.find('.summary').html data.currently.summary
    
    $('#summary').html data.summary
    
    $('.celsius').addClass 'hidden'
    currentlyIcon.play()
    
    $('.celsius').click (e) ->
      e.preventDefault()
      $('.fahrenheit').removeClass 'hidden'
      $('.celsius').addClass 'hidden'
      chart.update sliceData($.extend(true, {}, fdata), 5)
      wideChart.update fdata
      
    $('.fahrenheit').click (e) ->
      e.preventDefault()
      $('.celsius').removeClass 'hidden'
      $('.fahrenheit').addClass 'hidden'
      chart.update sliceData($.extend(true, {}, cdata), 5)
      wideChart.update cdata
    
    
    list = (day.icon for day in data.daily)
    # console.log list
    
    icons = new Skycons({resizeClear: true})
    grayIcons = new Skycons({resizeClear: true, color: 'lightgray'})
    
    $template = $('#chart .template')
    
    for icon,i in list.slice(0,5)
      [div] = $template.clone()
                       .addClass("day-#{i}")
                       .attr 'title', data.daily[i].summary
                      
      $(div).insertBefore($template)
      $(div).find('canvas').attr('id', "icon-#{i}")
                           
      skycons = if i < 2 then grayIcons else icons
      skycons.set "icon-#{i}", list[i]
      $("#chart .day-#{i} .label").html cdata.labels[i]
      
    $template.remove()
    
    grayIcons.play()
    icons.play()
    
    
    $template = $('#wide-chart .template')
    
    for icon,i in list
      [div] = $template.clone()
                       .addClass("day-#{i}")
                       .attr 'title', data.daily[i].summary
      $(div).insertBefore($template)
      $(div).find('canvas').attr('id', "icon-w#{i}")
      skycons = if i < 2 then grayIcons else icons
      skycons.set "icon-w#{i}", list[i]
      $("#wide-chart .day-#{i} .label").html cdata.labels[i]
      
    $template.remove()
    

    makeChart = (id, data) ->
      new Chartist.Line id, data,
        axisY:
          showLabel: false
        axisX:
          showLabel: false
  
        fullWidth: true
        chartPadding:
          top:    15,
          right:  20,
          bottom: 15,
          left:  -15
          
        plugins: [
          Chartist.plugins.ctPointLabels
            textAnchor: 'middle'
            labelOffset:
              x: 0,
              y: -10
            labelInterpolationFnc: (v) ->
              Math.round v
            series:
              'apparent-low':
                  textAnchor: 'middle'
                  labelOffset:
                    x: 0,
                    y: 20
                  labelInterpolationFnc: (v) ->
                    v
              
        ]
        
        series:
          'apparent-low':
            plugins: [
              Chartist.plugins.ctPointLabels
                textAnchor: 'middle'
                labelOffset:
                  x: 0,
                  y: 20
                labelInterpolationFnc: (v) ->
                  v
            ]
            showArea: false
        
    chart = makeChart '#chart .chartist', sliceData($.extend(true, {}, fdata), 5)
    wideChart = makeChart '#wide-chart .chartist', fdata
      
        
