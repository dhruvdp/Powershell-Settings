# Set-Location SQLSERVER:\sql\$env:COMPUTERNAME\SQL\
$dbcmd = @"
        select HVCasePK, PC1ID, CaseStartDate, ScreenDate, KempeDate, IntakeDate, DischargeDate
          from CaseProgram cp
         inner join HVCase hc on hc.HVCasePK = cp.HVCaseFK
         where PC1ID like 'jr%'
"@
Clear-Host
Invoke-Sqlcmd -Query $dbcmd `
                -ServerInstance $env:COMPUTERNAME\ `
                -SuppressProviderContextWarning `

# put the output into a variable so we can use it later
Clear-Host
$myOutput = Invoke-Sqlcmd -Query $dbcmd `
                            -ServerInstance $env:COMPUTERNAME `
                            -SuppressProviderContextWarning `
# see the result
$myOutput            # As the default table
$myOutput | Format-Table -AutoSize
$myOutput.HVCasePK

# System.Data.DataRow datatype
$myOutput.GetType()

# Get-Member will output the full type name and other info
$myOutput | Get-Member

##