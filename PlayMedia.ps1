## PlayMedia.ps1
Param(
	[ValidateScript({Test-Path $_})]
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=1)]
	[Alias("FolderPath","LiteralPath","Path")]
	[string[]]
	$filePath
)

Add-Type -AssemblyName presentationCore 
$mediaPlayer = New-Object system.windows.media.mediaplayer 
## $path = "X:\My Music\Jay\" 
$files = Get-ChildItem -path $filePath -include *.mp3,*.m4a -recurse 
foreach($file in $files) 
	{ 
		"Playing $($file.fullName)" 
		$mediaPlayer.open([uri]"$($file.fullname)") 
		$mediaPlayer.Play() 
		Start-Sleep -Seconds 10 
		$mediaPlayer.Stop() 
	}