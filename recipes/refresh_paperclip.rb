



app = data_bag_item("apps", 'ish')
appname = app['id']
  

rbenv_script "refresh paperclip" do
  code %{cd /home/ubuntu/projects/#{appname}/current/ && bundle exec rake paperclip:refresh:missing_styles }
end
