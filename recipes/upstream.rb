search(:apps) do |app|
  (app["server_roles"] & node.run_list.roles).each do |app_role|
    app["type"][app_role].each do |thing|
      node.run_state[:current_app] = app
      appname = app_role
      deploy_to = "/home/ubuntu/projects/#{app['id']}"
      
      app = data_bag_item("apps", appname)
      rails_env = app['rack_environment']

      ## Then, deploy
      deploy_revision app['id'] do
        revision app['revision'][node.chef_environment]
        repository app['repository']
        user app['owner']
        group app['group']
        deploy_to app['deploy_to']
        environment 'RAILS_ENV' => rails_env
        action app['force'][node.chef_environment] ? :force_deploy : :deploy
        ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
        shallow_clone true
        before_migrate do
          if app['gems'].has_key?('bundler')
            link "#{release_path}/vendor/bundle" do
              to "#{app['deploy_to']}/shared/vendor_bundle"
            end
            common_groups = %w{development test cucumber staging production}
            execute "bundle install --deployment --without #{(common_groups -([node.chef_environment])).join(' ')}" do
              ignore_failure true
              cwd release_path
            end
          elsif app['gems'].has_key?('bundler08')
            execute "gem bundle" do
              ignore_failure true
              cwd release_path
            end
            
          elsif node.chef_environment && app['databases'].has_key?(node.chef_environment)
            # chef runs before_migrate, then symlink_before_migrate symlinks, then migrations,
            # yet our before_migrate needs database.yml to exist (and must complete before
            # migrations).
            #
            # maybe worth doing run_symlinks_before_migrate before before_migrate callbacks,
            # or an add'l callback.
            execute "(ln -s ../../../shared/database.yml config/database.yml && rake gems:install); rm config/database.yml" do
              ignore_failure true
              cwd release_path
            end
          end
        end
        
        symlink_before_migrate({
                                 "database.yml" => "config/database.yml",
                                 "memcached.yml" => "config/memcached.yml"
                               })
        
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
      
      rbenv_script "permissions for bundler" do
        code %{ sudo chown ubuntu /usr/local/rbenv -R }
      end
      
      rbenv_script "install bundler" do
        code %{ cd #{deploy_to}/current && gem install bundler }
      end

      rbenv_script 'bundle install' do
        code %{ cd #{deploy_to}/current && bundle install --without development test }
      end

      rbenv_script 'recompile bcrypt' do
        code %{ cd #{deploy_to}/current/vendor/ruby/1.9.1/gems/bcrypt*/ext/mri && ruby extconf.rb && make && make install }
      end

      template "#{deploy_to}/shared/unicorn.rb" do
        owner 'ubuntu'
        group 'nogroup'
        source "unicorn.conf.rb.erb"
        mode "0664"
        variables(
          :app => appname,
          :port => app['unicorn_port']
        )
      end

      # rbenv_script "bundle install" do
      #   code %{cd #{deploy_to}/current && bundle install --without test development --path vendor/bundle }
      # end

      rbenv_script "precompile assets" do
        code %{cd #{deploy_to}/current && bundle exec rake assets:precompile && chown ubuntu public/assets -R }
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
          :rack_env       => app['rack_environment']
        )
      end

      template "#{deploy_to}/current/config/initializers/const.rb" do
        owner 'ubuntu'
        group 'nogroup'
        source "qxt/const.rb.erb"
        mode "0664"
      end

      template "#{deploy_to}/current/config/mongoid.yml" do        
        if appname == 'qxt'
          source "app/config/mongoid.yml.erb"
        else
          source "app/config/mongoid_v2.0.yml.erb"
        end
        
        owner "ubuntu"
        group "ubuntu"
        mode "0664"
      
        variables(
          :host => data_bag_item('utils', 'db_config')["mongodb_ip"],
          :port => data_bag_item('utils', 'db_config')["mongodb_port"],
          :database => data_bag_item('utils', 'db_config')["mongodb_database"]
        )
      end
      
      template "#{deploy_to}/current/config/database.yml" do
        source "app/config/database_remote.yml.erb"
        owner "ubuntu"
        group "ubuntu"
        mode "0664"
      
        variables(
          :host => data_bag_item('utils', 'db_config')["mysql_ip"],
          :database => "showv"
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

node.run_state.delete(:current_app)

