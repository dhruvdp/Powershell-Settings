## If your PC doesn't have this set already, someone could tamper with this script...
## but at least now, they can't tamper with any of the scripts that I auto-load!
Set-ExecutionPolicy Unrestricted ## AllSigned Process
## Set the profile directory first, so we can refer to it from now on.
Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Option AllScope
## Set color of error text to green, a little more readable
$Host.PrivateData.ErrorForegroundColor = "green"
## I determine which modules to pre-load here (in this SIGNED script)
$AutoModules = 'Autoload', 'Authenticode', 'HttpRest', 'PoshCode', 'PowerTab', 'ResolveAliases', 'PSCX'
## 'Strings', 
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

###################################################################################################
## I have a few additional custom type and format data items which take prescedence over anyone else's
Update-TypeData   -PrependPath "$ProfileDir\Formats\Types.ps1xml"
Update-FormatData -PrependPath "$ProfileDir\Formats\Formats.ps1xml"

###################################################################################################
## Developer tools stuff ... 
## I need InstallUtil, MSBuild, and TF (TFS) and they're all in the.Net RuntimeDirectory OR Visual Studio*\Common7\IDE
$Env:Path = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() + ";" +
            @(Get-Item C:\Program*Files*\*Visual?Studio*\Common7\IDE\TF.exe -EA 0| Sort LastWriteTime -Desc)[0].Directory + 
            ";$Env:Path"

if(!(Get-Command TF.exe -ErrorAction SilentlyContinue)) { 
	Write-Warning "Could not locate TF.exe in Visual Studio\Common7. It may not be installed on this PC"
}	

###################################################################################################
## And a couple of functions that can't be saved as script files, and aren't worth modularizing
## Elipsis shortcut for Select -Expand name
${function:...} = { process { $_.$($args[0]) } }

## The Trinary shortcut function
function ?: {
   param([ScriptBlock]$trueblock,[ScriptBlock]$falseblock)
   process {  
      if($_){ 
         &$trueblock $_ 
      } else { 
         &$falseblock $_ 
      }
   }
}

## Pre-load a few of my functions in case I need them. 
## In particular, a couple that are better than PSCX's versions
Autoload New-ShortCut
Autoload Edit-File
Autoload Get-PerformanceHistory

###################################################################################################
## Custom aliases I can't live without
Set-Alias   exec         Invoke-Expression         -Option AllScope -Description "Personal Function alias"
Set-Alias   edit         Edit-File                 -Option AllScope -Description "Personal Function alias"
Set-Alias   rand         Get-Random                -Option AllScope -Description "Personal Cmdlet Alias"
Set-Alias   say          Out-Speech                -Option AllScope -Description "Personal Script Alias"
Set-Alias   gph          Get-PerformanceHistory    -Option AllScope -Description "Personal Script Alias"

###################################################################################################
## I love my random quotes ... 
Set-Variable QuoteDir (Resolve-Path (Join-Path (Split-Path $ProfileDir -parent) "@stuff\Quotes")) -Scope Global -Option AllScope -Description "Personal PATH Variable"

Set-Alias   RandomLine   Select-RandomLine         -Option AllScope -Description "Personal Script Alias"
Set-Alias   Get-Quote    Select-RandomLine         -Option AllScope -Description "Personal Script Alias"
Set-Alias   gq           Select-RandomLine         -Option AllScope -Description "Personal Script Alias"

###################################################################################################
## I add my "Scripts" directory and all of its direct subfolders to my PATH
$ENV:PATH = Get-ChildItem $ProfileDir\Script[s],$ProfileDir\Scripts\* | 
               Where-Object { $_.PsIsContainer } | 
               ForEach-Object { $_.FullName } | 
               Join ";" -append $ENV:PATH -unique

## I like all of my sessions to start in my profile directory
Set-Location $ProfileDir
## My prompt function is in it's own script
. Set-Prompt

## And finally, relax the code signing restriction so we can actually get work done
Set-ExecutionPolicy RemoteSigned Process

## Get a random quote, and print it in yellow :D
Write-Host $(Get-Quote) -Fore Yellow

# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTf/G2RuXibbNw/GxUxoBclEt
# kOKgggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTEwMDUxNDAwMDAwMFoXDTExMDUxNDIzNTk1OVowgZUx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUwNjg1MDEUMBIGA1UECAwLQ29ubmVjdGlj
# dXQxEDAOBgNVBAcMB05vcndhbGsxFjAUBgNVBAkMDTQ1IEdsb3ZlciBBdmUxGjAY
# BgNVBAoMEVhlcm94IENvcnBvcmF0aW9uMRowGAYDVQQDDBFYZXJveCBDb3Jwb3Jh
# dGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfUdxwiuWDb8zId
# KuMg/jw0HndEcIsP5Mebw56t3+Rb5g4QGMBoa8a/N8EKbj3BnBQDJiY5Z2DGjf1P
# n27g2shrDaNT1MygjYfLDntYzNKMJk4EjbBOlR5QBXPM0ODJDROg53yHcvVaXSMl
# 498SBhXVSzPmgprBJ8FDL00o1IIAAhYUN3vNCKPBXsPETsKtnezfzBg7lOjzmljC
# mEOoBGT1g2NrYTq3XqNo8UbbDR8KYq5G101Vl0jZEnLGdQFyh8EWpeEeksv7V+YD
# /i/iXMSG8HiHY7vl+x8mtBCf0MYxd8u1IWif0kGgkaJeTCVwh1isMrjiUnpWX2NX
# +3PeTmsCAwEAAaOCAW8wggFrMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBTK0OAaUIi5wvnE8JonXlTXKWENvTAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhC
# AQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcC
# ARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0
# LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNv
# bW9kb2NhLmNvbTAhBgNVHREEGjAYgRZKb2VsLkJlbm5ldHRAWGVyb3guY29tMA0G
# CSqGSIb3DQEBBQUAA4IBAQAEss8yuj+rZvx2UFAgkz/DueB8gwqUTzFbw2prxqee
# zdCEbnrsGQMNdPMJ6v9g36MRdvAOXqAYnf1RdjNp5L4NlUvEZkcvQUTF90Gh7OA4
# rC4+BjH8BA++qTfg8fgNx0T+MnQuWrMcoLR5ttJaWOGpcppcptdWwMNJ0X6R2WY7
# bBPwa/CdV0CIGRRjtASbGQEadlWoc1wOfR+d3rENDg5FPTAIdeRVIeA6a1ZYDCYb
# 32UxoNGArb70TCpV/mTWeJhZmrPFoJvT+Lx8ttp1bH2/nq6BDAIvu0VGgKGxN4bA
# T3WE6MuMS2fTc1F8PCGO3DAeA9Onks3Ufuy16RhHqeNcMYICTDCCAkgCAQEwgaow
# gZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
# aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0
# LU9iamVjdAIQKQm90jYWUDdv7EgFkuELajAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQURIrjK39r
# ycFCQgjjCok8yydU410wDQYJKoZIhvcNAQEBBQAEggEAaDce6yCDu4TU2JQzCji+
# JlREUjrc5achsjJXN3KqaElxEn4WDX2SZzSy+AfgthUkt0g+usfQhLDmqNBaXJnw
# vlrvlq64ABY2z/fBUv5KurXOiSvDxWSGJTflN960TQsKdaO1dzisOSUxizUGAold
# r4JvfnsRXGRTFSGnlOvi54VhOlypgsZuh0BXL2JF/6huGWNKXL1eXKz/gFArIeHB
# +EcOenddxaUtlhmVV9s3As/MQS1/NRfFy5qa6gmG0nj9Vpn+2nzwMeMiXE4dAiJc
# nQ09/WOFXrjhZZIEyNwwdl6lVoJTsL1XTIFOiU2UFK9V8xhNSjIqaGMj9uK1KP5u
# zQ==
# SIG # End signature block