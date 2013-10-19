require 'git-ssh-wrapper'
require 'git'
require 'zlib'

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

  def repo_exists?
    Dir.exists?(File.join(local_folder, '.git'))
  end

  def update_local_repository
    clone unless repo_exists?
    puts "fetching"
    `cd #{local_folder} && git fetch && git reset --hard origin/master`
  end

  def clone
    puts "cloning"
    `git clone #{config.git_repo} #{local_folder}`
    `cd #{local_folder} && git remote add heroku #{config.heroku_repo}`
  end

  def push
    puts "pushing"
    puts `cd #{local_folder}; git push -f heroku master`
  end
end
