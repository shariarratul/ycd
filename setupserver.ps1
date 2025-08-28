# ===============================
#   YCD Auto-Setup Script
# ===============================

# === Prompt for Ngrok Auth Token and Domain ===
$ngrokAuthToken = Read-Host "Enter your Ngrok Auth Token"
$ngrokDomain = Read-Host "Enter your Ngrok Domain (e.g., mydomain.ngrok.io)"

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

# === Create ngrok.yml dynamically ===
$ngrokYmlContent = @"
version: "3"
tunnels:
    my-app:
        proto: http
        addr: 5050
        domain: $ngrokDomain
agent:
    authtoken: $ngrokAuthToken
"@

$ngrokYmlPath = Join-Path $ngrokConfigPath "ngrok.yml"
$ngrokYmlContent | Out-File -FilePath $ngrokYmlPath -Encoding UTF8

Write-Output "=== ngrok.yml created at $ngrokYmlPath ==="

# === Download files from GitHub (except ngrok.yml) ===
$repoBase = "https://raw.githubusercontent.com/shariarratul/ycd/main"

Write-Output "=== Downloading YCD files from GitHub ==="
Invoke-WebRequest "$repoBase/launch.ps1" -OutFile "$ycdPath\launch.ps1" -UseBasicParsing
Invoke-WebRequest "$repoBase/server.js" -OutFile "$ycdPath\server.js" -UseBasicParsing
Invoke-WebRequest "$repoBase/package.json" -OutFile "$ycdPath\package.json" -UseBasicParsing
Invoke-WebRequest "$repoBase/package-lock.json" -OutFile "$ycdPath\package-lock.json" -UseBasicParsing
Invoke-WebRequest "$repoBase/run.vbs" -OutFile "$startupPath\run.vbs" -UseBasicParsing

# === Update Ngrok, yt-dlp, ffmpeg ===
Write-Output "=== Updating NGROK | yt-dlp | ffmpeg to latest ==="
ngrok update
yt-dlp -U
choco upgrade ffmpeg -y

# === Install Node dependencies ===
Write-Output "=== Installing Node dependencies ==="
cd $ycdPath
npm install

Write-Output "=== Setup Complete ✅ ==="
