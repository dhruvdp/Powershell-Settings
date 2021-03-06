function Open-EC2Port
{
    <#
    .Synopsis
        Opens Ports on EC2 Instances
    .Description
        Opens port ranges on EC2 Instances
    .Link
        Enable-EC2Remoting
    .Example
        Get-EC2 |
            Open-EC2Port -Range 80 
    #>
    [OutputType([Nullable],[PSObject])]
    param(
    # The name of the security group
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('GroupName')]
    [string]$SecurityGroup,
    
    # The port range to open
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Uint32[]]$Range,
    
    # The IP address to allow
    [string]$CidrIP = "0.0.0.0/0",
        
    # The protocol to allow
    [ValidateSet('tcp','udp','icmp')]
    [string]$Protocol = 'tcp',
    
    # IF set, will output the group
    [Switch]$PassThru        
    )
            
    process {
        
        $authorizeRequest=  New-Object Amazon.EC2.Model.AuthorizeSecurityGroupIngressRequest
        $fromPort = $range | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
        $toPort = $range | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
        
        $auth = $authorizeRequest.WithGroupName($SecurityGroup).WithIpProtocol($Protocol).WithFromPort($FromPort).WithToPort($ToPort).WithCidrIp($CidrIP)
        $null = $AwsConnections.EC2.AuthorizeSecurityGroupIngress($auth)
        
        if ($PassThru) {
            if ($_) { 
                $_
            } else {
                $SecurityGroup
            }            
        }
    }
}
