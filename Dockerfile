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

# Set environment variable
ENV BUILD_DIR=/build/linux86
ENV APP_DIR=/home/anet

# Copy from build stage using the variable
WORKDIR /app
COPY --from=build $BUILD_DIR $APP_DIR

# Create non-root user
RUN useradd -m alink

# Set proper permissions for the user
RUN chown -R alink:alink $APP_DIR

RUN mv $APP_DIR/anetmon/ /home/alink/
RUN mv $APP_DIR/server/etc /home/alink/

# Ports > 21157 since we're not root.
EXPOSE 21157/udp

# Install cron
RUN apt-get update && apt-get install -y cron && rm -rf /var/lib/apt/lists/*

# Set proper permissions for cron
RUN chmod gu+rw /var/run
RUN chmod gu+s /usr/sbin/cron

# Switch to non-root user
USER alink

WORKDIR /home/alink

# Servfil 
RUN cd /home/alink/etc/ && sh servfil

# Create local-servers.txt and populate it with an IP and hostname
RUN echo "0.0.0.0 localhost" > /home/alink/etc/local-servers.txt

# Install crontab for the game server user
RUN crontab -u alink /home/alink/etc/crontab2.lst

# Ensure cron is running in the background
CMD ["cron", "-f"]