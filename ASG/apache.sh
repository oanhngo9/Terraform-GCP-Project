#!/bin/bash
set -e  # Stop the script if any command fails
sudo apt-get update
sudo apt-get install -y apache2 unzip wget
sudo systemctl start apache2
sudo systemctl enable apache2
sudo rm -rf /var/www/html/*
cd /tmp
wget https://wordpress.org/latest.zip
unzip latest.zip
sudo mv wordpress/* /var/www/html/
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get install -y php7.3 php7.3-mysql
sudo systemctl restart apache2
php --version
sudo chown -R www-data:www-data /var/www/html
sudo rm -f /var/www/html/wp-config.php}}
