#= require_tree ./lib

class BaseClass
  xport: (deflate = true)->
    # create an anon object
    object = {}
    # recurse through self properties
    for k of this
      # ask if xport is a function
      if this[k]? && typeof this[k].xport is "function"
        object[k] = this[k].xport(false)
      else
        object[k] = this[k]
    # save result to anon object
    object["type"] = this.constructor.name

    if deflate
      JSON.stringify(object)
    else
      object

  mport: (data)=>
    if data?
      # if name is an object, childObj = eval "new #{obj[name][type]}"
      if data["type"]?
        object = eval("new #{data["type"]}()")
      else
        object = {}
      # recurse through object
      for k of data
        if data[k] instanceof Object
          object[k] = @mport(data[k])
        else
          object[k] = data[k] unless k == "type"
      # return object
      object

# OVERLAND_PARK:
#  lat: 38.94
#  lng: 94.68

# Bethlehem:
#  lat: 31.26
#  lng: 35.70

class Observer
  # coordinates: Terrestrial latitude and lognitude of the observer
  # speed: Observer's rate of motion in km/h
  # startAt: Movement begin
  # stopAt: Moovement end
  # currentTime:

  # _resolution: step increment in seconds

  _resolution: 3600
  totalDistance: 0

  callbacks:
    coordinateChange: ->

  reload: ->

  constructor: (@coordinates, @speed = 4.750, @startAt = new Date()) ->
    @currentTime = @startAt
    @sun = new Sun(this)

  setCoordinates: (value) ->
    @coordinates = value
    @callbacks.coordinateChange(@coordinates)

  setSpeed: (value) ->
    @speed = value

  setStartAt: (value) ->
    @totalDistance = 0
    @startAt = value
    @currentTime = value

  move: (duration, increment = @_resolution) ->
    while (duration -= increment) > 0
      increment = duration if duration < increment

      if pos = @step(@sun.getHeading(), increment)
        @setCoordinates pos

  step: (heading, increment = @_resolution) ->
    @inrementCurrentTime(increment)
    pos = false
    if @currentTime.getTime() >= @sun.periods.sunrise.getTime() && @currentTime.getTime() <= @sun.periods.sunset.getTime()
      distance = @speed * 1000
      @totalDistance += distance

      pos = google.maps.geometry.spherical.computeOffset(
        @coordinates.toGoogleMaps(),
        distance,
        heading
      )

    @sun = new Sun(this)

    if pos
      new Coordinates(pos.lat(), pos.lng())
    else
      false

  inrementCurrentTime: (increment) ->
    @currentTime = new Date(@currentTime.getTime() + (increment * 1000))

class Sun
  # observatory: Coordinates of terrestrial observation point
  # periods: Critical times

  constructor: (@observatory) ->
    @periods = SunCalc.getTimes(@observatory.currentTime, @observatory.coordinates.lat, @observatory.coordinates.lng)

  sunrise: ->
    new Sun(@observatory, @periods.sunrise)

  noon: ->
    new Sun(@observatory, @periods.solarNoon)

  sunset: ->
    new Sun(@observatory, @periods.sunset)

  winterSolstice: ->
    date = new Date(@observatory.currentTime)
    date.setMonth 11
    date.setDate 21

    new Sun(@observatory, date)

  summerSolstice: ->
    date = new Date(@observatory.currentTime)
    date.setMonth 5
    date.setDate 21

    new Sun(@observatory, date)

  getPosition: ->
    SunCalc.getPosition(@observatory.currentTime, @observatory.coordinates.lat, @observatory.coordinates.lng)

  getHeading: ->
    pos = @getPosition()
    @radiansToDegrees(Math.PI / 2 + pos.azimuth) + 90

  radiansToDegrees: (radians) ->
    radians * 180 / Math.PI

class Coordinates extends BaseClass
  # lat: Latitude
  # lng: Longitude

  constructor: (@lat, @lng) ->

  toString: ->
    @lat + ", " + @lng

  toGoogleMaps: ->
    new google.maps.LatLng(@lat, @lng)

class Settings extends BaseClass
  coords: null
  speed: 5
  duration: 1
  color: "#990000"
  startAt:
    year: new Date().getFullYear()
    month: new Date().getMonth()
    day: new Date().getDate()
    hour: 0
    minute: 0

window.onload = () =>
  settings = new Settings()
  stash = settings.mport(JSON.parse localStorage.getItem("Settings"))
  settings = stash if stash?

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition(
      (position) ->
        settings.coords ?= new Coordinates(position.coords.latitude, position.coords.longitude)
        marker.setPosition settings.coords.toGoogleMaps()
        map.panTo(settings.coords.toGoogleMaps())
        reload()
      (error) ->
        switch error.code
          when error.TIMEOUT
            console.warn "position timeout"
          when error.POSITION_UNAVAILABLE
            console.warn "position unavailable"
          when error.PERMISSION_DENIED
            console.warn "position permission denied"
          when error.UNKNOWN_ERROR
            console.warn "position unknown error"

        settings.coords ?= new Coordinates(38.94, -94.68)
        reload()
      )

  path = []

  father = new Observer(new Coordinates(38.94, -94.68))

  markerOptions =
    position: father.coordinates.toGoogleMaps()
    draggable: true,
    icon: new google.maps.MarkerImage("/images/marker.png", null, null, new google.maps.Point(22,42))

  trailOptions =
    geodesic: true,
    strokeColor: settings.color,
    strokeOpacity: 1.0,
    strokeWeight: 5

  mapOptions =
    center: father.coordinates.toGoogleMaps()
    zoom: 9
    disableDefaultUI: false
    panControl: false
    streetViewControl: false
    mapTypeControl: false
    mapTypeId: google.maps.MapTypeId.HYBRID

  map = new google.maps.Map(document.getElementById("map"), mapOptions)

  trail = new google.maps.Polyline(trailOptions)
  trail.setMap(map)

  marker = new google.maps.Marker(markerOptions)
  marker.setMap(map)

  google.maps.event.addListener marker, "dragend", ->
    markerPos = marker.getPosition()
    settings.coords = new Coordinates(markerPos.lat(), markerPos.lng())
    map.panTo(settings.coords.toGoogleMaps())
    reload()

  clearMarkers = ->
    trail.setPath(path = [settings.coords.toGoogleMaps()])

  father.callbacks.coordinateChange = ->
    path.push father.coordinates.toGoogleMaps()

    trail.setPath path

  reload = ->
    localStorage.setItem("Settings", settings.xport())
    startAt = new Date()
    startAt.setFullYear(settings.startAt.year)
    startAt.setMonth(settings.startAt.month - 1)
    startAt.setDate(settings.startAt.day)
    startAt.setHours(settings.startAt.hour)
    startAt.setMinutes(settings.startAt.minute)
    startAt.setSeconds(0);
    startAt.setMilliseconds(0);

    console.group("reload()")
    console.info "coords: " + settings.coords.toString()
    console.info "startAt: " + startAt.toString()
    console.groupEnd()

    father = new Observer(settings.coords, settings.speed, startAt)
    clearMarkers()
    father.move(settings.duration * 86400)

  gui = new dat.GUI()
  f1 = gui.addFolder("Follower")
  f1.add(settings, "speed").min(1).max(50).step(1).onFinishChange ->
    reload()
  f1.add(settings, "duration").min(1).max(1460).step(1).onFinishChange ->
    reload()

  f2 = gui.addFolder("Map")
  f2.addColor(settings, "color").onChange ->
    trailOptions.strokeColor = settings.color
    trail.setOptions(trailOptions)
    localStorage.setItem("Settings", settings.xport())

  f3 = gui.addFolder("Time")
  f3.add(settings.startAt, "year").min(0).max(3000).step(1).onFinishChange ->
    reload()
  f3.add(settings.startAt, "month").min(1).max(12).step(1).onFinishChange ->
    reload()
  f3.add(settings.startAt, "day").min(1).max(31).step(1).onFinishChange ->
    reload()
  f3.add(settings.startAt, "hour").min(0).max(23) .step(1).onFinishChange ->
    reload()
  f3.add(settings.startAt, "minute").min(0).max(59).step(1).onFinishChange ->
    reload()

  f1.open()
  f2.open()
  f3.open()