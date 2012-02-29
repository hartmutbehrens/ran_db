load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

depend :remote, :command, "perlbrew"

#before "deploy:setup", "db:setup"
after "deploy:symlink", "application:symlink"

set :mysql_path, "/usr/bin/mysql"
set :application, "ran_db"
set :repository, "file:///home/hartmut/workspace/#{application}"
set :scm, :git
set :branch, "master"
set :deploy_via, :copy
set :copy_exclude, [".git", "Capfile", "config"]
set :use_sudo, false
set :deploy_to, "/home/PNM/hartmut/#{application}"
ssh_options[:forward_agent] = true

set :db_superuser do Capistrano::CLI.ui.ask "MySQL username (with CREATE privilege): " end
set :db_superpass do Capistrano::CLI.password_prompt "MySQL password (with CREATE privilege): " end
set :db_user do	Capistrano::CLI.ui.ask "MySQL username: " end
set :db_pass do	Capistrano::CLI.password_prompt "MySQL password: " end

set :bss_ver do	Capistrano::CLI.ui.ask "BSS version: " end
set :utran_ver do	Capistrano::CLI.ui.ask "UTRAN version: " end

set :production_db do Capistrano::CLI.ui.ask "Database name: " end

role :hosts, "PNM@ilndcpnm015"
role :db, "PNM@ilndcpnm015", :primary => true

namespace :perlbrew do
	desc "Install perl"
	task :install, :roles => :hosts do
		run "which perlbrew"
	end
end

namespace :ran_db do
	desc "Update tables"
end


namespace :db do
	desc "Create MySQL database"
	task :setup, :roles => :db do
		create_command = "CREATE DATABASE IF NOT EXISTS #{production_db}"
		run "#{mysql_path} --user=#{db_superuser} -p#{db_superpass} --execute=\"#{create_command}\""
	end

	desc "Create a new MySQL user"
	task :create_user, :roles => :db do		
		for host in ['localhost','%']
			create_command = "CREATE USER '#{db_user}'@'#{host}' IDENTIFIED BY '#{db_pass}'"
			run "#{mysql_path} --user=#{db_superuser} -p#{db_superpass} --execute=\"#{create_command}\""
		end
	end

	desc "Grant privileges to user"
	task :grant_privileges, :roles => :db do		
		for host in ['localhost','%']
			create_command = "GRANT ALL ON #{production_db}.*  to '#{db_user}'@'#{host}'"
			run "#{mysql_path} --user=#{db_superuser} -p#{db_superpass} --execute=\"#{create_command}\""
		end
	end
end

namespace :application do
	desc "Create csvload and data directory symlinks"
	task :symlink, :roles => :hosts do
		run "mkdir -p #{shared_path}/system/csvload #{shared_path}/system/data #{shared_path}/system/copylog"
		run "ln -nfs #{shared_path}/system/csvload #{current_path}/csvload"
		run "ln -nfs #{shared_path}/system/data #{current_path}/data"
		run "ln -nfs #{shared_path}/system/copylog #{current_path}/copylog"
	end

	desc "Create GSM tables in database"
	task :create_gsm_tables, :roles => :hosts do
		for table in ['rnl','t18','t31','t110','t180','obsynt.gpm','cellpositions','cell_bh','Alarms_2G','matrix']
			run "#{current_path}/bin/rdb-make tables -u #{db_user} -x #{db_pass} -h localhost -d #{production_db} -D #{current_path}/templates/table.#{table}.#{bss_ver}.xml"
		end
	end

	desc "Add triggers to GSM tables"
	task :add_gsm_triggers, :roles => :db do
		for item in ['2G','distance','giveDayStart'] do
			run "#{mysql_path} --user=#{db_user} -p#{db_pass} --database=#{production_db} < #{current_path}/templates/functions.#{item}.sql"
		end
		run "#{mysql_path} --user=#{db_user} -p#{db_pass} --database=#{production_db} < #{current_path}/templates/triggers.2G.sql"
	end

	desc "Make shell wrappers, suitable for crontab use"
	task :make_wrappers, :roles => :hosts do
	end
end
	
