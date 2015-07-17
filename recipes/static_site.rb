
#
# Recipe ish::static_site
#
# Deploys the resource of a static site (with public/ directory).
# Works in conjunction with ish_apache::static_site, which takes up a port and serves the ish::static_site to the load balancer (presumably).

# review config
site               = data_bag_item('utils', 'static_site')
site['repository'] = node['static_site']['repository'] || site['repository']
site['user']       = node['static_site']['user'] || site['user']
site['port']       = node['static_site']['port'] || site['port']
site['name']       = node['static_site']['site_name'] || site['name']
site['force']      = node['static_site']['force'] || site['force'][node.chef_environment]

# deploy resource
` mkdir -p /home/#{site['user']}/projects `
ruby_block "write_key" do
  block do
    f = ::File.open("/home/#{site['user']}/projects/id_deploy", "w")
    f.print(site["deploy_key"])
    f.close
  end
  not_if do ::File.exists?("/home/#{site['user']}/projects/id_deploy"); end
end
file "/home/#{site['user']}/projects/id_deploy" do
  owner app['owner']
  group app['group'] 
  mode '0600'
end
template "/home/#{site['user']}/projects/deploy-ssh-wrapper" do
  source "deploy-ssh-wrapper.erb"
  owner app['owner']
  group app['group']
  mode "0755"
  variables({
    :deploy_to => "/home/#{site['user']}/projects/#{site['name']}"
  })
end

#
# deploy resource
#
deploy_revision site['name'] do
  revision site['revision'][node.chef_environment]
  repository site['repository']
  user site['user']
  group site['user']
  deploy_to "/home/#{site['user']}/projects/#{site['name']}"
  environment 'RAILS_ENV' => site['rack_environment']
  action site['force'] ? :force_deploy : :deploy
  ssh_wrapper "/home/#{site['user']}/projects/deploy-ssh-wrapper" if site['deploy_key']
  shallow_clone true
  migrate false
end



# open this port in apache2 config
if File.read( "/etc/apache2/ports.conf" ).include?( "Listen #{site['port']}" )
  ; # do nothing
else
  ` echo "Listen #{site['port']}" >> /etc/apache2/ports.conf `
  ` echo "NameVirtualHost *:#{site['port']}" >> /etc/apache2/ports.conf `
end

# configure apache2 site
template "/etc/apache2/sites-available/#{site['name']}" do # no .conf extension
  source "etc/apache2/sites-available/site_simple.erb"
  owner site['user']
  group site['user']
  mode "0664"
  variables(
    :name => site['name'],
    :port => site['port'],
  )
end

execute "enable site" do
  command %{ a2ensite #{site['name']} }
end





