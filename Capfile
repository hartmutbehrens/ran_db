load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks

depend :remote, :command, "perlbrew"

#before "deploy:setup", "db:setup"
after "deploy:symlink", "custom:symlink"

set :application, "ran_db"
set :repository, "file:///home/hartmut/workspace/#{application}"
set :scm, :git
set :branch, "master"
set :deploy_via, :copy
set :copy_exclude, [".git", "Capfile", "config"]

set :use_sudo, false
set :deploy_to, "/home/wahl/#{application}"
set :production_db, "orange_ug_3g"
ssh_options[:forward_agent] = true

role :hosts, "wahl@10.101.11.218"
role :db, "wahl@10.101.11.218", :primary => true

namespace :perlbrew do
	desc "Install perl"
	task :install, :roles => :hosts do
		run "which perlbrew"
	end
end

namespace :db do
	desc "Create MySQL database"
	task :setup, :roles => :db do
		set :db_user do
			Capistrano::CLI.ui.ask "MySQL username: "
		end
		set :db_pass do
			Capistrano::CLI.password_prompt "MySQL password: "
		end

		create_command = "CREATE DATABASE IF NOT EXISTS #{production_db}"
		run "mysql --user=#{db_user} -p#{db_pass} --execute=\"#{create_command}\""
	end
end

namespace :custom do
	desc "Create csvload and data directory symlinks"
	task :symlink, :roles => :hosts do
		run "mkdir -p #{shared_path}/system/csvload #{shared_path}/system/data"
		run "ln -nfs #{shared_path}/system/csvload #{current_path}/csvload"
		run "ln -nfs #{shared_path}/system/data #{current_path}/data"
	end
end
	
