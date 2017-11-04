
require 'socket'

data_bag = data_bag_item 'utils', 'ish_hostnames'

# observe my IP
addr_infos = Socket.ip_address_list
data_bag['nodes'].each do |this_node|
  addr_infos.each do |addr_info|
    if addr_info.ip_address == this_node['ip']

      execute "Set hostname #{this_node['hostname']}" do
        command "hostname #{this_node['hostname']} && echo #{this_node['hostname']} > /etc/hostname"
      end

      # edit /etc/hosts file
      hosts_line = "127.0.0.1     #{this_node['hostname']}"
      if File.read("/etc/hosts").include?( hosts_line )
        # do nothing
      else
        cmd = %| echo "#{hosts_line}" >> /etc/hosts |
        puts! cmd
        ` #{cmd} `
      end

    end
  end
end
