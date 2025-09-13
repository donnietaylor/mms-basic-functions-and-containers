using namespace System.Net

# Input bindings are passed in via param block
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream
Write-Host "PowerShell HTTP trigger function with storage integration processed a request."

try {
    # Get storage account connection string from environment variables
    $storageConnectionString = $env:AzureWebJobsStorage
    
    if (-not $storageConnectionString) {
        throw "Storage connection string not found"
    }

    # Get the action from query parameters or request body
    $action = $Request.Query.Action
    if (-not $action) {
        $action = $Request.Body.Action
    }
    
    # Get message content
    $message = $Request.Query.Message
    if (-not $message) {
        $message = $Request.Body.Message
    }
    
    # Container name for storing messages
    $containerName = "demo-messages"
    
    # Import Azure modules
    Import-Module Az.Storage
    
    # Create storage context
    $storageContext = New-AzStorageContext -ConnectionString $storageConnectionString
    
    # Ensure container exists
    $container = Get-AzStorageContainer -Name $containerName -Context $storageContext -ErrorAction SilentlyContinue
    if (-not $container) {
        New-AzStorageContainer -Name $containerName -Context $storageContext -Permission Blob | Out-Null
        Write-Host "Created storage container: $containerName"
    }
    
    switch ($action) {
        "store" {
            if (-not $message) {
                $body = @{
                    error = "Message parameter is required for store action"
                    usage = "?action=store&message=YourMessage"
                } | ConvertTo-Json
                $statusCode = [HttpStatusCode]::BadRequest
            } else {
                # Create a unique blob name
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $blobName = "message-$timestamp.txt"
                
                # Store the message
                $messageContent = @{
                    message = $message
                    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    source = "Azure Function Demo 2"
                } | ConvertTo-Json
                
                Set-AzStorageBlobContent -Container $containerName -Blob $blobName -BlobType Block -Context $storageContext -Content $messageContent | Out-Null
                
                $body = @{
                    success = "Message stored successfully"
                    blobName = $blobName
                    message = $message
                } | ConvertTo-Json
                $statusCode = [HttpStatusCode]::OK
            }
        }
        
        "list" {
            # List all stored messages
            $blobs = Get-AzStorageBlob -Container $containerName -Context $storageContext
            $messages = @()
            
            foreach ($blob in $blobs) {
                $content = Get-AzStorageBlobContent -Container $containerName -Blob $blob.Name -Context $storageContext -Force
                $messageData = $content | Get-Content | ConvertFrom-Json
                $messages += @{
                    blobName = $blob.Name
                    lastModified = $blob.LastModified
                    message = $messageData.message
                    timestamp = $messageData.timestamp
                }
            }
            
            $body = @{
                totalMessages = $messages.Count
                messages = $messages
            } | ConvertTo-Json -Depth 3
            $statusCode = [HttpStatusCode]::OK
        }
        
        default {
            $body = @{
                message = "Welcome to Azure Functions Demo 2 - Storage Integration!"
                description = "This function demonstrates how to interact with Azure Blob Storage from PowerShell"
                usage = @{
                    store = "?action=store&message=YourMessage - Store a message in blob storage"
                    list = "?action=list - List all stored messages"
                }
            } | ConvertTo-Json -Depth 2
            $statusCode = [HttpStatusCode]::OK
        }
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    $body = @{
        error = "An error occurred while processing your request"
        details = $_.Exception.Message
    } | ConvertTo-Json
    $statusCode = [HttpStatusCode]::InternalServerError
}

# Associate values to output bindings by calling 'Push-OutputBinding'
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = $body
    Headers = @{
        "Content-Type" = "application/json"
    }
})