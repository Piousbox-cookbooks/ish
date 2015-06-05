
require 'socket'

def puts! arg, label=''
  puts "+++ +++ #{label}"
  puts arg.inspect
end

data_bag = data_bag_item 'utils', 'ish_hostnames'

# observe my IP
addr_infos = Socket.ip_address_list
data_bag['nodes'].each do |this_node|
  addr_infos.each do |addr_info|
    if addr_info.ip_address == this_node['ip']
      execute "Set hostname #{this_node['hostname']}" do
        command "hostname #{this_node['hostname']} && echo #{this_node['hostname']} > /etc/hostname"
      end
    end
  end
end
