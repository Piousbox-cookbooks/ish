
# ish base

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{
 libsasl2-2 libsasl2-dev libsasl2-modules
 memcached
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

rbenv_script "rbenv rehash" do
  code %{ rbenv rehash }
end
