#!/usr/bin/env pwsh

# Startup script for Container Apps Demo 4 - Integrated Solution
Write-Host "Starting Container Apps Demo 4 - Integrated Solution API Server"
Write-Host "Container hostname: $($env:HOSTNAME)"
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"

# Display integration configuration
if ($env:FUNCTION_APP_URL) {
    Write-Host "Function App integration configured: $($env:FUNCTION_APP_URL)"
} else {
    Write-Host "Function App integration not configured (FUNCTION_APP_URL not set)"
}

# Get port from environment variable or use default
$port = if ($env:PORT) { [int]$env:PORT } else { 8080 }

Write-Host "Using port: $port"

# Start the application
& /app/api.ps1 -Port $port