
#
# Recipe ish::static_site
#

def puts! args, label=""
  puts "+++ +++ #{label}"
  puts args.inspect
end

#
# review config
#
site               = data_bag_item('utils', 'static_site')
site['repository'] = node['static_site']['repository'] || site['repository']
site['user']       = node['static_site']['user'] || site['user']
site['port']       = node['static_site']['port'] || site['port']
site['name']       = node['static_site']['site_name'] || site['name']
site['force']      = node['static_site']['force'] || site['force'][node.chef_environment]
site['is_angular']    = node['static_site']['is_angular'] || false

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
  owner site['user']
  group site['user'] 
  mode '0600'
end
template "/home/#{site['user']}/projects/deploy-ssh-wrapper" do
  source "deploy-ssh-wrapper.erb"
  owner site['user']
  group site['user']
  mode "0755"
  variables({
    :deploy_to => "/home/#{site['user']}/projects"
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
if File.exist?( "/etc/apache2/ports.conf" )
  if File.read( "/etc/apache2/ports.conf" ).include?( "Listen #{site['port']}" )
    ; # do nothing
  else
    ` echo "Listen #{site['port']}" >> /etc/apache2/ports.conf `
    ` echo "NameVirtualHost *:#{site['port']}" >> /etc/apache2/ports.conf `
  end
end

if site['is_angular']
# configure apache2 angular site
template "/etc/apache2/sites-available/#{site['name']}.conf" do # no .conf extension
  source "etc/apache2/sites-available/site_angular.conf.erb"
  owner site['user']
  group site['user']
  mode "0664"
  variables(
    :name => site['name'],
    :port => site['port'],
    :user => site['user']
  )
end
else
# configure apache2 site
template "/etc/apache2/sites-available/#{site['name']}.conf" do # no .conf extension
  source "etc/apache2/sites-available/site_simple.conf.erb"
  owner site['user']
  group site['user']
  mode "0664"
  variables(
    :name => site['name'],
    :port => site['port'],
    :user => site['user']
  )
end
end

execute "enable site" do
  command %{ a2ensite #{site['name']} }
end

execute "open this port" do
  command %{ echo "\nListen #{site['port']}" >> /etc/apache2/ports.conf }
  not_if { ::File.read("/etc/apache2/ports.conf").include?("Listen #{site['port']}") }
end
execute "open this port 2" do
  command %{ echo "\nNameVirtualHost *:#{site['port']}" >> /etc/apache2/ports.conf }
  not_if { ::File.read("/etc/apache2/ports.conf").include?("NameVirtualHost *:#{site['port']}") }
end

execute "reload apache2 config" do
  command %{ service apache2 reload }
end







