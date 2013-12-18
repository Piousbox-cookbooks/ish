
# ish:base_java

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{ gcc g++ 
 build-essential libssl-dev zlib1g-dev linux-headers-generic
 libcurl4-openssl-dev 
 libxml2-dev libyaml-dev
 libcurl4-openssl-dev libssl-dev gcc-4.4 libopenssl-ruby libxslt-dev 
 tomcat6 tomcat7 default-jdk
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end
