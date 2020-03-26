#!/bin/bash
yum update -y
yum install epel-release -y
yum install httpd nano wget redis -y
systemctl start httpd
systemctl enable httpd
systemctl start redis
systemctl enable redis
yum install -y php
cd /var/www/html/
wget https://www.dropbox.com/s/7opbj7tneqz3ppl/magento-1.9.3.7-2017-11-27-05-32-35.tar.gz
tar xzfv magento-1.9.3.7-2017-11-27-05-32-35.tar.gz
cp magento/* .
cp -r magento/* .
chmod -R 777 /var/www/html/

yum install php-soap php-mbstring php-gd php-xml php-mcrypt php-mysql -y
systemctl restart httpd
cd /var/www/html
IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

php -f install.php -- --license_agreement_accepted yes \
--locale en_US --timezone "America/Los_Angeles" --default_currency USD \
--db_host magento2.c29eujmse07q.eu-west-1.rds.amazonaws.com --db_name magento --db_user admin --db_pass ilyass123 \
--url "http://$IP/" --use_rewrites yes \
--skip_url_validation "yes" \
--use_rewrites "no" \
--use_secure no --secure_base_url "" --use_secure_admin no \
--admin_lastname Test --admin_firstname Webkul --admin_email "test@webkul.com" \
--admin_username admin --admin_password admin123

touch SUCCESS
