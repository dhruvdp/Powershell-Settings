#requires -version 2.0
## HttpRest module version 2.0
####################################################################################################
## Still only the initial stages of converting to a full v2 module
## Based on the REST api from MindTouch's Dream SDK
##
## INSTALL:
## You need mindtouch.dream.dll (mindtouch.core.dll, SgmlReaderDll.dll, log4net.dll) from the SDK
## Get MindTouch_Dream_2.1.0.zip (code name Indigo) from http`://sourceforge.net/projects/dekiwiki/files/ 
##
## Unpack it, and you can find these dlls in the "dist" folder.
## Make sure to put them in the folder with this script module.
## You also need the PSD1 file. It's in a comment block at the bottom.
##
## For documentation of Dream:  http`://wiki.developer.mindtouch.com/Dream
####################################################################################################
## Version History
## 1.0   2008-11-30  First Release
## 1.0.1 2009-01-05  Added Get-WebPageContent
## 1.0.2 2009-05-14  Bug fix for Invoke-Http credential issues
## 1.1.0 2009-05-14  First release of a PowerShell 2.0 (CTP3/Windows7) version....
## 1.1.1 2009-05-15  Added Get-WebPageText and Get-Webfile ... cleaned up options
## 1.2   2009-08-09  Added Hashtable parsing on Get-DreamMessage
##                   Fixed parsing on Get-DreamPlug so we don't get errors on PowerShell 2
##                   Added ParameterSet on Invoke-Http to pass in a plug directly (easier to debug)
## 1.3   2010-07-27  Added a few more aliases to make life easier
## 1.4   2010-07-28  Changed Get-WebPageContent and Get-WebPageText to support pipline input
##                   Started adding help ...
## 2.0   2010-08-20  Upgrade to Mindtouch Dream 2.1
##                   Further Improvements to function behavior and parameter binding.
####################################################################################################
## Usage:
##   function Get-Google {
##     Invoke-Http GET http`://www.google.com/search @{q=$args} | 
##       Receive-Http Xml "//h3[@class='r']/a" | Select href, InnerText 
##   }
##   #########################################################################
##   function Get-WebFile($url,$cred) {
##     Invoke-Http GET $url -auth $cred | Receive-Http File
##   }
##   #########################################################################
##   function Send-Paste {
##   PARAM($PastebinURI="http`://posh.jaykul.com/p/",[IO.FileInfo]$file)
##   PROCESS {
##     if($_){[IO.FileInfo]$file=$_}
## 
##     if($file.Exists) { 
##       $ofs="`n"
##       $result = Invoke-Http POST $PastebinURI @{
##         format="posh"           # PowerShell
##         expiry="d"              # (d)ay or (m)onth or (f)orever
##         poster=$([Security.Principal.WindowsIdentity]::GetCurrent().Name.Split("\")[-1])
##         code2="$((gc $file) -replace "http`://","http``://")" # To get past the spam filter.
##         paste="Send"
##       } -Type FORM_URLENCODED -Wait
##       $xml = $result.AsDocument().ToXml()
##       write-output $xml.SelectSingleNode("//*[@class='highlight']/*").href
##     } else { throw "File Not Found" }
##   }}
##
####################################################################################################
Write-Debug "PSScriptRoot: '$PSScriptRoot'"
# This Module depends on MindTouch.Dream 
$null = Add-Type -Path "$PSScriptRoot\mindtouch.dream.dll" -ErrorAction Stop
# MindTouch.Dream requires: mindtouch.dream.dll, mindtouch.core.dll, SgmlReaderDll.dll, and log4net.dll)
# This Module also depends on utility functions from System.Web
$null = Add-Type -Assembly System.Web -ErrorAction Stop

## Some utility functions are defined at the bottom
[uri]$global:url = ""
[System.Management.Automation.PSCredential]$global:HttpRestCredential = $null

Function Get-DreamMessage {
PARAM($Content,$Type)
   #Write-Verbose "Content: $(if($Content){$Content.GetType()}else{"null"}) $($Content.Length) and Type: $(if($Type){$Type.GetType()}else{"null"})"
   if($Type -is [String]) {
      Write-Verbose "Specific Content: $([MindTouch.Dream.MimeType]::$Type)"
      $Type = [MindTouch.Dream.MimeType]::$Type
   }
   
   if($Type -is [MindTouch.Dream.MimeType] -and $Content) {
      Write-Verbose "Specific Content: $([MindTouch.Dream.MimeType]::$Type)"
      return [MindTouch.Dream.DreamMessage]::Ok( $Type, $Content )
   }
   
   if(!$Content) { 
      Write-Verbose "No Content"
      return [MindTouch.Dream.DreamMessage]::Ok()
   }
   if($Content -is [System.Xml.XmlDocument]) {
      Write-Verbose "Xml Content"
      return [MindTouch.Dream.DreamMessage]::Ok( $Content )
   }
   if($Content -is [Hashtable]) {
      $kvp = $Content.GetEnumerator() | %{ new-object "System.Collections.Generic.KeyValuePair[[String],[String]]" $_.Key, $_.Value }
      Write-Verbose "Hashtable content: $($kvp | ft -auto | out-string -stream | %{ "   $_ ".TrimEnd()} )"
      return [MindTouch.Dream.DreamMessage]::Ok( $kvp )
   }   
   if(Test-Path $Content -EA "SilentlyContinue") {
      Write-Verbose "File Content"
      return [MindTouch.Dream.DreamMessage]::FromFile((Convert-Path (Resolve-Path $Content))); 
   }

   Write-Verbose "Unspecified string content"
   return [MindTouch.Dream.DreamMessage]::Ok( $([MindTouch.Dream.MimeType]::TEXT), $Content )
}

Function Get-DreamPlug {
   [CmdletBinding()]
   PARAM ( $Url, [hashtable]$With, [hashtable]$Headers )
   if($Url -is [array]) {
      Write-Verbose "URL is an array of parts"
      if($Url[0] -is [hashtable]) {
         Write-Verbose "URL is an array of hashtable parts"
         $plug = [MindTouch.Dream.Plug]::New($global:url)
         foreach($param in $url.GetEnumerator()) {
            if($param.Value) {
               $plug = $plug.At($param.Key,"=$(Encode-Twice $param.Value)")
            } else {
               $plug = $plug.At($param.Key)
            }
         }
      } 
      else 
      {
         [URI]$uri = Join-Url $global:url $url 
         $plug = [MindTouch.Dream.Plug]::New($uri)
      }
   }
   elseif($url -is [string]) 
   {
      Write-Verbose "String URL"
      trap { continue }
      [URI]$uri = $url
      if(!$uri.IsAbsoluteUri) {
         $uri = Join-Url $global:url $url
         Write-Verbose "Relative URL, appending to $($global:url) to get: $uri"
      }
      $plug = [MindTouch.Dream.Plug]::New($uri)
   } 
   else {
      Write-Verbose "No URL, using default $($global:url)"
      $plug = [MindTouch.Dream.Plug]::New($global:url)
   }
   if($with) { 
      foreach($w in $with.GetEnumerator()) {
         if($w.Value) {
            $plug = $plug.With($w.Key,$w.Value)
         }
      } 
      Write-Verbose "Added 'with' params: $plug"
   }
   if($headers) { 
      foreach($header in $Headers.GetEnumerator()) {
         if($header.Value) {
            $plug = $plug.WithHeader($header.Key,$header.Value)
         }
      } 
      Write-Verbose "Added 'with' params: $plug"
   }
   return $plug
}

Function Receive-Http {
[CmdletBinding(DefaultParameterSetName="Response")]
PARAM(
   [Parameter(Position=1, Mandatory=$false)]
   [ValidateSet("Xml", "File", "Text","Bytes")]
   [Alias("As")]
   $Output = "Xml" 
, 
   [Parameter(Position=2, Mandatory=$false)]
   [AllowEmptyString()]
   [string]$Path
,
   [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Result")]
   [Alias("IO")]
   [MindTouch.Tasking.Result[MindTouch.Dream.DreamMessage]]
   $InputObject
,
   [Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Response")]
   [MindTouch.Dream.DreamMessage]
   $Response
) 
PROCESS {
   if($PSCmdlet.ParameterSetName -eq "Result") {
      $Response = $InputObject.Wait()
   }
   
   if($Response) {
      Write-Debug $($response | Out-String)
      if(!$response.IsSuccessful) {
         Write-Output $response
         Write-Host "Hello" -fore Yellow
         Write-Verbose $($response|gm|out-string)
         Write-Host "Hello" -fore Yellow
         Write-Error $($response | Out-String)
         throw "ERROR: '$($response.Status)' Response Status."
      } else {   
         switch($Output) {
            "File" {
               ## Joel's magic filename guesser ...
               if(!$Path) { 
                  [string]$fileName = ([regex]'(?i)filename=(.*)$').Match( $response.Headers["Content-Disposition"] ).Groups[1].Value
                  $Path = $fileName.trim("\/""'")
                  if(!$Path){
                     if($response.ResponseUri)  {
                        $fileName = $response.ResponseUri.Segments[-1]
                        $Path = $fileName.trim("\/")
                        if(!([IO.FileInfo]$Path).Extension) {
                           $Path = $Path + "." + $response.ContentType.Split(";")[0].Split("/")[1]
                        }
                     } 
                  }
               }
               if($Path) { 
                  $File = Get-FileName $Path
               } else {
                  $File = Get-FileName
               }
               $null = [MindTouch.IO.StreamUtil]::CopyToFile( $response.AsStream(), $File, $response.ContentLength )
               Get-ChildItem $File
            }
            "XDoc" {
               if($Path) { 
                  $response.AsDocument()[$Path]
               } else {
                  $response.AsDocument()#.ToXml()
               }
            }
            "Xml" {
               if($Path) { 
                  $response.AsDocument().ToXml().SelectNodes($Path)
               } else {
                  $response.AsDocument().ToXml()
               }
            }
            "Text" {
               if($Path) { 
                  $response.AsDocument()[$Path] | % { $_.AsInnerText }
               } else {
                  $response.AsText()
               }
            }
            "Bytes" {
               $response.AsBytes()
            }
         }
      }
   } else {
      Write-Warning "No Response!"
      if($InputObject) { Write-Output $InputObject }
   }
}
}

Function Invoke-Http {
#.Synopsis
#  Invoke an HTTP verb on a URI
#.Description
#  This is the core http rest cmdlet, which does most of the work and allows fetching web pages, files, etc.
[CmdletBinding(DefaultParameterSetName="ByPath")]
PARAM( 
   ## http`://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
   ## Nobody actually uses HEAD or OPTIONS, right? 
   ## And nobody's even heard of TRACE or CONNECT ;) 
   [Parameter(Position=0, Mandatory=$false)]
   [ValidateSet("POST", "GET", "PUT", "DELETE", "HEAD", "OPTIONS")] ## There are other verbs, but we need a list to make sure you don't screw up
   [string]$Verb = "GET"
,
   [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$false, ParameterSetName="WithPlug")]
   [MindTouch.Dream.Plug]
   $Plug
,
   [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="ByPath")]
   [string]
   $Path
, 
   [Parameter(Position=2, Mandatory=$false, ParameterSetName="ByPath")]
   [hashtable]$With
, 
   [Parameter(Position=3, Mandatory=$false, ParameterSetName="ByPath")]
   [hashtable]$Headers
,
   [Parameter(Mandatory=$false)]
   $Content
,
   [Parameter(Mandatory=$false)]
   [System.Collections.Generic.IEnumerable[MindTouch.Web.DreamCookie]]$Cookies
,
   [Parameter(Mandatory=$false)]
   $Type # Of Content
,
   [Parameter(Mandatory=$false)]
   [switch]$authenticate
, 
   [Parameter(Mandatory=$false)]
   $credentials
,
   [Parameter(Mandatory=$false)]
   [switch]$Persistent  ## Note this ALSO causes WaitForResponse
, 
   [switch]$waitForResponse
)
PROCESS {
      if($PSCmdlet.ParameterSetName -eq "ByPath") {
         $Plug = Get-DreamPlug $Path $With $Headers
      }

      ## Special Handling for FORM_URLENCODED
      if($Type -like "Form*" -and !$Content) {
         $dream = [MindTouch.Dream.DreamMessage]::Ok( $Plug.Uri )
         $Plug = [MindTouch.Dream.Plug]::New( $Plug.Uri.SchemeHostPortPath )
         Write-Verbose "RECREATED Plug: $($Plug.Uri.SchemeHostPortPath)"
      } else {
         $dream = Get-DreamMessage $Content $Type
         Write-Verbose "Created Dream with Content: $($dream.AsText() |out-String)"
      }
      
      if(!$plug -or !$dream) {
         throw "Can't come up with a request!"
      }
      
      if($Persistent -and $global:HttpRestCookies) {
         $dream.Cookies.AddRange( $global:HttpRestCookies )
      }
      if($Cookies) {
         $dream.Cookies.AddRange( $Cookies )
      }
      
      if($authenticate -or $credentials){ 
         if($credentials -is [System.Management.Automation.PSCredential]) {
            Write-Verbose "AUTHENTICATING AS $($credentials.GetNetworkCredential().UserName)"
            $plug = $plug.WithCredentials($credentials.GetNetworkCredential())
         } elseif($credentials -is [System.Net.ICredentials]) {
            Write-Verbose "AUTHENTICATING AS $($credentials.GetNetworkCredential().UserName)"
            $plug = $plug.WithCredentials($credentials.GetNetworkCredential())
         } else {
            if($credentials) {
               Write-Error "Credential must be a PSCredential or a System.Net.ICredentials"
            }
            $null = Get-HttpCredential  # Make sure they have global credentials
            Write-Verbose "AUTHENTICATING AS $($global:HttpRestCredential.UserName)"
            $plug = $plug.WithCredentials($global:HttpRestCredential.GetNetworkCredential())
         }
      }
      
      Write-Verbose $plug.Uri
      
      ## DEBUG:
      Write-Debug "URI: $($Plug.Uri)"
      Write-Debug "Verb: $($Verb.ToUpper())"
      Write-Debug $($dream | gm | Out-String)
      
      $result = $plug.InvokeAsync( $Verb.ToUpper(),  $dream )
      
      Write-Debug $($result | Out-String)
      #  if($DebugPreference -eq "Continue") {
      #     Write-Debug $($result.Wait() | Out-String)
      #  }
      
      if($waitForResponse -or $Persistent) { 
         $result = $result.Wait()
         $global:HttpRestCookies = $result.Cookies
      }
      
      write-output $result
   
      trap [MindTouch.Dream.DreamResponseException] {
         Write-Error @"
TRAPPED DreamResponseException
      
$($_.Exception.Response | Out-String)

$($_.Exception.Response.Headers | Out-String)
"@
         break;
      }
}
}

Function Get-WebPageContent {
#.Synopsis
#  A wrapper for http get | rcv xml
[CmdletBinding()]
param( 
   [Parameter(Position=0,Mandatory=$true, ValueFromPipeline=$true)]
   [string]$url
,
   [Parameter(Mandatory=$false)]
   [string]$xpath=""
,
   [Parameter(Position=2,Mandatory=$false)]
   [hashtable]$with=@{}
,
   [Parameter(Mandatory=$false)]
   [switch]$Persist 
,
   [Parameter(Mandatory=$false)]
   [switch]$Authenticate
)
PROCESS {
   invoke-http get $url $with -Authenticate:$Authenticate -Persist:$Persist | receive-http xml $xpath | select -expand outerxml
}
}

Function Get-WebPageText {
#.Synopsis
#  A wrapper for http get | rcv text
[CmdletBinding()]
param( 
   [Parameter(Position=0,Mandatory=$true, ValueFromPipeline=$true)]
   [string]$url
,
   [Parameter(Mandatory=$false)]
   [string]$xpath=""
,
   [Parameter(Position=2,Mandatory=$false)]
   [hashtable]$with=@{}
,
   [Parameter(Mandatory=$false)]
   [switch]$Persist 
,
   [Parameter(Mandatory=$false)]
   [switch]$Authenticate
)
PROCESS {
   invoke-http get $url $with -Authenticate:$Authenticate -Persist:$Persist | receive-http text $xpath
}
}

Function Get-WebFile {
#.Synopsis
#  Download a file from a URI to the local computer
[CmdletBinding()]
param( 
   [Parameter(Position=0,Mandatory=$true, ValueFromPipeline=$true)]
   [string]$url
,
   [Parameter(Mandatory=$false)]
   [Alias("output")]
   [string]$path=""
,
   [Parameter(Position=2,Mandatory=$false)]
   [hashtable]$with=@{}
,
   [Parameter(Mandatory=$false)]
   [switch]$Persist 
,
   [Parameter(Mandatory=$false)]
   [switch]$Authenticate
)
PROCESS {
   Invoke-Http GET $url $with -Authenticate:$Authenticate -Persist:$Persist | Receive-Http File $path
}
}

Function Set-HttpDefaultUrl {
#.Synopsis
#  Set the base URI for making lots of calls to a single webservice without re-entering the full URL each time
PARAM ([uri]$baseUri=$(Read-Host "Please enter the base Uri for your RESTful web-service"))
   $global:url = $baseUri 
}

Function Set-HttpCredential {
#.Synopsis
#  Set the default credentials for making lots of calls to a single webservice without re-entering credentials
param($Credential=$(Get-CredentialBetter -Title   "Http Authentication Request - $($global:url.Host)" `
                                         -Message "Your login for $($global:url.Host)" `
                                         -Domain  $($global:url.Host)) )
   if($Credential -is [System.Management.Automation.PSCredential]) {
      $global:HttpRestCredential = $Credential
   } elseif($Credential -is [System.Net.NetworkCredential]) {
      $global:HttpRestCredential = new-object System.Management.Automation.PSCredential $Credential.UserName, $(ConvertTo-SecureString $credential.Password)
   }
}

Function Get-HttpCredential {
#.Synopsis
#  Retrieves the default credentials for making lots of calls to a single webservice without re-entering credentials
   if(!$global:url) { Set-HttpDefaultUrl }
   if(!$global:HttpRestCredential) { Set-HttpCredential }
   if(!$Secure) {
      return $global:HttpRestCredential.GetNetworkCredential();
   } else {
      return $global:HttpRestCredential
   }
}

Function ConvertTo-UrlDoubleEncode {
#.Synopsis
#  Encode URLs twice for use with mindtouch APIs
   param([string]$text)
   return [System.Web.HttpUtility]::UrlEncode( [System.Web.HttpUtility]::UrlEncode( $text ) )
}

Function Join-Url {
#.Synopsis
#  Like Join-Path, but for URIs
[CmdletBinding()]
param( 
[Parameter()]
[uri]$baseUri=$global:url 
,
[Parameter(ValueFromRemainingArguments=$true)]
[string[]]$path
)
   $ofs="/";$BaseUrl = ""
   if($BaseUri -and $baseUri.AbsoluteUri) {
      $BaseUrl = "$($baseUri.AbsoluteUri.Trim('/'))/"
   }
   return [URI]"$BaseUrl$([string]::join("/",@($path)).TrimStart('/'))"
}

Function ConvertTo-SecureString {
#.Synopsis
#   Helper function which converts a string to a SecureString
Param([string]$input)
   $result = new-object System.Security.SecureString

   foreach($c in $input.ToCharArray()) {
      $result.AppendChar($c)
   }
   $result.MakeReadOnly()
   return $result
}

Function Get-FileName {
#.Synopsis
#  Helper function to get a VALID filesystem path
   param($fileName=$([IO.Path]::GetRandomFileName()), $path)
   $fileName = $fileName.trim("\/""'")
   ## if the $Path has a file name, and it's folder exists:
   if($Path -and !(Test-Path $Path -Type Container) -and (Test-Path (Split-Path $path) -Type Container)) {
      $path
   ## if the $Path is just a folder (and it exists)
   } elseif($Path -and (Test-Path $path -Type Container)) {
      $fileName = Split-Path $fileName -leaf
      Join-Path $path $fileName
   ## If there's no valid $Path, and the $FileName has a folder...
   } elseif((Split-Path $fileName) -and (Test-Path (Split-Path $fileName))) {
      $fileName
   } else {
      Join-Path (Get-Location -PSProvider "FileSystem") (Split-Path $fileName -Leaf)
   }
}

Function Get-UtcTime {
   Param($Format="yyyyMMddhhmmss")
   [DateTime]::Now.ToUniversalTime().ToString($Format)
}

Function Get-CredentialBetter { 
## .Synopsis
##    Gets a credential object based on a user name and password.
## .Description
##    The Get-Credential function creates a credential object for a specified username and password, with an optional domain. You can use the credential object in security operations.
## 
##    The function accepts more parameters to customize the security prompt than the default Get-Credential cmdlet (including forcing the call through the console if you're in the native PowerShell.exe CMD console), but otherwise functions identically.
##
## .Parameter UserName
##    A default user name for the credential prompt, or a pre-existing credential (would skip all prompting)
## .Parameter Title
##    Allows you to override the default window title of the credential dialog/prompt
##
##    You should use this to allow users to differentiate one credential prompt from another.  In particular, if you're prompting for, say, Twitter credentials, you should put "Twitter" in the title somewhere. If you're prompting for domain credentials. Being specific not only helps users differentiate and know what credentials to provide, but also allows tools like KeePass to automatically determine it.
## .Parameter Message
##    Allows you to override the text displayed inside the credential dialog/prompt.
##    
##    You can use this for things like presenting an explanation of what you need the credentials for.
## .Parameter Domain
##    Specifies the default domain to use if the user doesn't provide one (by default, this is null)
## .Parameter GenericCredentials
##    The Get-Credential cmdlet forces you to always return DOMAIN credentials (so even if the user provides just a plain user name, it prepends "\" to the user name). This switch allows you to override that behavior and allow generic credentials without any domain name or the leading "\".
## .Parameter Inline
##    Forces the credential prompt to occur inline in the console/host using Read-Host -AsSecureString (not implemented properly in PowerShell ISE)
##
[CmdletBinding(DefaultParameterSetName="Better")]
PARAM(
   [Parameter(Position=1,Mandatory=$false)]
   [Alias("Credential")]
   [PSObject]$UserName=$null,
   [Parameter(Position=2,Mandatory=$false)]
   [string]$Title=$null,
   [Parameter(Position=3,Mandatory=$false)]
   [string]$Message=$null,
   [Parameter(Position=4,Mandatory=$false)]
   [string]$Domain=$null,
   [Parameter(Mandatory=$false)]
   [switch]$GenericCredentials,
   [Parameter(Mandatory=$false)]
   [switch]$Inline
)
PROCESS {
   if( $UserName -is [System.Management.Automation.PSCredential]) {
      return $UserName
   } elseif($UserName -ne $null) {
      $UserName = $UserName.ToString()
   }
   
   if($Inline) {
      if($Title)    { Write-Host $Title }
      if($Message)  { Write-Host $Message }
      if($Domain) { 
         if($UserName -and $UserName -notmatch "[@\\]") { 
            $UserName = "${Domain}\${UserName}"
         }
      }
      if(!$UserName) {
         $UserName = Read-Host "User"
         if(($Domain -OR !$GenericCredentials) -and $UserName -notmatch "[@\\]") {
            $UserName = "${Domain}\${UserName}"
         }
      }
      return New-Object System.Management.Automation.PSCredential $UserName,$(Read-Host "Password for user $UserName" -AsSecureString)
   }
   if($GenericCredentials) { $Credential = "Generic" } else { $Credential = "Domain" }
   
   ## Now call the Host.UI method ... if they don't have one, we'll die, yay.
   ## BugBug? PowerShell.exe disregards the last parameter
   $Host.UI.PromptForCredential($Title, $Message, $UserName, $Domain, $Credential,"Default")
}
}

New-Alias Encode-Twice ConvertTo-UrlDoubleEncode

new-alias gwpc Get-WebPageContent -EA "SilentlyContinue"
new-alias gwpt Get-WebPageText    -EA "SilentlyContinue"
new-alias http Invoke-Http        -EA "SilentlyContinue"
new-alias rcv  Receive-Http       -EA "SilentlyContinue"

Export-ModuleMember -Function Invoke-Http, Receive-Http, Get-WebPageContent, Get-WebPageText, Get-WebFile, ConvertTo-UrlDoubleEncode, Get-HttpCredential, Set-HttpCredential, Set-HttpDefaultUrl -Alias *

##########################################################################################
##### HttpRest.psd1
##########################################################################################
## #
## # Module manifest for module 'HttpRest'
## # Generated by: Joel Bennett
## # Generated on: 3/19/2009
## #
## 
## @{
## 
## # These modules will be processed when the module manifest is loaded.
## ModuleToProcess = 'HttpRest.psm1'
## 
## # This GUID is used to uniquely identify this module.
## GUID = '49fc4e2a-0270-467d-a652-a9ba8f82e97b'
## 
## # The author of this module.
## Author = 'Joel Bennett'
## 
## # The company or vendor for this module.
## CompanyName = 'http://HuddledMasses.org'
## 
## # The copyright statement for this module.
## Copyright = 'Copyright (c) 2008, Joel Bennett. Released under Ms-PL license.'
## 
## # The version of this module.
## ModuleVersion = '2.0'
## 
## # A description of this module.
## Description = 'This module provides functions for working Http services.  Everything from downloading web pages, posting forms, and parsing HTML as XML, to downloading images and files, to interacting with REST web APIs'
## 
## # The minimum version of PowerShell needed to use this module.
## PowerShellVersion = '2.0'
## 
## # The CLR version required to use this module.
## CLRVersion = '2.0'
## 
## # Functions to export from this manifest.
## FunctionsToExport = '*'
## 
## # Aliases to export from this manifest.
## AliasesToExport = '*'
## 
## # Variables to export from this manifest.
## VariablesToExport = '*'
## 
## # Cmdlets to export from this manifest.
## CmdletsToExport = '*'
## 
## # This is a list of other modules that must be loaded before this module.
## RequiredModules = @()
## 
## # The script files (.ps1) that are loaded before this module.
## ScriptsToProcess = @()
## 
## # The type files (.ps1xml) loaded by this module.
## TypesToProcess = @()
## 
## # The format files (.ps1xml) loaded by this module.
## FormatsToProcess = @()
## 
## # A list of assemblies that must be loaded before this module can work.
## RequiredAssemblies = 'autofac.dll', 'log4net.dll', 'mindtouch.core.dll', 'SgmlReaderDll.dll', 'mindtouch.dream.dll'
## 
## # Module specific private data can be passed via this member.
## PrivateData = ''
## 
## }