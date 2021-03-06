function Remove-Daemon
{
    <#
    .Synopsis
        Removes a Daemon in the system
    .Description
        Removes a Daemon (Service) registered on the system
    Out-Deamon -ScriptBlock {    
            Write-Warning "Warning"
            Write-Error "Error"
            $VerbosePreference = 'continue'
            Write-Verbose "Verbose"
            $debugPreference = 'continue'
            Write-Debug "Debug"
            Write-Progress "a" "b" -PercentComplete 1
            1
            New-Object PSObject -Property @{"A" = "b";"c" = "d" }
    } -Interval "00:00:15" -Name streamtest

    Remove-Daemon -Name streamtest
    #>

        
    param(
    # The name of the daemon.  Can be either the short name or the display name.  Can include wildcards.
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
    [string]
    $Name,

    # If set, will remove the executable and the output files
    [Switch]
    $RemoveContent
    )

    process {
        Get-WmiObject Win32_Service| Where-Object {$_.Name -like $name -or $_.DisplayName -like $name } |
            ForEach-Object {
                $d = $_ 
                $null = Stop-Service -Name $d.Name
                $null = $_.Delete()

                if ($RemoveContent) {
                    $subName = Get-Item $d.PathName
                    $subName = $subName.Name.TrimEnd($subName.Extension)
                    Get-ChildItem -Path ($d.PathName | Split-Path) -Filter "$subName.*.out" | Remove-Item
                    Remove-Item $d.PathName 
                }
            }
    }
}
 
