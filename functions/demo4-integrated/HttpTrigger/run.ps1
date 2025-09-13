using namespace System.Net

# Input bindings are passed in via param block
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream
Write-Host "PowerShell HTTP trigger function for integrated solution processed a request."

try {
    # Get parameters
    $name = $Request.Query.Name
    if (-not $name) {
        $name = $Request.Body.Name
    }
    
    $action = $Request.Query.Action
    if (-not $action) {
        $action = $Request.Body.Action
    }
    
    # Get data parameter for storage operations
    $data = $Request.Query.Data
    if (-not $data) {
        $data = $Request.Body.Data
    }
    
    # Get container app URL for integration
    $containerAppUrl = $env:CONTAINER_APP_URL
    
    # Get shared storage connection string
    $sharedStorageConnection = $env:SharedStorageConnection
    
    switch ($action) {
        "container-ping" {
            # Test integration with Container App
            if ([string]::IsNullOrEmpty($containerAppUrl)) {
                $responseData = @{
                    error = "Container App URL not configured"
                    message = "CONTAINER_APP_URL environment variable is not set"
                }
                $statusCode = [HttpStatusCode]::BadRequest
            } else {
                try {
                    $testUrl = "$containerAppUrl/health"
                    Write-Host "Testing Container App at: $testUrl"
                    
                    $containerResponse = Invoke-RestMethod -Uri $testUrl -TimeoutSec 30
                    
                    $responseData = @{
                        success = $true
                        message = "Successfully contacted Container App"
                        containerApp = @{
                            url = $containerAppUrl
                            healthEndpoint = $testUrl
                            response = $containerResponse
                        }
                        integration = "Function App ↔ Container App communication successful"
                        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    }
                    $statusCode = [HttpStatusCode]::OK
                } catch {
                    $responseData = @{
                        error = "Failed to contact Container App"
                        containerAppUrl = $containerAppUrl
                        errorDetails = $_.Exception.Message
                        suggestion = "Make sure the Container App is deployed and running"
                    }
                    $statusCode = [HttpStatusCode]::BadGateway
                }
            }
        }
        
        "store-shared" {
            # Store data in shared storage that Container App can access
            if ([string]::IsNullOrEmpty($sharedStorageConnection)) {
                $responseData = @{
                    error = "Shared storage not configured"
                    message = "SharedStorageConnection environment variable is not set"
                }
                $statusCode = [HttpStatusCode]::BadRequest
            } elseif ([string]::IsNullOrEmpty($data)) {
                $responseData = @{
                    error = "Data parameter is required"
                    usage = "?action=store-shared&data=YourData"
                }
                $statusCode = [HttpStatusCode]::BadRequest
            } else {
                try {
                    # Import Az.Storage module
                    Import-Module Az.Storage
                    
                    # Create storage context
                    $storageContext = New-AzStorageContext -ConnectionString $sharedStorageConnection
                    
                    # Ensure container exists
                    $containerName = "integration-data"
                    $container = Get-AzStorageContainer -Name $containerName -Context $storageContext -ErrorAction SilentlyContinue
                    if (-not $container) {
                        New-AzStorageContainer -Name $containerName -Context $storageContext -Permission Blob | Out-Null
                    }
                    
                    # Create blob with data
                    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                    $blobName = "function-data-$timestamp.json"
                    
                    $dataObject = @{
                        data = $data
                        source = "Azure Function Demo 4"
                        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        name = $name
                        id = [guid]::NewGuid().ToString()
                    }
                    
                    $jsonData = $dataObject | ConvertTo-Json
                    
                    Set-AzStorageBlobContent -Container $containerName -Blob $blobName -BlobType Block -Context $storageContext -Content $jsonData | Out-Null
                    
                    $responseData = @{
                        success = $true
                        message = "Data stored in shared storage successfully"
                        storage = @{
                            containerName = $containerName
                            blobName = $blobName
                            url = "https://$($storageContext.StorageAccountName).blob.core.windows.net/$containerName/$blobName"
                        }
                        data = $dataObject
                        integration = "Data can now be accessed by Container App"
                    }
                    $statusCode = [HttpStatusCode]::OK
                } catch {
                    $responseData = @{
                        error = "Failed to store data in shared storage"
                        details = $_.Exception.Message
                    }
                    $statusCode = [HttpStatusCode]::InternalServerError
                }
            }
        }
        
        "notify-container" {
            # Send notification to Container App
            if ([string]::IsNullOrEmpty($containerAppUrl)) {
                $responseData = @{
                    error = "Container App URL not configured"
                    message = "CONTAINER_APP_URL environment variable is not set"
                }
                $statusCode = [HttpStatusCode]::BadRequest
            } else {
                try {
                    $message = if ($data) { $data } else { "Notification from Function App" }
                    $notificationUrl = "$containerAppUrl/messages"
                    
                    $body = @{
                        message = "$message (sent from Function App)"
                    } | ConvertTo-Json
                    
                    $headers = @{
                        "Content-Type" = "application/json"
                    }
                    
                    $containerResponse = Invoke-RestMethod -Uri $notificationUrl -Method POST -Body $body -Headers $headers -TimeoutSec 30
                    
                    $responseData = @{
                        success = $true
                        message = "Notification sent to Container App successfully"
                        containerApp = @{
                            url = $notificationUrl
                            response = $containerResponse
                        }
                        integration = "Function App → Container App messaging successful"
                        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    }
                    $statusCode = [HttpStatusCode]::OK
                } catch {
                    $responseData = @{
                        error = "Failed to send notification to Container App"
                        containerAppUrl = $containerAppUrl
                        errorDetails = $_.Exception.Message
                    }
                    $statusCode = [HttpStatusCode]::BadGateway
                }
            }
        }
        
        default {
            # Default response showing integration capabilities
            $responseData = @{
                message = "Welcome to Azure Functions Demo 4 - Integrated Solution!"
                description = "This Function App demonstrates integration with Container Apps and shared storage"
                greeting = if ($name) { "Hello, $name!" } else { "Hello from Azure Functions!" }
                integration = @{
                    containerApp = @{
                        configured = -not [string]::IsNullOrEmpty($containerAppUrl)
                        url = $containerAppUrl
                    }
                    sharedStorage = @{
                        configured = -not [string]::IsNullOrEmpty($sharedStorageConnection)
                    }
                }
                availableActions = @{
                    "container-ping" = "Test communication with Container App"
                    "store-shared" = "Store data in shared storage (use with &data=YourData)"
                    "notify-container" = "Send a message to Container App (use with &data=YourMessage)"
                }
                usage = @{
                    basic = "?name=YourName"
                    integration = "?action=container-ping"
                    storage = "?action=store-shared&data=YourData"
                    messaging = "?action=notify-container&data=YourMessage"
                }
            }
            $statusCode = [HttpStatusCode]::OK
        }
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    $responseData = @{
        error = "An error occurred while processing your request"
        details = $_.Exception.Message
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $statusCode = [HttpStatusCode]::InternalServerError
}

# Associate values to output bindings by calling 'Push-OutputBinding'
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = ($responseData | ConvertTo-Json -Depth 3)
    Headers = @{
        "Content-Type" = "application/json"
    }
})