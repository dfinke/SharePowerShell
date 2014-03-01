function Send-ISEGist {

$fileName=$psISE.CurrentFile.DisplayName -replace "\*$",""

$content = @"
<#
    This Gist was created by ISEGist
    $(Get-Date)    
#>

"@

    $content += $psISE.CurrentFile.Editor.Text

    $gist = @{
        "public"= $true
        "description"="Description for $($fileName)"
        "files"= @{
            "$($fileName)"= @{
                "content"= $content
            }
        }
    }
    
    $r=Invoke-RestMethod -Uri 'https://api.github.com/gists' -Method Post -Body ($gist | ConvertTo-Json)
    start $r.html_url
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
        $Error.Clear()
        $r=Invoke-RestMethod https://api.github.com/gists/$targetGist
        $fileName=($r.files| Get-Member -MemberType NoteProperty).Name
        $content=$r.files."$fileName".content
        
        $NewFile = $psISE.CurrentPowerShellTab.Files.Add()
        $NewFile.Editor.Text=$content
        $NewFile.Editor.EnsureVisible(1)
    } catch {
        $Error[0].exception
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

Add-MenuItem "_Share PowerShell" $null $null
Add-SubMenuItem "_Share PowerShell" "_Send Gist" { Send-ISEGist } "Alt+S"
Add-SubMenuItem "_Share PowerShell" "_Get Gist"  { Get-ISEGist  } "Alt+G"