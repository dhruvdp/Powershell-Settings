function Copy-SQL
{
    param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='InputObject')]
    [PSObject[]]
    $InputObject,

    # The name of the SQL table
    [Parameter(Mandatory=$true)]
    [string]$TableName,

    # The property of the input object to use as a row    
    [string]
    $RowProperty,

    # The connection string or a setting containing the connection string.
    [String]
    $ConnectionStringOrSetting,

    [Switch]
    $OutputSql,

    # If set, will use SQL server compact edition    
    [Switch]
    $UseSQLCompact,

    # The path to SQL Compact.  If not provided, SQL compact will be loaded from the GAC    
    [string]
    $SqlCompactPath,    
    

    # If set, will use SQL lite    
    [Alias('UseSqlLite')]
    [switch]
    $UseSQLite,
    
    # The path to SQLite.  If not provided, SQLite will be loaded from Program Files
    [Alias('SqlLitePath')]
    [string]    
    $SqlitePath,
    
    
    # The path to a SQL compact or SQL lite database    
    [Alias('DBPath')]
    [string]
    $DatabasePath,

    [Switch]
    $RunAs32
    
    )


    begin {
        $objects = New-Object Collections.ArrayList
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'InputObject') {

            $null = $objects.AddRange($inputObject)
            Write-Progress "Adding Objects" $objects.Count 
        }
    }

    end {
        $databatchSize = [Math]::Ceiling([Math]::Sqrt($objects.Count))

        $numberofBatches = [Math]::Ceiling([Math]::Sqrt($databatchSize))

        $jobQueue = New-Object Collections.Queue
        $sqlParams = @{} + $psboundparameters
        foreach ($k in @($sqlParams.Keys)) {
            if ('SqlCompactPath', 'UseSqlCompact', 'SqlitePath', 'UseSqlite', 'DatabasePath', 'ConnectionStringOrSetting', 'TableName', 'RowProperty' -notcontains $k) {
                $sqlParams.Remove($k)
            }
        }

        
        for ($i = 0; $i -lt $databatchSize; $i++) {
            $perc = $i * 100 / $databatchSize
            Write-Progress "Creating Batches" "$i of $databatchSize" -PercentComplete $perc
            $jobItem= @{
                JobScript = {
                    param([Hashtable]$JobData)
                    $process = Get-Process -Id $pid
                    #$process.PriorityClass = "AboveNormal"
                    #[Threading.Thread]::currentThread.Priority = "AboveNormal"
                    $progressId = Get-Random
                    $input = $JobData.Data
                    $jobData.Remove("Data")
                    $pipeworksPath = $JobData.PipeworksPath
                    $jobData.Remove("PipeworksPath")
                    $offset = $JobData.Offset

                    $jobData.Remove("Offset")
                    
                    Import-Module -Name $pipeworksPath
                    $count = 0
                    foreach ($in in $input) {
                        $perc = $count * 100 / $input.Count                        
                        Write-Progress "Updating SQL" "$($offset + $count)" -PercentComplete $perc -Id $progressId
                        if ($count -gt 0) {
                            $JobData.DoNotCheckTable = $true
                        }
                        $count++
                        if ($count -eq $input.Count) {
                            $JobData.KeepConnected  = $false
                        } else {
                            $JobData.KeepConnected  = $true
                        }
                        $in | 
                            Update-Sql @jobData
                    }

                    Write-Progress "Updating SQL" "$($offset + $count)" -Completed -Id $progressId
                    
                }
                JobData = @{
                    Data = $objects[($i * $databatchSize)..(($i + 1) * $databatchSize)]
                    PipeworksPath = Get-Module Pipeworks | Split-Path
                    Force = $true
                    Offset = $i * $databatchSize
                } + $sqlParams
            }
            $null = $jobQueue.Enqueue($jobItem)
        }

        $jobs = @()
        $Launched = 0 
        while ($jobQueue.Count -gt 0){
            
            
            if ($jobs.Count -lt $numberofBatches) {
                $jobInfo = $jobQueue.Dequeue()
                $launched++
                $perc = ($Launched / $databatchSize ) * 100
                Write-Progress "Launching Batches" "$launched Launched" -PercentComplete $perc
                $job = Start-Job -ArgumentList $jobInfo.JobData -ScriptBlock $jobInfo.JobScript -RunAs32:$runAs32 
                $null = $jobs+=$job
            } else {
                foreach ($j in @($jobs)) {
                    if ($j.State -eq 'Completed' -or $j.State -eq 'Failed') {
                        $j | Receive-Job
                        $jobs = @($jobs | Where-Object { $_.Name -ne $j.Name })
                        $j | Remove-Job
                        
                    }
                    Receive-Job -Job $j
                }
                $jobsToLaunch = $numberOfBatches - $jobs.Count
                for ($jc = 0 ;$jc  -lt $jobsToLaunch; $jc++) {
                    $jobInfo = $jobQueue.Dequeue()
                    $launched++
                    $perc = ($Launched / $databatchSize ) * 100
                    Write-Progress "Launching Batches" "$launched Launched" -PercentComplete $perc
                    $job = Start-Job -ArgumentList $jobInfo.JobData -ScriptBlock $jobInfo.JobScript -RunAs32:$runAs32
                    $null = $jobs+=$job 
                }
                Start-Sleep -Milliseconds 125
            }
            
            
            
        }

        $jobQueue.Count
    }
}
 
