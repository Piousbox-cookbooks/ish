
# ish base_lite

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{ gcc g++ 
 build-essential libssl-dev zlib1g-dev 
 linux-headers-generic 
 libcurl4-openssl-dev 
 libxml2-dev libyaml-dev
 tree 
 libcurl4-openssl-dev libssl-dev gcc-4.4 libxslt-dev 
 emacs23
 imagemagick
 nmap
 libsasl2-2 libsasl2-dev libsasl2-modules
 libcurl4-gnutls-dev libxml2 libxml2-dev libxslt1-dev
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

