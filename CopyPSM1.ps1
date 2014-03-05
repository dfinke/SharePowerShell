cls

$destination = Split-Path (Get-Module -ListAvailable sharepowershell).RootModule

Copy-Item .\SharePowerShell.psm1 $destination -Verbose 