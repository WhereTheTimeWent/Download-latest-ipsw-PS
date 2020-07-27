param(
	[string]$DownloadPath, # Optional: Where the .ipsw files get saved, defaults to the current directory + \Downloads\
	[switch]$IgnoreHash # Optional: If set, the file won't be deleted if the hashes don't match
)

# If the scripts wasn't started with the $DownloadPath argument or if the path doesn't exist
if(!($DownloadPath) -or !(Test-Path $DownloadPath)) {
	# Set $DownloadPath to the current directory + \Downloads\
	[string]$DownloadPath = [System.IO.Path]::Combine($PWD.Path, "Downloads")
	# Create directory if it doesn't exist
	if(!(Test-Path $DownloadPath)) {
		mkdir $DownloadPath | Out-Null
	}
}

# Set full path of Devices.txt
$DeviceListFile = [System.IO.Path]::Combine($DownloadPath, "Devices.txt")

# Set devices here - get name from this beautiful site: https://ipsw.me/product/iPhone
# Germany uses GSM
$Devices = @(
	"iPhone12,8", # iPhone SE (2020)
	"iPhone12,5", # iPhone 11 Pro Max
	"iPhone12,3", # iPhone 11 Pro
	"iPhone12,1", # iPhone 11
	"iPhone11,8", # iPhone XR
	"iPhone11,6", # iPhone XS Max
	"iPhone11,2", # iPhone XS
	"iPhone10,6", # iPhone X (GSM)
	"iPhone10,5", # iPhone 8 Plus (GSM)
	"iPhone10,4", # iPhone 8 (GSM)
	"iPhone9,4", # iPhone 7 Plus (GSM)
	"iPhone9,3", # iPhone 7 (GSM)
	"iPhone8,4", # iPhone SE
	"iPhone8,2", # iPhone 6s+
	"iPhone8,1", # iPhone 6s
	"iPhone7,2", # iPhone 6
	"iPhone7,1", # iPhone 6+
	"iPhone6,1", # iPhone 5s (GSM)
	"iPhone5,3" # iPhone 5c (GSM)
)

# For each device in the array $Devices
foreach($Device in $Devices) {
	# Paranoia
	$URL = $null; $Filename = $null; $dlFullFilename = $null; $dlMD5 = $null; $onlineMD5 = $null
	# Build device list
	# Check if file exists, otherwise create it
	if(!(Test-Path $DeviceListFile)) { New-Item -Path $DeviceListFile -ItemType "File" | Out-Null }
	# Check if the device isn't already in the txt file
	if(!(Select-String -Path $DeviceListFile -Pattern $Device -SimpleMatch -Quiet)) {
		# Add device name + tab to text file
		($Device + "`t" + (Invoke-WebRequest ("https://api.ipsw.me/v2.1/" + $Device + "/latest/name")).Content) | Out-File $DeviceListFile -Append
	}
	# Get URL from ipsw.me and check if it suceeded
	$URL = (Invoke-WebRequest ("https://api.ipsw.me/v2.1/" + $Device + "/latest/url")).Content
	if(!($URL)) { Write-Error ("Couldn't get latest link for " + $Device + ". Let's try the next one..."); continue }
	# Get file name from URL
	$Filename = $URL.Substring($URL.LastIndexOf("/") + 1)
	$dlFullFilename = [System.IO.Path]::Combine($DownloadPath, $Filename)
	# Check if the file doesn't exist
	if(!(Test-Path $dlFullFilename)) {
		# File doesn't exist, let's download it
		Write-Host ("Downloading " + $Filename + "...") -ForegroundColor "Cyan"
		(New-Object System.Net.WebClient).DownloadFile($URL, $dlFullFilename)
		# Check if downloaded file exists
		if(Test-Path $dlFullFilename) {
			# Downloaded file exists
			# Get hash from downloaded file
			$dlMD5 = (Get-FileHash -Path $dlFullFilename -Algorithm "MD5").Hash
			# Get hash from ipsw.me
			$onlineMD5 = (Invoke-WebRequest ("https://api.ipsw.me/v2.1/" + $Device + "/latest/md5sum")).Content
			# Check if ipsw.me provided the hash
			if($dlMD5) {
				# Check if both hashes are the same
				if($dlMD5 -eq $onlineMD5) {
					# Yay, everything worked
					Write-Host "Hashes match, downloaded successfully!" -ForegroundColor "Green"
				} else {
					# Oof, hashes don't match
					Write-Error "File downloaded but hashes don't match."
					# Check if hashes should be ignored
					if($IgnoreHash) {
						# Hashes should be ignored, won't delete file
						Write-Host "The file won't get deleted because `$IgnoreHash is true."
					} else {
						# File is faulty, let's delete it
						Write-Host ("Deleting file " + $Filename + " because hashes don't match...") -ForegroundColor "Red"
					}
				}
			} else {
				# ipsw.me didn't provide a hash, won't perform hash check
				Write-Error "Couldn't get MD5 hash from ipsw.me, won't perform hash check."
			}
		} else {
			# Downloaded file doesn't exist
			Write-Error "Couldn't find downloaded file. Run the script again to retry."
		}
	}
}