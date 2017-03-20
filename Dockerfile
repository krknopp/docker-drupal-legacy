FROM ubuntu:14.04

RUN apt-get update && apt-get install -y \
	php-apc php-console-table php-pear php5-ldap php5-mongo \
	php5-fpm php5-cli php5-common php5-curl php5-dev php5-gd php5-gmp php5-mcrypt php5-mysql \
	libcurl4-openssl-dev libxml2-dev mime-support unzip \
	apache2 \
	ca-certificates curl supervisor git cron mysql-client ssmtp \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN a2enmod ssl rewrite headers proxy_fcgi remoteip
RUN php5enmod mcrypt

# Install New Relic daemon
RUN echo newrelic-php5 newrelic-php5/application-name string "AppName" | debconf-set-selections && \
    echo newrelic-php5 newrelic-php5/license-key string "12345asdfg54321gfdsa" | debconf-set-selections
ENV NR_INSTALL_SILENT true
RUN env && curl https://download.newrelic.com/548C16BF.gpg | apt-key add - && \
    echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list && \
    apt-get update && apt-get -y install newrelic-php5

RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor /var/run/php /mnt/sites-files /etc/confd/conf.d /etc/confd/templates

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer \
&& ln -s /usr/local/bin/composer /usr/bin/composer

# Install Drush
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && cd /usr/local/src/drush \
&& git checkout 8.1.9 && cd /usr/local/src/drush && composer install && ln -s /usr/local/src/drush/drush /usr/local/bin/drush

# Install Confd
ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY www.conf /etc/php5/fpm/pool.d/www.conf
COPY site.conf /etc/apache2/sites-enabled/000-default.conf
COPY php.ini /etc/php5/fpm/php.ini
COPY remoteip.conf /etc/apache2/conf-enabled/remoteip.conf
COPY confd /etc/confd/
COPY apache2.conf /etc/apache2/apache2.conf
COPY registry_rebuild /root/.drush/registry_rebuild

# Copy in drupal-specific files
COPY wwwsite.conf drupal-settings.sh crons.conf start.sh load-configs.sh mysqlimport.sh mysqlexport.sh xdebug-php.ini /root/
COPY bash_aliases /root/.bash_aliases
COPY drupal7-settings /root/drupal7-settings/

# Volumes
VOLUME /var/www/site /etc/apache2/sites-enabled /mnt/sites-files

EXPOSE 80

WORKDIR /var/www/site

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
