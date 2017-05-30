
def puts! a, b=''
  puts "+++ +++ #{b}"
  puts a.inspect
end

include_recipe 'ish::install_ruby'

search(:apps) do |any_app|
  node.roles.each do |role|
    if any_app['id'] == role
      app = data_bag_item('apps', any_app['id'])
      if app['type'][app['id']].include?( "upstream_microsites3" )

        ##
        ## config
        ##
        user                = app['user'][node.chef_environment]
	      ruby_version        = app['ruby_version'][node.chef_environment]
        upstart_script_name = "#{app['id']}.service"
        bundle_exec = "RAILS_ENV=#{app['rack_environment']} /home/#{user}/.rbenv/versions/#{ruby_version}/bin/bundle exec"

        # let's free up some memory for this run
        service upstart_script_name do
          action :stop
        end


        ##
        ## some folders
        ##
        puts! app, 'herehere deployt ot'
        directory "#{app['deploy_to']}/shared" do
          mode "0777"
          recursive true
        end
        %w{ log pids }.each do |name|
          directory "#{app['deploy_to']}/shared/#{name}" do
            action :create
            recursive true
            owner app['owner']
            mode '0700'
          end
        end

        ##
        ## wrapper
        ##
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
       
        ##
        ## deploy resource
        ##
        deploy_revision app['id'] do
          revision app['revision'][node.chef_environment]
          repository app['repository']
          user app['owner']
          group app['group']
          deploy_to app['deploy_to']
          environment 'RAILS_ENV' => app['rack_environment']
          action app['force'][node.chef_environment] ? :force_deploy : :deploy
          ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
          shallow_clone false # reference is not a tree -> set this to false.
          migrate false
        end

        #
        # bundle
        #
        if app['skip_bundle']
          ; # do nothing
        else
          #
          # bundle
          #
          [ :delete, :create ].each do |which_action| # let's not :delete first, too time consuming _vp_ 20170520
            directory "#{app['deploy_to']}/current/vendor" do
              action which_action
              recursive true
            end
          end
          execute "bundle" do
            command "export LANG=en_US.UTF-8 &&
                     export LANGUAGE=en_US.UTF-8 &&
                     export export LC_ALL=en_US.UTF-8 && 
                     /home/#{user}/.rbenv/versions/#{ruby_version}/bin/bundle install --path vendor/bundle \
                       --without development test"
            cwd "#{app['deploy_to']}/current"
          end
        end
        
        #
        # configure the app
        #
        template "#{app['deploy_to']}/current/config/initializers/00_s3.rb" do
          owner app['owner']
          source "app/config/initializers/s3.rb.erb"
          variables(
            :key       => app['s3_key'],
            :secret    => app['s3_secret'],
            :bucket    => app['s3_bucket'],
            :s3_region => app['s3_region']
          )
        end
        template "#{app['deploy_to']}/current/config/mongoid.yml" do
          owner app['owner']
          source "app/config/mongoid.yml.erb"
          variables(
            :host => app['databases']['mongoid']['host'],
            :database => app['databases']['mongoid']['database'],
            :environment => app['rack_environment']
          )
        end


        #
        # create some dirs
        #
        %w{ tmp/cache tmp/cache/assets }.each do |folder|
          directory "#{app['deploy_to']}/current/#{folder}" do
            action :create
            owner app['owner']
            recursive true
            mode "0777"
          end
        end
        
        
        #
        # compile assets
        #
        execute "compile assets" do
          command "#{bundle_exec} rake assets:precompile"
          cwd "#{app['deploy_to']}/current"
        end


        #
        # service
        #
        template "#{app['deploy_to']}/shared/unicorn.rb" do
          owner app['owner']
          group app['owner']
          source "unicorn.rb.erb"
          mode "0664"
          variables({
                      :app => app['id'],
                      :deploy_to => app['deploy_to'],
                      :port => app['unicorn_port'],
                      :owner => app['owner'],
                      :group => app['group']
                    })
        end

        template "/lib/systemd/system/#{upstart_script_name}" do
          source "lib/systemd/system/unicorn-systemd.service.erb"
          owner "root"
          group "root"
          mode "0664"
          variables(
            :description    => app['id'],
            :cwd            => "#{app['deploy_to']}/current",
            :exec_start     => "/home/#{user}/.rbenv/versions/#{ruby_version}/bin/bundle exec unicorn_rails " +
                               "-c #{app['deploy_to']}/shared/unicorn.rb -E #{app['rack_environment']}",
            :exec_stop      => "/bin/echo nothing"
          )
        end
        service upstart_script_name do
          case node['platform']
          when 'ubuntu'
            if node['platform_version'].to_f >= 16.04
              provider Chef::Provider::Service::Systemd
            else
              provider Chef::Provider::Service::Upstart
            end
          end
          supports :status => true, :restart => true
          action [ :enable, :start, :restart ]
        end

        ##
        ## clear cache
        ##
        execute "#{bundle_exec} rake tmp:cache:clear"

      end
    end
  end
end

