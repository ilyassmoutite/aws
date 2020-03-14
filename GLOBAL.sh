#!/bin/bash
#====================================================================#
#        Automated Server Configuration for Magento 1+2              #
#        Copyright (C) 2017 admin@magenx.com                         #
#        All rights reserved.                                        #
#====================================================================#
SELF=$(basename $0)
MASCM_VER="20.8.1"
MASCM_BASE="https://masc.magenx.com"

### DEFINE LINKS AND PACKAGES STARTS ###

# Software versions
# Magento 1
MAGE_TMP_FILE="https://www.dropbox.com/s/7opbj7tneqz3ppl/magento-1.9.3.7-2017-11-27-05-32-35.tar.gz"
MAGE_FILE_MD5="42cfa3305ae1f7e7f0856681bd2edc3b"
MAGE_VER_1="1.9.3.7"

# Magento 2
MAGE_VER_2=$(curl -s https://api.github.com/repos/magento/magento2/tags 2>&1 | head -3 | grep -oP '(?<=")\d.*(?=")')
REPO_MAGE="composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"

REPO_MASCM_TMP="https://raw.githubusercontent.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/master/tmp/"

# HHVM package
HHVM_RPM="https://www.dropbox.com/s/e91b8vism8dor15/hhvm-3.22.0-1.x86_64.rpm"

# Webmin Control Panel plugins:
WEBMIN_NGINX="https://www.dropbox.com/s/pxzrcmixzr05yve/webmin-nginx-nginx-0.08.wbm__0.tar"
WEBMIN_FAIL2BAN="https://www.dropbox.com/s/elzby7qt7hx788m/fail2ban.wbm.gz"

# Repositories
REPO_PERCONA="https://www.dropbox.com/s/xeytgb2cr7583nr/percona-release-0.1-4.noarch.rpm"
REPO_REMI="https://www.dropbox.com/s/3lzctynjienfege/remi-release-7.rpm"


# WebStack Packages
EXTRA_PACKAGES=" autoconf automake dejavu-fonts-common dejavu-sans-fonts libtidy libpcap pygpgme gettext-devel cppunit recode boost boost-build boost-jam double-conversion fastlz fribidi gflags glog oniguruma tbb ed lz4 libyaml libdwarf bind-utils e2fsprogs svn screen gcc iptraf inotify-tools smartmontools net-tools mcrypt mlocate unzip vim wget curl sudo bc mailx clamav-filesystem clamav-server clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib clamav-scanner proftpd logrotate git patch ipset strace rsyslog gifsicle ncurses-devel GeoIP GeoIP-devel GeoIP-update openssl-devel ImageMagick libjpeg-turbo-utils pngcrush lsof net-snmp net-snmp-utils xinetd python-pip python-devel ncftp postfix certbot yum-cron yum-plugin-versionlock sysstat libuuid-devel uuid-devel attr iotop expect postgresql-libs unixODBC gcc-c++"
PHP_PACKAGES=(cli common git nano wget fpm opcache gd curl mbstring bcmath soap mcrypt mysqlnd pdo xml xmlrpc intl gmp php-gettext phpseclib recode symfony-class-loader symfony-common tcpdf tcpdf-dejavu-sans-fonts tidy udan11-sql-parser snappy lz4)
PHP_PECL_PACKAGES=(pecl-redis pecl-lzf pecl-geoip pecl-zip pecl-memcache pecl-oauth)
PERL_MODULES=(LWP-Protocol-https libwww-perl CPAN Template-Toolkit Time-HiRes ExtUtils-CBuilder ExtUtils-Embed ExtUtils-MakeMaker TermReadKey DBI DBD-MySQL Digest-HMAC Digest-SHA1 Test-Simple Moose Net-SSLeay devel)
SPHINX="https://www.dropbox.com/s/vm74pm6zsiv0mxu/sphinx-2.2.11-1.rhel7.x86_64.rpm"

# Nginx extra configuration
NGINX_VERSION=$(curl -s http://nginx.org/en/download.html | grep -oP '(?<=gz">nginx-).*?(?=</a>)' | head -1)
NGINX_BASE="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/"
NGINX_EXTRA_CONF="assets.conf error_page.conf extra_protect.conf export.conf status.conf setup.conf php_backend.conf maps.conf phpmyadmin.conf maintenance.conf"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"
MYSQL_TOP="https://www.dropbox.com/s/dm2y2csp86qpjhl/mytop_1.9.1.orig.tar.gz"

### DEFINE LINKS AND PACKAGES ENDS ###

# Simple colors
RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"

# Background
DGREYBG="\t\t\e[100m"
BLUEBG="\e[44m"
REDBG="\t\t\e[41m"

# Styles
BOLD="\e[1m"

# Reset
RESET="\e[0m"

# quick-n-dirty settings
function WHITETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${WHITE}${MESSAGE}${RESET}"
}
function BLUETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${BLUE}${MESSAGE}${RESET}"
}
function REDTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${RED}${MESSAGE}${RESET}"
}
function GREENTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${GREEN}${MESSAGE}${RESET}"
}
function YELLOWTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${YELLOW}${MESSAGE}${RESET}"
}
function BLUEBG() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}

function pause() {
   read -p "$*"
}

function start_progress {
  while true
  do
    echo -ne "#"
    sleep 1
  done
}

function quick_progress {
  while true
  do
    echo -ne "#"
    sleep 0.05
  done
}

function long_progress {
  while true
  do
    echo -ne "#"
    sleep 3
  done
}

function stop_progress {
kill $1
wait $1 2>/dev/null
echo -en "\n"
}

updown_menu () {
i=1;for items in $(echo $1); do item[$i]="${items}"; let i=$i+1; done
i=1
echo
echo -e "\n---> Use up/down arrow keys then press Enter to select $2"
while [ 0 ]; do
  if [ "$i" -eq 0 ]; then i=1; fi
  if [ ! "${item[$i]}" ]; then let i=i-1; fi
  echo -en "\r                                 "
  echo -en "\r${item[$i]}"
  read -sn 1 selector
  case "${selector}" in
    "B") let i=i+1;;
    "A") let i=i-1;;
    "") echo; read -sn 1 -p "To confirm [ ${item[$i]} ] press y or n for new selection" confirm
      if [[ "${confirm}" =~ ^[Yy]$  ]]; then
        printf -v "$2" '%s' "${item[$i]}"
        break
      else
        echo
        echo -e "\n---> Use up/down arrow keys then press Enter to select $2"
      fi
      ;;
  esac
done }


clear
###################################################################################
#                                     START CHECKS                                #
###################################################################################
echo
echo
 

# network is up?
host1=209.85.202.91
host2=151.101.193.69
RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo
  REDTXT "ERROR: NETWORK IS DOWN?"
  YELLOWTXT "------> PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi
        MD5_NEW=$(curl -sL ${MASCM_BASE} > MASCM_NEW && md5sum MASCM_NEW | awk '{print $1}')
        MD5_OLD=$(md5sum ${SELF} | awk '{print $1}')
            if [[ "${MD5_NEW}" == "${MD5_OLD}" ]]; then
            GREENTXT "PASS: INTEGRITY CHECK FOR '${SELF}' OK"
            rm MASCM_NEW
            elif [[ "${MD5_NEW}" != "${MD5_OLD}" ]]; then
            echo
            YELLOWTXT "INTEGRITY CHECK FOR '${SELF}'"
            YELLOWTXT "DETECTED DIFFERENT MD5 CHECKSUM"
            YELLOWTXT "REMOTE REPOSITORY FILE HAS SOME CHANGES"
            REDTXT "IF YOU HAVE LOCAL CHANGES - SKIP UPDATES"
            echo
                echo -n "---> Would you like to update the file now?  [y/n][y]:"
update_agree="n"
		if [ "${update_agree}" == "y" ];then
		mv MASCM_NEW ${SELF}
		echo
                GREENTXT "THE FILE HAS BEEN UPGRADED, PLEASE RUN IT AGAIN"
		echo
                exit 1
            else
        echo
        YELLOWTXT "NEW FILE SAVED TO MASCM_NEW"
        echo
  fi
fi



# check if x64. if not, beat it...
ARCH=$(uname -m)
if [ "${ARCH}" = "x86_64" ]; then
  GREENTXT "PASS: 64-BIT"
  else
  echo
  REDTXT "ERROR: 32-BIT SYSTEM?"
  YELLOWTXT "------> CONFIGURATION FOR 64-BIT ONLY."
  echo
  exit 1
fi



# some selinux, sir?
if [ -f "/etc/selinux/config" ]; then
SELINUX=$(sestatus | awk '{print $3}')
if [ "${SELINUX}" != "disabled" ]; then
  echo
  REDTXT "ERROR: SELINUX IS NOT DISABLED"
  YELLOWTXT "------> PLEASE CHECK YOUR SELINUX SETTINGS"
  echo
  exit 1
  else
  GREENTXT "PASS: SELINUX IS DISABLED"
fi
fi
echo
if grep -q "yes" /root/mascm/.systest >/dev/null 2>&1 ; then
  BLUETXT "the systems test has been made already"
  else
echo "-------------------------------------------------------------------------------------"
BLUEBG "| QUICK SYSTEM TEST |"
echo "-------------------------------------------------------------------------------------"
echo
    yum -y install epel-release > /dev/null 2>&1
    yum -y install time bzip2 tar > /dev/null 2>&1

    test_file=vpsbench__$$
    tar_file=tarfile
    now=$(date +"%m/%d/%Y")

    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
    tram=$( free -m | awk 'NR==2 {print $2}' )

    echo

    echo -n "     PROCESSING I/O PERFORMANCE "
    start_progress &
    pid="$!"
    io=$( ( dd if=/dev/zero of=$test_file bs=64k count=16k conv=fdatasync && rm -f $test_file ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
    stop_progress "$pid"

    echo -n "     PROCESSING CPU PERFORMANCE "
    dd if=/dev/urandom of=$tar_file bs=1024 count=25000 >>/dev/null 2>&1
    start_progress &
    pid="$!"
    tf=$( (/usr/bin/time -f "%es" tar cfj $tar_file.bz2 $tar_file) 2>&1 )
    stop_progress "$pid"
    rm -f tarfile*
    echo
    echo

    if [ ${io% *} -ge 250 ] ; then
        IO_COLOR="${GREEN}$io - excellent result"
    elif [ ${io% *} -ge 200 ] ; then
        IO_COLOR="${YELLOW}$io - average result"
    else
        IO_COLOR="${RED}$io - very bad result"
    fi

    if [ ${tf%.*} -ge 10 ] ; then
        CPU_COLOR="${RED}$tf - very bad result"
    elif [ ${tf%.*} -ge 5 ] ; then
        CPU_COLOR="${YELLOW}$tf - average result"
    else
        CPU_COLOR="${GREEN}$tf - excellent result"
    fi

  WHITETXT "${BOLD}SYSTEM DETAILS"
  WHITETXT "CPU model: $cname"
  WHITETXT "Number of cores: $cores"
  WHITETXT "CPU frequency: $freq MHz"
  WHITETXT "Total amount of RAM: $tram MB"
  echo
  WHITETXT "${BOLD}BENCHMARK RESULTS"
  WHITETXT "I/O speed: ${IO_COLOR}"
  WHITETXT "CPU Time: ${CPU_COLOR}"

echo
mkdir -p /root/mascm/ && echo "yes" > /root/mascm/.systest
echo

echo
fi
echo
if grep -q "yes" /root/mascm/.sshport >/dev/null 2>&1 ; then
BLUETXT "ssh port has been changed already"
else
if grep -q "Port 22" /etc/ssh/sshd_config >/dev/null 2>&1 ; then
REDTXT "DEFAULT SSH PORT :22 DETECTED"
echo
      sed -i "s/.*LoginGraceTime.*/LoginGraceTime 30/" /etc/ssh/sshd_config
      sed -i "s/.*MaxAuthTries.*/MaxAuthTries 6/" /etc/ssh/sshd_config
      sed -i "s/.*X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
      sed -i "s/.*PrintLastLog.*/PrintLastLog yes/" /etc/ssh/sshd_config
      sed -i "s/.*TCPKeepAlive.*/TCPKeepAlive yes/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveInterval.*/ClientAliveInterval 600/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveCountMax.*/ClientAliveCountMax 3/" /etc/ssh/sshd_config
      sed -i "s/.*UseDNS.*/UseDNS no/" /etc/ssh/sshd_config

echo -n "---> Lets change the default ssh port now? [y/n][n]:"
 new_ssh_set="n"
if [ "${new_ssh_set}" == "y" ];then
   echo
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BACK
      SSHPORT=$(shuf -i 9537-9554 -n 1)
      read -e -p "---> Enter a new ssh port : " -i "${SSHPORT}" NEW_SSH_PORT
      sed -i "s/.*Port 22/Port ${NEW_SSH_PORT}/g" /etc/ssh/sshd_config
     echo
        GREENTXT "SSH PORT AND SETTINGS HAS BEEN UPDATED  -  OK"
        systemctl restart sshd.service
        ss -tlp | grep sshd
     echo
echo
REDTXT "!IMPORTANT: NOW OPEN A NEW SSH SESSION WITH THE NEW PORT!"
REDTXT "!IMPORTANT: DO NOT CLOSE THE CURRENT SESSION!"
echo
echo -n "------> Have you logged in another session? [y/n][n]:"
 new_ssh_test="n"
if [ "${new_ssh_test}" == "y" ];then
      echo
        GREENTXT "REMEMBER THE NEW SSH PORT NOW: ${NEW_SSH_PORT}"
        echo "yes" > /root/mascm/.sshport
        else
	echo
        mv /etc/ssh/sshd_config.BACK /etc/ssh/sshd_config
        REDTXT "RESTORING sshd_config FILE BACK TO DEFAULTS ${GREEN} [ok]"
        systemctl restart sshd.service
        echo
        GREENTXT "SSH PORT HAS BEEN RESTORED  -  OK"
        ss -tlp | grep sshd
fi
fi
fi
fi
echo
echo
###################################################################################
#                                     CHECKS END                                  #
###################################################################################
echo
if grep -q "yes" /root/mascm/.terms >/dev/null 2>&1 ; then
  echo ""
  else
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
  YELLOWTXT "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
  YELLOWTXT "YOU ACKNOWLEDGE AND AGREE:"
  echo
  YELLOWTXT "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
  YELLOWTXT "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
  echo
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
   echo
    echo -n "---> Do you agree to these terms?  [y/n][y]:"
     terms_agree="y"
  if [ "${terms_agree}" == "y" ];then
    echo "yes" > /root/mascm/.terms
          else
        REDTXT "Going out. EXIT"
        echo
    exit 1
  fi
fi
###################################################################################
#                                  HEADER MENU START                              #
###################################################################################


echo
echo
if grep -q "yes" /root/mascm/.sysupdate >/dev/null 2>&1 ; then
echo
else
## install all extra packages
GREENTXT "SYSTEM PACKAGES INSTALLATION. PLEASE WAIT"
yum -q -y upgrade >/dev/null 2>&1
yum -q -y install https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/yum-plugin-replace-0.2.7-1.ius.centos7.noarch.rpm >/dev/null 2>&1
yum -q -y install ${REPO_FAN} >/dev/null 2>&1

yum install -y yum-utils >/dev/null 2>&1
yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm


yum -q -y install ${EXTRA_PACKAGES} ${PERL_MODULES[@]/#/perl-} >/dev/null 2>&1
echo
echo "yes" > /root/mascm/.sysupdate
echo
fi
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| START THE INSTALLATION OF REPOSITORIES AND PACKAGES |"
echo "-------------------------------------------------------------------------------------"
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Percona repository and Percona database installation? [y/n][n]:"
 repo_percona_install="n"
if [ "${repo_percona_install}" == "y" ];then
          echo
            read -e -p "---> Select Percona database version to install 56 or 57: " -i "56"  PERCONA_VER
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U ${REPO_PERCONA} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q percona-release
      if [ "$?" = 0 ] # if repository installed then install package
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
              echo
              echo
              GREENTXT "Installation of Percona ${PERCONA_VER} database:"
              echo
              echo -n "     PROCESSING  "
              long_progress &
              pid="$!"
              yum -y -q install Percona-Server-server-${PERCONA_VER} Percona-Server-client-${PERCONA_VER} >/dev/null 2>&1
              stop_progress "$pid"
              rpm  --quiet -q Percona-Server-server-${PERCONA_VER} Percona-Server-client-${PERCONA_VER}
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              GREENTXT "DATABASE HAS BEEN INSTALLED  -  OK"
              echo
              ## plug in service status alert
              cp /usr/lib/systemd/system/mysqld.service /etc/systemd/system/mysqld.service
              sed -i "s/^Restart=always/Restart=on-failure/" /etc/systemd/system/mysqld.service
              sed -i "/^After=syslog.target.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/mysqld.service
              sed -i "/Restart=on-failure/a RestartSec=10" /etc/systemd/system/mysqld.service
              systemctl daemon-reload
              systemctl enable mysqld >/dev/null 2>&1
              echo
              WHITETXT "Downloading my.cnf file from MagenX Github repository"
              wget -qO /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
              echo
                echo
                 WHITETXT "We need to correct your innodb_buffer_pool_size"
                 rpm -qa | grep -qw bc || yum -q -y install bc >/dev/null 2>&1
                 IBPS=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
                 sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf
                 sed -i "s/innodb_buffer_pool_instances = 4/innodb_buffer_pool_instances = ${IBPS}/" /etc/my.cnf
                 echo
                 YELLOWTXT "innodb_buffer_pool_size = ${IBPS}G"
                 YELLOWTXT "innodb_buffer_pool_instances = ${IBPS}"
                echo
              echo
              ## get mysql tools
              cd /usr/local/src
              wget -qO - ${MYSQL_TOP} | tar -xzp && cd mytop*
              perl Makefile.PL && make && make install  >/dev/null 2>&1
              yum -y -q install percona-toolkit >/dev/null 2>&1
              echo
              echo
	      echo ${PERCONA_VER} > /root/mascm/.percona
              else
              echo
              REDTXT "DATABASE INSTALLATION ERROR"
          exit # if package is not installed then exit
        fi
          else
            echo
              REDTXT "REPOSITORY INSTALLATION ERROR"
        exit # if repository is not installed then exit
      fi
        else
              echo
            YELLOWTXT "Percona repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start nginx ${NGINX_VERSION} installation? [y/n][n]:"
 repo_nginx_install="y"
if [ "${repo_nginx_install}" == "y" ];then
          echo
            WHITETXT "Downloading Nginx GPG key"
            wget -qO /etc/pki/rpm-gpg/nginx_signing.key  http://nginx.org/packages/keys/nginx_signing.key
            echo
            echo
cat > /etc/yum.repos.d/nginx.repo <<END
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/x86_64/
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/nginx_signing.key
gpgcheck=1
END
            echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of nginx package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install nginx nginx-module-geoip nginx-module-perl >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q nginx
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "NGINX HAS BEEN INSTALLED  -  OK"
            echo
            ## plug in service status alert
            cp /usr/lib/systemd/system/nginx.service /etc/systemd/system/nginx.service
            sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/nginx.service
            sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/nginx.service
            sed -i "s,PIDFile=/run/nginx.pid,PIDFile=/var/run/nginx.pid," /etc/systemd/system/nginx.service
            sed -i "s/PrivateTmp=true/PrivateTmp=false/" /etc/systemd/system/nginx.service
            systemctl daemon-reload
            systemctl enable nginx >/dev/null 2>&1
              else
             echo
            REDTXT "NGINX INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "Nginx repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start the Remi repository and PHP 7.0 installation? [y/n][n]:"
 repo_remi_install="y"
if [ "${repo_remi_install}" == "y" ];then
          echo
            GREENTXT "Installation of Remi repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U ${REPO_REMI} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q remi-release
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of PHP 7.0:"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum --enablerepo=remi,remi-php70 -y -q install php ${PHP_PACKAGES[@]/#/php-} ${PHP_PECL_PACKAGES[@]/#/php-} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q php
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "PHP HAS BEEN INSTALLED  -  OK"
             ## plug in service status alert
             cp /usr/lib/systemd/system/php-fpm.service /etc/systemd/system/php-fpm.service
             sed -i "s/PrivateTmp=true/PrivateTmp=false/" /etc/systemd/system/php-fpm.service
             sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/php-fpm.service
             sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/php-fpm.service
             systemctl daemon-reload
             systemctl enable php-fpm >/dev/null 2>&1
             systemctl disable httpd >/dev/null 2>&1
             yum list installed | awk '/php.*x86_64/ {print "      ",$1}'
                else
               echo
             REDTXT "PHP INSTALLATION ERROR"
         exit
       fi
         echo
           echo
            GREENTXT "Installation of Redis, Memcached and Sphinx packages:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum --enablerepo=remi -y -q install redis memcached ${SPHINX} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q redis
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "REDIS HAS BEEN INSTALLED"
             systemctl disable redis >/dev/null 2>&1
             echo
cat > /etc/systemd/system/redis@.service <<END
[Unit]
Description=Redis %i
After=network.target
OnFailure=service-status-mail@%n.service
PartOf=redis.target

[Service]
Type=simple
User=redis
Group=redis
PrivateTmp=true
PIDFile=/var/run/redis-%i.pid
ExecStart=/usr/bin/redis-server /etc/redis-%i.conf

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target redis.target
END

cat > /etc/systemd/system/redis.target <<END
[Unit]
Description=Redis start/stop all redis@.service instances
END

for REDISPORT in 6379 6380
do
mkdir -p /var/lib/redis-${REDISPORT}
chmod 755 /var/lib/redis-${REDISPORT}
chown redis /var/lib/redis-${REDISPORT}
cp -rf /etc/redis.conf /etc/redis-${REDISPORT}.conf
chmod 644 /etc/redis-${REDISPORT}.conf
sed -i "s/^bind 127.0.0.1.*/bind 127.0.0.1/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^dir.*/dir \/var\/lib\/redis-${REDISPORT}\//"  /etc/redis-${REDISPORT}.conf
sed -i "s/^logfile.*/logfile \/var\/log\/redis\/redis-${REDISPORT}.log/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^pidfile.*/pidfile \/var\/run\/redis-${REDISPORT}.pid/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^port.*/port ${REDISPORT}/" /etc/redis-${REDISPORT}.conf
sed -i "s/dump.rdb/dump-${REDISPORT}.rdb/" /etc/redis-${REDISPORT}.conf
done
echo
cat > /etc/sysconfig/memcached <<END
PORT="11211"
USER="memcached"
MAXCONN="5024"
CACHESIZE="128"
OPTIONS="-l 127.0.0.1"
END
## plug in service status alert
cp /usr/lib/systemd/system/memcached.service /etc/systemd/system/memcached.service
cp /usr/lib/systemd/system/searchd.service /etc/systemd/system/searchd.service
sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/memcached.service
sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/memcached.service
sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/searchd.service
sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/searchd.service
systemctl daemon-reload
systemctl enable redis@6379 >/dev/null 2>&1
systemctl enable redis@6380 >/dev/null 2>&1
systemctl enable memcached  >/dev/null 2>&1
                else
               echo
             REDTXT "PACKAGES INSTALLATION ERROR"
         exit
       fi
         else
           echo
             REDTXT "REPOSITORY INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "The Remi repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Varnish cache installation? [y/n][n]:"
 varnish_install="n"
if [ "${varnish_install}" == "y" ];then
          echo
            read -e -p "---> Select Varnish cache version to install 41 or 52: " -i "52"  VARNISH_VER
            echo
cat >> /etc/yum.repos.d/varnishcache_varnish${VARNISH_VER}.repo <<END
[varnishcache_varnish${VARNISH_VER}]
name=varnishcache_varnish${VARNISH_VER}
baseurl=https://packagecloud.io/varnishcache/varnish${VARNISH_VER}/el/7/x86_64
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/varnishcache/varnish${VARNISH_VER}/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[varnishcache_varnish${VARNISH_VER}-source]
name=varnishcache_varnish${VARNISH_VER}-source
baseurl=https://packagecloud.io/varnishcache/varnish${VARNISH_VER}/el/7/SRPMS
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/varnishcache/varnish${VARNISH_VER}/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
END
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install varnish >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q varnish
      if [ "$?" = 0 ]
        then
          echo
	    wget -qO /etc/systemd/system/varnish.service ${REPO_MASCM_TMP}varnish.service
            wget -qO /etc/varnish/varnish.params ${REPO_MASCM_TMP}varnish.params
            systemctl daemon-reload >/dev/null 2>&1
            GREENTXT "VARNISH ${VARNISH_VER} HAS BEEN INSTALLED  -  OK"
               else
              echo
            REDTXT "VARNISH INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "Varnish installation was skipped by the user. Next step"
fi
echo
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start HHVM installation? [y/n][n]:"
hhvm_install="n"
if [ "${hhvm_install}" == "y" ];then
echo
            GREENTXT "Installation of HHVM package:"
            echo
	    cd /usr/local/src/
	    wget -q ${HHVM_RPM} >/dev/null 2>&1
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install ${HHVM_RPM##*/} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q hhvm
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "HHVM HAS BEEN INSTALLED  -  OK"
            echo
            ## plug in service status alert
            cp /usr/lib/systemd/system/hhvm.service /etc/systemd/system/hhvm.service
            sed -i "/^Description=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/hhvm.service
            sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/hhvm.service
	    sed -i "s,/usr/bin/hhvm,/usr/bin/hhvm --config /etc/hhvm/server.ini," /etc/systemd/system/hhvm.service
            systemctl daemon-reload
            systemctl enable hhvm >/dev/null 2>&1
               else
              echo
            REDTXT "HHVM INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "HHVM installation was skipped by the user. Next step"
fi
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| THE INSTALLATION OF REPOSITORIES AND PACKAGES IS COMPLETE |"
echo "-------------------------------------------------------------------------------------"
echo
echo
GREENTXT "NOW WE ARE GOING TO CONFIGURE EVERYTHING"
echo


echo
echo "Load optimized configs of php, opcache, fpm, fastcgi, sysctl, varnish"
WHITETXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
cat > /etc/sysctl.conf <<END
fs.file-max = 1000000
fs.inotify.max_user_watches = 1000000
vm.swappiness = 10
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65535
kernel.msgmax = 65535
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65535 8388608
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_challenge_ack_limit = 1073741823
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 400000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_sack = 1
net.ipv4.route.flush = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535
END

sysctl -q -p
echo
WHITETXT "sysctl.conf loaded ${GREEN} [ok]"
cat > /etc/php.d/10-opcache.ini <<END
zend_extension=opcache.so
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 4
opcache.max_accelerated_files = 50000
opcache.max_wasted_percentage = 5
opcache.use_cwd = 1
opcache.validate_timestamps = 0
;opcache.revalidate_freq = 2
;opcache.validate_permission=1
;opcache.validate_root=1
opcache.file_update_protection = 2
opcache.revalidate_path = 0
opcache.save_comments = 1
opcache.load_comments = 1
opcache.fast_shutdown = 1
opcache.enable_file_override = 0
opcache.optimization_level = 0xffffffff
opcache.inherited_hack = 1
opcache.blacklist_filename=/etc/php.d/opcache-default.blacklist
opcache.max_file_size = 0
opcache.consistency_checks = 0
opcache.force_restart_timeout = 60
opcache.error_log = "/var/log/php-fpm/opcache.log"
opcache.log_verbosity_level = 1
opcache.preferred_memory_model = ""
opcache.protect_memory = 0
;opcache.mmap_base = ""
END

WHITETXT "opcache.ini loaded ${GREEN} [ok]"
#Tweak php.ini.
cp /etc/php.ini /etc/php.ini.BACK
sed -i 's/^\(max_execution_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(max_input_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(memory_limit = \)[0-9]*M/\11024M/' /etc/php.ini
sed -i 's/^\(post_max_size = \)[0-9]*M/\164M/' /etc/php.ini
sed -i 's/^\(upload_max_filesize = \)[0-9]*M/\164M/' /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/;realpath_cache_size = 16k/realpath_cache_size = 512k/' /etc/php.ini
sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 86400/' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/; max_input_vars = 1000/max_input_vars = 50000/' /etc/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 28800/' /etc/php.ini
sed -i 's/mysql.allow_persistent = On/mysql.allow_persistent = Off/' /etc/php.ini
sed -i 's/mysqli.allow_persistent = On/mysqli.allow_persistent = Off/' /etc/php.ini
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php-fpm.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 10000/' /etc/php-fpm.d/www.conf
sed -i 's/pm.max_children = 50/pm.max_children = 1000/' /etc/php-fpm.d/www.conf

WHITETXT "php.ini loaded ${GREEN} [ok]"
echo
echo "*         soft    nofile          700000" >> /etc/security/limits.conf
echo "*         hard    nofile          1000000" >> /etc/security/limits.conf
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| FINISHED PACKAGES INSTALLATION |"
echo "-------------------------------------------------------------------------------------"
echo
echo

###################################################################################
#                                MAGENTO                                          #
###################################################################################
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "|   SELECT TO DOWNLOAD MAGENTO 1 (${MAGE_VER_1}) OR 2 (${MAGE_VER_2})  |"
echo "-------------------------------------------------------------------------------------"
echo
echo
     MAGE_SEL_VER="1"
	 MAGE_VER=MAGE_VER_${MAGE_SEL_VER}
	 echo
       MAGE_DOMAIN=$(ifconfig eth0 | grep "inet " | awk -F" " '{print $2}')
       MAGE_WEB_USER="myshop"
     MAGE_WEB_ROOT_PATH="/home/${MAGE_WEB_USER}/public_html"
     echo
	 echo "---> MAGENTO ${MAGE_SEL_VER} (${!MAGE_VER})"
	 echo "---> WILL BE DOWNLOADED TO ${MAGE_WEB_ROOT_PATH}"
     echo
        mkdir -p ${MAGE_WEB_ROOT_PATH} && cd $_
        useradd -d ${MAGE_WEB_ROOT_PATH%/*} -s /sbin/nologin ${MAGE_WEB_USER}  >/dev/null 2>&1
        MAGE_WEB_USER_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 15 | head -n 1)
        echo "${MAGE_WEB_USER}:${MAGE_WEB_USER_PASS}"  | chpasswd  >/dev/null 2>&1
        chmod 711 /home/${MAGE_WEB_USER}
        chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH%/*}
        chmod 2770 ${MAGE_WEB_ROOT_PATH}
        setfacl -Rdm u:${MAGE_WEB_USER}:rwx,g:${MAGE_WEB_USER}:rwx,g::rw-,o::- ${MAGE_WEB_ROOT_PATH}
        echo
		if [ "${MAGE_SEL_VER}" = "1" ]; then
			echo -n "      DOWNLOADING MAGENTO"
			long_progress &
			pid="$!"
			su ${MAGE_WEB_USER} -s /bin/bash -c "wget -qO - ${MAGE_TMP_FILE} | tar -xzp --strip-components 1"
			stop_progress "$pid"
        else
			curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1
			mv composer.phar /usr/local/bin/composer
			[ -f "/usr/local/bin/composer" ] || { echo "---> COMPOSER INSTALLATION ERROR" ; exit 1 ;}
			su ${MAGE_WEB_USER} -s /bin/bash -c "${REPO_MAGE} ."
		fi
        echo
     echo
WHITETXT "============================================================================="
GREENTXT "      == MAGENTO DOWNLOADED AND READY FOR INSTALLATION =="
WHITETXT "============================================================================="
mkdir -p /root/mascm/
if [ -f /root/mascm/.mascm_index ]; then
sed -i "s,webshop.*,webshop ${MAGE_DOMAIN}    ${MAGE_WEB_ROOT_PATH}    ${MAGE_WEB_USER}   ${MAGE_WEB_USER_PASS}  ${MAGE_SEL_VER}  ${!MAGE_VER}," /root/mascm/.mascm_index
else
cat >> /root/mascm/.mascm_index <<END
webshop ${MAGE_DOMAIN}    ${MAGE_WEB_ROOT_PATH}    ${MAGE_WEB_USER}   ${MAGE_WEB_USER_PASS}  ${MAGE_SEL_VER}  ${!MAGE_VER}
END
fi
echo
###################################################################################
#                                MAGENTO DATABASE SETUP                           #
###################################################################################

###################################################################################
#                                MAGENTO INSTALLATION                             #
###################################################################################
MAGE_SEL_VER=$(awk '/webshop/ { print $6 }' /root/mascm/.mascm_index)
MAGE_VER=$(awk '/webshop/ { print $7 }' /root/mascm/.mascm_index)
echo "-------------------------------------------------------------------------------------"
BLUEBG   "|  MAGENTO ${MAGE_SEL_VER} (${MAGE_VER}) INSTALLATION  |"
echo "-------------------------------------------------------------------------------------"
echo
MAGE_WEB_ROOT_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
MAGE_WEB_USER=$(awk '/webshop/ { print $4 }' /root/mascm/.mascm_index)
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
DB_HOST=$(awk '/database/ { print $2 }' /root/mascm/.mascm_index)
DB_NAME=$(awk '/database/ { print $3 }' /root/mascm/.mascm_index)
DB_USER_NAME=$(awk '/database/ { print $4 }' /root/mascm/.mascm_index)
DB_PASS=$(awk '/database/ { print $5 }' /root/mascm/.mascm_index)

cd ${MAGE_WEB_ROOT_PATH}
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH}
echo
echo "---> ENTER SETUP INFORMATION"
echo
WHITETXT "Database information"
  MAGE_DB_NAME="magento"
  MAGE_DB_HOST="magento2.c29eujmse07q.eu-west-1.rds.amazonaws.com"

   MAGE_DB_USER_NAME="admin"
  MAGE_DB_PASS="ilyass123"
echo
WHITETXT "Administrator and domain"
  MAGE_ADMIN_FNAME="ilyass"
   MAGE_ADMIN_LNAME="moutite"
  MAGE_ADMIN_EMAIL="ilyass@gmail.com"
 MAGE_ADMIN_LOGIN="admin"
  MAGE_ADMIN_PASS="admin11"
  MAGE_SITE_URL="http://${MAGE_DOMAIN}/"
echo
WHITETXT "Language, Currency and Timezone settings"
if [ "${MAGE_SEL_VER}" = "1" ]; then

echo
echo
chmod u+x mage
su ${MAGE_WEB_USER} -s /bin/bash -c "./mage mage-setup ."
su ${MAGE_WEB_USER} -s /bin/bash -c "php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "en_US" \
--timezone "America/Los_Angeles" \
--default_currency "USD" \
--db_host "${MAGE_DB_HOST}" \
--db_name "${MAGE_DB_NAME}" \
--db_user "${MAGE_DB_USER_NAME}" \
--db_pass '${MAGE_DB_PASS}' \
--url "${MAGE_SITE_URL}" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--skip_url_validation "yes" \
--use_secure_admin "no" \
--admin_frontname "admin" \
--admin_firstname "${MAGE_ADMIN_FNAME}" \
--admin_lastname "${MAGE_ADMIN_LNAME}" \
--admin_email "${MAGE_ADMIN_EMAIL}" \
--admin_username "${MAGE_ADMIN_LOGIN}" \
--admin_password '${MAGE_ADMIN_PASS}'"
echo
	else
chmod u+x bin/magento
updown_menu "$(bin/magento info:language:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_LOCALE
updown_menu "$(bin/magento info:currency:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_CURRENCY
updown_menu "$(bin/magento info:timezone:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_TIMEZONE
echo
echo
GREENTXT "SETUP MAGENTO ${MAGE_SEL_VER} (${MAGE_VER}) WITHOUT SAMPLE DATA"
echo

echo
su ${MAGE_WEB_USER} -s /bin/bash -c "bin/magento setup:install --base-url=${MAGE_SITE_URL} \
--db-host=${MAGE_DB_HOST} \
--db-name=${MAGE_DB_NAME} \
--db-user=${MAGE_DB_USER_NAME} \
--db-password='${MAGE_DB_PASS}' \
--admin-firstname=${MAGE_ADMIN_FNAME} \
--admin-lastname=${MAGE_ADMIN_LNAME} \
--admin-email=${MAGE_ADMIN_EMAIL} \
--admin-user=${MAGE_ADMIN_LOGIN} \
--admin-password='${MAGE_ADMIN_PASS}' \
--language=${MAGE_LOCALE} \
--currency=${MAGE_CURRENCY} \
--timezone=${MAGE_TIMEZONE} \
--cleanup-database \
--session-save=files \
--use-rewrites=1"

mysqldump --single-transaction --routines --triggers --events ${MAGE_DB_NAME} | gzip > /root/${MAGE_DB_NAME}.sql.gz
fi
echo
    WHITETXT "============================================================================="
    echo
    GREENTXT "INSTALLED MAGENTO ${MAGE_SEL_VER} (${MAGE_VER}) WITHOUT SAMPLE DATA"
    echo
    WHITETXT "============================================================================="
echo
cat >> /root/mascm/.mascm_index <<END
mageadmin  ${MAGE_ADMIN_LOGIN}  ${MAGE_ADMIN_PASS}  ${MAGE_ADMIN_EMAIL}  ${MAGE_TIMEZONE}  ${MAGE_LOCALE} ${MAGE_ADMIN_PATH_RANDOM}
END
###################################################################################
#                                SYSTEM CONFIGURATION                             #
###################################################################################
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
MAGE_WEB_ROOT_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
MAGE_WEB_USER=$(awk '/webshop/ { print $4 }' /root/mascm/.mascm_index)
MAGE_WEB_USER_PASS=$(awk '/webshop/ { print $5 }' /root/mascm/.mascm_index)
MAGE_ADMIN_EMAIL=$(awk '/mageadmin/ { print $4 }' /root/mascm/.mascm_index)
MAGE_TIMEZONE=$(awk '/mageadmin/ { print $5 }' /root/mascm/.mascm_index)
MAGE_LOCALE=$(awk '/mageadmin/ { print $6 }' /root/mascm/.mascm_index)
MAGE_ADMIN_LOGIN=$(awk '/mageadmin/ { print $2 }' /root/mascm/.mascm_index)
MAGE_ADMIN_PASS=$(awk '/mageadmin/ { print $3 }' /root/mascm/.mascm_index)
MAGE_ADMIN_PATH_RANDOM=$(awk '/mageadmin/ { print $7 }' /root/mascm/.mascm_index)
MAGE_SEL_VER=$(awk '/webshop/ { print $6 }' /root/mascm/.mascm_index)
MAGE_VER=$(awk '/webshop/ { print $7 }' /root/mascm/.mascm_index)
MAGE_DB_HOST=$(awk '/database/ { print $2 }' /root/mascm/.mascm_index)
MAGE_DB_NAME=$(awk '/database/ { print $3 }' /root/mascm/.mascm_index)
MAGE_DB_USER_NAME=$(awk '/database/ { print $4 }' /root/mascm/.mascm_index)
MAGE_DB_PASS=$(awk '/database/ { print $5 }' /root/mascm/.mascm_index)
MYSQL_ROOT_PASS=$(awk '/database/ { print $6 }' /root/mascm/.mascm_index)
echo "-------------------------------------------------------------------------------------"
BLUEBG "| POST-INSTALLATION CONFIGURATION |"
echo "-------------------------------------------------------------------------------------"
echo
if [ "${MAGE_SEL_VER}" = "1" ]; then
PUB_FOLDER="/"
else
PUB_FOLDER="/pub/"
fi
echo
GREENTXT "SERVER HOSTNAME SETTINGS"
hostnamectl set-hostname server.${MAGE_DOMAIN} --static
echo
GREENTXT "SERVER TIMEZONE SETTINGS"
timedatectl set-timezone ${MAGE_TIMEZONE}
echo
GREENTXT "HHVM AND PHP-FPM SETTINGS"
sed -i "s/\[www\]/\[${MAGE_WEB_USER}\]/" /etc/php-fpm.d/www.conf
sed -i "s/user = apache/user = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/group = apache/group = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/;listen.owner = nobody/listen.group = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/;listen.group = nobody/listen.group = ${MAGE_WEB_USER}/" /etc/php-fpm.d/www.conf
sed -i "s/;listen.mode = 0660/listen.mode = 0660/" /etc/php-fpm.d/www.conf
sed -i "s,session.save_handler = files,session.save_handler = redis," /etc/php.ini
sed -i 's,;session.save_path = "/tmp",session.save_path = "tcp://127.0.0.1:6379",' /etc/php.ini
sed -i '/PHPSESSID/d' /etc/php.ini
sed -i "s,.*date.timezone.*,date.timezone = ${MAGE_TIMEZONE}," /etc/php.ini
sed -i '/sendmail_path/,$d' /etc/php-fpm.d/www.conf

cat >> /etc/php-fpm.d/www.conf <<END
;;
;; Custom pool settings
php_flag[display_errors] = off
php_admin_flag[log_errors] = on
php_admin_value[error_log] = ${MAGE_WEB_ROOT_PATH}/var/log/php-fpm-error.log
php_admin_value[memory_limit] = 1024M
php_admin_value[date.timezone] = ${MAGE_TIMEZONE}
END

sed -i -e '/User/,+1d' /etc/systemd/system/hhvm.service
sed -i "s/--user hhvm/--user ${MAGE_WEB_USER}/" /etc/systemd/system/hhvm.service
sed -i "s/daemon/server/" /etc/systemd/system/hhvm.service
sed -i '/PrivateTmp/d' /etc/systemd/system/hhvm.service

cat > /etc/hhvm/server.ini <<END
;php options
hhvm.php7.all = 1
hhvm.php7.deprecate_old_style_ctors = 1
hhvm.php7.engine_exceptions = 1
hhvm.php7.int_semantics = 1
hhvm.php7.ltr_assign = 1
hhvm.php7.no_hex_numerics = 1
hhvm.php7.scalar_types = 0
hhvm.php7.uvs = 1
hhvm.enable_zend_ini_compat = false
;hhvm specific
hhvm.pid_file = "/var/run/hhvm/hhvm.pid"
hhvm.server.port = 9001
hhvm.server.ip = 127.0.0.1
hhvm.server.type = fastcgi
hhvm.server.default_document = index.php
hhvm.server.graceful_shutdown_wait = 5
hhvm.server.enable_keep_alive = true
hhvm.server.apc.enable_apc = true
hhvm.server.request_timeout_seconds = 120
hhvm.server.expose_hphp = false
hhvm.log.level = Notice
hhvm.log.always_log_unhandled_exceptions = true
hhvm.log.runtime_error_reporting_level = 8191
hhvm.log.use_log_file = true
hhvm.log.use_syslog = false
hhvm.log.file = ${MAGE_WEB_ROOT_PATH}/var/log/php-fpm-error.log
hhvm.log.header = true
hhvm.log.native_stack_trace = true
hhvm.repo.central.path = /tmp/hhvm.hhbc
hhvm.jit = true
session.save_handler =  redis
session.save_path = "tcp://127.0.0.1:6379"
date.timezone = ${MAGE_TIMEZONE}
max_execution_time = 600
END

systemctl daemon-reload
systemctl restart hhvm >/dev/null 2>&1
echo
GREENTXT "NGINX SETTINGS"
wget -qO /etc/nginx/fastcgi_params  ${NGINX_BASE}magento${MAGE_SEL_VER}/fastcgi_params
wget -qO /etc/nginx/nginx.conf  ${NGINX_BASE}magento${MAGE_SEL_VER}/nginx.conf
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
wget -q ${NGINX_BASE}magento${MAGE_SEL_VER}/sites-available/default.conf
wget -q ${NGINX_BASE}magento${MAGE_SEL_VER}/sites-available/magento${MAGE_SEL_VER}.conf
ln -s /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf /etc/nginx/sites-enabled/magento${MAGE_SEL_VER}.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
mkdir -p /etc/nginx/conf_m${MAGE_SEL_VER} && cd /etc/nginx/conf_m${MAGE_SEL_VER}/
for CONFIG in ${NGINX_EXTRA_CONF}
do
wget -q ${NGINX_BASE}magento${MAGE_SEL_VER}/conf_m${MAGE_SEL_VER}/${CONFIG}
done
sed -i "s/user  nginx;/user  ${MAGE_WEB_USER};/" /etc/nginx/nginx.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/nginx.conf
sed -i "s,/var/www/html,${MAGE_WEB_ROOT_PATH},g" /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf
    if [ "${MAGE_SEL_VER}" = "1" ]; then
    	MAGE_ADMIN_PATH=$(grep -Po '(?<=<frontName><!\[CDATA\[)\w*(?=\]\]>)' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml)
    	else
	MAGE_ADMIN_PATH=$(grep -Po "(?<='frontName' => ')\w*(?=')" ${MAGE_WEB_ROOT_PATH}/app/etc/env.php)
    fi
	sed -i "s/ADMIN_PLACEHOLDER/${MAGE_ADMIN_PATH}/" /etc/nginx/conf_m${MAGE_SEL_VER}/extra_protect.conf
echo
GREENTXT "PHPMYADMIN INSTALLATION AND CONFIGURATION"
     PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
     PMA_PASSWD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&?=+_[]{}()<>-' | fold -w 6 | head -n 1)
     BLOWFISHCODE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9=+_[]{}()<>-' | fold -w 64 | head -n 1)
     yum -y -q --enablerepo=remi,remi-test,remi-php70 install phpMyAdmin
     USER_IP=${SSH_CLIENT%% *}
     sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISHCODE}';/" /etc/phpMyAdmin/config.inc.php
     sed -i "s/PHPMYADMIN_PLACEHOLDER/mysql_${PMA_FOLDER}/g" /etc/nginx/conf_m${MAGE_SEL_VER}/phpmyadmin.conf
     sed -i "5i satisfy any; \\
           deny  all; \\
           auth_basic  \"please login\"; \\
           auth_basic_user_file .mysql;"  /etc/nginx/conf_m${MAGE_SEL_VER}/phpmyadmin.conf

     htpasswd -b -c /etc/nginx/.mysql mysql ${PMA_PASSWD}  >/dev/null 2>&1
     echo
cat >> /root/mascm/.mascm_index <<END
pma   mysql_${PMA_FOLDER}   mysql   ${PMA_PASSWD}
END
echo
GREENTXT "PROFTPD CONFIGURATION"
     wget -qO /etc/proftpd.conf ${REPO_MASCM_TMP}proftpd.conf
     ## change proftpd config
     SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
     USER_IP=${SSH_CLIENT%% *}
     USER_GEOIP=$(geoiplookup ${USER_IP} | awk 'NR==1{print substr($4,1,2)}')
     FTP_PORT=$(shuf -i 5121-5132 -n 1)
     sed -i "s/server_sftp_port/${FTP_PORT}/" /etc/proftpd.conf
     sed -i "s/server_ip_address/${SERVER_IP_ADDR}/" /etc/proftpd.conf
     sed -i "s/client_ip_address/${USER_IP}/" /etc/proftpd.conf
     sed -i "s/geoip_country_code/${USER_GEOIP}/" /etc/proftpd.conf
     sed -i "s/sftp_domain/${MAGE_DOMAIN}/" /etc/proftpd.conf
     sed -i "s/FTP_USER/${MAGE_WEB_USER}/" /etc/proftpd.conf
     echo
     ## plug in service status alert
     cp /usr/lib/systemd/system/proftpd.service /etc/systemd/system/proftpd.service
     sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/proftpd.service
     sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/proftpd.service
     systemctl daemon-reload
     systemctl enable proftpd.service >/dev/null 2>&1
     systemctl restart proftpd.service
     echo
cat >> /root/mascm/.mascm_index <<END
proftpd   ${USER_GEOIP}   ${FTP_PORT}   ${MAGE_WEB_USER_PASS}
END
echo
if [ -f /etc/systemd/system/varnish.service ]; then
GREENTXT "VARNISH CACHE SETTINGS"
    sed -i "s/MAGE_WEB_USER/${MAGE_WEB_USER}/g"  /etc/systemd/system/varnish.service
	systemctl enable varnish.service >/dev/null 2>&1
    systemctl restart varnish.service
	YELLOWTXT "VARNISH CACHE PORT :8081"
fi
echo
GREENTXT "OPCACHE GUI, n98-MAGERUN, IMAGE OPTIMIZER, MYSQLTUNER, SSL DEBUG TOOLS"
     mkdir -p /opt/magento_saved_scripts
     wget -qO /opt/magento_saved_scripts/tlstest_$(openssl rand 2 -hex).php ${REPO_MASCM_TMP}tlstest.php
     wget -qO /usr/local/bin/wesley.pl ${REPO_MASCM_TMP}wesley.pl
     wget -qO /usr/local/bin/mysqltuner ${MYSQL_TUNER}
echo
GREENTXT "SYSTEM AUTO UPDATE WITH YUM-CRON"
yum-config-manager --enable remi-php70 >/dev/null 2>&1
yum-config-manager --enable remi >/dev/null 2>&1
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
sed -i "s/email_from = root@localhost/email_from = yum-cron@${MAGE_DOMAIN}/" /etc/yum/yum-cron.conf
sed -i "s/email_to = root/email_to = ${MAGE_ADMIN_EMAIL}/" /etc/yum/yum-cron.conf
systemctl enable yum-cron >/dev/null 2>&1
systemctl restart yum-cron >/dev/null 2>&1
echo
GREENTXT "LETSENCRYPT SSL CERTIFICATE REQUEST"
DNS_A_RECORD=$(getent hosts ${MAGE_DOMAIN} | awk '{ print $1 }')
SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
if [ "${DNS_A_RECORD}" != "${SERVER_IP_ADDR}" ] ; then
    echo
    REDTXT "DNS A record and your servers IP address do not match"
	YELLOWTXT "Your servers ip address ${SERVER_IP_ADDR}"
	YELLOWTXT "Domain ${MAGE_DOMAIN} resolves to ${DNS_A_RECORD}"
	YELLOWTXT "Please change your DNS A record to this servers IP address, and run this command later: "
	WHITETXT "/usr/bin/certbot certonly --agree-tos --no-eff-email --email ${MAGE_ADMIN_EMAIL} --webroot -w ${MAGE_WEB_ROOT_PATH}${PUB_FOLDER} -d ${MAGE_DOMAIN} -d www.${MAGE_DOMAIN}"
	echo
    else
    /usr/bin/certbot certonly --agree-tos --no-eff-email --email ${MAGE_ADMIN_EMAIL} --webroot -w ${MAGE_WEB_ROOT_PATH}${PUB_FOLDER} -d ${MAGE_DOMAIN} -d www.${MAGE_DOMAIN}
    systemctl reload nginx
 fi
echo '45 5 * * 1 root /usr/bin/certbot renew --quiet --renew-hook "systemctl reload nginx" >> /var/log/letsencrypt-renew.log' >> /etc/crontab
echo
GREENTXT "GENERATE DHPARAM FOR NGINX SSL"
openssl dhparam -dsaparam -out /etc/ssl/certs/dhparams.pem 4096
echo
GREENTXT "GENERATE DEFAULT NGINX SSL SERVER KEY/CERT"
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout /etc/ssl/certs/default_server.key -out /etc/ssl/certs/default_server.crt \
-subj "/CN=default_server" -days 3650 -subj "/C=US/ST=Oregon/L=Portland/O=default_server/OU=Org/CN=default_server"
echo
GREENTXT "SIMPLE LOGROTATE SCRIPT FOR MAGENTO LOGS"
cat > /etc/logrotate.d/magento <<END
${MAGE_WEB_ROOT_PATH}/var/log/*.log
{
su root root
create 640 ${MAGE_WEB_USER} ${MAGE_WEB_USER}
weekly
rotate 2
notifempty
missingok
compress
}
END
echo
GREENTXT "SERVICE STATUS WITH E-MAIL ALERTING"
wget -qO /etc/systemd/system/service-status-mail@.service ${REPO_MASCM_TMP}service-status-mail@.service
wget -qO /bin/service-status-mail.sh ${REPO_MASCM_TMP}service-status-mail.sh
sed -i "s/MAGEADMINEMAIL/${MAGE_ADMIN_EMAIL}/" /bin/service-status-mail.sh
sed -i "s/DOMAINNAME/${MAGE_DOMAIN}/" /bin/service-status-mail.sh
chmod u+x /bin/service-status-mail.sh
systemctl daemon-reload
echo
GREENTXT "MAGENTO MALWARE SCANNER"
YELLOWTXT "Hourly cronjob created"
pip -q install --no-cache-dir --upgrade mwscan
cat > /etc/cron.hourly/mwscan <<END
## MAGENTO MALWARE SCANNER
MAILTO="${MAGE_ADMIN_EMAIL}"
RULESURL="https://raw.githubusercontent.com/gwillem/magento-malware-scanner/master/build/all-confirmed.yar"
RULEFILE="/tmp/rules.yar"

/usr/bin/curl -s ${RULESURL} -o ${RULEFILE} && /usr/bin/mwscan --quiet --newonly --rules ${RULEFILE} ${MAGE_WEB_ROOT_PATH}
END
echo
GREENTXT "MALDET MALWARE MONITOR WITH E-MAIL ALERTING"
YELLOWTXT "warning: infected files will be moved to quarantine"
cd /usr/local/src
git clone https://github.com/rfxn/linux-malware-detect.git
cd linux-malware-detect
./install.sh > maldet-make-log-file 2>&1

sed -i 's/email_alert="0"/email_alert="1"/' /usr/local/maldetect/conf.maldet
sed -i "s/you@domain.com/${MAGE_ADMIN_EMAIL}/" /usr/local/maldetect/conf.maldet
sed -i 's/quarantine_hits="0"/quarantine_hits="1"/' /usr/local/maldetect/conf.maldet
sed -i 's/inotify_base_watches="16384"/inotify_base_watches="85384"/' /usr/local/maldetect/conf.maldet
echo -e "${MAGE_WEB_ROOT_PATH%/*}\n\n/var/tmp/\n\n/tmp/" > /usr/local/maldetect/monitor_paths

cp /usr/lib/systemd/system/maldet.service /etc/systemd/system/maldet.service
sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/maldet.service
sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /etc/systemd/system/maldet.service
systemctl daemon-reload

sed -i "/^Example/d" /etc/clamd.d/scan.conf
sed -i "/^Example/d" /etc/freshclam.conf
sed -i "/^FRESHCLAM_DELAY/d" /etc/sysconfig/freshclam
echo
GREENTXT "GOACCESS REALTIME ACCESS LOG DASHBOARD"
YELLOWTXT "goaccess access.log -o ${MAGE_WEB_ROOT_PATH}${PUB_FOLDER}access_report_${RANDOM}.html --real-time-html"
cd /usr/local/src
git clone https://github.com/allinurl/goaccess.git
cd goaccess
autoreconf -fi
./configure --enable-utf8 --enable-geoip=legacy --with-openssl  >/dev/null 2>&1
make > goaccess-make-log-file 2>&1
make install > goaccess-make-log-file 2>&1
sed -i '13s/#//' /usr/local/etc/goaccess.conf >/dev/null 2>&1
sed -i '36s/#//' /usr/local/etc/goaccess.conf >/dev/null 2>&1
sed -i '70s/#//' /usr/local/etc/goaccess.conf >/dev/null 2>&1
echo
GREENTXT "MAGENTO CRONJOBS"
if [ "${MAGE_SEL_VER}" = "1" ]; then
        echo "MAILTO=${MAGE_ADMIN_EMAIL}" >> magecron
        echo "* * * * * ! test -e ${MAGE_WEB_ROOT_PATH}/maintenance.flag && /bin/bash ${MAGE_WEB_ROOT_PATH}/cron.sh  > /dev/null" >> magecron
    else
        echo "#* * * * * php -c /etc/php.ini ${MAGE_WEB_ROOT_PATH}/bin/magento cron:run" >> magecron
        echo "#* * * * * php -c /etc/php.ini ${MAGE_WEB_ROOT_PATH}/update/cron.php" >> magecron
        echo "#* * * * * php -c /etc/php.ini ${MAGE_WEB_ROOT_PATH}/bin/magento setup:cron:run" >> magecron
fi
crontab -u ${MAGE_WEB_USER} magecron
echo "*/5 * * * * /bin/bash /usr/local/bin/cron_check.sh" >> rootcron
echo "5 8 * * 7 perl /usr/local/bin/mysqltuner --nocolor 2>&1 | mailx -E -s \"MYSQLTUNER WEEKLY REPORT at ${HOSTNAME}\" ${MAGE_ADMIN_EMAIL}" >> rootcron
echo "30 23 * * * cd /var/log/nginx/; goaccess access.log -a -o access_log_report.html 2>&1 && echo | mailx -s \"Daily access log report at ${HOSTNAME}\" -a access_log_report.html ${MAGE_ADMIN_EMAIL}" >> rootcron
crontab rootcron
rm magecron
rm rootcron
echo
GREENTXT "REDIS CACHE AND SESSION STORAGE"
if [ "${MAGE_SEL_VER}" = "1" ]; then
sed -i '/<session_save>/d' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml
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
            <port>6380</port> \
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
    </cache>' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml

    sed -i "s/false/true/" ${MAGE_WEB_ROOT_PATH}/app/etc/modules/Cm_RedisSession.xml
echo
GREENTXT "DISABLE MAGENTO DATABASE LOGGING"
echo
sed -i '/<\/admin>/ a\
<frontend> \
        <events> \
            <controller_action_predispatch> \
            <observers><log><type>disabled</type></log></observers> \
            </controller_action_predispatch> \
            <controller_action_postdispatch> \
            <observers><log><type>disabled</type></log></observers> \
            </controller_action_postdispatch> \
            <customer_login> \
            <observers><log><type>disabled</type></log></observers> \
            </customer_login> \
            <customer_logout> \
            <observers><log><type>disabled</type></log></observers> \
            </customer_logout> \
            <sales_quote_save_after> \
            <observers><log><type>disabled</type></log></observers> \
            </sales_quote_save_after> \
            <checkout_quote_destroy> \
            <observers><log><type>disabled</type></log></observers> \
            </checkout_quote_destroy> \
        </events> \
</frontend>' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml
echo
	else
sed -i -e '/session/{n;N;N;d}' ${MAGE_WEB_ROOT_PATH}/app/etc/env.php
sed -i "/.*session.*/a \\
   array ( \\
   'save' => 'redis', \\
   'redis' => \\
      array ( \\
        'host' => '127.0.0.1', \\
        'port' => '6379', \\
        'password' => '', \\
        'timeout' => '5', \\
        'persistent_identifier' => 'db1', \\
        'database' => '1', \\
        'compression_threshold' => '2048', \\
        'compression_library' => 'lzf', \\
        'log_level' => '1', \\
        'max_concurrency' => '6', \\
        'break_after_frontend' => '5', \\
        'break_after_adminhtml' => '30', \\
        'first_lifetime' => '600', \\
        'bot_first_lifetime' => '60', \\
        'bot_lifetime' => '7200', \\
        'disable_locking' => '0', \\
        'min_lifetime' => '60', \\
        'max_lifetime' => '2592000' \\
    ), \\
), \\
'cache' =>  \\
  array ( \\
    'frontend' =>  \\
    array ( \\
      'default' =>  \\
      array ( \\
        'backend' => 'Cm_Cache_Backend_Redis', \\
        'backend_options' =>  \\
        array ( \\
          'server' => '127.0.0.1', \\
          'port' => '6380', \\
          'persistent' => '', \\
          'database' => '1', \\
          'force_standalone' => '0', \\
          'connect_retries' => '2', \\
          'read_timeout' => '10', \\
          'automatic_cleaning_factor' => '0', \\
          'compress_data' => '0', \\
          'compress_tags' => '0', \\
          'compress_threshold' => '20480', \\
          'compression_lib' => 'lzf', \\
        ), \\
      ), \\
      'page_cache' =>  \\
      array ( \\
        'backend' => 'Cm_Cache_Backend_Redis', \\
        'backend_options' =>  \\
        array ( \\
          'server' => '127.0.0.1', \\
          'port' => '6380', \\
          'persistent' => '', \\
          'database' => '2', \\
          'force_standalone' => '0', \\
          'connect_retries' => '2', \\
          'read_timeout' => '10', \\
          'automatic_cleaning_factor' => '0', \\
          'compress_data' => '1', \\
          'compress_tags' => '1', \\
          'compress_threshold' => '20480', \\
          'compression_lib' => 'lzf', \\
        ), \\
      ), \\
    ), \\
  ), \\ " ${MAGE_WEB_ROOT_PATH}/app/etc/env.php
fi
echo
systemctl daemon-reload
systemctl restart nginx.service
systemctl restart php-fpm.service
systemctl restart redis@6379
systemctl restart redis@6380

cd ${MAGE_WEB_ROOT_PATH}
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH%/*}
GREENTXT "OPCACHE INVALIDATION MONITOR"
OPCACHE_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 12 | head -n 1)
wget -qO /opt/magento_saved_scripts/${OPCACHE_FILE}_opcache_gui.php https://raw.githubusercontent.com/magenx/opcache-gui/master/index.php
cp /opt/magento_saved_scripts/${OPCACHE_FILE}_opcache_gui.php ${MAGE_WEB_ROOT_PATH}${PUB_FOLDER}
echo
cat > /usr/local/bin/zend_opcache.sh <<END
#!/bin/bash
## monitor magento folder and invalidate opcache
/usr/bin/inotifywait -e modify,move \\
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' \\
    --excludei '(\.swp|\.$(find ${MAGE_WEB_ROOT_PATH} -type f -name '*.*' | sed 's|.*\.||' | sort -u | grep -v ph | xargs | sed 's/ /|\\./g'))' \\
    ${MAGE_WEB_ROOT_PATH}/ | while read line; do
    echo "\$line " >> ${MAGE_WEB_ROOT_PATH}/var/log/zend_opcache_monitor.log
    FILE=\$(echo \${line} | cut -d' ' -f1 | sed -e 's/\/\./\//g' | cut -f1-2 -d'.')
    TARGETEXT="(php|phtml)"
    EXTENSION="\${FILE##*.}"
  if [[ "\$EXTENSION" =~ \$TARGETEXT ]];
    then
    su ${MAGE_WEB_USER} -s /bin/bash -c "curl --cookie 'varnish_bypass=1' --silent ${MAGE_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php?page=invalidate&file=\${FILE} >/dev/null 2>&1"
  fi
done
END
echo
if [ "${MAGE_SEL_VER}" = "1" ]; then
su ${MAGE_WEB_USER} -s /bin/bash -c "mkdir -p var/log"
curl -s -o /usr/local/bin/n98-magerun https://files.magerun.net/n98-magerun.phar
rm -rf index.php.sample LICENSE_AFL.txt LICENSE.html LICENSE.txt RELEASE_NOTES.txt php.ini.sample dev
GREENTXT "CLEANING UP INDEXES LOCKS AND RUNNING RE-INDEX ALL"
echo
rm -rf  ${MAGE_WEB_ROOT_PATH}/var/locks/*
su ${MAGE_WEB_USER} -s /bin/bash -c "php ${MAGE_WEB_ROOT_PATH}/shell/indexer.php --reindexall"
echo
	else
GREENTXT "DISABLE MAGENTO CACHE AND ENABLE DEVELOPER MODE"
rm -rf var/*
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento deploy:mode:set developer --quiet"
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento cache:flush --quiet"
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento cache:disable --quiet"
sed -i "s/report/report|${OPCACHE_FILE}_opcache_gui/" /etc/nginx/sites-available/magento2.conf
systemctl restart php-fpm.service
echo
curl -s -o /usr/local/bin/n98-magerun2 https://files.magerun.net/n98-magerun2.phar
chmod u+x bin/magento
GREENTXT "SAVING COMPOSER JSON AND LOCK"
cp composer.json ../composer.json.saved
cp composer.lock ../composer.lock.saved
fi
echo
GREENTXT "IMAGES OPTIMIZATION SCRIPT"
echo
cat >> /usr/local/bin/optimages.sh <<END
#!/bin/bash
## monitor media folder and optimize new images
/usr/bin/inotifywait -e create \\
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' \\
    --excludei '(\.swp|\.$(find ${MAGE_WEB_ROOT_PATH} -type f -name '*.*' | sed 's|.*\.||' | sort -u |  grep -Eiv 'jpe?g|png' | xargs | sed 's/ /|\\./g'))' \\
    ${MAGE_WEB_ROOT_PATH}${PUB_FOLDER}media | while read line; do
    echo "\${line} " >> ${MAGE_WEB_ROOT_PATH}/var/log/images_optimization.log
    FILE=\$(echo \${line} | cut -d' ' -f1)
    TARGETEXT="(jpg|jpeg|png|JPG|gif)"
    EXTENSION="\${FILE##*.}"
  if [[ "\${EXTENSION}" =~ \${TARGETEXT} ]];
    then
   su ${MAGE_WEB_USER} -s /bin/bash -c "/usr/local/bin/wesley.pl \${FILE} >/dev/null 2>&1"
  fi
done
END
cat >> /usr/local/bin/cron_check.sh <<END
#!/bin/bash
## check opcache gui exists
if [ ! -f "${MAGE_WEB_ROOT_PATH}${PUB_FOLDER}${OPCACHE_FILE}_opcache_gui.php" ]; then
    cp /opt/magento_saved_scripts/${OPCACHE_FILE}_opcache_gui.php ${MAGE_WEB_ROOT_PATH}${PUB_FOLDER}${OPCACHE_FILE}_opcache_gui.php
    chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH}${PUB_FOLDER}${OPCACHE_FILE}_opcache_gui.php
fi
## check magento cli permissions
chmod u+x ${MAGE_WEB_ROOT_PATH}/bin/magento
## check if optimization scripts running
pgrep optimages.sh > /dev/null || /usr/local/bin/optimages.sh &
pgrep zend_opcache.sh > /dev/null || /usr/local/bin/zend_opcache.sh &
END
echo
GREENTXT "FIXING PERMISSIONS"
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH}
find . -type f -exec chmod 660 {} \;
find . -type d -exec chmod 2770 {} \;
chmod +x /usr/local/bin/*
echo
echo
echo "===========================  INSTALLATION LOG  ======================================"
echo
echo
WHITETXT "[shop domain]: ${MAGE_DOMAIN}"
WHITETXT "[webroot path]: ${MAGE_WEB_ROOT_PATH}"
WHITETXT "[admin path]: ${MAGE_DOMAIN}/${MAGE_ADMIN_PATH}"
WHITETXT "[admin name]: ${MAGE_ADMIN_LOGIN}"
WHITETXT "[admin pass]: ${MAGE_ADMIN_PASS}"
echo
WHITETXT "[phpmyadmin url]: ${MAGE_DOMAIN}/mysql_${PMA_FOLDER}"
WHITETXT "[phpmyadmin http auth name]: mysql"
WHITETXT "[phpmyadmin http auth pass]: ${PMA_PASSWD}"
WHITETXT "[phpmyadmin allowed ip]: ${USER_IP}"
echo
WHITETXT "[mysql host]: ${MAGE_DB_HOST}"
WHITETXT "[mysql user]: ${MAGE_DB_USER_NAME}"
WHITETXT "[mysql pass]: ${MAGE_DB_PASS}"
WHITETXT "[mysql database]: ${MAGE_DB_NAME}"
WHITETXT "[mysql root pass]: ${MYSQL_ROOT_PASS}"
echo
WHITETXT "[ftp port]: ${FTP_PORT}"
WHITETXT "[ftp user]: ${MAGE_WEB_USER}"
WHITETXT "[ftp password]: ${MAGE_WEB_USER_PASS}"
WHITETXT "[ftp allowed geoip]: ${USER_GEOIP}"
WHITETXT "[ftp allowed ip]: ${USER_IP}"
echo
WHITETXT "[percona toolkit]: https://www.percona.com/doc/percona-toolkit/LATEST/index.html"
WHITETXT "[database monitor]: /usr/local/bin/mytop"
WHITETXT "[mysql tuner]: /usr/local/bin/mysqltuner"
echo
if [ "${MAGE_SEL_VER}" = "1" ]; then
WHITETXT "[n98-magerun]: /usr/local/bin/n98-magerun"
else
WHITETXT "[n98-magerun]: /usr/local/bin/n98-magerun2"
fi
echo
WHITETXT "[images optimization]: /usr/local/bin/optimages.sh + /usr/local/bin/wesley.pl"
WHITETXT "[opcache gui]: ${MAGE_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php"
WHITETXT "[opcache invalidation]: /usr/local/bin/zend_opcache.sh + ${OPCACHE_FILE}_opcache_gui.php"
WHITETXT "[cronjob]: /usr/local/bin/cron_check.sh - to keep above files running"
echo
WHITETXT "[redis on port 6379]: systemctl restart redis@6379"
WHITETXT "[redis on port 6380]: systemctl restart redis@6380"
echo
if [ "${MAGE_SEL_VER}" = "2" ]; then
WHITETXT "[crontab]: in case of migration magento 2 cron disabled. enable it if no migration."
WHITETXT "[installed db dump]: /root/${MAGE_DB_NAME}.sql.gz"
fi
echo
echo "===========================  INSTALLATION LOG  ======================================"
echo
usermod -G apache ${MAGE_WEB_USER}
echo "-------------------------------------------------------------------------------------"
BLUEBG "| POST-INSTALLATION CONFIGURATION IS COMPLETED |"
echo "-------------------------------------------------------------------------------------"

###################################################################################
#                          INSTALLING CSF FIREWALL                                #
###################################################################################

###################################################################################
#                               WEBMIN HERE YOU GO                                #
###################################################################################

###################################################################################
#                          INSTALLING OSSEC ELK STACK                             #
###################################################################################

###################################################################################
#                               MENU DEFAULT CATCH ALL                            #
###################################################################################
