function Push-FTP
{
    <#
    .Synopsis
        Pushes items to an FTP server
    .Description
        Pushes a directory to an FTP server
    .Example
        Push-Ftp -Path c:\Example -Include *.aspx        
    #>
    [CmdletBinding()]
    param(
    # The local path
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$Path,    
    # If set, will only include items that match the wildcard
    [string[]]$Include,
    # If set, will exclude items that match the wildcard
    [string[]]$Exclude,
    # The FTP server
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Uri]$FTP,
    
    # The credentail used to connect to the FTP server
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]$Credential
    )
    
    begin {
        $progressId = Get-Random
    }
    process {
        $webClient = New-Object Net.Webclient
        $root = Get-Item $path
        $files = Get-ChildItem $path -Recurse 
        
        $remainingFiles = foreach ( $item in $files) {
            if ($include) {
                $found = $false
                $found =                
                    foreach ($i in $include) {
                        if ($item.Fullname -ilike "$i") {
                            $true
                            break
                        }
                    }
                if (-not $found) {
                    continue
                }
            }
            
            if ($exclude) {
                $found = $false
                $found = 
                    foreach ($ex in $exclude) {
                        if ($item.Fullname -ilike "$ex") {
                            $true
                            break
                        }
                    }
                    
                if ($found) {
                    continue
                }
            }
            $relativePath = $item.Fullname -ireplace $path.Replace("\","\\").Replace(":", "\:"),""        
            if ($item.PsIsContainer) {
                Write-Progress "Creating Directories" $item.Fullname -Id $progressId 
                $relativePath  = $relativePath -replace "\\", "/"    
                $url = "$ftp".TrimEnd("/")  + $relativePath
                $url = $url.TrimEnd("/") + "/"
                $ftpRequest = [Net.WebRequest]::Create($url)
                $ftpRequest.Credentials = New-Object Net.NetworkCredential $Credential.Username, $Credential.GetNetworkCredential().Password                
                $ftpRequest.Method = [Net.WebRequestMethods+Ftp]::MakeDirectory
                try { 
                    $result = $ftpRequest.GetResponse()        
                } catch {
                    Write-Verbose "Error creating directory $ftp - $($item.Fullname)"
                }
            } else {
                $item
            }
        }
        
        $c  = 0 
        foreach ($f in $remainingFiles) {
            $item = $f
            $relativePath = $f.Fullname.Replace($path,"")        
            $perc = $c * 100 /@($remainingFiles).Count
            $c++
                
            Write-Progress "Uploading Files" $item.Fullname -PercentComplete $perc -Id $progressId 
            # Upload the file
            $relativePath  = $relativePath -replace "\\", "/"
            $domainSubpath = $Credential.GetNetworkCredential().Domain
            $domainSubpath = "$ftp".Substring(("$ftp".IndexOf($domainSubpath) + $domainSubpath.Length))
            $domainSubpath  = $domainSubpath.TrimEnd("/") + $relativePath
            
            
            $url = "ftp://$($Credential.GetNetworkCredential().Username):$($Credential.GetNetworkCredential().Password)@$($Credential.GetNetworkCredential().Domain)$domainSubpath"                    
            try { 
                $webClient.UploadFile($url, "$($item.Fullname)")
            } catch{
                Write-Verbose "Error uploading $($item.Fullname) to $domainSubpath"                        
            }
                
        }   
        
        
    }
    
    end {
        Write-Progress "Uploading Files" "Completed" -Completed -Id $progressId 
    }   
}
 
