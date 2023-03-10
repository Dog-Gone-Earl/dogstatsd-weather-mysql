Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "uwbbi/bionic-arm64"
  config.vm.provider "vmware_desktop" do |v|
    v.ssh_info_public = true
    v.gui = true
    v.linked_clone = false
    v.vmx["ethernet0.virtualdev"] = "vmxnet3"
    end 
  config.vm.synced_folder "./shared", "/home/vagrant/shared", create: true
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
  sudo apt-get update
  yes y | sudo apt-get upgrade
  DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=<api_key> DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"
  
  user=root
  database=weather_database
  
  echo -e "Installing pip and datadog"
  sleep 3
  sudo apt install python3-pip -y
  sudo pip3 install datadog
  
  echo -e "Mysql install"
  sleep 3
  sudo apt install mysql-server -y
  pip3 install mysql-connector-python-rf

  sudo mysql --user=$user --execute="CREATE DATABASE $database; USE $database; CREATE TABLE weather_table (temp INT(3), humidity INT(3), pressure INT(4)); "
  sudo mysql --user=$user --execute="CREATE USER 'weather_user'@'localhost' IDENTIFIED BY 'Datadog2023'; GRANT ALL ON *.* TO 'weather_user'@'localhost'; FLUSH PRIVILEGES;"
  sudo mysql --user=$user --execute="CREATE USER 'datadog'@'%' IDENTIFIED BY 'Datadog2023'; GRANT REPLICATION CLIENT ON *.* TO 'datadog'@'%' WITH MAX_USER_CONNECTIONS 5; GRANT PROCESS ON *.* TO datadog@'%';"
  sudo mysql --user=$user --execute="GRANT SELECT ON performance_schema.* TO datadog@'%'; CREATE SCHEMA IF NOT EXISTS datadog; GRANT EXECUTE ON datadog.* to datadog@'%'; GRANT CREATE TEMPORARY TABLES ON datadog.* TO datadog@'%';"
  sudo mysql --user=$user --execute="DELIMITER $$ CREATE PROCEDURE datadog.explain_statement(IN query TEXT) SQL SECURITY DEFINER BEGIN SET @explain := CONCAT('EXPLAIN FORMAT=json ', query);   PREPARE stmt FROM @explain; PREPARE stmt FROM @explain;  EXECUTE stmt; DEALLOCATE PREPARE stmt; END $$  DELIMITER ;"
  sudo mysql --user=$user --execute="DELIMITER $$ CREATE PROCEDURE datadog.enable_events_statements_consumers() SQL SECURITY DEFINER BEGIN UPDATE performance_schema.setup_consumers SET enabled='YES' WHERE name LIKE 'events_statements_%'; UPDATE performance_schema.setup_consumers SET enabled='YES' WHERE name = 'events_waits_current'; END $$ DELIMITER ; GRANT EXECUTE ON PROCEDURE datadog.enable_events_statements_consumers TO datadog@'%';"
  
  echo -e "Retrieving Python file"
  sleep 3
  curl -o weather.py https://raw.githubusercontent.com/Dog-Gone-Earl/dogstatsd-weather-mysql/main/dsd_weather.py

  echo "\n""\e[4mComponents Completed/Installed:\e[0m" "\nLinux Updates" "\nPip Install" "\nDatadog Python Module Install" "\nMysql Install" "\nMysql-connect Python Module Install" "\nCreate 'weather_database' Database in Mysql" "\nCreate 'weather_table' Table in 'weather_database' Database" "\nGrant permission to datadog user to host Database" "\nGrant permissions for Agent to Collect Mysql metrics/DBM" "\nCurl 'Weather App Python' File"
  SHELL
end
