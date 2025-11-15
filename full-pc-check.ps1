full-pc-check.ps1 {

Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🧠 DEVNOX IT - FULL PC CHECKUP v2"
Write-Host "========================================" -ForegroundColor Cyan
Start-Sleep -Milliseconds 500

# --------------------------
# SYSTEM INFO
# --------------------------
Write-Host "`n💻 SYSTEM INFO" -ForegroundColor Yellow
$pc = Get-ComputerInfo
$cpu = Get-WmiObject Win32_Processor
$gpu = Get-WmiObject Win32_VideoController | Select-Object -First 1
$os = Get-WmiObject Win32_OperatingSystem
$bios = Get-WmiObject Win32_BIOS
$baseboard = Get-WmiObject Win32_BaseBoard
$disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"

Write-Host "🌐 PC Name: $env:COMPUTERNAME"
Write-Host "🏢 Manufacturer: $($pc.CsManufacturer)"
Write-Host "🖥 Model: $($pc.CsModel)"
Write-Host "🧠 CPU: $($cpu.Name)"
Write-Host "🎮 GPU: $($gpu.Name)"
Write-Host "📀 OS: $($os.Caption) $($os.OSArchitecture)"
Write-Host "🔑 BIOS Serial: $($bios.SerialNumber)"
Write-Host "🖧 Baseboard Serial: $($baseboard.SerialNumber)"

# --------------------------
# RAM STATUS
# --------------------------
Write-Host "`n📦 MEMORY (RAM)" -ForegroundColor Yellow
$totalRAM = [math]::Round($pc.CsTotalPhysicalMemory / 1GB,2)
$usedRAM = $totalRAM - [math]::Round($os.FreePhysicalMemory / 1MB,2)
$ramUsagePercent = [math]::Round(($usedRAM/$totalRAM)*100)

Write-Host "💾 Total RAM: $totalRAM GB"
Write-Host "📊 Used RAM: $usedRAM GB ($ramUsagePercent`%)"
Write-Host "📉 Free RAM: $([math]::Round($os.FreePhysicalMemory / 1MB,2)) GB"

# --------------------------
# DISK STATUS
# --------------------------
Write-Host "`n🗄 STORAGE" -ForegroundColor Yellow
$diskReport = @()
foreach ($disk in $disks) {
    $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace)/1GB,2)
    $totalGB = [math]::Round($disk.Size/1GB,2)
    $freeGB = [math]::Round($disk.FreeSpace/1GB,2)
    $usagePercent = [math]::Round(($usedGB/$totalGB)*100)
    $diskReport += [PSCustomObject]@{
        Drive = $disk.DeviceID
        Volume = $disk.VolumeName
        UsedGB = $usedGB
        FreeGB = $freeGB
        TotalGB = $totalGB
        Usage = $usagePercent
    }
}
$diskReport | Format-Table -AutoSize

# --------------------------
# TEMPERATURE CHECK
# --------------------------
Write-Host "`n🌡 TEMPERATURE STATUS" -ForegroundColor Yellow
Try {
    $tempSensors = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi"
    foreach ($t in $tempSensors) {
        $c = [math]::Round(($t.CurrentTemperature /10 - 273.15),1)
        Write-Host "Sensor: $($t.InstanceName)  Temp: $c °C"
    }
} Catch { Write-Host "Temperature sensors not available." -ForegroundColor DarkGray }

# --------------------------
# PERFORMANCE
# --------------------------
Write-Host "`n⚙ PERFORMANCE STATUS" -ForegroundColor Yellow
$cpuUsage = (Get-Counter "\\Processor(_Total)\\% Processor Time").CounterSamples.CookedValue
$cpuUsage = [math]::Round($cpuUsage,1)

$diskUsage = ($diskReport | Measure-Object Usage -Maximum).Maximum
$score = 100
if ($cpuUsage -gt 80) { $score -= 20 }
if ($ramUsagePercent -gt 85) { $score -= 20 }
if ($diskUsage -gt 90) { $score -= 20 }

Write-Host "CPU Load: $cpuUsage %"
Write-Host "RAM Usage: $ramUsagePercent %"
Write-Host "Max Disk Usage: $diskUsage %"

# --------------------------
# NETWORK SPEED TEST (optional)
# --------------------------
Write-Host "`n🌐 NETWORK TEST (ping google.com)" -ForegroundColor Yellow
$ping = Test-Connection -ComputerName google.com -Count 4 -Quiet:$false
$avgPing = [math]::Round(($ping | Measure-Object ResponseTime -Average).Average,1)
Write-Host "Average Ping: $avgPing ms"

# --------------------------
# HEALTH SCORE & VISUAL
# --------------------------
Write-Host "`n📊 SYSTEM HEALTH SCORE" -ForegroundColor Magenta
if ($score -ge 90) { Write-Host "🟢 Excellent ($score/100)" -ForegroundColor Green }
elseif ($score -ge 70) { Write-Host "🟡 Good ($score/100)" -ForegroundColor Yellow }
else { Write-Host "🔴 Poor ($score/100)" -ForegroundColor Red }

# --------------------------
# VISUAL BAR FUNCTION
# --------------------------
function Bar($value) {
    $filled = "".PadLeft([math]::Round($value/5),"█")
    $empty = "".PadLeft(20-[math]::Round($value/5),"░")
    return "$filled$empty"
}

Write-Host "`n📈 VISUAL LOAD STATUS"
Write-Host "CPU: " (Bar($cpuUsage)) "$cpuUsage`%"
Write-Host "RAM: " (Bar($ramUsagePercent)) "$ramUsagePercent`%"
Write-Host "Disk: " (Bar($diskUsage)) "$diskUsage`%"

# --------------------------
# FINAL REPORT SAVE
# --------------------------
$reportPath = "$env:USERPROFILE\Desktop\PC_Health_Report.txt"
Write-Host "`n💾 Saving report to Desktop: $reportPath" -ForegroundColor Cyan

$report = @"
DEVNOX IT FULL PC CHECKUP v2
=============================
PC Name: $env:COMPUTERNAME
Manufacturer: $($pc.CsManufacturer)
Model: $($pc.CsModel)
CPU: $($cpu.Name)
GPU: $($gpu.Name)
OS: $($os.Caption) $($os.OSArchitecture)
RAM: $totalRAM GB (Used: $usedRAM GB)
Disk Usage: Max $diskUsage%
CPU Load: $cpuUsage%
Average Ping: $avgPing ms
Health Score: $score/100
"@

$report | Out-File $reportPath

Write-Host "`n✔ FULL CHECKUP COMPLETE!" -ForegroundColor Green
Write-Host "Report saved to Desktop." -ForegroundColor Cyan
}
