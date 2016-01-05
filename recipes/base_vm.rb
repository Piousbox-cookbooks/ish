
#
# cookbook   ish
# recipe     base_vm
#
# _vp_ 20151227
#

user = node['user'] || 'oink'
homedir = 'root' == user ? '/root' : "/home/#{user}"

execute 'apt-get update -y'

packages = %w{
  ruby-dev
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

# puts! node['nagios']['server_role'], "nagios role on #{node} is"

