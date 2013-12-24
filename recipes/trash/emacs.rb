
#
# ish recipe `emacs`
#

execute 'apt-get update -y' do
  command %{apt-get update -y}
end

packages = %w{ emacs23
}

packages.each do |pkg|
  package pkg do
    action :install
  end
end
