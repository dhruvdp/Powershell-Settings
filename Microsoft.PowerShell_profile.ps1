function prompt {
	# this line is used by "z" to update the reference list of folders
    Update-NavigationHistory $pwd.Path
    # this prompt function chops off the path to fit within 20 characters
    # $loc = Resize-Path (Get-Location)
    $loc = (Get-Location)
    $tail = ""
    if($loc.ToString().length -lt 20) {
      $currpath = ($loc)
    } else {
      $tail = Split-Path -leaf -path $loc
      $currpath = $loc.ToString().substring(0,$loc.ToString().IndexOf("\",3)+1) + "...\" + $tail
	}

		$head = $env:COMPUTERNAME + "@" + $env:USERNAME + ": " + $currpath

		$p = $head.ToString().Replace("\","/")
    
    "$p $_$ "
}

function Resize-Path {
  Param( 
          [ValidateScript({Test-Path $_ -PathType 'Container'})] 
          [string] 
          $Path 
  ) 
  $tail = ""
  if($Path.ToString().length -lt 20) {
    $currpath = ($Path)
  } else {
    $tail = Split-Path -leaf -path ($Path)
    $pathSegments = Split-Path -parent -path $Path.ToString().Split('\')
    $currpath = $Path.ToString().substring(0,$Path.ToString().IndexOf("\",3)+1) + "...\" + $tail
  }

}
<#
function prompt { 
	$p = $loc.ToString().substring(0,$loc.ToString().IndexOf("\",3)+1)+"...\"+$tail.Replace("\","/") 
	"$p>" 
}

# put your logic here for getting prompt color by machine name
function GetMachineColor($computerName)
{
   [ConsoleColor]::Green
}

# put your logic here for getting prompt color by machine name
function GetUserColor($userName)
{
   [ConsoleColor]::Magenta
}

function GetComputerName
{
  # if you want FQDN
  # $ipProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
  # "{0}.{1}" -f $ipProperties.HostName, $ipProperties.DomainName

  # if you want host name only
  $env:computername
}

function prompt
{
  $cn = GetComputerName

  # write computer name with color
  Write-Host "[${cn}]:~" -Fore (GetMachineColor $cn) -NoNew

  $un = $env:username
  Write-Host "${un} " -Fore (GetUserColor $un) -NoNew

  # generate regular prompt you would be showing
  $defaultPrompt = "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "

  # generate backspaces to cover [computername]: pre-prompt printed by powershell
  $backspaces = "`b" * ($cn.Length + 4) + "`b" * ($un.Length + 4)

  # compute how much extra, if any, needs to be cleaned up at the end
  $remainingChars = [Math]::Max(($cn.Length + 4) - $defaultPrompt.Length, 0)
  $tail = (" " * $remainingChars) + ("`b" * $remainingChars)

  "${backspaces}${defaultPrompt}$_${tail}"
}
#>

function Set-EmptyFile {
    param(  [parameter(Mandatory = $true)]            
         [ValidateNotNullOrEmpty()]            
            [string] $targetFile)
            
    <# Set-Content -Path ($args[0]) -Value ($null) #>
	if (Test-Path ($targetFile)) {
		Set-Timestamp $targetFile
	} else {
		New-Item -ItemType file $targetFile
	} 
}

function Set-Timestamp {
    <# To update the timestamp of a file: #>
    ($args[0]).LastWriteTime = Get-Date
}

<#
    .Synopsis
        Sets location to the first parent directory that whose name starts with the given target dir.
    .Description
        Searches upwards to the root drive.
        If target dir is not found, a message is emitted to the console
    .Example
        cd c:\user\joeshmoe\Documents 
        C:\user\joeshmoe\Documents>
        Set-LocationTo us 
        C:\user>
#>            
            
function Set-LocationTo {            
    param(  [parameter(Mandatory = $true)]            
         [ValidateNotNullOrEmpty()]            
            [string] $targetDir)            
            
    $dirs = (pwd).Path.Split('\')            
    for($i = $dirs.Length - 1; $i -ge 0; $i--) {            
        if ($dirs[$i].ToLower().StartsWith($targetDir.ToLower())) {            
            $targetIndex = $i            
            break            
        }            
    }            
    if($targetIndex -eq 0) {             
        Write-Host "Unable to resolve $targetDir"             
        return            
    }            
            
    $targetPath = ''            
    for($i = 0; $i -le $targetIndex; $i++) {            
       $targetPath += $dirs[$i] + '\'             
    }            
            
    Set-Location $targetPath            
}            
<#
.. # goes to parent folder
 .. Foo # goes to sibling folder named ‘Foo’
#>

function GoUp($path) {
    Set-Location -path "..\$path"
}
function GoUpUp($path) {
    Set-Location -path "..\..\$path"
}
function GoHome($path) {
    Set-Location -path "$env:HOME\$path"
}

function Get-DirSize
{
  param ($dir)
  $bytes = 0
  $count = 0

  Get-Childitem $dir | Foreach-Object {
    if ($_ -is [System.IO.FileInfo])
    {
      $bytes += $_.Length
      $count++
    }
  }

  Write-Host "`n    " -NoNewline

  if ($bytes -ge 1KB -and $bytes -lt 1MB)
  {
    Write-Host ("" + [Math]::Round(($bytes / 1KB), 2) + " KB") -ForegroundColor "White" -NoNewLine
  }
  elseif ($bytes -ge 1MB -and $bytes -lt 1GB)
  {
    Write-Host ("" + [Math]::Round(($bytes / 1MB), 2) + " MB") -ForegroundColor "White" -NoNewLine
  }
  elseif ($bytes -ge 1GB)
  {
    Write-Host ("" + [Math]::Round(($bytes / 1GB), 2) + " GB") -ForegroundColor "White" -NoNewLine
  }
  else
  {
    Write-Host ("" + $bytes + " bytes") -ForegroundColor "White" -NoNewLine
  }
  Write-Host " in " -NoNewline
  Write-Host $count -ForegroundColor "White" -NoNewline
  Write-Host " files"

}

function Get-DirWithSize
{
  param ($dir)
  Get-Childitem $dir
  Get-DirSize $dir
}

function Add-Path {
  <#
    .SYNOPSIS
      Adds a Directory to the Current Path
    .DESCRIPTION
      Add a directory to the current path.  This is useful for 
      temporary changes to the path or, when run from your 
      profile, for adjusting the path within your powershell 
      prompt.
    .EXAMPLE
      Add-Path -Directory "C:\Program Files\Notepad++"
    .PARAMETER Directory
      The name of the directory to add to the current path.
  #>

  [CmdletBinding()]
  param (
    [Parameter(
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='What directory would you like to add?')]
    [Alias('dir')]
    [string[]]$Directory
  )

  PROCESS {
    $Path = $env:PATH.Split(';')

    foreach ($dir in $Directory) {
      if ($Path -contains $dir) {
        Write-Verbose "$dir is already present in PATH"
      } else {
        if (-not (Test-Path $dir)) {
          Write-Verbose "$dir does not exist in the filesystem"
        } else {
          $Path += $dir
        }
      }
    }

    $env:PATH = [String]::Join(';', $Path)
  }
}
#Add-Path -Directory “C:\Program Files (x86)\Notepad++”
#Set-Alias edit notepad++.exe

#Add-Path –Directory “C:\Program Files\Splunk\bin”
#Add-Path –Directory “C:\Program Files (x86)\PuTTY”

# git related functions
function get-gitbranch { git branch }
function get-gitbranchall { git branch -a }
function get-gitconfiglist { git config -l }
function get-gitlog { git log }
function get-gitlogpretty { git lg-pretty }
function get-gitlogplaintext { git lg-plaintext }
function get-gitlogalt { git lg-alt }
function get-gitresethard { git reset --hard }
function get-gitstash { git stash -l }
function get-gitstatus2 { git status }
function get-gitsvnfetch { git svn fetch }
function get-gitsvnrebase { git svn rebase }
function get-gitsvndcommit { git svn dcommit }

# php/symfony/doctrine related functions
function php-app-console { php app/console $args }
function php-generate { php app/console generate:$args }
function php-doctrine-migration-diff { php app/console doctrine:migration:diff $args }
function php-doctrine-migration-migrate { php app/console doctrine:migration:migrate $args }
function php-cache-clear { php app/console cache:clear }
function php-cache-warmup { php app/console cache:warmup }
function php-deploy { php deployer.phar }
function php-deploy-development { php deployer.phar deploy ny_development }
function php-deploy-staging { php deployer.phar deploy ny_staging }
function php-deploy-production { php deployer.phar deploy ny_production }
# z - folder jumper related functions
# z - update working directory
function z-uwd { Update-NavigationHistory $pwd.Path }
# ssh / firehost related functions
function ssh-firehost { ssh 146.88.97.168 -P 22 -l jay -i ..\..\.ssh\id_rsa.ppk }

####################################
# end of functions
####################################
# start of initialization code
####################################

## Set the profile directory first, so we can refer to it from now on.
# Set-Variable ProfileDir = (Split-Path -Parent $MyInvocation.MyCommand.Path) -Option AllScope
Set-Variable ProfileDir (Split-Path -Parent $MyInvocation.MyCommand.Path) -Option AllScope
## Set the script directory
Set-Variable ScriptDir (Split-Path -Parent $MyInvocation.MyCommand.Path) -Option AllScope

$env:cdpath = "$env:HOME\Downloads\_Categories\;c:\dev;$env:HOME\Downloads"
$env:Path += ";$(Split-Path $PROFILE);$env:HOME\Downloads\_Categories\PowerShell" 
## I add my "Scripts" directory and all of its direct subfolders to my PATH
$env:Path += ";$(Split-Path $PROFILE)\Scripts"
#$env:Path = Get-ChildItem $ProfileDir\Script[s],$ProfileDir\Scripts\* | 
#               Where-Object { $_.PsIsContainer } | 
#               ForEach-Object { $_.FullName } | 
#               Join ";" -append $ENV:PATH -unique

# dot source the directory jumper and file dir/ls colorizer
# . "$env:HOME\Documents\WindowsPowerShell\posz.ps1"
. "$env:HOME\Documents\WindowsPowerShell\git-dir.ps1"

Import-Module z
Set-Alias z Search-NavigationHistory
Set-Alias uz z-uwd

# set the aliases that we like
Set-Alias -Name cdto -Value Set-LocationTo
Set-Alias -Name touch -Value Set-EmptyFile
Set-Alias -Name subl -Value "C:\Program Files\Sublime Text 3\sublime_text.exe"
Set-Alias -name n -Value notepad.exe
Set-Alias -name npp -Value "C:\Program Files (x86)\Notepad++\notepad++.exe" 
<#Set-Alias -Name man -Value less.exe#>
Set-Alias -Name ".." -Value GoUp 
Set-Alias -Name "cd.." -Value GoUp
Set-Alias -Name "..." -Value GoUpUp
Set-Alias -Name home -Value GoHome
Set-Alias -Name pp -Value Edit-DTWCleanScript
Set-Alias -Name addp -Value Add-Path
# git aliases
Set-Alias -Name g -Value Git.exe
Set-Alias -Name gb -Value get-gitbranch
Set-Alias -Name gba -Value get-gitbranchall
Set-Alias -Name gcl -Value get-gitconfiglist 
Set-Alias -Name glg -Value get-gitlog
Set-Alias -Name glgp -Value get-gitlogpretty
Set-Alias -Name glgt -Value get-gitlogplaintext
Set-Alias -Name glga -Value get-gitlogalt
Set-Alias -Name grh -Value get-gitresethard
Set-Alias -Name gs -Value get-gitstatus2
Set-Alias -Name gst -Value get-gitstash
Set-Alias -Name gsvnf -Value get-gitsvnfetch
Set-Alias -Name gsvnr -Value get-gitsvnrebase
Set-Alias -Name gsvnc -Value get-gitsvndcommit
# php aliases
Set-Alias -Name phpac -Value php-app-console
Set-Alias -Name phpgen -Value php-generate
Set-Alias -Name phpmd -Value php-doctrine-migration-diff
Set-Alias -Name phpmm -Value php-doctrine-migration-migrate
Set-Alias -Name phpcc -Value php-cache-clear
Set-Alias -Name phpcw -Value php-cache-warmup
Set-Alias -Name dep -Value php-deploy
Set-Alias -Name depdev -Value php-deploy-development
Set-Alias -Name depstage -Value php-deploy-staging
Set-Alias -Name depprod -Value php-deploy-production
# firehost connection aliases
Set-Alias -Name ss -Value ssh-firehost

## I determine which modules to pre-load hesolire (in this SIGNED script)
$AutoModules = 'PsGet', 'PoshCode', 'PSCX', 'DTW.PS.PrettyPrinterV1.psd1'
## 'PSReadline', 'Autoload', 'Authenticode', 'HttpRest', 'Strings', 'ResolveAliases', 'PowerTab', 'sqlps', 
###################################################################################################
## Preload all the modules in AutoModules, printing out their names in color based on status
## No errors while loading modules (I will save them and print them out later)
$ErrorActionPreference = "SilentlyContinue"
Write-Host "Loading Modules: " -Fore Cyan -NoNewLine
$AutoRunErrors = @()
ForEach( $module in $AutoModules ) {
   Import-Module $module -EA SilentlyContinue -EV +script:AutoRunErrors
   if($?) {  
      Write-Host "$module " -fore Cyan -NoNewLine  
   } else {
      Write-Host "$module " -fore Red -NoNewLine
   }
}
###################################################################################################

Write-Host
$ErrorActionPreference = "Continue"
# Write out the error messages if we missed loading any modules
if($AutoRunErrors) { $AutoRunErrors | Out-String | Write-Host -Fore Red }

<#
Import-Module PsGet
Import-Module pssql
# Import-Module PSCX
Import-Module "C:\Users\jr286576\Documents\WindowsPowerShell\Modules\DTW.PS.PrettyPrinterV1.psd1"
Import-Module DTW.PS.FileSystem.Encoding.psm1
Import-Module DTW.PS.PrettyPrinterV1.psm1
#>

# Load posh-git example profile
. "$env:HOME\Documents\Github\posh-git\profile.example.ps1"

# dot source the new-command-wrapper
#. '$env:HOME\Documents\WindowsPowerShell\Scripts\New-CommandWrapper.ps1'

Remove-Item alias:dir
Remove-Item alias:ls
Set-Alias dir Get-DirWithSize
Set-Alias ls Get-DirWithSize

#
set-Alias -Name gls -Value Write-Color-LS

# start a transcript session
$TempDate = Get-Date
$TranscriptFile = "$env:HOME\Documents\WindowsPowershell\Transcripts\PoshTranscript" `
                  + $TempDate.Year + $TempDate.Month.ToString("00") + $TempDate.Day.ToString("00")
if (Test-Path ($TranscriptFile+".txt")) {
  $ctr = 0
  do { $ctr ++ } while ( Test-Path ($TranscriptFile+"-"+$ctr.ToString("00")+".txt") )
  # $ctr++
  $TranscriptFile += "-"+$ctr.ToString("00")+".txt" 
} else {
  $TranscriptFile += ".txt" 
}
"Transcript will be started in: $TranscriptFile"
Start-Transcript $TranscriptFile | Out-Null