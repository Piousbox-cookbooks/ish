
#
# Recipe ish::static_site
#

search(:apps) do |any_app|
  node.roles.each do |role|
    if any_app['id'] == role
      app = data_bag_item 'apps', any_app['id']
      if app['type'][app['id']].include? 'static_site'
        puts! "ish::static_site, deploying #{role}"

        # deploy resource
        ` mkdir -p /home/#{app['user']}/projects `
        ruby_block "write_key" do
          block do
            f = ::File.open("/home/#{app['user']}/projects/id_deploy", "w")
            f.print(app["deploy_key"])
            f.close
          end
          not_if do ::File.exists?("/home/#{app['user']}/projects/id_deploy"); end
        end
        file "/home/#{app['user']}/projects/id_deploy" do
          owner app['user']
          group app['user'] 
          mode '0600'
        end
        template "/home/#{app['user']}/projects/deploy-ssh-wrapper" do
          source "deploy-ssh-wrapper.erb"
          owner app['user']
          group app['user']
          mode "0755"
          variables({
                      :deploy_to => "/home/#{app['user']}/projects"
                    })
        end
        
        #
        # deploy resource
        #
        deploy_revision app['id'] do
          revision app['revision'][node.chef_environment]
          repository app['repository']
          user app['user']
          group app['user']
          deploy_to "/home/#{app['user']}/projects/#{app['id']}"
          environment 'RAILS_ENV' => app['rack_environment']
          action app['force'][node.chef_environment] ? :force_deploy : :deploy
          ssh_wrapper "/home/#{app['user']}/projects/deploy-ssh-wrapper" if app['deploy_key']
          shallow_clone true
          migrate false
        end

        # open this port in apache2 config
        if File.exist?( "/etc/apache2/ports.conf" )
          if File.read( "/etc/apache2/ports.conf" ).include?( "Listen #{app['port']}" )
            ; # do nothing
          else
            ` echo "Listen #{app['port']}" >> /etc/apache2/ports.conf `
            ` echo "NameVirtualHost *:#{app['port']}" >> /etc/apache2/ports.conf `
          end
        end
        
        if app['is_angular']
          # configure apache2 angular site
          template "/etc/apache2/sites-available/#{app['id']}.conf" do
            source "etc/apache2/sites-available/site_angular.conf.erb"
            owner app['user']
            group app['user']
            mode "0664"
            variables(
              :name => app['id'],
              :port => app['port'],
              :user => app['user']
            )
          end
          # configure the api endpoint
          template "/home/#{app['user']}/projects/#{app['id']}/current/public/js/config.js" do
            source "app/public/js/config.js.erb"
            owner app['user']
            group app['user']
            mode "0664"
            variables(
              :endpoint => app['api_endpoint']
            )
          end
        else
          # configure apache2 site
          template "/etc/apache2/sites-available/#{app['id']}.conf" do
            source "etc/apache2/sites-available/site_simple.conf.erb"
            owner app['user']
            group app['user']
            mode "0664"
            variables(
              :name => app['id'],
              :port => app['port'],
              :user => app['user']
            )
          end
        end
        
        execute "enable site" do
          command %{ a2ensite #{app['id']} }
        end

        execute "open this port" do
          command %{ echo "\nListen #{app['port']}" >> /etc/apache2/ports.conf }
          not_if { ::File.read("/etc/apache2/ports.conf").include?("Listen #{app['port']}") }
        end
        execute "open this port 2" do
          command %{ echo "\nNameVirtualHost *:#{app['port']}" >> /etc/apache2/ports.conf }
          not_if { ::File.read("/etc/apache2/ports.conf").include?("NameVirtualHost *:#{app['port']}") }
        end
        
        execute "reload apache2 config" do
          command %{ service apache2 reload }
        end

      end
    end
  end
end






