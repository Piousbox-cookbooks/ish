
#
# cookbook   ish 
# recipe     base_dev
#
# _vp_ 20151227
#

def puts! a, b=""
  puts "+++ +++ #{b}"
  puts a.inspect
end

user = node['user'] || 'oink'
homedir = 'root' == user ? '/root' : "/home/#{user}"

packages = %w{
 tree
 emacs
 imagemagick
 git
 screen
}

packages.each do |pkg|
  package pkg do
    action :install
  end
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
