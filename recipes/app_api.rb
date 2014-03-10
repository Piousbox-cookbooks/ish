
# 
# upstream JS recipe.
#

def puts! args
  puts '+++ +++'
  puts args.inspect
end

ish_lib = {}
ish_lib['deploy_to'] = '/home/ubuntu/projects/ish_lib'

search(:apps) do |app|
  (app["server_roles"] & node.run_list.roles).each do |app_role|

    puts! app_role

    app["type"][app_role].each do |thing|

      node.run_state[:current_app] = app      
      app = data_bag_item("apps", app_role)

      directory "#{app['deploy_to']}/shared" do
        owner app['owner']
        group app['group']
        mode '0755'
        recursive true
      end

      %w{ log pids system vendor_bundle config }.each do |dir|
        directory "#{app['deploy_to']}/shared/#{dir}" do
          owner app['owner']
          group app['group']
          mode '0755'
          recursive true
        end
      end

      execute "touch database.yml" do
        command "touch #{app['deploy_to']}/shared/config/database.yml"
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

      template "#{app['deploy_to']}/current/config/mongoid.yml" do        
        if app_role == 'qxt'
          source "app/config/mongoid.yml.erb"
        else
          source "app/config/mongoid_v2.0.yml.erb"
        end
        
        owner app['owner']
        group app['group']
        mode "0664"
      
        variables(
          :host => data_bag_item('utils', 'db_config')["mongodb_ip"],
          :port => data_bag_item('utils', 'db_config')["mongodb_port"],
          :database => data_bag_item('utils', 'db_config')["mongodb_database"]
        )
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

      rbenv_script "permissions for bundler" do
        code %{ sudo chown #{app['owner']} /usr/local/rbenv -R }
      end
      
      # rbenv_script "install bundler" do
      #   code %{ cd #{app['deploy_to']}/current && gem install bundler }
      # end

      rbenv_script 'uninstall and cleanup bundler gem' do
        code %{ cd #{app['deploy_to']}/current && gem cleanup bundler }
      end

      app['gems'].each do |gem|
        rbenv_script "install gem #{gem[0]}" do
          code %{ cd #{app['deploy_to']}/current && gem install #{gem[0]} --version #{gem[1]} }
        end
      end

      rbenv_script 'bundle install' do
        code %{ cd #{app['deploy_to']}/current && bundle install --without development test }
      end

      #
      # I'm using this recipe for deploying microsites2_resume2, which is the API backend for Pi & related.
      # This means that the nginx or unicorn site ^must^ be running, so there is  the upstart service yeah.
      #
      upstart_script_name = "#{app['id']}-app"

      template "#{app['deploy_to']}/shared/unicorn.rb" do
        owner app['owner']
        group app['group']
        source "unicorn.conf.rb.erb"
        mode "0664"
        variables(
          :app => app_role,
          :port => app['unicorn_port']
        )
      end
      
      template "/etc/init/#{upstart_script_name}.conf" do
        source "unicorn-upstart.conf.erb"
        owner "root"
        group "root"
        mode "0664"

        variables(
          :app_name       => app['id'],
          :app_root       => "#{app['deploy_to']}/current",
          :log_file       => "#{app['deploy_to']}/current/log/unicorn.log",
          :unicorn_config => "#{app['deploy_to']}/shared/unicorn.rb",
          :unicorn_binary => "bundle exec unicorn_rails",
          :rack_env       => app['rack_environment']
        )
      end

      service upstart_script_name do
        provider Chef::Provider::Service::Upstart
        supports :status => true, :restart => true
        action [ :enable, :start ]
      end
    
      # nginx site
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

      #
      # and then the links for the model and lib.
      #
      link "#{app['deploy_to']}/current/app/models" do
        to "#{ish_lib['deploy_to']}/current/app/models"
      end
      link "#{app['deploy_to']}/current/lib" do
        to "#{ish_lib['deploy_to']}/current/lib"
      end

    end
  end
end

node.run_state.delete(:current_app)

