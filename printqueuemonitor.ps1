$serverList= $serverList
$verbose= $false

$host.ui.RawUI.WindowTitle= "Print Queue Monitor"
.\Send-Report.ps1 "Starting print queue monitor..."

while(1)
{
    foreach ($server in $serverList)
    {
        if ($verbose) {Write-Host "getting list of print jobs from $server..."}
        $jobList= Get-CimInstance -ComputerName $server -ClassName win32_printjob
        foreach ($job in $jobList)
        {
            if ($job.TimeSubmitted -lt [datetime]::Now.AddMinutes(-10))
            {
                Write-Host "$(Get-Date -Format "yyyy/MM/dd HH:mm:ss") ""$($job.Document)"" $($job.Owner) $($job.Name) $($job.TimeSubmitted)"
                $job | Remove-CimInstance
            }
            if ($job.TimeSubmitted -lt [datetime]::Now.AddHours(-1))
            {
                .\Send-Report """$($job.Document)"" on $server with owner $($job.Owner) is stuck.  Restarting print queue..."
                Invoke-Command -ComputerName $server -ScriptBlock {Restart-Service Spooler}
                Start-Sleep -Seconds 15
            }
        }
    }
    if ($verbose) {Write-Host "sleeping..."}
    Start-Sleep -Seconds 15
}