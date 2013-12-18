
# ish base_php

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{ 
  php5
  libapache2-mod-php5
  postfix
  mailutils
  mysql-client-core-5.5
  php5-mysql
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

