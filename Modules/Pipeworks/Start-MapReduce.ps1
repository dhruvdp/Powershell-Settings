function Start-MapReduce
{
    <#
    .Synopsis
        Runs a MapReduce on a set of data
    .Description
        Runs a MapReduce on a set of data, sequentially or in background jobs, on one or more machines.


        MapReduce is an approach to summarizing data.  With MapReduce:
        
        * A Map function takes each value of incoming data and returns one or more objects summarizing that data
        * The summarized data is grouped and passed to one or more functions that reduce that data into a final result

    .Example
        New-Object PSObject -Property @{
            Text = "the quick brown fox jumped over the lazy dog"
        } | 
            Start-MapReduce -Map {
                param($Text, $data) 


                foreach ($w in ($text -split ' ')) {
                    New-Object PSObject -Property @{
                        Word = $w 
                        Count = 1
                    }
                }
            } -Reduce {
                param($Word, $WordCount) 

                New-Object PSObject -Property @{
                    Word = $word 
                    Count = $WordCount | Measure-Object -Property Count -Sum | Select-Object -ExpandProperty Sum
                } 
            } 
    .Link
        http://en.wikipedia.org/wiki/Mapreduce
    #>
    [CmdletBinding(DefaultParameterSetName='Local')]
    param(
    # One or more map functions
    [ValidateScript({
        foreach ($sb in $_) {
            Set-Item function:Map0 -Value $sb
            $mapFunc = $ExecutionContext.SessionState.InvokeCommand.GetCommand("Map0", "Function")
            Remove-Item function:Map0
            if ($mapFunc.Parameters.Count -ne 2) {
                throw "Map functions must have two parameters"
            }
        
        }
        return $true
    })]    
    [Parameter(Mandatory=$true,Position=0)]
    [ScriptBlock[]]
    $Map,

    # One or more reduce functions    

    [Parameter(Mandatory=$true,Position=1)]
    [ValidateScript({
        foreach ($sb in $_) {
            Set-Item function:Reduce0 -Value $sb
            $reduceFunc = $ExecutionContext.SessionState.InvokeCommand.GetCommand("Reduce0", "Function")
            Remove-Item function:Reduce0
            if ($reduceFunc.Parameters.Count -ne 2) {
                throw "Reduce functions must have two parameters"
            }
        
        }
        return $true
    })]    
    [ScriptBlock[]]
    $Reduce,

    # A set of input data
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject[]]
    $InputObject,


    # The number of records in each shard.  By default, this will be the square root of the number of total items.
    [Uint32]
    $ShardSize,

    # The number of record in each batch.  By default, this will be the square root of the number of the shard size.
    [Uint32]
    $BatchSize,

    # The buffer between job launches.  By default, 1/4th of a second.
    [Timespan]
    $Buffer = [Timespan]::FromMilliseconds(250),

    # If set, reduce will be run sequentially
    [Switch]
    $RunReduceSequentially,

    # If set, map will be run sequentially
    [Switch]
    $RunMapSequentially,

    # A list of computers that will be used in the map reduce
    [Parameter(Mandatory=$true,ParameterSetName='Grid')]
    [Alias('Node')]
    [string[]]
    $Grid,

    # If set, the local machine will be included in the grid
    [Parameter(ParameterSetName='Grid')]
    [Switch]
    $IncludeLocalhost,

    # The credential to use when remoting to the grid
    [Parameter(ParameterSetName='Grid')]
    [Management.Automation.PSCredential]
    $Credential,


    # The ratio of use of the local node to remote nodes in the grid.  By default, the ratio will be 1/n, where N is the number of nodes including localhost.
    # If provided, a use of the local host will be entered in once for every N items.  For instance, a LocalRatio of 1 would run every other job on the local machine, a LocalRatio of 2 would run every 3rd job on the local machine, and so on.
    [Parameter(ParameterSetName='Grid')]
    [Uint32]
    $LocalRatio    
    )

    begin {
        $accumulatedObjects = New-Object Collections.ArrayList
        $progressId = Get-Random
    }

    process {
        $null = $accumulatedObjects.AddRange($InputObject)
        Write-Progress "Accumulating Input" "$($accumulatedObjects.Count) Objects Accumulated" -id $progressId
    }

    end {
        

        $psBoundParameters["InputObject"] = $accumulatedObjects
        
        

        if (-not $PSBoundParameters.ShardSize) {
            $shardSize = [Math]::Sqrt($accumulatedObjects.Count)
        }

        if (-not $PSBoundParameters.BatchSize) {
            $batchSize = [Math]::Sqrt($ShardSize)
        }

        if ($IncludeLocalhost -and $Grid) {
            if (-not $LocalRatio) {
            $grid=@('localhost') + $Grid
            } else {
                $newGrid = @()
                for ($gc = 0; $gc -lt $grid.count;$gc+=$LocalRatio) {
                    $newGrid+='localhost'
                    $newGrid +=$grid[$gc..($gc + $LocalRatio -1)]
                }
                $grid = $newGrid
            }
        }

        $script:JobsLaunched = @{}
        $launchJob = {
            param($s, $jobInfo)
            
            $j = if ($jobInfo.ComputerName -and $jobInfo.ComputerName -ne 'localhost') {
                if ($jobInfo.Credential) {                                                    
                    Invoke-Command -ArgumentList $s, $jobInfo.JobData.Data -ScriptBlock $jobInfo.JobScript -ComputerName $jobInfo.ComputerName -AsJob -Credential $jobInfo.Credential -ErrorAction Stop
                    
                } else {
                    
                    Invoke-Command -ArgumentList $s, $jobInfo.JobData.Data -ScriptBlock $jobInfo.JobScript -ComputerName $jobInfo.ComputerName -AsJob -ErrorAction Stop                    
                }
                            
            } else {                
                Start-Job -ArgumentList $s, $jobInfo.JobData.Data -ScriptBlock $jobInfo.JobScript -ErrorAction Stop                
            }
            $script:JobsLaunched[$j.Name] = $jobInfo
            $j
        }
        
        #region Map
        $allMapResults = @(
        $n = 0
        foreach ($m in $map) {
            
            $n++
            Set-Item function:Map0 -Value $m
            
            $mapFunction= $ExecutionContext.SessionState.InvokeCommand.GetCommand("Map0", "Function")
            $MapKey = $mapFunction.Parameters.Values | 
                Sort-Object { $_.ParameterSets.Values[0].Position } | 
                Select-Object -First 1 -ExpandProperty Name

            Write-progress "Mapping $MapKey" " " -id $progressId

            $mapResults = New-Object Collections.ArrayList
            
            $RunMap = {
                param($mapScript, $accumulatedObjects)                
                Set-Item function:Map0 -Value $mapScript            
                $mapFunction= $ExecutionContext.SessionState.InvokeCommand.GetCommand("Map0", "Function")
                $MapKey = $mapFunction.Parameters.Values | 
                    Sort-Object { $_.ParameterSets.Values[0].Position } | 
                    Select-Object -First 1 -ExpandProperty Name

                
                foreach ($obj in $accumulatedObjects) {
                    if ($obj.$mapKey) {
                        & $mapFunction $obj.$mapKey $obj
                    }                    
                }                
            }
            $startMapTime = [DateTime]::Now
            Write-Verbose "Starting Map @ $StartMapTime"
            if (-not $RunMapSequentially) {
                $finished = 0 
                $jobQueue = New-Object Collections.Queue 
                if ($Grid) {
                    $currentGridIndex =  0
                }   
                for ($i = 0; $i -lt $accumulatedObjects.Count; $i+=$ShardSize) {
                    
                    $perc = $i / $accumulatedObjects.Count
                    Write-Progress "Creating Shards" "Of $ShardSize" -PercentComplete $perc
                    $jobItem= @{
                        JobScript = $RunMap
                        JobData = @{
                            Data = $accumulatedObjects[$i..($i + (1 * $ShardSize) -1)]                            
                            Offset = $i * $ShardSize
                        }
                    }

                    if ($Grid) {
                        $jobItem.ComputerName = $grid[$currentGridIndex]
                        if ($Credential) {
                            $jobItem.Credential = $Credential
                        }
                        $currentGridIndex++
                        if ($currentGridIndex -eq $grid.Length) {
                            $currentGridIndex = 0 
                        }
                    }
                    $null = $jobQueue.Enqueue($jobItem)
                }

                $jobQueueSize = $jobQueue.Count
                $jobs = @()
                $Launched = 0 
                while ($jobQueue.Count -gt 0){
                    
            
                    if ($jobs.Count -lt $BatchSize) {
                        $jobInfo = $jobQueue.Dequeue()
                        $launched++
                        $perc = ($Launched / $jobQueueSize ) * 100

                        if ($perc -le 100) {
                            Write-Progress "Launching Map Batches" "$launched Launched - $Finished Finished" -PercentComplete $perc
                        } else {
                            Write-Progress "Launching Map Batches (Rescheduled Items)" "$launched Launched - $Finished Finished" -PercentComplete 100
                        }
                        

                        $job = . $launchJob $m $jobInfo
                        
                        $null = $jobs+=$job
                    } else {
                        foreach ($j in @($jobs)) {
                            if ($j.State -eq 'Completed' -or $j.State -eq 'Failed') {  
                                $finished++                              
                                try {
                                    Receive-Job -Job $j -ErrorAction Stop                            
                                } catch {
                                    if ($_.FullyQualifiedErrorId -eq 'PSSessionStateBroken') {
                                        Write-Verbose "Rescheduling $($j.Name)"
                                        $null = $jobQueue.Enqueue($script:JobsLaunched[$j.Name] )    
                                    } else {
                                        Write-Error $_
                                    }
                                    
                                }
                                $jobs = @($jobs | Where-Object { $_.Name -ne $j.Name })
                                $j | Remove-Job                        
                            } else {
                                try {
                                    Receive-Job -Job $j -ErrorAction Stop                            
                                } catch {
                                    if ($_.FullyQualifiedErrorId -eq 'PSSessionStateBroken') {
                                        Write-Verbose "Rescheduling $($j.Name)"
                                        $null = $jobQueue.Enqueue($script:JobsLaunched[$j.Name] )    
                                    } else {
                                        Write-Error $_
                                    }
                                }
                            }                            
                        }
                        $jobsToLaunch = $numberOfBatches - $jobs.Count
                        for ($jc = 0 ;$jc  -lt $jobsToLaunch; $jc++) {
                            $jobInfo = $jobQueue.Dequeue()
                            $launched++
                            $perc = ($Launched / $jobQueueSize ) * 100
                            if ($perc -le 100) {
                            Write-Progress "Launching Map Batches" "$launched Launched - $Finished Finished" -PercentComplete $perc
                            } else {
                                Write-Progress "Launching Map Batches (Rescheduled Items)" "$launched Launched - $Finished Finished" -PercentComplete 100
                            }
                            $job = . $launchJob $m $jobInfo
                            $null = $jobs+=$job 
                        }
                        Start-Sleep -Milliseconds $Buffer.TotalMilliseconds
                    }                                    
                }       
                while (@($jobs).Count) {
                    foreach ($j in @($jobs)) {
                        if ($j.State -eq 'Completed' -or $j.State -eq 'Failed') {  
                            $finished++                              
                            try {
                                Receive-Job -Job $j -ErrorAction Stop                            
                            } catch {
                                if ($_.FullyQualifiedErrorId -eq 'PSSessionStateBroken') {
                                    Write-Verbose "Rescheduling $($j.Name)"                                    
                                    $jobs += . $launchJob $m $script:JobsLaunched[$j.Name]
                                } else {
                                    Write-Error $_
                                }
                                    
                            }
                            $jobs = @($jobs | Where-Object { $_.Name -ne $j.Name })
                            if ($j.State -eq 'Completed') {
                                $j | Remove-Job                        
                            }
                        } 
                    }
                }         
            } else {            
                & $RunMap -mapScript $m -AccumulatedObjects $accumulatedObjects
            }
                        
            Remove-Item function:Map0
        })

        Write-verbose "Time spent mapping $([DateTime]::Now -$StartMapTime)"
        #endregion Map

        $reduceStartedAt = [DateTime]::now

        Write-Verbose "Starting Reduce @ $reduceStartedAt"

        #region Reduce
        foreach ($r in $Reduce) {
            
            Set-Item function:Reduce0 -Value $r 
            
            $reduceFunction = $ExecutionContext.SessionState.InvokeCommand.GetCommand("Reduce0", "Function")
            $ReduceKey = $reduceFunction.Parameters.Values | 
                    Sort-Object { $_.ParameterSets.Values[0].Position } | 
                    Select-Object -First 1 -ExpandProperty Name
            Write-progress "Reducing $MapKey" " " -id $progressId

            $sortStartTime = [DateTime]::now
            Write-verbose "Starting Sort & Group @ $SortStartTime"
            Write-Progress "Sorting MapResults" "By $ReduceKey" -Id $progressId
            $sortedResults = Sort-Object -InputObject $allMapResults -Property $ReduceKey -Descending
            Write-Progress "Grouping MapResults" "By $ReduceKey" -Id $progressId
            $groupedResults = @($sortedResults  | Group-Object -Property $ReduceKey)
            Write-verbose "Time spent in Sort & Group $([Datetime]::Now -$SortStartTime)"
            $reduceResults = New-Object Collections.ArrayList


            $RunReduce = {
                param($reduceScript, $reducedGroup)                


                $progId = Get-Random
                
                Set-Item function:Reduce0 -Value $reduceScript
                $reduceFunction = $ExecutionContext.SessionState.InvokeCommand.GetCommand("Reduce0", "Function")
                $ReduceKey = $reduceFunction.Parameters.Values | 
                    Sort-Object { $_.ParameterSets.Values[0].Position } | 
                    Select-Object -First 1 -ExpandProperty Name                               
                
                foreach ($group in $reducedGroup) {
                    if ($group.Name) {
                        & $reduceFunction $group.Name $group.Group
                    }
                }                                                                                                                
            }

            if (-not $RunReduceSequentially) {
                $finished = 0 
                $jobQueue = New-Object Collections.Queue    
                if (-not $PSBoundParameters.ShardSize) {
                    $shardSize = [Math]::Sqrt($groupedResults.Count)
                }

                if (-not $PSBoundParameters.BatchSize) {
                    $batchSize = [Math]::Sqrt($ShardSize)
                }

                if ($grid) {
                    $currentGridIndex = 0
                }
                
                for ($i = 0; $i -lt $groupedResults.Count; $i+=$shardSize) {                    
                    $perc = $i * 100/ $groupedResults.Count
                    Write-Progress "Creating Shards" "of $ShardSize" -PercentComplete $perc
                    $jobItem= @{
                        JobScript = $RunReduce
                        JobData = @{
                            Data = $groupedResults[$i..($i + (1 * $ShardSize) -1)]                            
                                                   
                            Offset = $i * $ShardSize
                        }
                    }
                    if ($Grid) {
                        $jobItem.ComputerName = $grid[$currentGridIndex]
                        if ($Credential) {
                            $jobItem.Credential = $Credential
                        }
                        $currentGridIndex++
                        if ($currentGridIndex -eq $grid.Length) {
                            $currentGridIndex = 0 
                        }
                    }
                    $null = $jobQueue.Enqueue($jobItem)
                }

                $jobQueueSize = $jobQueue.Count
                $jobs = @()
                $Launched = 0 
                while ($jobQueue.Count -gt 0){                                
                    if ($jobs.Count -lt $BatchSize) {
                        $jobInfo = $jobQueue.Dequeue()
                        $launched++
                        $perc = ($Launched / $jobQueueSize ) * 100
                        if ($perc -le 100) {
                            Write-Progress "Launching Reduce Batches" "$launched Launched - $Finished Finished" -PercentComplete $perc
                        } else {
                            Write-Progress "Launching Reduce Batches (Rescheduled Items)" "$launched Launched - $Finished Finished" -PercentComplete 100
                        }
                        $job =  . $LaunchJob $r $jobInfo
                        $null = $jobs+=$job
                    } else {
                        foreach ($j in @($jobs)) {
                            if ($j.State -eq 'Completed' -or $j.State -eq 'Failed') {                                
                                $finished++ 
                                try {
                                    Receive-Job -Job $j -ErrorAction Stop                            
                                } catch {
                                    if ($_.FullyQualifiedErrorId -eq 'PSSessionStateBroken') {
                                        Write-Verbose "Rescheduling $($j.Name)"
                                        $null = $jobQueue.Enqueue($script:JobsLaunched[$j.Name] )    
                                    } else {
                                        Write-Error $_
                                    }
                                }
                                $jobs = @($jobs | Where-Object { $_.Name -ne $j.Name })
                                $j | Remove-Job                        
                            } else {
                                try {
                                    Receive-Job -Job $j -ErrorAction Stop                            
                                } catch {
                                    if ($_.FullyQualifiedErrorId -eq 'PSSessionStateBroken') {
                                        Write-Verbose "Rescheduling $($j.Name)"
                                        $null = $jobQueue.Enqueue($script:JobsLaunched[$j.Name] )    
                                    } else {
                                        Write-Error $_
                                    }             
                                }
                            }
                            
                            
                            
                        }
                        $jobsToLaunch = $numberOfBatches - $jobs.Count
                        for ($jc = 0 ;$jc  -lt $jobsToLaunch; $jc++) {
                            $jobInfo = $jobQueue.Dequeue()
                            $launched++
                            $perc = ($Launched / $jobQueueSize ) * 100
                            if ($perc -le 100) {
                                Write-Progress "Launching Reduce Batches" "$launched Launched - $Finished Finished" -PercentComplete $perc
                            } else {
                                Write-Progress "Launching Reduce Batches (Rescheduled Items)" "$launched Launched - $Finished Finished" -PercentComplete 100
                            }
                            $job =  . $LaunchJob $r $jobInfo.JobData.Data 
                            $null = $jobs+=$job 
                        }
                        Start-Sleep -Milliseconds $Buffer.TotalMilliseconds
                    }
            
            
            
                }

                while (@($jobs).Count) {
                    foreach ($j in @($jobs)) {
                        if ($j.State -eq 'Completed' -or $j.State -eq 'Failed') {  
                            $finished++                              
                            try {
                                Receive-Job -Job $j -ErrorAction Stop                            
                            } catch {
                                if ($_.FullyQualifiedErrorId -eq 'PSSessionStateBroken') {
                                    Write-Verbose "Rescheduling $($j.Name)"                                    
                                    $jobs += . $launchJob $r $script:JobsLaunched[$j.Name]
                                } else {
                                    Write-Error $_
                                }
                                    
                            }
                            $jobs = @($jobs | Where-Object { $_.Name -ne $j.Name })
                            if ($j.State -eq 'Completed') {
                                $j | Remove-Job                        
                            }                        
                        } 
                    }
                }  
                
            } else {
                & $RunReduce $r $groupedResults
            }

            

            Remove-Item function:Reduce0
        }
        #endregion Reduce

        Write-verbose "Time spent in Reduce $([Datetime]::Now -$reduceStartedAt)"                       
    }
} 
