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

user = node['user'] || 'ubuntu'
homedir = 'root' == user ? '/root' : "/home/#{user}"

packages = %w{
  emacs tree screen git
}
packages += node['packages']||[]
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
