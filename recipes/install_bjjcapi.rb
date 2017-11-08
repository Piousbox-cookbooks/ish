
#
# _vp_ 20171103
# use with ish::install_nginx, ish::install_bjjcapi then use capistrano to deploy
#
# this just puts the codebase in, not runs the service
#

def puts! a, b=''
  puts "+++ +++ #{b}"
  puts a.inspect
end

include_recipe 'ish::install_ruby'

user             = node.attributes['user']
app              = data_bag_item('apps', 'bjjcollective')
app['deploy_to'] = "/home/#{user}/projects/#{app['id']}"
app['owner']     = user
app['group']     = user
ruby_version     = node.attributes['ruby_version']
ruby_path        = "/home/#{user}/.rbenv/versions/#{ruby_version}/bin/ruby"
bundle_cmd       = "RAILS_ENV=#{app['rack_environment'][node.chef_environment]} /home/#{user}/.rbenv/versions/#{ruby_version}/bin/bundle"
bundle_exec      = "#{bundle_cmd} exec"
mongo_host       = node.attributes['mongo_host'] # app['databases']['mongoid']['host']

raise 'need ruby version here' unless ruby_version
raise 'need user here'         unless user
raise "need domain here"       unless app['domain'][node.chef_environment]

puts! app['domain'][node.chef_environment], 'domain is'
puts! app, 'app'

app['packages'].each do |pkg, version|
  package pkg do
    action :install
  end
end

        ##
        ## some folders
        ##
        directory "#{app['deploy_to']}/shared" do
          mode       "0777"
          recursive  true
        end
        %w{ log pids config/initializers }.each do |name|
          directory "#{app['deploy_to']}/shared/#{name}" do
            action     :create
            recursive  true
            owner      app['owner']
            mode       '0700'
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
          owner  app['owner']
          group  app['group'] 
          mode   '0600'
        end
        template "#{app['deploy_to']}/deploy-ssh-wrapper" do
          source     "deploy-ssh-wrapper.erb"
          owner      app['owner']
          group      app['group']
          mode       "0755"
          variables  app.to_hash
        end
       
        ##
        ## deploy resource
        ##
        deploy_revision app['id'] do
          revision      app['revision'][node.chef_environment]
          repository    app['repository']
          user          app['owner']
          group         app['group']
          deploy_to     app['deploy_to']
          environment   'RAILS_ENV' => app['rack_environment'][node.chef_environment]
          action        app['force'][node.chef_environment] ? :force_deploy : :deploy
          ssh_wrapper   "#{app['deploy_to']}/deploy-ssh-wrapper" if app['deploy_key']
          shallow_clone false # reference is not a tree -> set this to false.
          migrate       false
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
          execute "bundle" do
            command "export LANG=en_US.UTF-8 &&
                     export LANGUAGE=en_US.UTF-8 &&
                     export export LC_ALL=en_US.UTF-8 && 
                     #{bundle_cmd} --path #{app['deploy_to']}/vendor/bundle --without development test"
            cwd "#{app['deploy_to']}/current"
          end
        end
        
        #
        # configure the app
        #
        template "#{app['deploy_to']}/shared/config/database.yml" do
          owner app['owner']
          source "app/config/database.yml.erb"
          variables(
          )
        end
        link "#{app['deploy_to']}/current/config/database.yml" do
          to "#{app['deploy_to']}/shared/config/database.yml"
          link_type :symbolic
        end

        template "#{app['deploy_to']}/shared/config/initializers/00_s3.rb" do
          owner app['owner']
          source "app/config/initializers/s3.rb.erb"
          variables(
            :key       => app['s3_key'][node.chef_environment],
            :secret    => app['s3_secret'][node.chef_environment],
            :bucket    => app['s3_bucket'][node.chef_environment],
            :s3_region => app['s3_region'][node.chef_environment]
          )
        end
        link "#{app['deploy_to']}/current/config/initializers/00_s3.rb" do
          to "#{app['deploy_to']}/shared/config/initializers/00_s3.rb"
          link_type :symbolic
        end

        template "#{app['deploy_to']}/shared/config/initializers/05_stripe.rb" do
          owner app['owner']
          source "app/config/initializers/05_stripe.rb.erb"
          variables(
            :stripe_sk => app['stripe_sk'][node.chef_environment],
            :stripe_pk => app['stripe_pk'][node.chef_environment]
          )
        end
        link "#{app['deploy_to']}/current/config/initializers/05_stripe.rb" do
          to "#{app['deploy_to']}/shared/config/initializers/05_stripe.rb"
          link_type :symbolic
        end

        template "#{app['deploy_to']}/shared/config/initializers/koala.rb" do
          owner app['owner']
          source "app/config/initializers/koala.rb.erb"
          variables(
            # :access_token     => app['facebook'][node.chef_environment]['access_token'],
            # :app_access_token => app['facebook'][node.chef_environment]['app_access_token'],
            :app_id           => app['facebook'][node.chef_environment]['app_id'],
            :app_secret       => app['facebook'][node.chef_environment]['app_secret']
          )
        end
        link "#{app['deploy_to']}/current/config/initializers/koala.rb" do
          to "#{app['deploy_to']}/shared/config/initializers/koala.rb"
          link_type :symbolic
        end

        template "#{app['deploy_to']}/shared/config/mongoid.yml" do
          owner app['owner']
          source "app/config/mongoid.yml.erb"
          variables(
            :host        => mongo_host,
            :database    => app['mongodb']['database'],
            :environment => app['rack_environment'][node.chef_environment]
          )
        end
        link "#{app['deploy_to']}/current/config/mongoid.yml" do
          to "#{app['deploy_to']}/shared/config/mongoid.yml"
          link_type :symbolic
        end
        

        #
        # create some dirs
        #
        %w{ tmp/cache tmp/cache/assets }.each do |folder|
          directory "#{app['deploy_to']}/current/#{folder}" do
            action     :create
            owner      app['owner']
            recursive  true
            mode       "0777"
          end
        end

        #
        # migrate
        #
        execute "migrate" do
          command "#{bundle_exec} rake migrate"
          cwd     "#{app['deploy_to']}/current"
        end

        #
        # clear cache
        #
        execute "#{bundle_exec} rake tmp:cache:clear" do
          cwd "#{app['deploy_to']}/current"
        end


        #
        # virtual site of nginx
        #
        template "/etc/nginx/sites-available/#{app['id']}" do
          source "etc/nginx/sites-available/app"
          variables(
            :site_domain => app['domain'][node.chef_environment],
            :root      => "#{app['deploy_to']}/current/public",
            :ruby_path => ruby_path,
            :rails_env => app['rack_environment'][node.chef_environment]
          )
        end
        link "/etc/nginx/sites-enabled/#{app['id']}" do
          to "/etc/nginx/sites-available/#{app['id']}"
        end

        execute "sudo systemctl restart nginx.service" 




