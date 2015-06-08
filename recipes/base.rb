
#
# Ish recipe base
#

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{
 tree
 emacs23
 imagemagick
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end
