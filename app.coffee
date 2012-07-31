express = require("express")
assets = require('connect-assets')
fs = require('fs')

require('express-resource')

fs.stat "./heroku_config.json", (err, stat) ->
  unless err
    app.settings.env = JSON.parse(fs.readFileSync("./heroku_config.json"))

app = module.exports = express.createServer()
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use assets()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure "production", ->
  app.use express.errorHandler()

js.root = "javascripts"
css.root = "stylesheets"

app.resource require('./controllers/map')

port = process.env.PORT || 3000;
app.listen port, () ->
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);