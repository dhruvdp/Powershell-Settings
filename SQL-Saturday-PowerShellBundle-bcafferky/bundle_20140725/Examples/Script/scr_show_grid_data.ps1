# Display a file in Grid View ...

. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Function\ufn_Get_Winform_FileName.ps1
 
 $infile = ufn_Get_Winform_FileName -initialDirectory "C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Data\"
 Import-CSV $infile | Out-GridView
 
 
 
 