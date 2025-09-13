# Use PowerShell Core base image
FROM mcr.microsoft.com/powershell:7.2-ubuntu-20.04

# Set working directory
WORKDIR /app

# Install required PowerShell modules and dependencies
RUN pwsh -Command "Install-Module -Name Microsoft.PowerShell.UnixCompleters -Force -Scope AllUsers"

# Copy application files
COPY app.ps1 /app/
COPY start.ps1 /app/

# Make scripts executable
RUN chmod +x /app/app.ps1 /app/start.ps1

# Expose port
EXPOSE 8080

# Set environment variable for port
ENV PORT=8080

# Run the application
ENTRYPOINT ["pwsh", "/app/start.ps1"]