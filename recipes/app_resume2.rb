
# 
# upstream JS recipe.
#

def puts! args
  puts '+++ +++'
  puts args.inspect
end

app = data_bag_item("apps", "microsites2_resume")
node.run_state[:current_app] = app      

directory "#{app['deploy_to']}/shared" do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

%w{ log pids system vendor_bundle }.each do |dir|
  directory "#{app['deploy_to']}/shared/#{dir}" do
    owner app['owner']
    group app['group']
    mode '0755'
    recursive true
  end
end

if app.has_key?("deploy_key")
  ruby_block "write_key" do
    block do
      f = ::File.open("#{app['deploy_to']}/id_deploy", "w")
      f.print(app["deploy_key"])
      f.close
    end
    not_if do ::File.exists?("#{app['deploy_to']}/id_deploy"); end
  end
  
  file "#{app['deploy_to']}/id_deploy" do
    owner app['owner']
    group app['group']
    mode '0600'
  end
  
  template "#{app['deploy_to']}/deploy-ssh-wrapper" do
    source "deploy-ssh-wrapper.erb"
    owner app['owner']
    group app['group']
    mode "0755"
    variables app.to_hash
  end
end

deploy_revision app['id'] do
  revision app['revision'][node.chef_environment]
  repository app['repository']
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  environment 'RAILS_ENV' => app['rack_environment']
  action app['force'][node.chef_environment] ? :force_deploy : :deploy
  ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
  # ssh_wrapper "#{app['deploy_to']/wrap-ssh4git.sh"
  shallow_clone true
  
  # symlink_before_migrate({
  #                          "database.yml" => "config/database.yml",
  #                          "memcached.yml" => "config/memcached.yml"
  #                        })
  
  if app['migrate'][node.chef_environment] && node[:apps][app['id']][node.chef_environment][:run_migrations]
    migrate true
    migration_command app['migration_command'] || "rake db:migrate"
  else
    migrate false
  end
  
  before_symlink do
    ruby_block "remove_run_migrations" do
      block do
        if node.role?("#{app['id']}_run_migrations")
          Chef::Log.info("Migrations were run, removing role[#{app['id']}_run_migrations]")
          node.run_list.remove("role[#{app['id']}_run_migrations]")
        end
      end
    end
  end
end

template "#{app['deploy_to']}/current/config/database.yml" do
  source "app/config/database_remote.yml.erb"
  owner app['owner']
  group app['group']
  mode "0664"
  variables(
            :host => data_bag_item('utils', 'db_config')["mysql_ip"],
            :database => "showv"
            )
end

#
# I'm using this recipe for deploying microsites2_resume2, which is the API backend for Pi & related.
# This means that the nginx or unicorn site ^must^ be running, so there is  the upstart service yeah.
#
#
#service upstart_script_name do
#  provider Chef::Provider::Service::Upstart
#  supports :status => true, :restart => true
#  action [ :enable, :start ]
#end

#
# nginx site
#
template "/etc/nginx/sites-available/#{app['id']}" do
  source "/etc/nginx/sites-available/default.erb"
  owner app['owner']
  group app['group']
  mode '0664'
  variables({
              :listen => app['appserver_port'],
              :server_names => [ app['domain'] ].concat( app['domains'] ),
              :deploy_to => app['deploy_to']
            })
end

