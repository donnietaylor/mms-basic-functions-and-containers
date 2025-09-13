#!/usr/bin/env pwsh

# Startup script for Container Apps Demo 3
Write-Host "Starting Container Apps Demo 3 - PowerShell API Server"
Write-Host "Container hostname: $($env:HOSTNAME)"
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"

# Get port from environment variable or use default
$port = if ($env:PORT) { [int]$env:PORT } else { 8080 }

Write-Host "Using port: $port"

# Start the application
& /app/app.ps1 -Port $port