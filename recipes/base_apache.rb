
#
# ish base
#

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{ 
 apache2 
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end

#rbenv_script "rbenv rehash" do
#  code %{ rbenv rehash }
#end
