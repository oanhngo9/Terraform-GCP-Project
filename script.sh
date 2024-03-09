sudo setenforce 0

sudo yum install httpd -y 

sudo systemctl start httpd
sudo systemctl enable httpd

sudo  yum install unzip wget -y
sudo rm -rf /var/www/html/*
sudo wget https://wordpress.org/latest.zip
sudo unzip latest.zip
sudo mv wordpress/* /var/www/html/

sudo yum install epel-release yum-utils -y
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
sudo yum-config-manager --enable remi-php73
sudo yum install php php-mysql -y 
sudo systemctl restart httpd
sudo php --version

sudo chown -R apache:apache /var/www/html
sudo rm -f wp-config.php