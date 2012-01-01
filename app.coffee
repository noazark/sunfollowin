express = require("express")
assets = require('connect-assets')
fs = require('fs')

require('express-resource')

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

app.set "config", JSON.parse(fs.readFileSync("./config.json"))
js.root = "javascripts"
css.root = "stylesheets"

app.resource require('./controllers/map')

app.listen 3000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env