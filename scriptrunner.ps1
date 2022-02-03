$fileFilter= '*monitor.ps1'
$verbose= $true

$host.UI.RawUI.WindowTitle= "Script Monitor"
$path= Get-Location
Write-Host ""
if ($verbose) {Write-Host "we're at $path"}
$oldScriptList= Get-ChildItem $fileFilter
if ($verbose) {Write-Host $oldScriptList}

while (1)
{
    $newScriptList= Get-ChildItem $fileFilter
    $procList= Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*monitor*"}
    foreach ($script in $newScriptList)
    {
        if (!($procList.CommandLine -like "*$($script)*"))
        {
            if ($verbose) {Write-Host "starting $script..."}
            Start-Process -FilePath pwsh -ArgumentList $script.FullName
            continue
        }
        if ($script.LastWriteTime -ne ($oldScriptList | Where-Object {$_.Name -like $script.Name}).LastWriteTime)
        {
            if ($verbose) {Write-Host "restarting $script"}
            Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*$($script.Name)*"} | Stop-Process
            Start-Sleep -Seconds 5
            Start-Process -FilePath pwsh -ArgumentList $script.FullName
            continue
        }
    }
    foreach ($script in $oldScriptList)
    {
        if (!($newScriptList.Name -like $script.Name))
        {
            if ($verbose) {Write-Host "$script is gone.  shutting down the process..."}
            Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*$($script.Name)*"} | Stop-Process
        }
    }
    $oldScriptList= $newScriptList
    Start-Sleep  -Seconds 5
}