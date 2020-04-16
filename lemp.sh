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
EXTRA_PACKAGES="autoconf automake dejavu-fonts-common dejavu-sans-fonts libtidy libpcap pygpgme gettext-devel cppunit recode boost boost-build boost-jam double-conversion fastlz fribidi gflags glog oniguruma tbb ed lz4 libyaml libdwarf bind-utils e2fsprogs svn screen gcc iptraf inotify-tools smartmontools net-tools mcrypt mlocate unzip vim wget curl sudo bc mailx clamav-filesystem clamav-server clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib clamav-scanner proftpd logrotate git patch ipset strace rsyslog gifsicle ncurses-devel GeoIP GeoIP-devel GeoIP-update openssl-devel ImageMagick libjpeg-turbo-utils pngcrush lsof net-snmp net-snmp-utils xinetd python-pip python-devel ncftp postfix certbot yum-cron yum-plugin-versionlock sysstat libuuid-devel uuid-devel attr iotop expect postgresql-libs unixODBC gcc-c++"
PHP_PACKAGES=(cli common fpm opcache gd curl mbstring bcmath soap mcrypt mysqlnd pdo xml xmlrpc intl gmp php-gettext phpseclib recode symfony-class-loader symfony-common tcpdf tcpdf-dejavu-sans-fonts tidy udan11-sql-parser snappy lz4)
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
# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  YELLOWTXT "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "PASS: ROOT!"
fi

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

###################################################################################
#                                MAGENTO DATABASE SETUP                           #
###################################################################################

###################################################################################
#                                MAGENTO INSTALLATION                             #
###################################################################################

###################################################################################
#                                SYSTEM CONFIGURATION                             #
###################################################################################

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
