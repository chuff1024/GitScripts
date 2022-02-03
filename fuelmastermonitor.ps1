$dbpath= "\\$servername\FuelMasterPlus\CCSData\FuelMasterPlus.mdb"
$adOpenForwardOnly= 0
$adLockReadOnly= 1
$verbose= $false

$host.ui.RawUI.WindowTitle= 'FuelMaster Monitor'
.\Send-Report.ps1 "Starting FuelMaster monitor..."

$cn= New-Object -ComObject ADODB.Connection
$rs= New-Object -ComObject ADODB.RecordSet

while (1) 
{
  if ($verbose) {"Opening database connection..."}
  if (!(Test-Path $dbpath)) {.\Send-Report.ps1 "fuelmastermonitor could not open $dbpath"}
  $cn.Open("Provider= Microsoft.ACE.OLEDB.12.0;Data Source= $dbpath")
  $rs.Open("SELECT [SITENAME],[ip] FROM [Site]", $cn, $adOpenForwardOnly, $adLockReadOnly)
  $rs.MoveFirst()
  do {
    if ($verbose) {Write-Host "checking $($rs.Fields.Item("SITENAME").Value) fuel pump at $($rs.Fields.Item("ip").Value)"}
    if (!(Test-Connection $rs.Fields.Item("ip").Value -TcpPort 23)) {
      .\Send-Report.ps1 "Could not contact $($rs.Fields.Item("SITENAME").Value) fuel pump"
      }
    $rs.MoveNext()
    } while ($rs.Fields.Item("ip").Value)
  $cn.Close()
  if ($verbose) {Write-Host "sleeping..."}
  Start-Sleep -Seconds 3600
}