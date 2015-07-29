
#
# Ish recipe base
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
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end


bashrc_line = "source #{homedir}/.ishrc"
if File.read("#{homedir}/.bashrc").include? bashrc_line
  # do nothing
else
  execute "add .ishrc to .bashrc" do
    command %| echo "#{bashrc_line}" >> #{homedir}/.bashrc |
  end
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
