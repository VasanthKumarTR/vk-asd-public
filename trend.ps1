$url= "https://files.trendmicro.com/products/deepsecurity/en/10.0/Agent-Windows-10.0.0-2797.x86_64.zip"
$zipfile= "C:\Windows\temp\deep_security_agent.zip"
$outpath= "C:\Windows\temp\deep_security_agent"
$registeragent = "C:\Windows\temp\enable_dsa.bat"

Write-Host "Downloading Deep Security Agent"
(New-Object System.Net.WebClient).DownloadFile($url, $zipfile)

Write-Host "Unzipping Deep Security Agent"
Expand-Archive -LiteralPath $zipfile -DestinationPath $outpath

Write-Host "Installing Deep Security Agent"
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\Windows\Temp\deep_security_agent\Agent-Core-Windows-10.0.0-2797.x86_64.msi /quiet'

# Show scheduled task history
$logName = 'Microsoft-Windows-TaskScheduler/Operational'
$log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
$log.IsEnabled=$true
$log.SaveChanges()

Write-Host "Adding Enable Deep Security Agent Task"
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Delay = 'PT1M'
$batchcommands = @'
cmd /c "C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd" -r
cmd /c "C:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd" -a dsm://TrendDSM-DS-DSMELB-6BXKCUVFMX54-1124567102.us-east-1.elb.amazonaws.com:4120/
'@
Set-Content -Path $registeragent -Value $batchcommands -Encoding ASCII

$action = New-ScheduledTaskAction -Execute $registeragent
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType S4U -RunLevel Highest
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

Register-ScheduledTask -TaskName "Enable Deep Security Agent" -InputObject $task

#If you have a script that will cause a reboot, then install applications and run scripts, you can schedule the reboot using a Windows Scheduled Task, or use tools such as DSC, Chef, or Puppet extensions.
$Params = @{
    Action = (New-ScheduledTaskAction -Execute "powershell" -Argument "-NoProfile Restart-Computer -force")
    Trigger = (New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(120))
    Principal = $principal
    TaskName = 'Trend Restart'
    Description = 'Restart to complete Trend configuration'
  }
  Register-ScheduledTask @Params
