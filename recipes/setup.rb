#
# Cookbook Name:: wp-cookbook
# Recipe:: setup
#
# Copyright 2013, Scott Walkinshaw
#
# All rights reserved - Do Not Redistribute
#

execute 'Composer install' do
  command "sudo -Hu #{node[:wp_cookbook][:user]} -i bash -c 'cd #{node[:wp_cookbook][:dir]} && composer install'"
end

execute 'wp_cookbook theme npm install' do
  command "sudo -Hu #{node[:wp_cookbook][:user]} -i bash -c 'cd #{node[:wp_cookbook][:dir]}/#{node[:wp_cookbook][:theme_dir]} && npm install'"
end

unless node[:wp_cookbook][:wp_import]
  execute 'wp_cookbook WP install' do
    user node[:wp_cookbook][:user]
    cwd node[:wp_cookbook][:dir]
    command "#{node[:wp_cookbook][:wp_cli]} core install --path=wp --url=http://#{node[:wp_cookbook][:hostname]}/wp --title=#{node[:wp_cookbook][:wp_title]} --admin_email=#{node[:wp_cookbook][:wp_admin_email]} --admin_password=#{node[:wp_cookbook][:wp_admin_pass]} --admin_name=#{node[:wp_cookbook][:wp_admin_user]}"
    action :run
    notifies :restart, 'service[nginx]', :immediately
    not_if "#{node[:wp_cookbook][:wp_cli]} core is-installed --path=wp --url=http://#{node[:wp_cookbook][:hostname]}/wp", :user => node[:wp_cookbook][:user], :cwd => node[:wp_cookbook][:dir]
  end
end

mysql_database node[:wp_cookbook][:db_name] do
  connection ({:host => 'localhost', :username => 'root', :password => node['mysql']['server_root_password']})
  sql { ::File.open("#{node[:wp_cookbook][:dir]}/#{node[:wp_cookbook][:wp_import_dump]}").read }
  action :query
  only_if { node[:wp_cookbook][:wp_import] }
end

grunt_cookbook_grunt "#{node[:wp_cookbook][:dir]}/#{node[:wp_cookbook][:theme_dir]}" do
  action :task
  task 'default'
end

