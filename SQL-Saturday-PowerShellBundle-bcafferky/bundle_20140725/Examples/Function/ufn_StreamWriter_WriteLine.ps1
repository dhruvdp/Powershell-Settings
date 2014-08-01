# Author:  Bryan Cafferky      Date:  2013-11-29
# 
# Purpose:  Write string to a file ...
#
<#

  Other and probably better methods are:
  
  
       To overwrite file...
       "mytest stuff" >  C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Data\Outfile1.txt   
       
       
       T append to file..
       "mytest stuff2" >>  C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Data\Outfile2.txt

#>

function ufn_streamwriter_writeline([string] $path, [string] $line)
{ 

$stream = [System.IO.StreamWriter] $path

$stream.WriteLine($line) 


$stream.close()

$stream = $null

}

# Example Call:
      ufn_streamwriter_writeline "C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Data\Outfile.txt" "Line to write 444."        
      
      

