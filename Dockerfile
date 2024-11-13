# Stage 1: Build assets with Node.js
FROM node:22 as node-builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json for dependency installation
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Copy the rest of the application code and build assets
COPY . .
RUN npm run build


# Stage 2: Build PHP environment with Composer
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install PHP dependencies and Node.js 22.x (if needed for any other reason)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    default-mysql-client

# Clear APT cache to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer

# Copy the Composer files and install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Copy the application code
COPY . .

# Copy built assets from Node stage
COPY --from=node-builder /app/public /var/www/public

# Set permissions
RUN chown -R www-data:www-data /var/www && chmod -R 755 /var/www

# Set permissions for storage and bootstrap cache
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Make run.sh executable
COPY run.sh /var/www/run.sh
RUN chmod +x /var/www/run.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Run the custom entrypoint script
CMD ["/var/www/run.sh"]
