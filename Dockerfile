FROM php:8.3-apache

# Install dependencies 
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libopencv-dev \
    && docker-php-ext-install gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "<VirtualHost *:80>\n\
    DocumentRoot /var/www/html\n\
    <Directory /var/www/html>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    # Redirect from root to Introduction.html\n\
    RewriteEngine On\n\
    RewriteCond %{REQUEST_URI} ^/$\n\
    RewriteRule ^/$ /Introduction.html [R=301,L]\n\
    </VirtualHost>" >  /etc/apache2/sites-available/000-default.conf

COPY ./build/ /var/www/html/

# Compile simulation cpp files for one experiment
WORKDIR /var/www/html/exp/image-arithmetic/simulation
RUN g++ codes/im_arith.cpp -o execs/arith.out `pkg-config --cflags --libs opencv4` \
    && cp execs/arith.out ../assignment/execs/arith.out

# Enable the Apache mod_rewrite module
RUN a2enmod rewrite

# Configure Apache to allow .htaccess overrides and set directory permissions
RUN echo "<Directory /var/www/html>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
    </Directory>" > /etc/apache2/conf-available/exp.conf && \
    a2enconf exp

# php.ini configuration
# RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Set proper permissions for the web root
RUN chown -R www-data:www-data /var/www/html/ && chmod -R 755 /var/www/html/

# Set ServerName to avoid Apache warnings
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && a2enconf servername

EXPOSE 80
CMD ["apache2-foreground"]
