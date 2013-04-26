

# recipe for aws instance for x11 forwarding

script 'do it' do
  code <<-EIF
  export DISPLAY=10.99.2.157:0
  echo "ForwardX11 yes" >> /etc/ssh/ssh_config
  echo "ForwardX11Trusted yes" >> /etc/ssh/ssh_config

  sudo apt-get update
  sudo apt-get install xorg -y
  sudo apt-get install openbox obconf openbox-themes -y

  sudo chown ubuntu /home/ubuntu/.Xauthority -R
EIF

  # on older ubuntus, install:
  # x-window-system-core xserver-xorg xorg xterm -y
  
  # command is
  # startx
  
end
