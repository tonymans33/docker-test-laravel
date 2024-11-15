#!/bin/sh

# Navigate to the project directory
cd /var/www

rm -f public/hot

# Wait for MySQL to be ready
until mysqladmin ping -h"$DB_HOST" --silent; do
    echo "Waiting for MySQL..."
    sleep 2
done

# Clear and optimize Laravel cache
php artisan cache:clear
php artisan config:clear
php artisan package:discover --ansi
php artisan vendor:publish --tag=laravel-assets --ansi --force

# Install Composer dependencies (already done in Dockerfile but keeping it here as a safeguard)
composer install --no-dev --optimize-autoloader

# Set permissions for bootstrap and storage
chmod -R 777 /var/www/bootstrap/cache /var/www/storage

# Run migrations and seeders (optional)
php artisan migrate --force
php artisan db:seed --force

# Clear and cache Laravel configurations and routes
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link (optional)
php artisan storage:link

# Start PHP-FPM as the final process in the container
exec php-fpm
