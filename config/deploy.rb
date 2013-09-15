require 'bundler/capistrano'
require 'sidekiq/capistrano'
require 'capistrano/ext/multistage'

set :stages, ['development']
set :default_stage =, 'development'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :application, 'weava'
set :repo_url, 'git@github.com:ajgrayson/weava.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_to, '/var/www/weava'
set :branch, 'master'
set :scm, :git
set :scm_verbose, 'development'

set :format, :pretty
set :log_level, :debug
# set :pty, true

set :use_sudo, true
set :user, 'deploy'

# set :linked_files, %w{config/database.yml}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

after 'deploy:setup' do 
  sudo "chown -R #{user} #{deploy_to} && chmod -R g+s #{deploy_to}"
end

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'

end