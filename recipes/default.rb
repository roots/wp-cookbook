#
# Cookbook Name:: wp-cookbook
# Recipe:: default
#
# Copyright 2013, Scott Walkinshaw
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'build-essential'
include_recipe 'apt'
include_recipe 'git'
include_recipe 'mysql::server'
include_recipe 'database::mysql'
include_recipe 'nginx'
include_recipe 'dotdeb'
include_recipe 'dotdeb::php54'
include_recipe 'php'

package 'php5-mysqlnd' do
  action :install
end

package 'php5-curl' do
  action :install
end

include_recipe 'php-fpm'
include_recipe 'nodejs::install_from_package'
include_recipe 'grunt_cookbook::install_grunt_cli'
include_recipe 'composer'

group 'deploy' do
  action :create
end

user 'deploy' do
  supports :manage_home => true
  gid      'deploy'
  shell    '/bin/bash'
  home     '/home/deploy'
  system   true
end

group 'www-data' do
  members node[:wp_cookbook][:user]
  append  true
  action  :modify
end

directory node[:wp_cookbook][:dir] do
  owner      node[:wp_cookbook][:user]
  group      'www-data'
  mode       00764
  recursive  true
end

mysql_database node[:wp_cookbook][:db_name] do
  connection ({:host => 'localhost', :username => 'root', :password => node['mysql']['server_root_password']})
  action [:drop, :create]
end

hostsfile_entry '127.0.0.1' do
  hostname node[:wp_cookbook][:hostname]
  action   :append
end

cron 'WP Cron' do
  minute  '*/5'
  command "curl http://#{node[:wp_cookbook][:hostname]}/wp/wp-cron.php"
end

nginx_site 'default' do
  enable false
end

wordpress_nginx_site node[:wp_cookbook][:hostname] do
  host node[:wp_cookbook][:hostname]
  root node[:wp_cookbook][:dir]
  notifies :reload, 'service[nginx]'
end

