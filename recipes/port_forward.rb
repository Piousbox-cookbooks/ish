
execute "sudo sysctl net.ipv4.ip_forward=1"
execute "sudo iptables --flush && sudo iptables --flush -t nat"
execute "sudo iptables -t nat -A POSTROUTING -j MASQUERADE"

this_ip = node['ipaddress']

this_data_bag = data_bag_item( 'utils', 'port_forward' )
this_data_bag['port_forwards'].each do |row|
  execute "sudo iptables -t nat -A PREROUTING -p tcp -d #{this_ip} -j DNAT --dport #{row['port']} --to #{row['forward']}:22"
end

execute "sudo service ufw restart"
