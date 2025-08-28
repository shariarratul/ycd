# ===============================
#   YCD Auto-Setup Script
# ===============================

# === Detect PC Username Automatically ===
$userName = $env:USERNAME
Write-Output "Detected username: $userName"

# === Prompt for Ngrok Auth Token and Domain ===
$ngrokAuthToken = Read-Host "Enter your Ngrok Auth Token"
$ngrokDomain = Read-Host "Enter your Ngrok Domain (e.g., mydomain.ngrok.io)"

# === Define Paths ===
$ngrokConfigPath = "C:\Users\$userName\AppData\Local\ngrok"
$ycdPath = "C:\Users\$userName\AppData\Local\ycd"
$startupPath = [Environment]::GetFolderPath("Startup")

# === Ensure folders exist ===
$paths = @($ngrokConfigPath, $ycdPath)
foreach ($path in $paths) {
    if (-not (Test-Path $path)) {
        Write-Output "Creating folder: $path"
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    } else {
        Write-Output "Folder already exists: $path"
    }
}

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
$files = @("launch.ps1","server.js","package.json","package-lock.json","run.vbs")
foreach ($file in $files) {
    $outPath = if ($file -eq "run.vbs") { Join-Path $startupPath $file } else { Join-Path $ycdPath $file }
    Invoke-WebRequest "$repoBase/$file" -OutFile $outPath -UseBasicParsing
    Write-Output "Downloaded: $file"
}

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
