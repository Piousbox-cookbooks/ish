#
# Cookbook Name:: tgtapps
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# backward compatibility
# use recipe upstream_2 instead
# problem: `ish` is hardcoded

app = data_bag_item("apps", 'cac')
appname = 'cac'

rbenv_script "install bundler" do
  code %{ cd /home/ubuntu/projects/#{appname}/current && gem install bundler }
end

template "/home/ubuntu/projects/#{appname}/shared/unicorn.rb" do
  owner 'ubuntu'
  group 'nogroup'
  source "unicorn.conf.rb.erb"
  mode "0664"
  variables(
    :app => appname,
    :port => app['unicorn_port']
  )
end

rbenv_script "bundle install" do
  # rbenv_version '1.9.2-p290'
  code %{cd /home/ubuntu/projects/#{appname}/current && bundle install --without test development --path vendor/bundle}
end

upstart_script_name = "#{app['id']}-app"

template "/etc/init/#{upstart_script_name}.conf" do
  source "unicorn-upstart.conf.erb"
  owner "root"
  group "root"
  mode "0664"

  variables(
    :app_name       => app['id'],
    :app_root       => "/home/ubuntu/projects/#{appname}/current",
    :log_file       => "/home/ubuntu/projects/#{appname}/current/log/unicorn.log",
    :unicorn_config => "/home/ubuntu/projects/#{appname}/shared/unicorn.rb",
    :unicorn_binary => "bundle exec unicorn_rails",
    :rack_env       => 'production'
  )
end

service upstart_script_name do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true
  action [ :enable, :start ]
end
    
    
