# TechSupport powershell-speccy script
# Writen by PipeItToDevNull

#Check if this is being run as admin, this is used to determine if the admin prompt is displayed
$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)


#Define the function used to inform the user of admin. If they choose not to the script will be run without admin.
if ($admin -eq $False) {
Function GUIPAUSE ($Message = "Click Yes or No to run the script with or without admin", $Title = "Continue or Cancel") {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $MsgBox = [System.Windows.Forms.MessageBox]
    $Decision = $MsgBox::Show($Message,$Title,"YesNo", "Information")
    return $Decision
}
$adminRequest = GUIPAUSE -Message "This program will request admin so that it can read CPU temperatures and hard drive health, these are Windows limitations. You may press No to run without these tests. Note: They may be required for assistance." -Title "User Information"
}

#If user approves then prompt UAC and restart script
if ($adminRequest -like "Yes") {
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
     if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
      $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
      Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
      Exit
     }
    }
}

#Check if this is being run as admin, this is used to determine what hardware to poll
$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

#Start recording output
Start-Transcript "TechSupport_Speccy.txt"
Get-Date
Write-Host "`n" -NoNewline

#Define the function used to determine OS version
function Get-OS{
    $OSInfo = Get-WmiObject Win32_OperatingSystem
    $OS = $OSInfo.Version
    return $OS
}
Write-Host "OS: " -NoNewline
Get-OS
Write-Host "`n" -NoNewline

#Define function to get CPU model
function Get-CPU{
    $CPUInfo = Get-WmiObject Win32_Processor
    $CPU = $CPUInfo.Name
    return $CPU
}
Write-Host "CPU: " -NoNewline
Get-CPU
Write-Host "`n" -NoNewline

#Define function to get temperature of CPU
function Get-Temperature {
    $t = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction SilentlyContinue
    $returntemp = @()
    if ($t){
        foreach ($temp in $t.CurrentTemperature) {
            $currentTempKelvin = $temp / 10
            $currentTempCelsius = $currentTempKelvin - 273.15

            $currentTempFahrenheit = (9/5) * $currentTempCelsius + 32

            $returntemp += $currentTempCelsius.ToString() + " C : " + $currentTempFahrenheit.ToString() + " F : " + $currentTempKelvin + "K"  
        }
    }
    else {
        $returntemp = "Not supported"
        }
    return $returntemp
}
Write-Host "CPU Temperature: " -NoNewline
Get-Temperature
Write-Host "`n" -NoNewline

#Define function to get motherboard model
function Get-Mobo{
    $moboBase = Get-WmiObject Win32_BaseBoard
    $moboMan = $moboBase.manufacturer
    $moboMod = $moboBase.product
    $mobo = $moboMan + " | " + $moboMod
    return $mobo
}
Write-Host "Motherboard: " -NoNewline
Get-Mobo
Write-Host "`n" -NoNewline

#Define function to get GPU model
function Get-GPU {
    $GPUbase = Get-WmiObject Win32_VideoController
    $GPUname = $GPUbase.Name
    $GPU= $GPUname + " at " + $GPUbase.CurrentHorizontalResolution + "x" + $GPUbase.CurrentVerticalResolution
    return $GPU
}
Write-Host "Graphics Card: " -NoNewline
Get-GPU
Write-Host "`n" -NoNewline

#Get current users startup tasks and items
function Get-Startup {
    $startBase = Get-CimInstance Win32_StartupCommand
    $startNames = $startBase.Caption
    return $startNames
}
Write-Host "Startup Tasks for user: "
Get-Startup
Write-Host "`n" -NoNewline

#Get current users running processes
function Get-Processes {
    $procBase = Get-Process
    $procTrash = $procBase.ProcessName
    $procClean = $procTrash | select -Unique
    return $procClean
}
Write-Host "Running processes: "
Get-Processes
Write-Host "`n" -NoNewline

#Get system services and states
Write-Host "Services: " -NoNewline
Get-Service | Format-Table

#Get SMART data only if running as admin
if ($admin -eq $true) {
function Get-SMART {
    $smartBase = gwmi -namespace root\wmi -class MSStorageDriver_FailurePredictStatus
    $smartValue = $smartBase | Select InstanceName, PredictFailure | Format-Table
    return $smartValue
}
Write-Host "Basic SMART: " -NoNewline
Get-SMART
}
Stop-transcript

#Call the outputted file from above and then send it to pastebin server
$FilePath = '.\TechSupport_Speccy.txt'
$link = Invoke-WebRequest -ContentType 'text/plain' -Method 'PUT' -InFile $FilePath -Uri 'https://share.dev0.sh/upload' -UseBasicParsing

#Write the link generated by the server to the clipboard and inform the user of how to use it
set-clipboard $link.Content
msg console /server:localhost "The link to share the results is now in your clipboard, just paste into the chat to share it."