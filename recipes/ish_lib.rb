
#
# ish-lib, deploy resource 
# Copyright (c) CAC 
# 20120801
# 20140623
#
#
#

app = data_bag_item('utils', 'ish_lib')

rails_env = '_default'
deploy_to = app['deploy_to']

node.default[:apps][app['id']][node.chef_environment][:run_migrations] = false

directory app['deploy_to'] do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

directory "#{app['deploy_to']}/shared" do
  owner app['owner']
  group app['group']
  mode '0755'
  recursive true
end

template "#{deploy_to}/shared/database.yml" do
  owner 'ubuntu'
  group 'nogroup'
  source "database.yml.erb"
  mode "0664"
  variables(
    
  )
end

%w{ log pids system vendor_bundle }.each do |dir|

  directory "#{app['deploy_to']}/shared/#{dir}" do
    owner app['owner']
    group app['group']
    mode '0755'
    recursive true
  end

end

puts '+++ +++'
puts app.inspect

if app['deploy_key']
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


## Then, deploy
deploy_revision app['id'] do
  revision app['revision'][node.chef_environment]
  repository app['repository']
  user app['owner']
  group app['group']
  deploy_to app['deploy_to']
  environment 'RAILS_ENV' => app['rack_environment']
  action app['force'][node.chef_environment] ? :force_deploy : :deploy
  ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
  shallow_clone true  
  migrate false

end

node.run_state.delete(:current_app)
