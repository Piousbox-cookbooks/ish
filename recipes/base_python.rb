
# ish base_php

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

execute 'adding python 2.6' do
  command %{ sudo add-apt-repository ppa:fkrull/deadsnakes }
end

packages = %w{ 
  python-pip python-dev build-essential
  python2.6 python2.6-dev
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

execute 'virtualenv install' do
  command %{ sudo pip install virtualenv }
end

execute 'install django' do
  command %{ sudo pip install django }
end

# install nginx

# install passenger

