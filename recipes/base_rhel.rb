
#
# cookbook   ish 
# recipe     base_rhel
#
# _vp_ 20151227
#      20170608
#

packages = %w{
 httpd
 tree
 emacs
 imagemagick
 git
 screen
 openssl-devel readline-devel zlib-devel
}

execute 'yum groupinstall "Development Tools" -y'

packages.each do |pkg|
  package pkg do
    action :install
  end
end

service "httpd" do
  action :start
end

bashrc_line = "source #{homedir}/.ishrc"
execute "add .ishrc to .bashrc" do
  command %| echo "#{bashrc_line}" >> #{homedir}/.bashrc |
  not_if { File.read("#{homedir}/.bashrc").include? bashrc_line }
end

cookbook_file "ishrc" do
  path "#{homedir}/.ishrc"
  action :create
end

cookbook_file "screenrc" do
  path "#{homedir}/.screenrc"
  action :create
end

cookbook_file "emacs" do
  path "#{homedir}/.emacs"
  action :create
end

