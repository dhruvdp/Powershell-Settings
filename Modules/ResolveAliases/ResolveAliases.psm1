#requires -version 2.0
## ResolveAliases Module v 1.7
########################################################################################################################
## Sample Use:
##    Resolve-Aliases Script.ps1 | Set-Content Script.Resolved.ps1 
##    ls *.ps1 | Resolve-Aliases -Inplace
########################################################################################################################
## Version History
## 1.0 - First Version. "It worked on my sample script"
## 1.1 - Now it parses the $(...) blocks inside strings
## 1.2 - Some tweaks to spacing and indenting (I really gotta get some more test case scripts)
## 1.3 - I went back to processing the whole script at once (instead of a line at a time)
##       Processing a line at a time makes it impossible to handle Here-Strings...
##       I'm considering maybe processing the tokens backwards, replacing just the tokens that need it
##       That would mean I could get rid of all the normalizing code, and leave the whitespace as-is
## 1.4 - Now resolves parameters too
## 1.5 - Fixed several bugs with command resolution (the ? => ForEach-Object problem)
##     - Refactored the Resolve-Line filter right out of existence
##     - Created a test script for validation, and 
## 1.6 - Added resolving parameter ALIASES instead of just short-forms
## 1.7 - Minor tweak to make it work in CTP3
##
## * *TODO:* Put back the -FullPath option to resolve cmdlets with their snapin path
## * *TODO:* Add an option to put #requires statements at the top for each snapin used
########################################################################################################################
function which {
PARAM( [string]$command )
   # aliases, functions, cmdlets, scripts, executables, normal files
   $cmds = @(Get-Command $command -EA "SilentlyContinue")
   if($cmds.Count -gt 1) {
      $cmd = @( $cmds | Where-Object { $_.Name -match "^$([Regex]::Escape($command))" })[0]
   } else {
      $cmd = $cmds[0]
   }
   if(!$cmd) {
      $cmd = @(Get-Command "Get-$command" -EA "SilentlyContinue" | Where-Object { $_.Name -match "^Get-$([Regex]::Escape($command))" })[0]
   }
   if( $cmd.CommandType -eq "Alias" ) {
      $cmd = which $cmd.Definition
   }
   return $cmd
}

function Resolve-Aliases
{
   [CmdletBinding(ConfirmImpact="low",DefaultParameterSetName="Files")]
   Param (
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Text")]
      [string]$Line
,
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Files")]
      [Alias("FullName","PSChildName","PSPath")]
      [IO.FileInfo]$File
,
      [Parameter(Position=1, ParameterSetName="Files")] 
      [Switch]$InPlace
   )
   BEGIN {
      Write-Debug $PSCmdlet.ParameterSetName
   }
   PROCESS {
      if($PSCmdlet.ParameterSetName -eq "Files") {
         if($File -is [System.IO.FileInfo]){
            $Line = ((Get-Content $File) -join "`n")
         } else {
            throw "We can't resolve a whole folder at once yet" 
         }
      }

      $Tokens = [System.Management.Automation.PSParser]::Tokenize($Line,[ref]$null)
      for($t = $Tokens.Count; $t -ge 0; $t--) {
         $token = $Tokens[$t]
         # DEBUG $token | fl * | out-host
         switch($token.Type) {
            "Command" {
               $cmd = which $token.Content
               Write-Debug "Command $($token.Content) => $($cmd.Name)"
               #if($cmd.CommandType -eq "Alias") {
               $Line = $Line.Remove( $token.Start, $token.Length ).Insert( $token.Start, $cmd.Name )
               #}
            }
            "CommandParameter" {
               Write-Debug "Parameter $($token.Content)"
               for($c = $t; $c -ge 0; $c--) {
                  if( $Tokens[$c].Type -eq "Command" ) {
                     $cmd = which $Tokens[$c].Content
                     # if($cmd.CommandType -eq "Alias") {
                        # $cmd = @(which $cmd.Definition)[0]
                     # }
                     $short = $token.Content -replace "^-?","^"
                     Write-Debug "Parameter $short"
                     $parameters = $cmd.ParameterSets | Select -expand Parameters
                     $param = @($parameters | Where-Object { $_.Name -match $short -or $_.Aliases -match $short} | Select -Expand Name -Unique)
                     if($param.Count -eq 1) {
                        $Line = $Line.Remove( $token.Start, $token.Length ).Insert( $token.Start, "-$($param[0])" )
                     }
                     break
                  }
               }
            }
         }
      }

      switch($PSCmdlet.ParameterSetName) {
         "Text" {
            $Line
         }
         "Files" {
            switch($File.GetType()) {
               "System.IO.FileInfo" {
                  if($InPlace) {
                     $Line | Set-Content $File 
                  } else {
                     $Line
                  }
               }
               default { throw "We can't resolve a whole folder at once yet" }
            }
         }
         default { throw "ParameterSet: $($PSCmdlet.ParameterSetName)" }
      }
   }
}