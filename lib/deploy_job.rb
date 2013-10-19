require 'sucker_punch'
require_relative 'heroku_deployer'

class DeployJob
  include SuckerPunch::Job

  def perform(app_name)
    HerokuDeployer.new(app_name).deploy
  end
end
