
gems = %w{ bundler }

gems.each do |gem|
  gem_package gem do
    action :install
  end
end

app = data_bag_item("apps", 'microsites2_resume')



#
# stupid wrapper
#

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



#
# deploy resource
#

deploy_revision app['id'] do
  revision app['revision'][node.chef_environment]
  repository app['repository']
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  environment 'RAILS_ENV' => app['rack_environment']
  action :force_deploy # :deploy
  ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper"
  shallow_clone false
  migrate false
end

%w{ log pigs }.each do |name|
  directory "#{app['deploy_to']}/shared/#{name}" do
    action :create
    recursive true
    owner app['owner']
  end
end

#
# service
#
template "#{app['deploy_to']}/shared/unicorn.rb" do
  owner 'ubuntu'
  group 'nogroup'
  source "unicorn.conf.rb.erb"
  mode "0664"
  variables(
    :app => app['id'],
    :port => app['unicorn_port']
  )
end 
upstart_script_name = "#{app['id']}-app"
template "/etc/init/#{upstart_script_name}.conf" do
  source "unicorn-upstart.conf.erb"
  owner "root"
  group "root"
  mode "0664"
  variables(
    :app_name       => app['id'],
    :app_root       => "/srv/#{app['id']}/current",
    :log_file       => "/srv/#{app['id']}/current/log/unicorn.log",
    :unicorn_config => "/srv/#{app['id']}/shared/unicorn.rb",
    :unicorn_binary => "bundle exec unicorn_rails",
    :rack_env       => 'production'
  )
end

service upstart_script_name do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true
  action [ :enable, :start ]
end
    
