
#  Calling code written by Chad Miller
#  Link: http://blogs.technet.com/b/heyscriptingguy/archive/2011/11/28/four-easy-ways-to-import-csv-files-to-sql-server-with-powershell.aspx

# Get the functions we need...
. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\function\ufn_out-datatable.ps1

. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\function\ufn_Add-SqlTable.ps1

. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\function\ufn_write-datatable.ps1

. C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\function\ufn_Invoke-SqlCmd2.ps1

#  $dt = .\Get-DiskSpaceUsage.ps1 | Out-DataTable

Get-ChildItem -Path C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\function\

Add-SqlTable -ServerInstance "Win7boot\Sql1" -Database "hsg" -TableName diskspaceFunc -DataTable $dt

Write-DataTable -ServerInstance "Win7boot\Sql1" -Database "hsg" -TableName "diskspaceFunc" -Data $dt

invoke-sqlcmd2 -ServerInstance "Win7boot\Sql1" -Database "hsg" -Query "SELECT * FROM diskspaceFunc" | Out-GridView

C:\Users\BryanCafferky\Documents\BI_UG\PowerShell\Examples\Data\PersonData.csv