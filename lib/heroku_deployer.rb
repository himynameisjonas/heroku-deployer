require 'git-ssh-wrapper'
require 'git'
require 'zlib'
require 'ostruct'
require 'logger'

class HerokuDeployer
  attr_reader :app, :logger

  def self.exists?(app)
    !!(ENV["#{app}_HEROKU_REPO"] && ENV["#{app}_GIT_REPO"] && ENV["#{app}_SSH_KEY"])
  end

  def initialize(app_name, logger = Logger.new(STDOUT))
    @app = app_name
    @logger = logger
  end

  def deploy
    tries = 0
    begin
      update_local_repository
      push
      post_deploy_command
    rescue
      tries += 1
      if tries <= 1
        `rm -r #{local_folder}` rescue nil
        retry
      end
    end
    logger.info 'done'
  end

  private

  def config
    @config ||= OpenStruct.new({
      heroku_repo: ENV["#{app}_HEROKU_REPO"],
      git_repo: ENV["#{app}_GIT_REPO"],
      ssh_key: ENV["#{app}_SSH_KEY"],
      post_deploy_command: ENV["#{app}_POST_DEPLOY_COMMAND"],
      github_branch: ENV["#{app}_BRANCH"] || 'master'
    })
  end

  def local_folder
    @local_folder ||= "repos/#{Zlib.crc32(config.git_repo + config.github_branch)}"
  end

  def repo_exists?
    Dir.exists?(File.join(local_folder, '.git'))
  end

  def update_local_repository
    GitSSHWrapper.with_wrapper(:private_key => config.ssh_key) do |wrapper|
      wrapper.set_env
      clone unless repo_exists?
      logger.info "fetching #{config.github_branch}"
      logger.debug `cd #{local_folder} && git fetch && git reset --hard origin/#{config.github_branch}`
    end
  end

  def clone
    logger.info "cloning"
    logger.debug `git clone #{config.git_repo} #{local_folder}`
    logger.info "switching to branch #{config.github_branch}"
    logger.debug `cd #{local_folder} && git fetch && git checkout #{config.github_branch} && git pull`
    logger.debug `cd #{local_folder} && git remote add heroku #{config.heroku_repo}`

  end

  def push
    GitSSHWrapper.with_wrapper(:private_key => ENV['DEPLOY_SSH_KEY']) do |wrapper|
      wrapper.set_env
      logger.info "pushing"
      logger.debug `cd #{local_folder}; git push -f heroku #{config.github_branch}:master`
    end
  end

  def post_deploy_command
    if config.post_deploy_command
      logger.info "calling post deploy command"
      logger.debug `#{config.post_deploy_command}`
    end
  end
end
