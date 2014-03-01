param([string]$InstallDirectory)

$fileList = @(
    'SharePowerShell.psm1'
)


if ('' -eq $InstallDirectory)
{
    $personalModules = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
    if (($env:PSModulePath -split ';') -notcontains $personalModules)
    {
        Write-Warning "$personalModules is not in `$env:PSModulePath"
    }

    if (!(Test-Path $personalModules))
    {
        Write-Error "$personalModules does not exist"
    }

    $InstallDirectory = Join-Path -Path $personalModules -ChildPath SharePowerShell
}

if (!(Test-Path $InstallDirectory))
{
    mkdir $InstallDirectory | Out-Null
}

$wc = New-Object System.Net.WebClient
$fileList | 
    ForEach-Object {
        $wc.DownloadFile("https://raw.github.com/dfinke/SharePowerShell/master/$_","$installDirectory\$_")
    }