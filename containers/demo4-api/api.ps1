# PowerShell HTTP Server for Container Apps Demo 4 - Integrated Solution
param(
    [int]$Port = 8080
)

# Import required modules
Add-Type -AssemblyName System.Web

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:$Port/")

Write-Host "Starting PowerShell HTTP Server for Demo 4 - Integrated Solution on port $Port..."

# In-memory data store for demo purposes
$global:dataStore = @{
    requests = @()
    messages = @()
    stats = @{
        totalRequests = 0
        totalMessages = 0
    }
}

try {
    $listener.Start()
    Write-Host "Server is listening on http://*:$Port/"
    Write-Host "Container Apps Demo 4 - Integrated API is ready!"
    
    $startTime = Get-Date
    
    while ($listener.IsListening) {
        # Wait for incoming request
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $global:dataStore.stats.totalRequests++
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "[$timestamp] Request #$($global:dataStore.stats.totalRequests) - $($request.HttpMethod) $($request.Url.AbsolutePath)"
        
        # Log request for analytics
        $global:dataStore.requests += @{
            timestamp = $timestamp
            method = $request.HttpMethod
            path = $request.Url.AbsolutePath
            remoteEndpoint = $request.RemoteEndPoint.ToString()
            userAgent = $request.UserAgent
        }
        
        # Keep only last 100 requests
        if ($global:dataStore.requests.Count -gt 100) {
            $global:dataStore.requests = $global:dataStore.requests[-100..-1]
        }
        
        # Set CORS headers
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
        
        # Parse request body for POST requests
        $body = $null
        if ($method -eq "POST" -and $request.HasEntityBody) {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $bodyText = $reader.ReadToEnd()
            $reader.Close()
            
            if ($request.ContentType -like "application/json*") {
                try {
                    $body = $bodyText | ConvertFrom-Json
                } catch {
                    $body = $bodyText
                }
            } else {
                $body = $bodyText
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
                        message = "Welcome to Container Apps Demo 4 - Integrated Solution!"
                        description = "This Container App works together with Azure Functions to demonstrate a complete microservices architecture"
                        integration = @{
                            functionAppEndpoint = $env:FUNCTION_APP_URL
                            description = "This Container App can communicate with the Function App for data processing"
                        }
                        container = @{
                            hostname = $env:HOSTNAME
                            platform = [System.Environment]::OSVersion.Platform
                            powershellVersion = $PSVersionTable.PSVersion.ToString()
                        }
                        server = @{
                            uptime = "$([int]$uptime.TotalHours):$($uptime.Minutes.ToString('00')):$($uptime.Seconds.ToString('00'))"
                            requestCount = $global:dataStore.stats.totalRequests
                            messageCount = $global:dataStore.stats.totalMessages
                            timestamp = $timestamp
                        }
                        endpoints = @{
                            health = "/health - Health check endpoint"
                            messages = "/messages - Message management (GET to list, POST to add)"
                            analytics = "/analytics - Request analytics"
                            integration = "/integration - Test Function App integration"
                        }
                    }
                }
                
                "/health" {
                    $responseData = @{
                        status = "healthy"
                        timestamp = $timestamp
                        uptime = ((Get-Date) - $startTime).TotalSeconds
                        version = "1.0.0"
                        integration = @{
                            functionAppConfigured = -not [string]::IsNullOrEmpty($env:FUNCTION_APP_URL)
                            functionAppUrl = $env:FUNCTION_APP_URL
                        }
                    }
                }
                
                "/messages" {
                    if ($method -eq "GET") {
                        $responseData = @{
                            totalMessages = $global:dataStore.messages.Count
                            messages = $global:dataStore.messages
                            statistics = $global:dataStore.stats
                        }
                    }
                    elseif ($method -eq "POST") {
                        $message = $null
                        
                        # Get message from body or query
                        if ($body -and $body.message) {
                            $message = $body.message
                        } elseif ($query.message) {
                            $message = $query.message
                        }
                        
                        if ($message) {
                            $newMessage = @{
                                id = [guid]::NewGuid().ToString()
                                message = $message
                                timestamp = $timestamp
                                source = "Container App Demo 4"
                                remoteEndpoint = $request.RemoteEndPoint.ToString()
                            }
                            
                            $global:dataStore.messages += $newMessage
                            $global:dataStore.stats.totalMessages++
                            
                            # Keep only last 50 messages
                            if ($global:dataStore.messages.Count -gt 50) {
                                $global:dataStore.messages = $global:dataStore.messages[-50..-1]
                            }
                            
                            $responseData = @{
                                success = $true
                                message = "Message added successfully"
                                data = $newMessage
                                totalMessages = $global:dataStore.messages.Count
                            }
                        } else {
                            $statusCode = 400
                            $responseData = @{
                                error = "Message is required"
                                usage = "POST with JSON body: {`"message`": `"Your message`"} or query parameter ?message=YourMessage"
                            }
                        }
                    }
                }
                
                "/analytics" {
                    $responseData = @{
                        statistics = $global:dataStore.stats
                        recentRequests = $global:dataStore.requests | Select-Object -Last 10
                        requestsByPath = $global:dataStore.requests | Group-Object path | ForEach-Object { 
                            @{ path = $_.Name; count = $_.Count } 
                        }
                        requestsByMethod = $global:dataStore.requests | Group-Object method | ForEach-Object { 
                            @{ method = $_.Name; count = $_.Count } 
                        }
                        serverInfo = @{
                            startTime = $startTime.ToString("yyyy-MM-dd HH:mm:ss")
                            currentTime = $timestamp
                            uptime = ((Get-Date) - $startTime).TotalSeconds
                        }
                    }
                }
                
                "/integration" {
                    $functionUrl = $env:FUNCTION_APP_URL
                    
                    if ([string]::IsNullOrEmpty($functionUrl)) {
                        $responseData = @{
                            status = "Function App not configured"
                            message = "FUNCTION_APP_URL environment variable is not set"
                            example = "Set FUNCTION_APP_URL to your Function App endpoint"
                        }
                    } else {
                        try {
                            # Test connection to Function App
                            $testMessage = "Integration test from Container App at $timestamp"
                            $functionEndpoint = "$functionUrl/api/HttpTrigger?name=ContainerApp-Demo4"
                            
                            $webRequest = Invoke-WebRequest -Uri $functionEndpoint -TimeoutSec 30 -UseBasicParsing
                            
                            $responseData = @{
                                status = "Integration successful"
                                functionApp = @{
                                    url = $functionUrl
                                    endpoint = $functionEndpoint
                                    statusCode = $webRequest.StatusCode
                                    response = $webRequest.Content
                                }
                                message = "Successfully communicated with Function App"
                                timestamp = $timestamp
                            }
                        }
                        catch {
                            $responseData = @{
                                status = "Integration failed"
                                error = $_.Exception.Message
                                functionApp = @{
                                    url = $functionUrl
                                    configured = $true
                                }
                                message = "Could not reach Function App"
                                timestamp = $timestamp
                            }
                        }
                    }
                }
                
                default {
                    $statusCode = 404
                    $responseData = @{
                        error = "Endpoint not found"
                        path = $path
                        message = "The requested endpoint does not exist"
                        availableEndpoints = @("/", "/health", "/messages", "/analytics", "/integration")
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
        $jsonResponse = $responseData | ConvertTo-Json -Depth 4
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