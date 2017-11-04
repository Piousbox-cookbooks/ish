
#
# _vp_ 20171103
# let's install passenger
#

def puts! a, b=''
  puts "+++ +++ #{b}"
  puts a.inspect
end

#
# config
#
user = node.attributes['user']

=begin
file "/etc/nginx/nginx.conf" do
  action :delete
end
file "/etc/nginx/passenger.conf" do
  action :delete
end
=end

template "/etc/nginx/nginx.conf" do
  source "etc/nginx/nginx.conf.erb"
  variables(
    :user => user
  )
end

template "/etc/nginx/passenger.conf" do
  source "etc/nginx/passenger.conf.erb"
  variables()
end

execute "apt-get install -y --force-yes dirmngr gnupg"
execute "apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7"
execute "apt-get install -y apt-transport-https ca-certificates"
execute "sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'"
execute "apt-get update"
execute "apt-get install -y nginx-extras passenger"

template "/etc/nginx/nginx.conf" do
  source "etc/nginx/nginx.conf.erb"
  variables(
    :user => user
  )
end

template "/etc/nginx/passenger.conf" do
  source "etc/nginx/passenger.conf.erb"
  variables()
end

service "nginx" do
  supports :status => true, :restart => true
  action [ :enable, :start, :restart ]
end



