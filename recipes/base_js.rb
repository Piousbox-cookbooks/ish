
# ish base_php

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{ 
  npm
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

