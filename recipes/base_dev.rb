
#
# Ish recipe base
#

packages = %w{
 tree
 emacs23
 imagemagick
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

bashrc_line = "source ~/.ishrc"
if File.read("~/.bashrc").include? bashrc_line
  # do nothing
else
  execute "add .ishrc to .bashrc" do
    command %| echo "#{bashrc_line}" >> ~/.bashrc |
  end
end
cookbook_file "ishrc" do
  path "~/.ishrc"
  action :create
end

cookbook_file "screenrc" do
  path "~/.screenrc"
  action :create
end

cookbook_file "emacs" do
  path "~/.emacs"
  action :create
end
