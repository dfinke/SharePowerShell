Share PowerShell
=
This PowerShell module lets you quickly post the current file you are editing in ISE to a GitHub Gist.

It also lets you retrieve a gist as well. Creating a new file on the fly in the ISE editor, and adding the file contents of the gist.

Install
-
```powershell
iex (new-object System.Net.WebClient).DownloadString('https://raw.github.com/dfinke/SharePowerShell/master/Install.ps1')
```

Video
-

![image](https://raw.github.com/dfinke/SharePowerShell/master/images/HowItWorks.gif)