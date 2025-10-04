FROM phpswoole/swoole:php8.4

# Copy composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Copy application code
COPY src/ ./src/
COPY examples/ ./examples/

ENTRYPOINT ["src/bin/mononoke"]
