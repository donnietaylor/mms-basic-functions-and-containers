# PowerShell HTTP Server for Container Apps Demo 3
param(
    [int]$Port = 8080
)

# Import required modules
Add-Type -AssemblyName System.Web

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:$Port/")

Write-Host "Starting PowerShell HTTP Server on port $Port..."

try {
    $listener.Start()
    Write-Host "Server is listening on http://*:$Port/"
    Write-Host "Container Apps Demo 3 - Simple PowerShell API is ready!"
    
    # Keep track of request count
    $requestCount = 0
    $startTime = Get-Date
    
    while ($listener.IsListening) {
        # Wait for incoming request
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $requestCount++
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "[$timestamp] Request #$requestCount - $($request.HttpMethod) $($request.Url.AbsolutePath) from $($request.RemoteEndPoint)"
        
        # Set CORS headers for web access
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        # Handle different endpoints
        $path = $request.Url.AbsolutePath.ToLower()
        $method = $request.HttpMethod.ToUpper()
        
        # Parse query parameters
        $query = @{}
        if ($request.Url.Query) {
            $queryString = $request.Url.Query.TrimStart('?')
            foreach ($pair in $queryString.Split('&')) {
                if ($pair.Contains('=')) {
                    $key, $value = $pair.Split('=', 2)
                    $query[[System.Web.HttpUtility]::UrlDecode($key)] = [System.Web.HttpUtility]::UrlDecode($value)
                }
            }
        }
        
        # Prepare response
        $responseData = @{}
        $statusCode = 200
        
        try {
            switch ($path) {
                "/" {
                    $uptime = (Get-Date) - $startTime
                    $responseData = @{
                        message = "Welcome to Container Apps Demo 3!"
                        description = "This is a simple PowerShell-based HTTP API running in an Azure Container App"
                        container = @{
                            hostname = $env:HOSTNAME
                            platform = [System.Environment]::OSVersion.Platform
                            powershellVersion = $PSVersionTable.PSVersion.ToString()
                        }
                        server = @{
                            uptime = "$([int]$uptime.TotalHours):$($uptime.Minutes.ToString('00')):$($uptime.Seconds.ToString('00'))"
                            requestCount = $requestCount
                            timestamp = $timestamp
                        }
                        endpoints = @{
                            health = "/health - Health check endpoint"
                            info = "/info - System information"
                            echo = "/echo?message=YourMessage - Echo service"
                            time = "/time - Current server time"
                        }
                    }
                }
                
                "/health" {
                    $responseData = @{
                        status = "healthy"
                        timestamp = $timestamp
                        uptime = ((Get-Date) - $startTime).TotalSeconds
                        version = "1.0.0"
                    }
                }
                
                "/info" {
                    $responseData = @{
                        system = @{
                            hostname = $env:HOSTNAME
                            platform = [System.Environment]::OSVersion.Platform.ToString()
                            powershellVersion = $PSVersionTable.PSVersion.ToString()
                            containerApp = "Demo 3 - Simple PowerShell API"
                        }
                        runtime = @{
                            startTime = $startTime.ToString("yyyy-MM-dd HH:mm:ss")
                            currentTime = $timestamp
                            requestsProcessed = $requestCount
                            memoryUsage = [System.GC]::GetTotalMemory($false)
                        }
                        environment = @{
                            port = $Port
                            workingDirectory = (Get-Location).Path
                        }
                    }
                }
                
                "/echo" {
                    $message = $query["message"]
                    if (-not $message) {
                        $message = "No message provided. Use ?message=YourMessage"
                    }
                    
                    $responseData = @{
                        echo = $message
                        timestamp = $timestamp
                        from = "Container Apps Demo 3"
                        request = @{
                            method = $method
                            remoteEndpoint = $request.RemoteEndPoint.ToString()
                            userAgent = $request.UserAgent
                        }
                    }
                }
                
                "/time" {
                    $responseData = @{
                        currentTime = $timestamp
                        utcTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss UTC")
                        timezone = [System.TimeZoneInfo]::Local.DisplayName
                        unixTimestamp = [int](Get-Date -UFormat %s)
                        iso8601 = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    }
                }
                
                default {
                    $statusCode = 404
                    $responseData = @{
                        error = "Endpoint not found"
                        path = $path
                        message = "The requested endpoint does not exist"
                        availableEndpoints = @("/", "/health", "/info", "/echo", "/time")
                    }
                }
            }
        }
        catch {
            $statusCode = 500
            $responseData = @{
                error = "Internal server error"
                message = $_.Exception.Message
                timestamp = $timestamp
            }
            Write-Host "Error processing request: $($_.Exception.Message)"
        }
        
        # Convert response to JSON and send
        $jsonResponse = $responseData | ConvertTo-Json -Depth 3
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
        
        $response.StatusCode = $statusCode
        $response.ContentType = "application/json"
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.OutputStream.Close()
    }
}
catch {
    Write-Host "Server error: $($_.Exception.Message)"
}
finally {
    if ($listener.IsListening) {
        $listener.Stop()
        Write-Host "Server stopped."
    }
}