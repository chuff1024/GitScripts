param([string]$message)
$mailRecipients=$mailRecipients
$smtpServer= $smtpServer
$smtpPort= 666
$smtpFrom= "monitors@campbell.local"
$logFile= ".\monitors.log"
$time= Get-Date -Format "yyyy/MM/dd HH:mm:ss"
Write-Host  "$time $message"
Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -From $smtpFrom -To $mailRecipients -Subject $message -WarningAction Ignore
Add-Content -Path $logFile -Value "$time $message"
