$verbose= $false

$sqlServer= $sqlServer
$sqlDatabase= $sqlDatabase
$lastServerRestartDate= Get-Date
$restartInterval= 2  #restart interval in days

$host.ui.RawUI.WindowTitle= 'Camera System Monitor'
.\Send-Report.ps1 "Starting security camera monitor script..."

while (1) 
{
  if ($verbose) {Write-Host "getting camera list..."}
  $cameraList= Invoke-Sqlcmd -ServerInstance $sqlServer -Database $sqlDatabase -Query "SELECT Servers.ServerName,Cameras.CameraName,Cameras.IPAddress FROM Cameras INNER JOIN Servers ON Cameras.ServerID = Servers.ServerID;"
  if ($verbose) {Write-Host "getting server list..."}
  $serverList= Invoke-Sqlcmd -ServerInstance $sqlServer -Database $sqlDatabase -Query "SELECT ServerName FROM Servers"
  if ($verbose) {Write-Host "getting error list..."}
  $errorList= Invoke-Sqlcmd -ServerInstance $sqlServer -Database $sqlDatabase -Query "SELECT System_Log.LogTime,Servers.ServerName,System_Log.LogMsg FROM System_Log INNER JOIN Servers ON System_Log.ServerID = Servers.ServerID WHERE System_Log.LogTime > DATEADD(hh,-1,SYSDATETIME()) AND (System_Log.LogMsg LIKE 'Cannot%')"
  foreach ($camera in $cameraList) 
  {
    if ($verbose) {Write-Host "pinging camera at $($camera.IPAddress)"}
    if (!(Test-Connection $camera.IPAddress -Quiet -TcpPort 80)) 
    {
      .\Send-Report.ps1 "Could not ping $($camera.CameraName) on $($camera.ServerName)"
    }
  }
  foreach ($err in $errorList) 
  {
    if ($verbose) {Write-Host "sending error $($err.LogMsg)"}
    .\Send-Report.ps1 "$($err.ServerName) $($err.LogMsg)"
  }
  foreach ($server in $serverList)
  {
    if ($verbose) {Write-Host "checking server $($server.ServerName)"}
    if (Test-Connection -ComputerName $server.ServerName -Quiet -TcpPort 445) 
    {
      if ((Invoke-Command -ComputerName $server.ServerName -Scriptblock {Get-Service -ServiceName VIEntService}).Status -ne 'Running') 
      {
        .\Send-Report.ps1 "Server process on $($server.ServerName) not running"
      }
    }
    else 
    {
      .\Send-Report.ps1 "Could not contact $($server.ServerName)"
    }
  }
  if ((Get-Date) -gt $lastServerRestartDate.AddDays($restartInterval)) 
  {
    $lastServerRestartDate= Get-Date
    foreach ($server in $serverList) 
    {
      Invoke-Command -ComputerName $server.Servername -ScriptBlock {Restart-Service vientservice}
    }
   }
   Start-Sleep -Seconds 3600
 }