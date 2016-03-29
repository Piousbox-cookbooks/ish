
#
# cookbook ish
# recipe   upstream_rails
#
# _vp_ 20151226
#

include_recipe "ish::install_ruby"

search(:apps).each do |any_app|
  node.roles.each do |role|
    if any_app['id'] == role
      app = data_bag_item('apps', any_app['id'])
      if app['type'][app['id']].include?( "upstream_rails" )
        puts! "Deploying ish::upstream_rails app #{app['id']}"

        owner = user = app['owner'] ? app['owner'][node.chef_environment] : app['user'][node.chef_environment]
        deploy_to = "/home/#{owner}/projects/#{app['id']}"
        app['deploy_to'] = deploy_to
        ruby_version = node['rbenv']['rubies'][0]
        # in case of bjjc listen port is the one on top of both angular and appserver ports.
        listen_port = app['appserver_port'] ? app['appserver_port'][node.chef_environment] : app['listen_port'][node.chef_environment]
      

        app['packages'].each do |pkg, version|
          package pkg do
            action :install
          end
        end

        directory "#{deploy_to}/shared" do
          action      :create
          owner       owner
          recursive   true
          mode        '0766'
        end
        
        %w{ log pids config }.each do |name|
          directory "#{deploy_to}/shared/#{name}" do
            action      :create
            recursive   true
            owner       owner
          end
        end
        
        execute "install bundler" do
          command "/home/#{user}/.rbenv/shims/gem install bundler"
        end
        
        #
        # wrapper
        #
        ruby_block "write_key" do
          block do            
            f = ::File.open("#{deploy_to}/id_deploy", "w")
            f.print(app["deploy_key"])
            f.close
          end
          not_if do ::File.exists?("#{deploy_to}/id_deploy"); end
        end
        file "#{deploy_to}/id_deploy" do
          owner   owner
          group   owner
          mode    '0600'
        end
        template "#{deploy_to}/deploy-ssh-wrapper" do
          source      "deploy-ssh-wrapper.erb"
          owner       owner
          group       owner
          mode        "0755"
          variables   app.to_hash
        end

        # has to be before deploy_revision ??
        template "#{deploy_to}/shared/config/database.yml" do
          source    "app/config/database_remote.yml.erb"
          owner     owner
          group     owner
          variables(
            :database => app['databases']['mysql'][node.chef_environment]['database'],
            :host     => app['databases']['mysql'][node.chef_environment]['host'],
            :username => app['databases']['mysql'][node.chef_environment]['username'],
            :password => app['databases']['mysql'][node.chef_environment]['password']
          )
          only_if { %w{ mysql mysql2 }.include? app['databases']['mysql'][node.chef_environment]['adapter'] }
        end

        #
        # deploy resource
        #
        deploy_revision app['id'] do
          revision          app['revision'][node.chef_environment]
          repository        app['repository']
          user              owner
          group             owner
          deploy_to         deploy_to
          environment       'RAILS_ENV' => app['rack_environment']
          action            app['force'][node.chef_environment] ? :force_deploy : :deploy
          ssh_wrapper       "#{deploy_to}/deploy-ssh-wrapper" if app['deploy_key']
          shallow_clone     false # reference is not a tree -> set this to false.
          migrate           false
        end

        if app['skip_bundle']
          ; # do nothing
        else
          #
          # bundle
          #
          [ :delete, :create ].each do |which_action|
            directory "#{deploy_to}/current/vendor" do
              action which_action
              recursive true
            end
          end
          execute "bundle" do
            command "export LANG=en_US.UTF-8 &&
                     export LANGUAGE=en_US.UTF-8 &&
                     export export LC_ALL=en_US.UTF-8 && 
                     /home/#{user}/.rbenv/shims/bundle install --path vendor/bundle --without development test"
            cwd "#{app['deploy_to']}/current"
          end
        end

        #
        # configure the app
        #
        if app['s3_key']
          template "#{deploy_to}/current/config/initializers/s3.rb" do
            owner     owner
            group     owner
            source    "app/config/initializers/s3.rb.erb"
            variables(
              :key    => app['s3_key'][node.chef_environment],
              :secret => app['s3_secret'][node.chef_environment],
              :bucket => app['s3_bucket'][node.chef_environment]
            )
          end
        end
        if app['databases']['mongoid']
          template "#{deploy_to}/current/config/mongoid.yml" do
            owner owner
            group owner
            source "app/config/mongoid.yml.erb"
            variables(
              :host        => app['databases']['mongoid'][node.chef_environment]['host'],
              :database    => app['databases']['mongoid'][node.chef_environment]['database'],
              :environment => app['rack_environment']
            )
          end
        end
        template "#{deploy_to}/current/config/initializers/recaptcha.rb" do
          source    "app/config/initializers/recaptcha.rb.erb"
          owner     owner
          group     owner
          variables(
            :site_key   => app['recaptcha_site_key'],
            :secret_key => app['recaptcha_secret_key']
          )
          only_if { app['recaptcha_site_key'] }
        end
                
        #
        # create some dirs
        #
        %w{ tmp tmp/cache tmp/cache/assets }.each do |folder|
          directory "#{deploy_to}/current/#{folder}" do
            action      :create
            mode        '0777'
            owner       owner
            group       owner
            recursive   true
          end
        end
        

        #
        # service
        #
        template "#{deploy_to}/shared/unicorn.rb" do
          owner    owner
          group    owner
          source   "unicorn.conf.rb.erb"
          mode     "0664"
          variables({
                      :app => app['id'],
                      :deploy_to => deploy_to,
                      :port => listen_port,
                      :owner => owner,
                      :group => owner
                    })
        end
        upstart_script_name = "#{app['id']}-app"
        template "/etc/init/#{upstart_script_name}.conf" do
          source "unicorn-upstart.conf.erb"
          owner  "root"
          group  "root"
          mode   "0664"
          variables(
            :app_name       => app['id'],
            :app_root       => "#{deploy_to}/current",
            :log_file       => "#{deploy_to}/current/log/unicorn.log",
            :unicorn_config => "#{deploy_to}/shared/unicorn.rb",
            :unicorn_binary => "/home/#{user}/.rbenv/shims/bundle exec unicorn_rails",
            :rack_env       => app['rack_environment'],
            :user           => owner
          )
        end
        service upstart_script_name do
          provider Chef::Provider::Service::Upstart
          supports :status => true, :restart => true
          action [ :enable, :start ]
        end
      end
    end
  end
end

