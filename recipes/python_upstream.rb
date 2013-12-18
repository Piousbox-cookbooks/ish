search(:apps) do |app|
  (app["server_roles"] & node.run_list.roles).each do |app_role|

    # @TODO remove
    puts '+++ +++ The app is:'
    puts app.inspect

    app["type"][app_role].each do |thing|
      node.run_state[:current_app] = app
      appname = app_role
      
      app = data_bag_item("apps", appname)
      rails_env = app['rack_environment']
      deploy_to = app['deploy_to']
      deploy_user = app['owner']

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
      
      # 
      # install pips
      #
      # note: this does not really work, everything should be done inside a virtualenv
      #
      # app['pips'].each do |p|
      #   python_pip p[0] do
      #     version p[1]
      #     action :install
      #   end
      # end

      #
      # install virtualenv
      #
      # mkdir -p /home/ubuntu/.virtualenv
      # cd /home/ubuntu/.virtualenv
      # virtualenv --python=python2.6 env_26
      
      # install pips in the virtualenv
      app['pips'].each do |p|
        execute "install pip #{p[0]}" do
          cwd "/home/ubuntu/.virtualenv/env_26/bin"
          command "./python ./pip install #{p[0]}"
          action :run
        end
      end

      template "#{deploy_to}/shared/unicorn.rb" do
        owner app['owner']
        group app['group']
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

      # rbenv_script "precompile assets" do
      #   code %{cd #{app['deploy_to']}/current && bundle exec rake assets:precompile && chown #{app['owner']} public/assets -R }
      # end

      upstart_script_name = "#{app['id']}-app"

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
    
    end
  end
end

node.run_state.delete(:current_app)

