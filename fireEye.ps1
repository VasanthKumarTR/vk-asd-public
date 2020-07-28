$url= "https://centralus206624asdjackfa.blob.core.windows.net/windows-2016-template/IMAGE_HX_AGENT_WIN_30.19.6.zip?sp=r&st=2020-07-21T18:07:12Z&se=2020-07-29T02:07:12Z&spr=https&sv=2019-10-10&sr=b&sig=q6FKbcYATeqtpX1RUJO%2F4jC5f38a%2BqkV1XHSUVunTXc%3D"
$zipfile= "C:\Windows\temp\fireeye_agent.zip"
$outpath= "C:\Windows\temp\fireeye_agent"
$registeragent = "C:\Windows\temp\enable_fireeye.bat"

Write-Host "Downloading Fireeye Agent"
(New-Object System.Net.WebClient).DownloadFile($url, $zipfile)

Write-Host "Unzipping Fireeye Agent"
Expand-Archive -LiteralPath $zipfile -DestinationPath $outpath

Write-Host "Installing Fireeye Agent"
Start-Process msiexec.exe -Wait -ArgumentList '/i C:\Windows\Temp\fireeye_agent\xagtSetup_30.19.6_universal.msi INSTALLSERVICE=2'

# Show scheduled task history
$logName = 'Microsoft-Windows-TaskScheduler/Operational'
$log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logName
$log.IsEnabled=$true
$log.SaveChanges()

Write-Host "Adding Fireeye Agent Task"
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Delay = 'PT1M'
$batchcommands = @'
cmd /c "C:\Program Files (x86)\FireEye\xagt\xagt.exe --mode SERVICE" -r
'@
Set-Content -Path $registeragent -Value $batchcommands -Encoding ASCII

$action = New-ScheduledTaskAction -Execute $registeragent
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType S4U -RunLevel Highest
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

Register-ScheduledTask -TaskName "Enable Fireeye Agent" -InputObject $task

#If you have a script that will cause a reboot, then install applications and run scripts, you can schedule the reboot using a Windows Scheduled Task, or use tools such as DSC, Chef, or Puppet extensions.
$Params = @{
    Action = (New-ScheduledTaskAction -Execute "powershell" -Argument "-NoProfile Restart-Computer -force")
    Trigger = (New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(120))
    Principal = $principal
    TaskName = 'Fireeye Restart'
    Description = 'Restart to complete Fireeye configuration'
  }
  Register-ScheduledTask @Params
