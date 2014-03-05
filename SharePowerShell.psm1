function Send-ToGist {
    param(
        [string]$FileName,
        [string]$Content,
        [Switch]$ShowWebPage, 
        [switch]$Private
    )

$content = @"
<#
    This Gist was created by ISEGist
    $(Get-Date)    
#>

"@ + $content

    $gist = @{
        "public"= (-not $Private)
        "description"="Description for $($fileName)"
        "files"= @{
            "$($fileName)"= @{
                "content"= $content
            }
        }
    }
    
    $Uri = 'https://api.github.com/gists'
    if (Test-Path Env:\GITHUB_OAUTH_TOKEN)
    {
        $Uri += "?access_token=$env:GITHUB_OAUTH_TOKEN"
    }
    elseif (Test-Path variable:GITHUB_OAUTH_TOKEN)
    {
        $Uri += "?access_token=$global:GITHUB_OAUTH_TOKEN"
    }
    $r = Invoke-RestMethod -Uri $uri  -Method Post -Body ($gist | ConvertTo-Json)
    
    if($ShowWebPage) {
        start $r.html_url
    } else {
        [PSCustomObject]@{
            FileName = $FileName
            WebPage  = $r.html_url
        }
    }
}

function Send-FileToGist {
    param(
        $FullName,
        [Switch]$ShowWebPage
    )

    $FullName = Resolve-Path $FullName
    $Content = ([System.IO.File]::ReadAllText($FullName))
    Send-ToGist (Split-Path -Leaf $FullName) -Content $Content -ShowWebPage:$ShowWebPage
}

function Send-ISEToGist {
    
    $CurrentFile = $psISE.CurrentFile

    $fileName = $CurrentFile.DisplayName -replace "\*$",""
    
    Send-ToGist -FileName $fileName -Content $CurrentFile.Editor.Text -ShowWebPage
}

function Get-ISEGist {

    [string]$targetGist=[System.Windows.Forms.Clipboard]::GetText()
    
    if([string]::IsNullOrEmpty($targetGist) -or !(Test-Uri $targetGist)) {
        $targetGist=9291292
    }

    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
    $targetGist = [Microsoft.VisualBasic.Interaction]::InputBox("Gist ID or Url", "Gist", $targetGist)

    if($targetGist.Contains("/")) {
        $targetGist = Split-Path -Leaf $targetGist        
    }
    
    try {        
        $r=Invoke-RestMethod https://api.github.com/gists/$targetGist
        $fileName=($r.files| Get-Member -MemberType NoteProperty).Name
        $content=$r.files."$fileName".content
        
        $NewFile = $psISE.CurrentPowerShellTab.Files.Add()
        $NewFile.Editor.Text=$content
        $NewFile.Editor.EnsureVisible(1)
    } catch {
        $_.exception
    }
}

function Test-Uri {
    param($uri)
    
    [Uri]$result=$null
    [Uri]::TryCreate($uri, [System.UriKind]::Absolute, [ref]$result)
}

function Add-MenuItem {
    param(
        [string]$DisplayName, 
        [Scriptblock]$ScriptBlock, 
        [System.Windows.Input.KeyGesture]$ShortCut
    )
        
    $menu=$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where {$_.DisplayName -Match $DisplayName}

    if($menu) {
        [void]$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Remove($menu)
    }

    [void]$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add($DisplayName, $ScriptBlock, $ShortCut)
}

function Add-SubMenuItem {
    param(
        [string]$Root, 
        [string]$SubMenu, 
        [scriptblock]$ScriptBlock, 
        [System.Windows.Input.KeyGesture]$ShortCut
    )

    $menu=$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where {$_.DisplayName -Match $Root}

    [void]$menu.Submenus.Add($SubMenu, $ScriptBlock, $ShortCut)
}

function Get-GitHubOAuthToken {
  [CmdletBinding()]
  param(
    [parameter()]
    [System.Management.Automation.Credential()]
	$Credential = [System.Management.Automation.PSCredential]::Empty,
    
    [parameter()]
    [string]
    $OneTimePassword,

    [parameter()]
    [string]
    $ApplicationName = 'SharePowerShell',

    [parameter()]
    [switch]
    $SetEnvironmentalVariable
  )

  Send-GithubAuthorizationRequest @psboundparameters
}

function New-GitHubOAuthToken {
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [System.Management.Automation.Credential()]
	$Credential = [System.Management.Automation.PSCredential]::Empty,
    
    [parameter()]
    [string]
    $OneTimePassword,

    [parameter()]
    [switch]
    $SetEnvironmentalVariable
  )

    $postData = @{
      scopes = @('gist');
      note = 'SharePowerShell'
    }

    $params = @{
      Method = 'POST';
      ContentType = 'application/json';
      Body = (ConvertTo-Json $postData -Compress)
    }

    Send-GithubAuthorizationRequest @psboundparameters -AdditionalRequestParameters $params
}

function Send-GithubAuthorizationRequest {    
    param(
        [parameter(Mandatory=$true)]
        [System.Management.Automation.Credential()]
	    $Credential = [System.Management.Automation.PSCredential]::Empty,
    
        [parameter()]
        [string]
        $OneTimePassword,

        [parameter()]
        [string]
        $ApplicationName = 'SharePowerShell',

        [parameter()]
        [switch]
        $SetEnvironmentalVariable,

        [parameter()]
        [System.Collections.Hashtable]
        $AdditionalRequestParameters = @{}
    )

    $NetworkCredential = $Credential.GetNetworkCredential()
    $BaseRequestParameters = @{
        Uri = 'https://api.github.com/authorizations';
        Headers = @{
            Authorization = 'Basic ' + [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes("$($NetworkCredential.UserName):$($NetworkCredential.password)")
            )
        }
    }

    $RequestParameters = $BaseRequestParameters + $AdditionalRequestParameters
    
    if ($PSBoundParameters.ContainsKey('OneTimePassword')) {
        $RequestParameters.Headers.Add('X-GitHub-OTP', $OneTimePassword) | out-null
    }

    try {

        $global:GITHUB_OAUTH_TOKEN = (Invoke-RestMethod @RequestParameters) | 
            Where { 
                $date = [DateTime]::Parse($_.created_at).ToString('g')
                Write-Verbose "`nFound: $($_.app.name) - Created $date"
                Write-Verbose "`t$($_.token)`n`t$($_.app.url)"
                $_.app.name -like "$ApplicationName (API)"
            } |
            foreach {
                Write-Verbose "Persisting token for $($_.app.name)"
                $_.token
            }


        if ($SetEnvironmentalVariable)
        {
            Write-Verbose "Creating environmental variable GITHUB_OATH_TOKEN for the current user."
            Write-Verbose "`tSetting the variable to $global:GITHUB_OAUTH_TOKEN"
            $Env:GITHUB_OAUTH_TOKEN = $global:GITHUB_OAUTH_TOKEN
            [Environment]::SetEnvironmentVariable('GITHUB_OAUTH_TOKEN', $global:GITHUB_OAUTH_TOKEN, 'User')
        }    

    }
    catch {
        Write-Error $_
    }
}

if($Host.Name -eq 'Windows PowerShell ISE Host') {
    Add-MenuItem    "_Share PowerShell" $null $null
    Add-SubMenuItem "_Share PowerShell" "_Send Gist" { Send-ISEToGist } "Alt+S"
    Add-SubMenuItem "_Share PowerShell" "_Get Gist"  { Get-ISEGist  } "Alt+G"
}

