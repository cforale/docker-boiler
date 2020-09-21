FROM amazonlinux:2

# Install nginx and php
RUN yum update -y && \
    amazon-linux-extras install nginx1=stable php7.2=stable && \
    yum install php-fpm php-bcmath php-ctype php-xml php-json php-mbstring php-pdo php-openssl php-opcache php-cli php-process php-common php-fpm php-zip php-unzip php-mysqlnd -y && \
    yum --skip-broken -t install git -y

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    ln -s /usr/local/bin/composer /usr/local/bin/composer.phar

# Setup document root
RUN mkdir -p /usr/share/nginx/php/project

# Permissions
RUN chown -R nginx:nginx /usr/share/nginx/php/project && \
    chown -R nginx:nginx /var/run/php-fpm && \
    chown -R nginx:nginx /var/log/php-fpm && \
    chmod -R 755 /usr/share/nginx/php/project

COPY .docker/php/php.ini /etc/php.ini
COPY .docker/php/php-fpm.d/www.conf /etc/php-fpm.d/www.conf
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/conf.d/ /etc/nginx/conf.d/

USER nginx

WORKDIR /usr/share/nginx/php/project

COPY --chown=nginx . /usr/share/nginx/php/project

RUN rm -rf .docker && \
    composer install --optimize-autoloader --no-dev && \
    composer dump-autoload -o

EXPOSE 80

USER root

CMD php-fpm -d variables_order="EGPCS" && exec nginx -g "daemon off;"

HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping
