# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Enable Flutter Web
RUN flutter config --enable-web

# Copy dependency definitions and pre-fetch
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source tree and compile release web bundle
COPY . .
RUN flutter pub get && flutter build web --release --no-wasm-dry-run

# Stage 2: Production Nginx Server
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
