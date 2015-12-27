
#
# Ish recipe base_vm
#

def puts! args, label=""
  puts "+++ +++ #{label}"
  puts args.inspect
end

user = node['user'] || 'oink'
homedir = 'root' == user ? '/root' : "/home/#{user}"

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

puts! node['nagios']['server_role'], "nagios role on #{node} is"

