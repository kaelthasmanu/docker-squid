# Use the official PHP image
FROM php:7.4-apache

WORKDIR /var/www/html

# Copy your PHP files into the container
COPY . /var/www/html/

RUN a2enmod rewrite

# Expose the port that Apache is using
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s CMD curl -fsS http://localhost/ || exit 1