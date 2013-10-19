$stdout.sync = true
require 'dotenv'
Dotenv.load

require './heroku_deployer'
run DeployerApp
