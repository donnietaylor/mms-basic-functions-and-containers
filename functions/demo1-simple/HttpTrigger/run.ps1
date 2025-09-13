using namespace System.Net

# Input bindings are passed in via param block
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream
Write-Host "PowerShell HTTP trigger function processed a request."

# Get the name from query parameters or request body
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

# Set default response
$body = "Hello from Azure Functions! This is Demo 1 - a simple HTTP trigger."

# If a name was provided, personalize the greeting
if ($name) {
    $body = "Hello, $name! Welcome to Azure Functions Demo 1. This PowerShell function is running in the cloud!"
}

# Associate values to output bindings by calling 'Push-OutputBinding'
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    Headers = @{
        "Content-Type" = "text/plain"
    }
})