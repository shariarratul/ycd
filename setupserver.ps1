# ===============================
#   YCD Auto-Setup Script
# ===============================

# === Hardcoded Ngrok Auth Token ===
$ngrokAuthToken = "YOUR_NGROK_AUTHTOKEN_HERE"

# === Install Chocolatey if missing ===
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Output "=== Installing Chocolatey ==="
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Output "Chocolatey is already installed. Skipping..."
}

# === Install winget if missing ===
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "=== Installing winget ==="
    choco install winget -y
} else {
    Write-Output "winget is already installed. Skipping..."
}

# === Install yt-dlp, ffmpeg, ngrok, nodejs ===
Write-Output "=== Installing yt-dlp, ffmpeg, ngrok, nodejs ==="
winget install -e --id yt-dlp.yt-dlp -h --accept-source-agreements --accept-package-agreements
winget install -e --id Gyan.FFmpeg -h --accept-source-agreements --accept-package-agreements
winget install -e --id Ngrok.Ngrok -h --accept-source-agreements --accept-package-agreements
winget install -e --id OpenJS.NodeJS.LTS -h --accept-source-agreements --accept-package-agreements

# === Configure Ngrok ===
Write-Output "=== Configuring Ngrok ==="
ngrok config add-authtoken $ngrokAuthToken

# === Define Paths ===
$userName = $env:USERNAME
$ngrokConfigPath = "C:\Users\$userName\AppData\Local\ngrok"
$ycdPath = "C:\Users\$userName\AppData\Local\ycd"
$startupPath = [Environment]::GetFolderPath("Startup")

# Ensure folders exist
New-Item -ItemType Directory -Force -Path $ngrokConfigPath | Out-Null
New-Item -ItemType Directory -Force -Path $ycdPath | Out-Null

# === Download Files from GitHub ===
$repoBase = "https://raw.githubusercontent.com/shariarratul/ycd/main"

Write-Output "=== Downloading files from GitHub ==="
Invoke-WebRequest "$repoBase/ngrok.yml" -OutFile "$ngrokConfigPath\ngrok.yml" -UseBasicParsing
Invoke-WebRequest "$repoBase/launch.ps1" -OutFile "$ycdPath\launch.ps1" -UseBasicParsing
Invoke-WebRequest "$repoBase/server.js" -OutFile "$ycdPath\server.js" -UseBasicParsing
Invoke-WebRequest "$repoBase/package.json" -OutFile "$ycdPath\package.json" -UseBasicParsing
Invoke-WebRequest "$repoBase/package-lock.json" -OutFile "$ycdPath\package-lock.json" -UseBasicParsing
Invoke-WebRequest "$repoBase/run.vbs" -OutFile "$startupPath\run.vbs" -UseBasicParsing

# === Run npm install ===
Write-Output "=== Updating NGROK ==="
ngrok update

# === Run npm install ===
Write-Output "=== Installing Node dependencies ==="
cd $ycdPath
npm install


Write-Output "=== Setup Complete ✅ ==="
