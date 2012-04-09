
# =============================================================================
# CUSTOM OPTIONS
# =============================================================================
task :staging do
  set :user, "deploy"
  set :application, "lowdownapp"
  set :domain, "dev.lowdownapp.com"
  set :alias, %{ lowdownapp.com }
  set :use_sudo, false

  role :web, domain
  role :app, domain
  role :db,  domain, :primary => true

  set :rails_env,       "staging"
end

task :production do
  set :user, "root"
  set :application, "lowdownapp"
  set :domain, "lowdownapp.com"
  set :alias, %{ lowdownapp.com }
  set :use_sudo, false

  role :web, domain
  role :app, domain
  role :db,  domain, :primary => true

  set :rails_env,       "production"

  ssh_options[:forward_agent] = true

  after "deploy:symlink", "deploy:chown"
end

# =============================================================================
# DATABASE OPTIONS
# =============================================================================



# =============================================================================
# DEPLOY TO
# =============================================================================
set :deploy_to, "/rails/lowdownapp"

# =============================================================================
# REPOSITORY
# =============================================================================
set :scm, "git"
set :deploy_via, :remote_cache
set :repository, "git@github.com:seancribbs/lowdown.git"
set :git_enable_submodules, true
# set :local_repository, "..."

# =============================================================================
# SSH OPTIONS
# =============================================================================
#ssh_options[:forward_agent] = true

# default_run_options[:pty] = true
# ssh_options[:paranoid] = false
# ssh_options[:keys] = %w(/Users/wg/.ssh/id_rsa)
# ssh_options[:port] = 42424
after "deploy:symlink", "deploy:package_assets"
after "deploy:update_code", "deploy:link_db_yml"

namespace :deploy do
  desc "Update the crontab file"
  task :update_crontab do
    run "cd #{current_path} && whenever --update-crontab #{application}" if "production" == rails_env
  end
  
  task :clear_scm_cache do
    run "rm -rf #{shared_path}/cached-copy"
  end

  desc "Link the database config."
  task :link_db_yml do
    run "ln -s #{shared_path}/#{application}.yml #{release_path}/config/database.yml"
  end

  desc "Package up the assets."
  task :package_assets, :roles => :web do
    run "cd #{current_path} && rake RAILS_ENV=production asset:packager:build_all"
  end

  desc "restart Passenger with a restart.txt file"
  task :restart, :roles => :app do
    run "touch #{deploy_to}/current/tmp/restart.txt"
  end

  desc "Chown the directory structure so it's owned by the correct user."
  task :chown do
    run "chown -R www-data:www-data #{release_path}"
    run "chown www-data:www-data #{current_path}"
  end
end


# namespace :sass do
#   desc 'Updates the stylesheets generated by Sass'
#   task :update, :roles => :app do
#     invoke_command "cd /rails/freedom/current; rake sass:update RAILS_ENV=production"
#   end
#
#   # Generate all the stylesheets manually (from their Sass templates) before each restart.
#   # before 'deploy:restart', 'sass:update'
# end
