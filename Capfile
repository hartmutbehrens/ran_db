load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks

depend :remote, :command, "perlbrew"

before "deploy:setup", "db:setup"

set :application, "ran_db"
set :repository, "file:///home/hartmut/workspace/#{application}"
set :scm, :git
set :branch, "master"
set :deploy_via, :copy
set :copy_exclude, [".git", "Capfile", "config"]

ssh_options[:forward_agent] = true
set :use_sudo, false
set :deploy_to, "/home/PNM/hartmut/#{application}"
set :user, "PNM"
set :db_user, "PNM"
set :production_db, "Sonar_TVL_2G"


role :hosts, "ilndcpnm015"
role :db, "ilndcpnm015", :primary => true

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
	
