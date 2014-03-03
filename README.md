Share PowerShell
=

From ISE
-
This PowerShell module, `Import-Module SharePowerShell`, lets you quickly post the current file you are editing in ISE to a GitHub Gist.

It also lets you retrieve a gist as well. Creating a new file on the fly in the ISE editor, and adding the file contents of the gist.

From The Command Line
-

This same module, `Import-Module SharePowerShell`, lets you post a file to a GitHub Gist.

```powershell
Send-FileToGist c:\test.ps1 -Show
```

Install
-
```powershell
iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/dfinke/SharePowerShell/master/install.ps1')
```

ISE Video
- 

![image](https://raw.github.com/dfinke/SharePowerShell/master/images/HowItWorks.gif)

Command Line Video
-
![image](https://raw.github.com/dfinke/SharePowerShell/master/images/HowItWorksCmdLine.gif)
