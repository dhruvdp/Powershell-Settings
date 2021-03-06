$randomDatabasePath =  Join-Path $env:Temp "$(Get-Random).sqlite.db"
$dbName = Get-Random

New-SQLDatabase -DatabasePath $randomDatabasePath -UseSqlite

#Add-SqlTable -DatabasePath $randomDatabasePath -UseSQLite -TableName "TestTable" -Column a,b -KeyType Sequential

$inputObjs = @()
$inputObjs += New-Object PSObject -Property @{
    "a" = Get-Random
    "B" = Get-Random
} 
$o = New-Object PSObject -Property @{
    "a" = Get-Random
    "B" = Get-Random
}
$o.pstypenames.clear()
$o.pstypenames.add('a')
$inputObjs += $o 
$inputObjs |
    Update-Sql -UseSQLite -DatabasePath $randomDatabasePath -TableName "TestTable" -Force

$dbobjs = Select-SQL -FromTable TestTable -UseSQLite -DatabasePath $randomDatabasePath

$dbobjs |
    Add-Member NoteProperty B (Get-Random) -Force -PassThru |
    Update-Sql -UseSQLite -DatabasePath $randomDatabasePath -TableName "TestTable"

Select-SQL -FromTable TestTable -UseSQLite -DatabasePath $randomDatabasePath
  
Remove-SQL -TableName TestTable -UseSQLite -DatabasePath $randomDatabasePath  -Where "RowKey = `"$($dbobjs[0].RowKey)`" " 

#Remove-Item -Path $randomDatabasePath