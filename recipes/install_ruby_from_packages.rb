
#
# ish::install_ruby_from_packages
# 20160113
#

execute "install ruby from packages" do
  only_if { %w{ debian ubuntu }.include? node.platform }
  command <<-EOL
apt-get install python-software-properties -y
apt-add-repository ppa:brightbox/ruby-ng
apt-get update -y
apt-get install ruby2.1 ruby2.1-dev ruby-switch -y
ruby-switch --set ruby2.1
EOL
end
