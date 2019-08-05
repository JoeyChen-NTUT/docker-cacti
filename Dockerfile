FROM centos:7
MAINTAINER Sean Cline <smcline06@gmail.com>

## --- SUPPORTING FILES ---
COPY cacti /cacti_install

## --- CACTI ---
RUN \
    rpm --rebuilddb && yum clean all && \
    yum update -y && \
    yum install -y \
        rrdtool net-snmp net-snmp-utils cronie php-ldap php-devel mysql php \
        ntp bison php-cli php-mysql php-common php-mbstring php-snmp curl \
        php-gd openssl openldap mod_ssl php-pear net-snmp-libs php-pdo \
        autoconf automake gcc gzip help2man libtool make net-snmp-devel \
        m4 libmysqlclient-devel libmysqlclient openssl-devel dos2unix wget \
        sendmail mariadb-devel ca-certificates && \

## --- CLEANUP ---
    yum clean all

## --- FOR NTUT Only ---
RUN \
    wget -qO NTUT_ROOT_CA.crt https://cnc.ntut.edu.tw/app/index.php?Action=downloadfile&file=WVhSMFlXTm9MemN6TDNCMFlWODBPVFEyT1Y4NE1qYzBOREl6WHpJeU1qSTJMbU55ZEE9PQ==&fname=1454DGB0LOCCTTZX50POKKXTTW30TWICQOJCDCMK41GD34A0YSMKA0VW34OO30USGCWW45MLVSPOPOHGYW30MKXSQORKTWNKIHMP04PKUWA4POB4WSKKUSPKYWXW45HD50POSWWTKK3030YSB0QKSWNKA1UXTSA0KPZWUSUW20HGCDA0ICSSUTZXHCLKLOIGKKJGA4LKB430A1A1 && \
    mkdir -p /etc/pki/ca-trust/source/anchors && \
    cp NTUT_ROOT_CA.crt /etc/pki/ca-trust/source/anchors/ && \
    update-ca-trust extract

## --- CRON ---
# Fix cron issues - https://github.com/CentOS/CentOS-Dockerfiles/issues/31
RUN sed -i '/session required pam_loginuid.so/d' /etc/pam.d/crond

## --- SERVICE CONFIGS ---
COPY configs /template_configs

## --- SETTINGS/EXTRAS ---
COPY plugins /cacti_install/plugins
COPY templates /templates
COPY settings /settings

## --- SCRIPTS ---
COPY upgrade.sh /upgrade.sh
RUN chmod +x /upgrade.sh

COPY restore.sh /restore.sh
RUN chmod +x /restore.sh

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

VOLUME /cacti

RUN mkdir /backups
RUN mkdir /spine

## -- MISC SETUP --
RUN echo "ServerName localhost" > /etc/httpd/conf.d/fqdn.conf

## --- ENV ---
ENV \
    DB_NAME=cacti \
    DB_USER=cactiuser \
    DB_PASS=cactipassword \
    DB_HOST=localhost \
    DB_PORT=3306 \
    RDB_NAME=cacti \
    RDB_USER=cactiuser \
    RDB_PASS=cactipassword \
    RDB_HOST=localhost \
    RDB_PORT=3306 \
    BACKUP_RETENTION=7 \
    BACKUP_TIME=0 \
    SNMP_COMMUNITY=public \
    REMOTE_POLLER=0 \
    INITIALIZE_DB=0 \
    INITIALIZE_INFLUX=0 \
    TZ=UTC \
    PHP_MEMORY_LIMIT=128M \
    PHP_MAX_EXECUTION_TIME=30

## --- Start ---
COPY start.sh /start.sh
CMD ["/start.sh"]

EXPOSE 80 443
