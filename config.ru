$stdout.sync = true
require 'dotenv'
Dotenv.load

require './lib/web'
run Web
