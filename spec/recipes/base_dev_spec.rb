
require 'spec_helper'

describe 'ish::base_dev' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['user'] = ENV['USER']
    end.converge(described_recipe)
  end

  it 'installs packages' do
    %w{ tree emacs imagemagick git screen }.each do |pkg|
      expect(chef_run).to install_package(pkg)
    end
  end

  it 'adds ishrc to bashrc' do
    expect(chef_run).to run_execute "add .ishrc to .bashrc"
  end

  it 'creates config files ishrc, screenrc, emacs' do
    %w{ ishrc screenrc emacs }.each do |filename|
      expect(chef_run).to create_cookbook_file filename
    end
  end
  
end
