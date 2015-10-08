#
# Ish recipe base_aws
#

def puts! args, label=""
  puts "+++ +++ #{label}"
  puts args.inspect
end

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{
  emacs tree
}

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
