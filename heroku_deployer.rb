require 'sinatra'
require 'git-ssh-wrapper'
require 'git'
require 'zlib'
require 'sucker_punch'

class HerokuDeployer
  attr_reader :app

  def self.exists?(app)
    !!(ENV["#{app}_HEROKU_REPO"] && ENV["#{app}_GIT_REPO"] && ENV["#{app}_SSH_KEY"])
  end

  def initialize(app_name)
    @app = app_name
  end

  def deploy
    GitSSHWrapper.with_wrapper(:private_key => config.ssh_key) do |wrapper|
      wrapper.set_env
      tries = 0
      begin
        update_local_repository
        push
      rescue
        tries += 1
        `rm -r #{local_folder}` rescue nil
        retry if tries <= 1
      end
    end
  end

  private

  def config
    @config ||= OpenStruct.new({
      heroku_repo: ENV["#{app}_HEROKU_REPO"],
      git_repo: ENV["#{app}_GIT_REPO"],
      ssh_key: ENV["#{app}_SSH_KEY"],
    })
  end

  def local_folder
    @local_folder ||= "repos/#{Zlib.crc32(config.git_repo)}"
  end

  def git_wrapper
    @git_wrapper ||= GitSSHWrapper.new(private_key: config.ssh_key)
  end

  def update_local_repository
    repo = begin
      Git.open(local_folder).tap do |g|
        g.fetch
        g.remote('origin').merge
      end
    rescue ArgumentError => e
      `rm -r #{local_folder}` rescue nil
      clone
      retry
    end
    repo.add_remote('heroku', config.heroku_repo) unless repo.remote('heroku').url
  end

  def clone
    `env #{git_wrapper.git_ssh} git clone #{config.git_repo} #{local_folder}`
  ensure
    git_wrapper.unlink
  end

  def push
    puts `cd #{local_folder}; env #{git_wrapper.git_ssh} git push -f heroku master`
  ensure
    git_wrapper.unlink
  end
end

class DeployJob
  include SuckerPunch::Job

  def perform(app_name)
    HerokuDeployer.new(app_name).deploy
  end
end

class DeployerApp < Sinatra::Application
  before do
    if ENV['DEPLOY_SECRET'].nil? || ENV['DEPLOY_SECRET'].empty?
      halt "Set your DEPLOY_SECRET"
    end
  end

  get '/' do
    "Hello World!"
  end

  post '/deploy/:app_name/:secret' do |app_name, secret|
    if secret == ENV['DEPLOY_SECRET']
      puts "correct secret"
      if HerokuDeployer.exists?(app_name)
        puts "app exists"
        DeployJob.new.async.perform(app_name)
      else
        puts "no app"
      end
    else
      puts "wrong secret"
    end
    "maybe"
  end
end
