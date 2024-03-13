{{{ # Configure WordPress to connect to the MySQL database
DB_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-name -H "Metadata-Flavor: Google")
DB_USER=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-user -H "Metadata-Flavor: Google")
DB_PASSWORD=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-password -H "Metadata-Flavor: Google")
DOMAIN_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/domain-name -H "Metadata-Flavor: Google")
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo bash -c "sed -i \"s/database_name_here/$DB_NAME/g\" /var/www/html/wp-config.php"
sudo bash -c "sed -i \"s/username_here/$DB_USER/g\" /var/www/html/wp-config.php"
sudo bash -c "sed -i \"s/password_here/$DB_PASSWORD/g\" /var/www/html/wp-config.php"
sudo bash -c "echo \"define('WP_HOME','http://$DOMAIN_NAME');\" >> /var/www/html/wp-config.php"
sudo bash -c "echo \"define('WP_SITEURL','http://$DOMAIN_NAME');\" >> /var/www/html/wp-config.php"