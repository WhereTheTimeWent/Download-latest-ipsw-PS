# Download-latest-ipsw
Downloads the latest .ipsw files from ipsw.me with PowerShell. Only downloads if there's a newer file online. Checks hashes.

Default download directory is the current directory + \Downloads\\.

# Parameters
> -DownloadPath

Accepts a string of an alternative download path - directory has to exist.


> -IgnoreHash

Doesn't delete .ipsw files if the hashes don't match.





# How to run it on Windows
1. Launch PowerShell with administrator privileges, type 
```
Set-ExecutionPolicy RemoteSigned
```
2. Launch the script by right clicking it or by launching powershell.exe with parameters, e.g.
```
powershell.exe -File "C:\Path\To\File\ipsw_downloader.ps1
```
