function Get-TextMessage
{
    <#
    .Synopsis
        Gets text messages
    .Description
        Get text messages sent to a Twilio number
    .Example
        Get-TextMessage
    .Link
        Twilio.com
    .Link
        Send-TextMessage
    #>

    param(    
    # The credential used to get the texts
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $Credential,
    
    
    # A setting storing the credential
    [Parameter(ValueFromPipelineByPropertyName=$true)]       
    [string[]]
    $Setting = @("TwilioAccountKey", "TwilioAccountSecret")
    )
    
    process {
        if (-not $Credential -and $Setting) {
            if ($setting.Count -eq 1) {

                $userName = Get-WebConfigurationSetting -Setting "${Setting}_UserName"
                $password = Get-WebConfigurationSetting -Setting "${Setting}_Password"
            } elseif ($setting.Count -eq 2)  {
                $userName = Get-secureSetting -Name $Setting[0] -ValueOnly
                $password= Get-secureSetting -Name $Setting[1] -ValueOnly
            }

            if ($userName -and $password) {                
                $password = ConvertTo-SecureString -AsPlainText -Force $password
                $credential  = New-Object Management.Automation.PSCredential $username, $password 
            } elseif ((Get-SecureSetting -Name "$Setting" -ValueOnly | Select-Object -First 1)) {
                $credential = (Get-SecureSetting -Name "$Setting" -ValueOnly | Select-Object -First 1)
            }
            
            
        }

        if (-not $Credential) {
            Write-Error "No Twilio Credential provided.  Use -Credential or Add-SecureSetting TwilioAccountDefault -Credential (Get-Credential) first"               
            return
        }

        $getWebParams = @{
            WebCredential=$Credential
            Url="https://api.twilio.com/2010-04-01/Accounts/$($Credential.GetNetworkCredential().Username.Trim())/SMS/Messages.xml"           
            AsXml =$true            
            UseWebRequest = $true
        }       
        
        do {
            $twiResponse = Get-Web @getwebParams -Verbose |            
                Select-Object -ExpandProperty TwilioResponse 
                
            if (-not $twiResponse) { break } 

            if ($twiResponse.SmsMessages) {
                $twiResponse.SmsMessages | 
                Select-Object -ExpandProperty SMSMessage |
                ForEach-Object {
                    $_.pstypenames.clear()
                    $_.pstypenames.add('Twilio.TextMessage')
                    $_
                }
            }
            if ($twiResponse.SmsMessages.NextPageUri) {
                $getWebParams.Url="https://api.twilio.com" + $twiResponse.SmsMessages.NextPageUri
    
            }


        } while ($twiResponse.SmsMessages.NextPageUri) 
              
    }       
}