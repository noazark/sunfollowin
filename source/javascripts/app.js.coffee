#= require_directory ./lib
#= require_directory .

# OVERLAND_PARK:
#  lat: 38.94
#  lng: 94.68

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

class Coordinates
  # lat: Latitude
  # lng: Longitude

  constructor: (@lat, @lng) ->

  toString: ->
    @lat + ", " + @lng

  toGoogleMaps: ->
    new google.maps.LatLng(@lat, @lng)

class Settings
  coords: new Coordinates(38.94, -94.68)
  speed: 5
  color: "#990000"

window.onload = () =>
  settings = new Settings()
  path = [settings.coords.toGoogleMaps()]


  father = new Observer(settings.coords, settings.speed)

  markerOptions =
    position: settings.coords.toGoogleMaps(),
    draggable: true,
    icon: new google.maps.MarkerImage("/images/marker.png", null, null, new google.maps.Point(22,42))

  trailOptions =
    geodesic: true,
    strokeColor: "#990000",
    strokeOpacity: 1.0,
    strokeWeight: 5

  mapOptions =
    zoom: 9
    center: settings.coords.toGoogleMaps()
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
    reload()

  clearMarkers = ->
    trail.setPath(path = [settings.coords.toGoogleMaps()])

  father.callbacks.coordinateChange = ->
    path.push father.coordinates.toGoogleMaps()

    trail.setPath path

  reload = ->
    father = new Observer(settings.coords, settings.speed)
    clearMarkers()
    father.move(86400 * 3650 * 0.25)

  reload()

  gui = new dat.GUI()
  f1 = gui.addFolder("Follower")
  f1.add(settings, "speed").min(1).max(50).step(1).onFinishChange ->
    reload()
  f2 = gui.addFolder("Map")
  f2.addColor(settings, "color").onChange ->
    trailOptions.strokeColor = settings.color
    trail.setOptions(trailOptions)
  f3 = gui.addFolder("Time")

  f1.open()
  f2.open()