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

  coordinateChange: ->

  constructor: (@coordinates, @speed = 4.750, @startAt = new Date(), @stopAt = new Date(@startAt.setDate(@startAt.getDate() + 1))) ->
    @currentTime = @startAt
    @sun = new Sun(this)

  setCoordinates: (value) ->
    @coordinates = value
    #Events.invoke(this, 'observer.coordinateChange');
    @coordinateChange(@coordinates)

  setSpeed: (value) ->
    @speed = value

  move: (duration, increment = @_resolution) ->
    while (duration -= increment) > 0
      increment = duration if duration < increment
      @setCoordinates @step(@sun.getHeading(), increment)

  step: (heading, increment = @_resolution) ->
    @inrementCurrentTime(increment)
    distance = (@speed * 1000) / 3600 * increment
    @totalDistance += distance
    console.log @totalDistance

    pos = google.maps.geometry.spherical.computeOffset(
      @coordinates.toGoogleMaps(),
      distance,
      heading
    )

    return new Coordinates(pos.lat(), pos.lng())

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
    @radiansToDegrees(Math.PI / 2 + pos.azimuth)

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

window.onload = () =>
  father = new Observer(new Coordinates(38.94, -94.68), new Date(2011, 5, 21, 12, 0, 0, 0))

  self.mapOptions =
    zoom: 9
    center: father.coordinates.toGoogleMaps()
    disableDefaultUI: false
    mapTypeId: google.maps.MapTypeId.HYBRID

  map = new google.maps.Map(document.getElementById("map"), self.mapOptions)

  father.coordinateChange = ->
    new google.maps.Marker(
      position: father.coordinates.toGoogleMaps()
      map: map
      title: "Hello World!"
    )

  father.move(86400 * 4)