FROM deeky666/base

MAINTAINER Steve Müller "st.mueller@dzh-online.de"

ARG MARIADB_VERSION

# Download and install MariaDB server $MARIADB_VERSION as lightweight package.
RUN \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        perl \
        wget \
        && \

    groupadd mysql && \
    useradd -r -g mysql mysql && \

    mkdir -p /mysql/conf.d /mysql/srv /mysql/log /usr/local/mysql && \
    touch /mysql/log/error.log && \
    chown -R mysql:mysql /mysql/srv /mysql/log && \
    chmod 755 /mysql/conf.d && \
    chmod -R 700 /mysql/srv && \
    touch /mysql/conf.d/my.cnf && \

    cd /tmp && \

    wget \
        -nv \
        -O mariadb.tar.gz \
        ftp.hosteurope.de/mirror/archive.mariadb.org/mariadb-${MARIADB_VERSION}/kvm-bintar-hardy-amd64/mariadb-${MARIADB_VERSION}-Linux-x86_64.tar.gz || \
    wget \
        -nv \
        -O mariadb.tar.gz \
        ftp.hosteurope.de/mirror/archive.mariadb.org/mariadb-${MARIADB_VERSION}/kvm-bintar-hardy-amd64/mariadb-${MARIADB_VERSION}-linux-x86_64.tar.gz || \
    wget \
        -nv \
        -O mariadb.tar.gz \
        ftp.hosteurope.de/mirror/archive.mariadb.org/mariadb-${MARIADB_VERSION}/bintar-linux-x86_64/mariadb-${MARIADB_VERSION}-linux-x86_64.tar.gz && \

    tar xf mariadb.tar.gz --strip 1 && \

    cp -p bin/my_print_defaults /usr/sbin/ && \
    cp -p bin/mysql /usr/bin/ && \
    cp -p bin/mysqld /usr/bin/ && \
    cp -p bin/mysqld_safe /usr/sbin/ && \
    (cp -p bin/mysqld_safe_helper /usr/sbin/ || true) && \
    cp -rp share /usr/local/mysql/ && \

    sed -i "s/'localhost',\s*'root'/'%','root'/g" share/mysql_system_tables_data.sql && \

    ./scripts/mysql_install_db --user=mysql --basedir=. --datadir=/mysql/srv && \

    apt-get purge --auto-remove -y \
        perl \
        wget \
        && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /mysql/srv/ib*

# Copy MySQL configuration file which is used as fixed basic server configuration.
ADD ./my.cnf /etc/my.cnf

# Expose volumes for custom server configuration, data and log files.
VOLUME ["/mysql/conf.d", "/mysql/log", "/mysql/srv"]

# Define MySQL server binary as entrypoint.
ENTRYPOINT ["mysqld_safe", "--defaults-extra-file=/mysql/conf.d/my.cnf", "--basedir=/usr/local/mysql", "--ledir=/usr/bin"]

# Expose MySQL server port 3306.
EXPOSE 3306

COPY healthcheck /usr/local/bin/

HEALTHCHECK --interval=1s --retries=30 CMD ["healthcheck"]
