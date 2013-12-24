
#
# cookbook ish
# recipe base
# author victor pudeyev <admin@piousbox.com>
# copyright 2013 Wasya.co
# GPLv2 license
#
# 
# descr: Provides the basics that are likely not resource-consuming and likely to be used on any node.
#        20131224
#

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{
 gcc g++ 
 build-essential libssl-dev zlib1g-dev 
 linux-headers-generic 
 libsqlite3-dev 
 libcurl4-openssl-dev 
 mysql-client libmysql-ruby libmysqlclient-dev mysql-server
 libxml2-dev libyaml-dev
 tree 
 libcurl4-openssl-dev libssl-dev gcc-4.4 libopenssl-ruby libxslt-dev 
 emacs23
 imagemagick
 mongodb 
 nodejs npm 
 apache2
 nmap
 libsasl2-2 libsasl2-dev libsasl2-modules
 memcached
 zip
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

rbenv_script "rbenv rehash" do
  code %{ rbenv rehash }
end
