# Stage 1: Lightweight Flutter Web Build (Using Ubuntu 22.04 with active package mirrors)
FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install minimal Flutter SDK for Web (No Android SDK)
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && git config --global --add safe.directory ${FLUTTER_HOME} \
    && flutter config --no-analytics \
    && flutter config --enable-web \
    && flutter precache --web

WORKDIR /app

# Copy dependencies and pre-fetch
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy project source and build web release
COPY . .
RUN flutter build web --release

# Stage 2: Production Nginx Server
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
