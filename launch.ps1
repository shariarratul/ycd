# Navigate to your project folder
Set-Location "C:\Users\CSE\AppData\Local\ycd"

# Start node server in background
Start-Process "node" -ArgumentList "server.js" -WindowStyle Hidden

# Start ngrok in background
Start-Process "ngrok" -ArgumentList "start my-app" -WindowStyle Hidden
