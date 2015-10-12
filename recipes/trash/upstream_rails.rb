
def puts! args, label = ""
  puts "+++ +++ #{label}"
  puts args.inspect
end

gems = %w{ bundler }
gems.each do |gem|
  gem_package gem do
    action :install
  end
end


# puts! node.roles, "Node Roles"
# search(:apps) do |any_app|
#   puts! any_app['id']
# end

search(:apps) do |any_app|

  if node.roles.include?( any_app['id'] )
    app = data_bag_item('apps', any_app['id'])

    if app['type'][app['id']].include?( 'rails' )

      #
      # deploy_to dirs & related
      #
      directory "#{app['deploy_to']}/shared" do
        action :create
        recursive true
        owner app['owner']
      end
      %w{ log pids system vendor_bundle }.each do |name|
        directory "#{app['deploy_to']}/shared/#{name}" do
          action :create
          recursive true
          owner app['owner']
        end
      end



      #
      # wrapper
      # 
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
      

      #
      # Deploy resource
      #
      deploy_revision app['id'] do
        revision app['revision'][node.chef_environment]
        repository app['repository']
        user app['owner']
        group app['group']
        deploy_to app['deploy_to']
        environment 'RAILS_ENV' => app['rack_environment']
        action app['force'][node.chef_environment] ? 'force_deploy' : 'deploy'
        ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
        shallow_clone false
        migrate false
      end
      
      
      
      #
      # bundle
      #
      rbenv_script "permissions for bundler" do
        code %{ sudo chown ubuntu /usr/local/rbenv -R }
      end
      rbenv_script "install bundler" do
        code %{ cd #{app['deploy_to']}/current && gem install bundler }
      end
      rbenv_script 'bundle install' do
        code %{ cd #{app['deploy_to']}/current && bundle install --without development test }
      end
      


      #
      # app config
      #
      template "#{app['deploy_to']}/current/config/initializers/s3.rb" do
        owner app['owner']
        source "app/config/initializers/s3.rb.erb"
        variables(
                  :key => app['s3_key'],
                  :secret => app['s3_secret'],
                  :bucket => app['s3_bucket']
                  )
      end
      template "#{app['deploy_to']}/current/config/mongoid.yml" do
        owner app['owner']
        source "app/config/mongoid.yml.erb"
        variables(
                  :host => data_bag_item('utils', 'db_config')['mongodb_ip'],
                  :database => app['databases']['mongoid']['database'],
                  :environment => app['rack_environment']
                  )
      end
      link "#{app['deploy_to']}/current/app/models" do
        to "/home/ubuntu/projects/ish_lib/current/app/models"
      end
      link "#{app['deploy_to']}/current/lib" do
        to "/home/ubuntu/projects/ish_lib/current/lib"
      end



      #
      # service
      #
      template "#{app['deploy_to']}/shared/unicorn.rb" do
        owner 'ubuntu'
        group 'nogroup'
        source "unicorn.conf.rb.erb"
        mode "0664"
        variables(
                  :app => app['id'],
                  :port => app['unicorn_port']
                  )
      end
      upstart_script_name = "#{app['id']}-app"
      template "/etc/init/#{upstart_script_name}.conf" do
        source "unicorn-upstart.conf.erb"
        owner "root"
        group "root"
        mode "0664"
        variables(
                  :app_name       => app['id'],
                  :app_root       => "/home/ubuntu/projects/#{app['id']}/current",
                  :log_file       => "/home/ubuntu/projects/#{app['id']}/current/log/unicorn.log",
                  :unicorn_config => "/home/ubuntu/projects/#{app['id']}/shared/unicorn.rb",
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

