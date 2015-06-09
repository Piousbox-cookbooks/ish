
gems = %w{ bundler }

gems.each do |gem|
  gem_package gem do
    action :install
  end
end

def puts! a, b=""
  puts "+++ +++ #{b}"
  puts a.inspect
end

search(:apps) do |any_app|
  if node.roles.include?( any_app['id'] )
    app = data_bag_item('apps', any_app['id'])

    directory "#{app['deploy_to']}/shared" do
      action :create
      recursive true
      owner app['owner']
    end
    %w{ log pids }.each do |name|
      directory "#{app['deploy_to']}/shared/#{name}" do
        action :create
        recursive true
        owner app['owner']
      end
    end

    execute "install bundler" do
      command "apt-get install bundler -y"
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
    # deploy resource
    #
    deploy_revision app['id'] do
      revision app['revision'][node.chef_environment]
      repository app['repository']
      user app['owner']
      group app['group']
      deploy_to app['deploy_to']
      environment 'RAILS_ENV' => app['rack_environment']
      action app['force'][node.chef_environment] ? :force_deploy : :deploy
      ssh_wrapper "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
      shallow_clone true
      migrate false
    end


    #
    # bundle
    #
    [ :delete, :create ].each do |which_action|
      directory "#{app['deploy_to']}/current/vendor" do
        action which_action
        recursive true
      end
    end
    execute "bundle" do
      cwd "#{app['deploy_to']}/current"
    end



    #
    # configure the app
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
        :host => app['databases']['mongoid']['host'],
        :database => app['databases']['mongoid']['database'],
        :environment => app['rack_environment']
      )
    end



    #
    # service
    #
    template "#{app['deploy_to']}/shared/unicorn.rb" do
      owner app['owner']
      group app['group']
      source "unicorn.conf.rb.erb"
      mode "0664"
      variables({
        :app => app['id'],
        :port => app['unicorn_port'],
        :owner => app['owner'],
        :group => app['group']
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
        :app_root       => "#{app['deploy_to']}/current",
        :log_file       => "#{app['deploy_to']}/current/log/unicorn.log",
        :unicorn_config => "#{app['deploy_to']}/shared/unicorn.rb",
        :unicorn_binary => "bundle exec unicorn_rails",
        :rack_env       => 'production',
        :user           => app['owner']
      )
    end
    service upstart_script_name do
      provider Chef::Provider::Service::Upstart
      supports :status => true, :restart => true
      action [ :enable, :start ]
    end


  end
end
    
