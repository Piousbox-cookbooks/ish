

rbenv_script "test which ruby version" do
  code %{cd /home/ubuntu/projects/ish/current && echo "+++ +++" && rbenv version && ruby -v}
end