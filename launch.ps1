# Get current user
$userName = $env:USERNAME

# Define target folder
$targetFolder = "C:\Users\$userName\AppData\Local\ycd"

# Ensure target folder exists
if (-Not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
}

# Define GitHub raw base URL
$baseUrl = "https://raw.githubusercontent.com/shariarratul/ycd/main"

# List of files to download
$files = @("server.js", "package.json", "package-lock.json")

# Download each file and save to target folder
foreach ($file in $files) {
    $url = "$baseUrl/$file"
    $outputPath = Join-Path $targetFolder $file
    Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing
}

# Navigate to your project folder
Set-Location $targetFolder

# Run npm install and wait for it to complete
npm install

# Start node server in background (hidden window)
Start-Process "node" -ArgumentList "server.js" -WindowStyle Hidden

# Start ngrok in background (hidden window)
Start-Process "ngrok" -ArgumentList "start my-app" -WindowStyle Hidden
