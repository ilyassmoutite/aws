#!/bin/bash
yum update -y
yum install epel-release -y
yum install httpd nano wget redis -y
systemctl start httpd
systemctl enable httpd
systemctl start redis
systemctl enable redis
echo "centos" | passwd --stdin centos
yum install -y vsftpd
systemctl enable vsftpd
systemctl start vsftpd
yum install -y php
cd /var/www/
wget https://www.dropbox.com/s/7opbj7tneqz3ppl/magento-1.9.3.7-2017-11-27-05-32-35.tar.gz
tar xzfv magento-1.9.3.7-2017-11-27-05-32-35.tar.gz
cp magento/* html
cp -r magento/* html
chmod -R 777 /var/www/html/

yum install php-soap php-mbstring php-gd php-xml php-mcrypt php-mysql -y
systemctl restart httpd
cd /var/www/html
IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

php -f install.php -- --license_agreement_accepted yes \
--locale en_US --timezone "America/Los_Angeles" --default_currency USD \
--db_host db.c29eujmse07q.eu-west-1.rds.amazonaws.com --db_name magento --db_user admin --db_pass ilyass123 \
--url "http://$IP/" --use_rewrites yes \
--skip_url_validation "yes" \
--use_rewrites "no" \
--use_secure no --secure_base_url "" --use_secure_admin no \
--admin_lastname Test --admin_firstname Webkul --admin_email "test@webkul.com" \
--admin_username admin --admin_password admin123
mount -t nfs4 $1:/ /var/www/html/skin
mount -t nfs4 $1:/ /var/www/html/media
cd /home/centos/aws
sed -i '/<session_save>/d' /var/www/html/app/etc/local.xml
sed -i '/<global>/ a\
 <session_save>db</session_save> \
	<redis_session> \
	<host>127.0.0.1</host> \
	<port>6379</port> \
	<password></password> \
	<timeout>10</timeout> \
	<persistent><![CDATA[db1]]></persistent> \
	<db>1</db> \
	<compression_threshold>2048</compression_threshold> \
	<compression_lib>lzf</compression_lib> \
	<log_level>1</log_level> \
	<max_concurrency>64</max_concurrency> \
	<break_after_frontend>5</break_after_frontend> \
	<break_after_adminhtml>30</break_after_adminhtml> \
	<first_lifetime>600</first_lifetime> \
	<bot_first_lifetime>60</bot_first_lifetime> \
	<bot_lifetime>7200</bot_lifetime> \
	<disable_locking>0</disable_locking> \
	<min_lifetime>86400</min_lifetime> \
	<max_lifetime>2592000</max_lifetime> \
    </redis_session> \
    <cache> \
        <backend>Cm_Cache_Backend_Redis</backend> \
        <backend_options> \
          <default_priority>10</default_priority> \
          <auto_refresh_fast_cache>1</auto_refresh_fast_cache> \
            <server>127.0.0.1</server> \
            <port>6379</port> \
            <persistent><![CDATA[db1]]></persistent> \
            <database>1</database> \
            <password></password> \
            <force_standalone>0</force_standalone> \
            <connect_retries>1</connect_retries> \
            <read_timeout>10</read_timeout> \
            <automatic_cleaning_factor>0</automatic_cleaning_factor> \
            <compress_data>1</compress_data> \
            <compress_tags>1</compress_tags> \
            <compress_threshold>204800</compress_threshold> \
            <compression_lib>lzf</compression_lib> \
        </backend_options> \
    </cache>' /var/www/html/app/etc/local.xml

    #sed -i "s/false/true/" /var/www/html/app/etc/modules/Cm_RedisSession.xml
#sed -i "s/127.0.0.1/$2/" /var/www/html/app/etc/local.xml
touch SUCCESS
echo "$1" >> SUCCESS
echo "$2" >> SUCCESS

touch SUCCESS
