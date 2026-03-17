FROM php:8.2-fpm

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка PHP расширений
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Создание пользователя для приложения
RUN groupadd -g 1000 www && \
    useradd -u 1000 -ms /bin/bash -g www www

# Копирование кода приложения С ПРАВИЛЬНЫМИ ПРАВАМИ (одна команда!)
COPY --chown=www:www . /var/www/html

COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Настройка безопасной директории для Git
RUN git config --global --add safe.directory /var/www/html

# Смена пользователя
USER www

# Рабочая директория
WORKDIR /var/www/html

# Установка зависимостей НА ЭТАПЕ СБОРКИ (не при деплое!)
RUN composer install --no-dev --optimize-autoloader --no-interaction

EXPOSE 9000
CMD ["php-fpm"]
