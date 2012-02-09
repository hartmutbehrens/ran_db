load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks

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

role :hosts, "ilndcpnm015"

namespace :perlbrew do
	desc "Check if perlbrew is installed"
	task :has, :roles => :hosts do
		run "which perlbrew"
	end
end
