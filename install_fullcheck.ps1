# ==============================
# DEVNOX IT Full PC Check Installer
# ==============================

# Raw script URL
$scriptURL = "https://git.io/JF9Tb"

# Destination path in user's PowerShell profile folder
$dest = "$env:USERPROFILE\Documents\WindowsPowerShell\full-pc-check.ps1"

# Download the script
Invoke-WebRequest -Uri $scriptURL -OutFile $dest -UseBasicParsing

# Add to PowerShell profile if not already present
if (!(Select-String -Path $PROFILE -Pattern "full-pc-check.ps1")) {
    Add-Content $PROFILE "`n. $dest"
}

# Reload profile
. $PROFILE

Write-Host "`n✅ Installation complete!"
Write-Host "You can now run 'fullcheck_v2' anytime from PowerShell." -ForegroundColor Green
