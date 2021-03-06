
# Author:  Bryan Cafferky      Date:  2013-11-14
# 
# Purpose:  For loads of FTPed files.  Merge mmultiple files based on file name pattern matching and combine into one file so Informatica can load it.
#

function ufn_combine_files([string] $source, [string] $destination, [string] $filter)
{

$filelist = Get-ChildItem -Path $source  -Recurse -include $filter 

try
{
 Remove-Item $destination -ErrorAction SilentlyContinue
 write-host "Deleted $destination ."
 }
catch
 {
   "Error:  Problem deleting old files."
 }

   

Add-Content $destination "Column1`r`n"

  foreach ($file in $filelist)
  {
 
  $fc = Get-Content $file

  write-host $file
  Add-Content $destination $fc
  }

}