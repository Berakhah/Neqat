# Use Flutter SDK
FROM ghcr.io/cirruslabs/flutter:stable

# Set working directory
WORKDIR /app

# Copy pubspec.yaml and pubspec.lock
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the application with the correct entry point
RUN flutter build web --release -t lib/app/main.dart

# Use nginx to serve the built application
FROM nginx:alpine

# Copy the built application to nginx
COPY --from=0 /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 3000

# Start nginx
CMD ["nginx", "-g", "daemon off;"] 