function Send-ToGist {
    param(
        [string]$FileName,
        [string]$Content,
        [Switch]$ShowWebPage
    )

$content = @"
<#
    This Gist was created by ISEGist
    $(Get-Date)    
#>

"@ + $content

    $gist = @{
        "public"= $true
        "description"="Description for $($fileName)"
        "files"= @{
            "$($fileName)"= @{
                "content"= $content
            }
        }
    }
    
    $r = Invoke-RestMethod -Uri 'https://api.github.com/gists' -Method Post -Body ($gist | ConvertTo-Json)
    
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
        Write-Error $_.exception
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

if($Host.Name -eq 'Windows PowerShell ISE Host') {
    Add-MenuItem    "_Share PowerShell" $null $null
    Add-SubMenuItem "_Share PowerShell" "_Send Gist" { Send-ISEToGist } "Alt+S"
    Add-SubMenuItem "_Share PowerShell" "_Get Gist"  { Get-ISEGist  } "Alt+G"
}