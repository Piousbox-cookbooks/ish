
#
# Recipe ish::static_site
#

def puts! args, label=""
  puts "+++ +++ #{label}"
  puts args.inspect
end

search(:apps) do |any_app|
  node.roles.each do |role|
    if any_app['id'] == role
      app = data_bag_item 'apps', any_app['id']
      if app['type'][app['id']].include? 'static_site'
        puts! "ish::static_site, deploying #{role}"

        port = app['port'][node.chef_environment]
        user = app['user'][node.chef_environment]
        
        # deploy resource
        ` mkdir -p /home/#{user}/projects `
        ruby_block "write_key" do
          block do
            f = ::File.open("/home/#{user}/projects/id_deploy", "w")
            f.print(app["deploy_key"])
            f.close
          end
          not_if do ::File.exists?("/home/#{user}/projects/id_deploy"); end
        end
        file "/home/#{user}/projects/id_deploy" do
          owner user
          group user 
          mode '0600'
        end
        template "/home/#{user}/projects/deploy-ssh-wrapper" do
          source "deploy-ssh-wrapper.erb"
          owner user
          group user
          mode "0755"
          variables({
                      :deploy_to => "/home/#{user}/projects"
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
          deploy_to "/home/#{user}/projects/#{app['id']}"
          environment 'RAILS_ENV' => app['rack_environment']
          action app['force'][node.chef_environment] ? :force_deploy : :deploy
          ssh_wrapper "/home/#{user}/projects/deploy-ssh-wrapper" if app['deploy_key']
          shallow_clone true
          migrate false
        end

        # open this port in apache2 config
        if File.exist?( "/etc/apache2/ports.conf" )
          if File.read( "/etc/apache2/ports.conf" ).include?( "Listen *:#{port}" )
            ; # do nothing
          else
            ` echo "Listen *:#{port}" >> /etc/apache2/ports.conf `
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
          template "/home/#{user}/projects/#{app['id']}/current/public/js/config.js" do
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
          command %{ echo "Listen *:#{port}" >> /etc/apache2/ports.conf }
          not_if { ::File.read("/etc/apache2/ports.conf").include?("Listen *:#{port}") }
        end
        
        service "apache2" do
          action :reload
        end
        
      end
    end
  end
end






