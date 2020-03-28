cd /home/centos
yum update -y
yum install httpd nano wget git nfs-utils -y
git clone https://github.com/ilyassmoutite/aws.git
cd aws
sh magento.sh $3
mount -t nfs4 $1:/ /var/www/html/skin
mount -t nfs4 $1:/ /var/www/html/media
cd /var/www/
rm -r html/*
cp -r magento/* html
chmod -R 777 /var/www/html/
cd /var/www/html/
IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
php -f install.php -- --license_agreement_accepted yes \
--locale en_US --timezone "America/Los_Angeles" --default_currency USD \
--db_host $3 --db_name magento --db_user admin --db_pass ilyass123 \
--url "http://$IP/" --use_rewrites yes \
--skip_url_validation "yes" \
--use_rewrites "no" \
--use_secure no --secure_base_url "" --use_secure_admin no \
--admin_lastname Test --admin_firstname Webkul --admin_email "test@webkul.com" \
--admin_username admin --admin_password admin11

cd /home/centos/aws
sh config.sh
sed -i "s/127.0.0.1/$2/" /var/www/html/app/etc/local.xml
touch SUCCESS
echo "$1" >> SUCCESS
echo "$2" >> SUCCESS
