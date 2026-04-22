# Use Python 3.11 slim image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=backend.settings \
    ACCEPT_EULA=Y \
    PYTHONPATH=/app

# Set work directory
WORKDIR /app

# Install system dependencies with careful cleanup to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg \
    curl \
    apt-transport-https \
    && curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    unixodbc \
    unixodbc-dev \
    msodbcsql18 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic link to ensure the driver is found at the expected path
RUN mkdir -p /opt/microsoft/msodbcsql18/lib64 && \
    ln -sf /opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.*.so.* /opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.3.so.2.1

# Configure ODBC driver
RUN echo "[ODBC Driver 18 for SQL Server]\nDriver=/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.3.so.2.1\nThreading=1\n" > /etc/odbcinst.ini

# Copy SSL certificates
COPY cert.pem /app/cert.pem
COPY key.pem /app/key.pem
COPY certs/keycloak.crt /app/keycloak.crt

# Copy project files first
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 8443

# Healthcheck to help diagnose connection issues
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Run Django development server
# CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
CMD ["python", "backend/manage.py", "runserver_plus", "0.0.0.0:8000", "--cert-file", "cert.pem", "--key-file", "key.pem"]