
#
# Recipe ish::static_site
#
# _vp_ 20151228
#

search(:apps).each do |any_app|
  node.roles.each do |role|
    if any_app['id'] == role
      app = data_bag_item 'apps', any_app['id']
      if app['type'][app['id']].include? 'static_site'
        puts! "ish::static_site, deploying #{role}"

        user = app['user'][node.chef_environment]
        port = app['port'][node.chef_environment]
        projects_dir = "/home/#{user}/projects"
        app['deploy_to'] = "#{projects_dir}/#{app['id']}"
        
        directory projects_dir do
          action :create
          recursive true
          owner user
          group user
        end

        # deploy resource
        ruby_block "write_key" do
          block do
            f = ::File.open("#{projects_dir}/id_deploy", "w")
            f.print(app["deploy_key"])
            f.close
          end
          not_if do ::File.exists?("#{projects_dir}/id_deploy"); end
        end
        file "#{projects_dir}/id_deploy" do
          owner user
          group user
          mode '0600'
        end
        template "#{projects_dir}/deploy-ssh-wrapper" do
          source "deploy-ssh-wrapper.erb"
          owner user
          group user
          mode "0755"
          variables({
                      :deploy_to => app['deploy_to']
                    })
        end
        
        #
        # deploy resource
        #
        deploy_revision app['id'] do
          revision app['revision'][node.chef_environment]
          repository app['repository']
          user user
          group user
          deploy_to app['deploy_to']
          environment 'RAILS_ENV' => app['rack_environment']
          action app['force'][node.chef_environment] ? :force_deploy : :deploy
          ssh_wrapper "#{projects_dir}/deploy-ssh-wrapper" if app['deploy_key']
          shallow_clone true
          migrate false
        end

        # open this port in apache2 config
        if File.exist?( "/etc/apache2/ports.conf" )
          if File.read( "/etc/apache2/ports.conf" ).include?( "Listen #{port}" )
            ; # do nothing
          else
            ` echo "Listen #{port}" >> /etc/apache2/ports.conf `
            ` echo "NameVirtualHost *:#{port}" >> /etc/apache2/ports.conf `
          end
        end
        
        if app['is_angular']
          # configure apache2 angular site
          template "/etc/apache2/sites-available/#{app['id']}.conf" do
            source "etc/apache2/sites-available/site_angular.conf.erb"
            owner user
            group user
            mode "0664"
            variables(
              :name => app['id'],
              :port => port,
              :user => user
            )
          end
          # configure the api endpoint
          template "#{app['deploy_to']}/current/public/js/config.js" do
            source "app/public/js/config.js.erb"
            owner user
            group user
            mode "0664"
            variables(
              :endpoint => app['api_endpoint']
            )
          end
        else
          # configure apache2 site
          template "/etc/apache2/sites-available/#{app['id']}.conf" do
            source "etc/apache2/sites-available/site_simple.conf.erb"
            owner user
            group user
            mode "0664"
            variables(
              :name => app['id'],
              :port => port,
              :user => user
            )
          end
        end
        
        execute "enable site" do
          command %{ a2ensite #{app['id']} }
        end

        execute "open this port" do
          command %{ echo "\nListen #{port}" >> /etc/apache2/ports.conf }
          not_if { ::File.read("/etc/apache2/ports.conf").include?("Listen #{port}") }
        end
        execute "open this port 2" do
          command %{ echo "\nNameVirtualHost *:#{port}" >> /etc/apache2/ports.conf }
          not_if { ::File.read("/etc/apache2/ports.conf").include?("NameVirtualHost *:#{port}") }
        end
        
        execute "reload apache2 config" do
          command %{ service apache2 reload }
        end

      end
    end
  end
end






