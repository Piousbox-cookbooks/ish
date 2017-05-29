#
# Ish recipe base_aws
#

## yarn, for compiling rails assets
execute "curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -"
file "/etc/apt/sources.list.d/yarn.list" do
  content "deb https://dl.yarnpkg.com/debian/ stable main"
  mode '0755'
end

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

user = node['user'] || 'ubuntu'
homedir = 'root' == user ? '/root' : "/home/#{user}"

## ruby-dev is not a package I need?
packages = %w{
  emacs tree screen git wget curl
  imagemagick yarn
}



# packages += node['packages'].to_a || [] # _vp_ 20160426 what this? 
# Error executing action `install` on resource 'apt_package[accountsservice, {"version"=>"0.6.35-0ubuntu7.2"}]'
packages.each do |pkg|
  package pkg do
    action :install
  end
end

cookbook_file "screenrc" do
  path "#{homedir}/.screenrc"
  action :create
end

cookbook_file "emacs" do
  path "#{homedir}/.emacs"
  action :create
end
