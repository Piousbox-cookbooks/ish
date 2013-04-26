#
#
# Copyright 2012, CAC
#
# ish upstream
# should be appname-agnostic
#
# 20120719
#

gems = %w{ bundler unicorn }

gems.each do |gem|
  gem_package gem do
    action :install
  end
end


# iterate over apps databag and set up each app
data_bag("apps").each do |entry|
  app = data_bag_item("apps", entry)
  appname = app['id']
  deploy_to = app['deploy_to']

  
  (app["server_roles"] & node.run_list.roles).each do |app_role|
    
    # app_role = piousbox
    Chef::Log.info("Installing #{app['id']}")
  

    shared_root = "#{deploy_to}/shared"

    directory shared_root do
      owner 'ubuntu'
      group 'ubuntu'
      recursive true
    end
  
    template "#{shared_root}/unicorn.rb" do
      owner 'ubuntu'
      group 'nogroup'
      source "unicorn.conf.rb.erb"
      mode "0664"
      variables(
        :app => appname,
        :port => app['unicorn_port']
      )
    end
    
    rbenv_script "permissions of global bundle" do
      code %{ sudo chown ubuntu /usr/local/rbenv/versions -R }
    end

    rbenv_script "bundle install" do
      code %{cd #{deploy_to}/current && bundle install --without test development --path vendor/bundle}
    end
  
#    rbenv_script "submodule updaate" do
#      code %{cd #{deploy_to}/current && git submodule init && git submodule update }
#    end

    upstart_script_name = "#{appname}-app"

    template "/etc/init/#{upstart_script_name}.conf" do
      source "unicorn-upstart.conf.erb"
      owner "root"
      group "root"
      mode "0664"

      variables(
        :app_name       => app['id'],
        :app_root       => "#{deploy_to}/current",
        :log_file       => "#{deploy_to}/current/log/unicorn.log",
        :unicorn_config => "#{deploy_to}/shared/unicorn.rb",
        :unicorn_binary => "bundle exec unicorn_rails",
        :rack_env       => 'production'
      )
    end

    service upstart_script_name do
      provider Chef::Provider::Service::Upstart
      supports :status => true, :restart => true
      action [ :enable, :start ]
    end
    
  end
end