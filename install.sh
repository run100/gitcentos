!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install it"
    exit 1
fi
clear
cur_dir=$(pwd)
mkdir -p /usr/local/webserver/

if [ "$1" != "--help" ]; then

rpm -qa|grep  httpd
rpm -e httpd
rpm -qa|grep mysql
rpm -e mysql
rpm -qa|grep php
rpm -e php

yum -y remove httpd
yum -y remove php
yum -y remove mysql-server mysql
yum -y remove php-mysql

yum -y install yum-fastestmirror
yum -y remove httpd
yum -y update

#Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

yum install -y ntp
ntpdate -u pool.ntp.org
date

#Disable SeLinux
if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

for packages in patch make gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal nano fonts-chinese gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip openldap openldap-devel nss_ldap openldap-clients openldap-servers automake libxslt libxslt-devel;
do yum -y install $packages; done


echo "============================check files end=================================="

cd $cur_dir

#tar zxvf autoconf-2.13.tar.gz
#cd autoconf-2.13/
#./configure --prefix=/usr/local/autoconf-2.13
#make && make install
#cd ../

tar zxvf libiconv-1.14.tar.gz
cd libiconv-1.14/
./configure --prefix=/usr/local
make && make install
cd ../

cd $cur_dir
tar zxvf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8/
./configure
make && make install
/sbin/ldconfig
cd libltdl/
./configure --enable-ltdl-install
make && make install
cd ../../

cd $cur_dir
tar zxvf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9/
./configure
make && make install
cd ../

ln -s /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
ln -s /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
ln -s /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
ln -s /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
ln -s /usr/local/lib/libmhash.a /usr/lib/libmhash.a
ln -s /usr/local/lib/libmhash.la /usr/lib/libmhash.la
ln -s /usr/local/lib/libmhash.so /usr/lib/libmhash.so
ln -s /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
ln -s /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
ln -s /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config

cd $cur_dir
tar zxvf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8/
./configure
make && make install
cd ../

if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
cp -frp /usr/lib64/libjpeg.* /usr/lib/
cp -frp /usr/lib64/libpng* /usr/lib/
cp -frp /usr/lib64/libldap* /usr/lib/
fi

ulimit -v unlimited

if [ ! `grep -l "/lib"    '/etc/ld.so.conf'` ]; then
	echo "/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/lib'    '/etc/ld.so.conf'` ]; then
	echo "/usr/lib" >> /etc/ld.so.conf
fi

if [ -d "/usr/lib64" ] && [ ! `grep -l '/usr/lib64'    '/etc/ld.so.conf'` ]; then
	echo "/usr/lib64" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
	echo "/usr/local/lib" >> /etc/ld.so.conf
fi

ldconfig

cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

cat >>/etc/sysctl.conf<<eof
fs.file-max=65535
eof

echo "============================proftpd install=================================="
cd $cur_dir
tar -zxvf proftpd-1.3.4rc2.tar.gz
cd proftpd-1.3.4rc2/
./configure --prefix=/usr/local/webserver/proftpd
make && make install
cd ../
mv /usr/local/webserver/proftpd/etc/proftpd.conf /usr/local/webserver/proftpd/etc/bak_proftpd.conf
mv /usr/local/webserver/proftpd/etc/ftpd.passwd /usr/local/webserver/proftpd/etc/bak_ftpd.passwd
cp conf/ftpd.passwd /usr/local/webserver/proftpd/etc/
cp conf/proftpd.conf /usr/local/webserver/proftpd/etc/

echo "============================mysql cmake=================================="
cd $cur_dir
tar -zxvf cmake-2.8.7.tar.gz
cd cmake-2.8.7/
./configure
make && make install
cd ../

echo "============================mysql install=================================="
cd $cur_dir
tar -zxvf mysql-5.5.13.tar.gz
tar -zxvf sphinx.tar.gz
cd sphinx-2.0.1-beta/
cp -ar mysqlse ../mysql-5.5.13/storage/sphinx
cd ../mysql-5.5.13/
sh BUILD/autorun.sh
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/webserver/mysql -DMYSQL_UNIX_ADDR=/tmp/mysqld.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DEXTRA_CHARSETS=all -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DSYSCONFDIR=/home/mysql -DMYSQL_DATADIR=/home/mysql/data -DWITH_EMBEDDED_SERVER=1 -DENABLED_LOCAL_INFILE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_SPHINX_STORAGE_ENGINE=1 -DMYSQL_TCP_PORT=3306
make && make install
cd ../

#groupadd mysql
#useradd -s /sbin/nologin -M -g mysql mysql
/usr/sbin/groupadd mysql
/usr/sbin/useradd -g mysql mysql
chmod +w /usr/local/webserver/mysql
chown -R mysql:mysql /usr/local/webserver/mysql
mkdir -p /home/mysql/data/
mkdir -p /home/mysql/binlog/
mkdir -p /home/mysql/relaylog/
chown -R mysql:mysql /home/mysql/
cd $cur_dir
/usr/local/webserver/mysql/scripts/mysql_install_db --basedir=/usr/local/webserver/mysql --datadir=/home/mysql/data --user=mysql
cp conf/my.cnf /home/mysql/my.cnf
cp conf/mysql /home/mysql/mysql
chmod 755 /home/mysql/mysql

#cat > /etc/ld.so.conf.d/mysql.conf<<EOF
#/usr/local/webserver/mysql/lib/mysql
#/usr/local/lib
#EOF
ln -s /usr/local/webserver/mysql/lib/libmysqlclient.so.18 /usr/lib/
ldconfig
/home/mysql/mysql start

#/usr/local/mysql/bin/mysqladmin -u root password 123456

#cat > /tmp/mysql_sec_script<<EOF
#use mysql;
#update user set password=password('123456') where user='root';
#delete from user where not (user='root') ;
#delete from user where user='root' and password=''; 
#drop database test;
#DROP USER ''@'%';
#flush privileges;
#EOF
#/usr/local/mysql/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script
#rm -f /tmp/mysql_sec_script
#/etc/init.d/mysql restart
#/etc/init.d/mysql stop
echo "============================mysql intall completed========================="

echo "============================php5.2.17 install======================"
cd $cur_dir

useradd -d /home/www -g 50 www
useradd -d /home/www/web -s /sbin/nologin -g 50 web

#chmod +w /home/wwwroot
mkdir -p /home/logs
mkdir -p /home/logs/apache
chmod 755 /home/logs
#mkdir -p /home/bak/serverlog/php
#chown -R www:ftp /home/www



echo "============================php install completed======================"

echo "============================nginx install================================="
cd $cur_dir
tar zxvf pcre-8.30.tar.gz
cd pcre-8.30/
./configure
make && make install
cd ../
ln -s /usr/local/lib/libpcre.so.1 /lib64/

tar zxvf nginx-1.2.3.tar.gz
cd nginx-1.2.3/
./configure --user=www --group=ftp --prefix=/usr/local/webserver/nginx --with-http_stub_status_module --with-http_ssl_module
make && make install
cd ../

#rm -f /usr/local/webserver/nginx/conf/nginx.conf
mv /usr/local/webserver/nginx/conf/nginx.conf /usr/local/webserver/nginx/conf/bak_nginx.conf
cd $cur_dir
cp conf/nginxapache/nginx.conf /usr/local/webserver/nginx/conf/nginx.conf
#new vhosts
mkdir -p  /usr/local/webserver/nginx/conf/vhosts
cp conf/nginxapache/vhosts/localhost.conf  /usr/local/webserver/nginx/conf/vhosts/localhost.conf

rm -f /usr/local/webserver/nginx/conf/fcgi.conf
cp conf/fcgi.conf /usr/local/webserver/nginx/conf/fcgi.conf
cp conf/proxy_pass.conf /usr/local/webserver/nginx/conf/proxy_pass.conf

cd $cur_dir
echo "============================nginx install completed================================="

echo "============================apache install================================="
cd $cur_dir
tar zxvf httpd-2.2.22.tar.gz
cd httpd-2.2.22/
./configure --prefix=/usr/local/webserver/apache --enable-so --enable-modules=all --enable-mods-shared=all --enable-vhost-alias --enable-deflate --enable-expires --enable-rewrite --enable-authn-dbm=shared --enable-ssl --with-ssl
make && make install
cd ..

mv /usr/local/webserver/apache/conf/httpd.conf /usr/local/webserver/apache/conf/httpd.conf.bak
#cp $cur_dir/conf/apache/httpd.conf /usr/local/webserver/apache/conf/httpd.conf
#cp $cur_dir/conf/apache/vhost.conf /usr/local/webserver/apache/conf/vhost.conf

#new
cp $cur_dir/conf/nginxapache/httpd.conf /usr/local/webserver/apache/conf/httpd.conf
mkdir /usr/local/webserver/apache/conf/vhosts
cp $cur_dir/conf/nginxapache/vhost/localhost.conf /usr/local/webserver/apache/conf/vhosts/localhost.conf
echo "============================apache install completed================================="

echo "============================apache php-5.3.8 install================================="
cd $cur_dir
tar zxvf php-5.3.13.tar.gz
cd php-5.3.13/
./configure --prefix=/usr/local/webserver/php5 --with-config-file-path=/usr/local/webserver/php5/etc --with-apxs2=/usr/local/webserver/apache/bin/apxs --with-mysql=/usr/local/webserver/mysql --with-mysqli=/usr/local/webserver/mysql/bin/mysql_config --with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-discard-path --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-ldap --with-ldap-sasl --with-bz2 --with-xmlrpc --enable-zip --enable-soap --enable-ftp --disable-debug --with-xsl
#rm -rf libtool
#cp /usr/local/webserver/apache/build/libtool .
make ZEND_EXTRA_LIBS='-liconv'
make install

mv /usr/local/webserver/php5/etc/php.ini /usr/local/webserver/php5/etc/bak_php.ini
cp $cur_dir/conf/php5/php.ini /usr/local/webserver/php5/etc/php.ini
cp conf/php5/php.ini /usr/local/webserver/php5/etc/php.ini
cd ../
echo "============================apache php-5.3.8 install completed================================="

echo "============================apache php-5.3.8 memcache install================================="
cd $cur_dir
tar zxvf memcache-2.2.6.tgz
cd memcache-2.2.6/
make clean
/usr/local/webserver/php5/bin/phpize
./configure --with-php-config=/usr/local/webserver/php5/bin/php-config
make && make install
cd ../
echo "============================apache php-5.3.8 memcache install completed================================="

echo "============================apache php-5.3.8 PDO_MYSQL install================================="
cd $cur_dir
tar zxvf PDO_MYSQL-1.0.2.tgz
cd PDO_MYSQL-1.0.2/
make clean
/usr/local/webserver/php5/bin/phpize
./configure --with-php-config=/usr/local/webserver/php5/bin/php-config --with-pdo-mysql=/usr/local/webserver/mysql
make && make install
cd ../
echo "============================apache php-5.3.13 PDO_MYSQL install completed================================="

echo "============================apache php-5.3.13 imagick install================================="
cd $cur_dir
tar imagick-3.0.1.tgz
cd imagick-3.0.1/
make clean
/usr/local/webserver/php5/bin/phpize
./configure --with-php-config=/usr/local/webserver/php5/bin/php-config --with-imagick=/usr/local/imagemagick
make && make install
cd ../
echo "============================apache php-5.3.13 imagick install completed================================="

echo "============================apache php-5.3.13 mongo install================================="
cd $cur_dir
tar zxvf mongo-1.2.7.tgz
cd mongo-1.2.7/
make clean
/usr/local/webserver/php5/bin/phpize
./configure --with-php-config=/usr/local/webserver/php5/bin/php-config
make && make install
cd ../
echo "============================apache php-5.3.13 memcache install completed================================="

echo "============================libevent and memcached install=================================="
cd $cur_dir
tar -zxvf libevent-1.4.14b-stable.tar.gz
cd libevent-1.4.14b-stable/
./configure --prefix=/usr
make && make install
cd ../
tar -zxvf memcached-1.4.7.tar.gz
cd memcached-1.4.7/
./configure --prefix=/usr/local/webserver/memcached --with-libevent=/usr/
make && make install
cd ../
echo "===========================libevent and memcached install end================================="
clear
if [ -s /usr/local/webserver/nginx ]; then
  echo "/usr/local/webserver/nginx [found]"
  else
  echo "Error: /usr/local/webserver/nginx not found!!!"
fi



if [ -s /usr/local/webserver/mysql ]; then
  echo "/usr/local/webserver/mysql [found]"
  else
  echo "Error: /usr/local/webserver/mysql not found!!!"
fi

if [ -s /usr/local/webserver/apache ]; then
  echo "/usr/local/webserver/apache [found]"
  else
  echo "Error: /usr/local/webserver/apache not found!!!"
fi

if [ -s /usr/local/webserver/php5 ]; then
  echo "/usr/local/webserver/php5 [found]"
  else
  echo "Error: /usr/local/webserver/php5 not found!!!"
fi

echo "========================== Check install ================================"
if [ -s /usr/local/webserver/nginx ]  && [ -s /usr/local/webserver/apache ] && [ -s /usr/local/webserver/php5 ] && [ -s /usr/local/webserver/mysql ]; then
echo "========================================================================="
echo "Install successfully!"
echo "========================================================================="
ulimit -SHn 65535
/usr/local/webserver/nginx/sbin/nginx
/usr/local/webserver/apache/bin/apachectl start
netstat -ntl
else
  echo "Sorry!!!!!!!!!!!!"
fi
fi
