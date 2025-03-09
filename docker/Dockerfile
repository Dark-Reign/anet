# Build stage
FROM debian:stable-slim AS build

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    make \
    zip \
    gzip \
    libbsd-dev \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*


# Select the architecture (assuming environment variables or ARG can determine this)
ARG ARCHITECTURE=x86_64  # Default to x86_64 if not specified

# Automatically detect architecture
RUN ARCHITECTURE=$(uname -m) && \
    if [ "$ARCHITECTURE" = "aarch64" ]; then \
        ln -s /usr/lib/aarch64-linux-gnu/libm.a /usr/lib/libm.a && \
        ln -s /usr/lib/aarch64-linux-gnu/libbsd.a /usr/lib/libbsd.a; \
    elif [ "$ARCHITECTURE" = "x86_64" ]; then \
        ln -s /usr/lib/x86_64-linux-gnu/libm.a /usr/lib/libm.a && \
        ln -s /usr/lib/x86_64-linux-gnu/libbsd.a /usr/lib/libbsd.a; \
    else \
        echo "Unsupported architecture: $ARCHITECTURE"; exit 1; \
    fi

# Copy from build stage using the variable
WORKDIR /build

# Define build directory
ENV APP_DIR=/build/linux86

# Copy only necessary files first (to leverage caching)
COPY Makefile ./
COPY src ./src  
COPY demo ./demo  
COPY h ./h 

# Compile (invalidates cache only when source files change)
RUN make

# Runtime stage
FROM debian:stable-slim

# Install cron and wget
RUN apt-get update && \
    apt-get install -y cron wget apache2 procps sudo supervisor && \
    rm -rf /var/lib/apt/lists/*

# Set environment variable
ENV BUILD_DIR=/build/linux86
ENV APP_DIR=/home/anet

# Copy from build stage using the variable
COPY --from=build $BUILD_DIR $APP_DIR

# Create non-root user
RUN useradd -m alink

# Sudo
#RUN apt-get update && \
#    apt-get install -y csudo && \
#    rm -rf /var/lib/apt/lists/*
#RUN echo 'alink:darkreign' | chpasswd
#RUN usermod -aG sudo alink

# Set proper permissions for the user
RUN chown -R alink:alink $APP_DIR

RUN mv $APP_DIR/anetmon/ /home/alink/
RUN mv $APP_DIR/server/etc /home/alink/

# Set proper permissions for cron
RUN chmod gu+rw /var/run
RUN chmod gu+s /usr/sbin/cron

# Install crontab for the game server user
RUN crontab -u alink /home/alink/etc/crontab2.lst

# Configure Apache Directory public_html
RUN mkdir -p /home/alink/public_html && \
    chown -R alink: /home/alink/public_html
    
# Configure Apache user
RUN chown -R alink: /var/log/apache2/ && \
    sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=alink/' /etc/apache2/envvars && \
    sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=alink/' /etc/apache2/envvars

COPY docker/apache2.conf /etc/apache2/conf-available/anet2.conf
RUN a2enconf anet2 && \
    a2enmod cgid && \
    sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf

# Copy supervisor configuration file
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chown -R alink /var/log/supervisor/
RUN chown -R alink /run

# Switch to non-root user
USER alink

WORKDIR /home/alink

# Ports > 21157 since we're not root.
EXPOSE 21157/udp
EXPOSE 8080/tcp

HEALTHCHECK --interval=1m --start-period=30s --start-interval=5s --timeout=2s \
    CMD ps auxww | grep 'alink.*anet3'

# Entrypoint
COPY docker/entrypoint.sh /opt/local/bin/entrypoint.sh
ENTRYPOINT ["/opt/local/bin/entrypoint.sh"]

# Switch to non-root user
USER alink

# Use supervisor as the main process
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]