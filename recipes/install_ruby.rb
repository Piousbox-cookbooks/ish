
#
# cookbook ish
# recipe   install_ruby
#
# _vp_ 20151227
#      20160113 rbenv doesn't work again... installing from packages
# _vp_ 20160508 This here, it better work!
#
#

# @TODO: refactor, this should be in attributes/default.rb
user = case node.chef_environment
       when 'vm_samsung'
         'oink'
       when 'vm_vagrant'
         'vagrant'
       when 'vm_vagrant_spec'
         'vagrant'
       when '_default'
         'ubuntu'
       when 'aws_production'
         'ubuntu'
       when 'aws_staging'
         'ubuntu'
       when 'demo1'
         'ubuntu'
       when 'demo2'
         'ubuntu'
       else
         'ubuntu'
       end

# @TODO: refactor this into attributes/default.rb
%w{ git libssl-dev libreadline-dev }.each do |pkg|
  package pkg
end

execute "install rbenv" do
  command "git clone https://github.com/rbenv/rbenv.git /home/#{user}/.rbenv"
  not_if { ::File.exists?( "/home/#{user}/.rbenv" ) }
end

execute "install ruby-build" do
  command "git clone https://github.com/rbenv/ruby-build.git /home/#{user}/.rbenv/plugins/ruby-build"
  not_if { ::File.exists?( "/home/#{user}/.rbenv/plugins/ruby-build" ) }
end

node['rbenv']['rubies'].each do |ruby_version|
  execute "install ruby #{ruby_version}" do
    cwd "/home/#{user}/.rbenv/bin"
    command <<-EOL
      ./rbenv install #{ruby_version}
    EOL
    not_if "/home/#{user}/.rbenv/bin/rbenv versions | grep #{ruby_version}"
  end
  execute "/home/#{user}/.rbenv/versions/#{ruby_version}/bin/gem install bundler"
end

file "/home/#{user}/.rbenv/version" do
  content node['rbenv']['global']
end


