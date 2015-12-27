
#
# cookbook ish
# recipe   upstream_rails
#
# _vp_ 20151226
#



# gems = %w{ bundler }
# gems.each do |gem|
#   gem_package gem do
#     action :install
#   end
# end

def puts! a, b=""
  puts "+++ +++ #{b}"
  puts a.inspect
end

include_recipe 'ruby_build'
include_recipe 'rbenv'

search(:apps) do |any_app|
  node.roles.each do |role|

    if any_app['id'] == role
      app = data_bag_item('apps', any_app['id'])
      if app['type'][app['id']].include?( "upstream_rails" )
        puts! "Deploying ish::upstream_rails app #{app['id']}"

        deploy_to = "/home/#{app['user'][node.chef_environment]}/projects/#{app['id']}"
        owner = app['owner'][node.chef_environment]

        app['packages'].each do |package, version|
          execute "apt-get install #{package} -y"
        end

        directory "#{deploy_to}/shared" do
          action :create
          owner owner
          recursive true
          mode '0766'
        end
        
        directory "#{deploy_to}/shared/config" do
          action :create
          recursive true
          owner owner
        end
        %w{ log pids }.each do |name|
          directory "#{deploy_to}/shared/#{name}" do
            action :create
            recursive true
            owner owner
          end
        end
        
        # execute "install bundler" do
        #   command "apt-get install bundler -y"
        # end
        
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
          owner owner
          group owner
          mode '0600'
        end
        template "#{deploy_to}/deploy-ssh-wrapper" do
          source "deploy-ssh-wrapper.erb"
          owner owner
          group owner
          mode "0755"
          variables app.to_hash
        end
       
        #
        # deploy resource
        #
        deploy_revision app['id'] do
          revision app['revision'][node.chef_environment]
          repository app['repository']
          user owner
          group owner
          deploy_to deploy_to
          environment 'RAILS_ENV' => app['rack_environment']
          action app['force'][node.chef_environment] ? :force_deploy : :deploy
          ssh_wrapper "#{deploy_to}/deploy-ssh-wrapper" if app['deploy_key']
          shallow_clone false # reference is not a tree -> set this to false.
          migrate false
        end

        # if app['skip_bundle']
        #   ; # do nothing
        # else
        #   #
        #   # bundle
        #   #
        #   [ :delete, :create ].each do |which_action|
        #     directory "#{deploy_to}/current/vendor" do
        #       action which_action
        #       recursive true
        #     end
        #   end
        #   execute "bundle" do
        #     command "export LANG=en_US.UTF-8 &&
        #              export LANGUAGE=en_US.UTF-8 &&
        #              export export LC_ALL=en_US.UTF-8 && 
        #              bundle --without development test"
        #     cwd "#{app['deploy_to']}/current"
        #   end
        # end

        
        #
        # configure the app
        #
        if app['s3_key']
          template "#{deploy_to}/current/config/initializers/s3.rb" do
            owner owner
            group owner
            source "app/config/initializers/s3.rb.erb"
            variables(
              :key => app['s3_key'],
              :secret => app['s3_secret'],
              :bucket => app['s3_bucket']
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
        if app['recaptcha_site_key']
          template "#{deploy_to}/current/config/initializers/recaptcha.rb" do
            owner owner
            group owner
            source "app/config/initializers/recaptcha.rb.erb"
            variables(
              :site_key => app['recaptcha_site_key'],
              :secret_key => app['recaptcha_secret_key']
            )
          end
        end
        if %w( mysql mysql2 ).include? app['databases'][node.chef_environment]['adapter']
          template "#{deploy_to}/shared/config/database.yml" do
            owner owner
            group owner
            source "app/config/database_remote.yml.erb"
            variables(
              :database => app['databases'][node.chef_environment]['database'],
              :host     => app['databases'][node.chef_environment]['host'],
              :username => app['databases'][node.chef_environment]['username'],
              :password => app['databases'][node.chef_environment]['password']
            )
          end
        end

        #
        # create some dirs
        #
        %w{ tmp tmp/cache tmp/cache/assets }.each do |folder|
          directory "#{deploy_to}/current/#{folder}" do
            action :create
            mode '0777'
            owner owner
            group owner
            recursive true
          end
        end
        

        #
        # service
        #
        template "#{deploy_to}/shared/unicorn.rb" do
          owner owner
          group owner
          source "unicorn.conf.rb.erb"
          mode "0664"
          variables({
                      :app => app['id'],
                      :deploy_to => deploy_to,
                      :port => app['unicorn_port'],
                      :owner => owner,
                      :group => owner
                    })
        end
        upstart_script_name = "#{app['id']}-app"
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

