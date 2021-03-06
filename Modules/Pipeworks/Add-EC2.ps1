function Add-EC2
{
    <#
    .Synopsis
        Adds an EC2 instance to Amazon Web Services
    .Description
        Adds EC2 instances to Amazon Web Services.  
    .Example
        Add-EC2 -ImageId ami-e31ccb8a #2k8R2
    .Example
        Add-EC2 -ImageId ami-41a37528 #2k8
    .Example
        Add-EC2 -ImageId ami-ddad7bb4 # Server Core 
        
    .Example
        Add-Ec2 -ImageId ami-ddad7bb4 -InstanceType m1.medium
    .Link
        Get-Ami
    .Link
        Get-EC2
    #>
    param(
    # The AMI ImageID
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [string]$ImageId,
    # The name of the instance
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]
    [string]$Name,        
    # The Instance Type (or size) to create.  The default is t1.micro
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateSet("m1.small", "m1.medium", "m1.large", "m1.xlarge", "t1.micro", 
        "m2.xlarge", "m2.2xlarge", "m2.4xlarge", 
        "c1.medium", "c1.xlarge", "cc1.4xlarge", "cc2.8xlarge", "cg1.4xlarge")]
    [string]$InstanceType = "t1.micro",
    # The minimum CPU Count
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Uint32]$MinCPUCount = 1,
    # The maximum CPU Count
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Uint32]$MaxCPUCount = 1,
    
    # The securityGroup that will contain the EC2 image
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$SecurityGroup = "RemoteDesktop",
    
    # If set, returns the created item
    [Switch]$PassThru
    )
    
    begin {
        # Look up the existing instances
        $existingInstances = Get-EC2
    }
    
    process {
        # Look up the existing instances
        $instanceCountWithThisAMI = @($existingInstances | 
            Where-Object { $_.ImageId -eq $imageId }).Count
        
        $instanceCountWithThisAMI = "{0:x}" -f (Get-Random)
            
                
        $riq = (New-Object Amazon.EC2.Model.RunInstancesRequest)
        if (-not $?) {
            Write-Error "EC2 c# SDK is not installed"
            return
        }
        if (-not $psBoundParameters.Name) {
            $name = "EC2_${ImageId}_${instanceCountWithThisAMI}"
        }
                
        if ($psBoundParameters.SecurityGroup) {
            # They've selected an existing security group, so find it
            $securityGroupId = 
                Get-EC2SecurityGroup|
                Where-Object {
                    $_.GroupName -eq $SecurityGroup
                } |
                Select-Object -ExpandProperty GroupId
        } else {
            # Create a security group on their behalf
            $securityGroup = "EC2_${ImageId}_${instanceCountWithThisAMI}_SecurityGroup"
            $securityGroupRequest = (New-Object Amazon.EC2.Model.CreateSecurityGroupRequest).WithGroupName($SecurityGroup)
            $securityGroupRequest  = $securityGroupRequest.WithGroupDescription("SecurityGroup for EC2 ${ImageId}_${instanceCountWithThisAMI}")            
            $securityGroupResult = $AwsConnections.EC2.CreateSecurityGroup($securityGroupRequest)
            $securityGroupId = $securityGroupResult.CreateSecurityGroupResult.GroupId
        }
        
        $keyPairRequest = (New-Object Amazon.EC2.Model.CreateKeyPairRequest).WithKeyName($name)
        $keyPairOutput = $AwsConnections.EC2.CreateKeyPair($keyPairRequest)
        
        # Store the key material encrypted in the registry, so we can decrypt the password later.
        Add-SecureSetting -Name $keyPairOutput.CreateKeyPairResult.KeyPair.KeyName -String $keyPairOutput.CreateKeyPairResult.KeyPair.KeyMaterial        
        $riq = $riq.WithInstanceType($InstanceType).WithMaxCount($MaxCPUCount).WithMinCount($MinCPUCount).WithImageId("$ImageId").WithKeyName($name).WithSecurityGroupId($SecurityGroupId)
        
        
        
        $null = $AwsConnections.EC2.RunInstances($riq)
        
        if ($PassThru) {
            Get-EC2 -Name $name 
        }
    }
    
} 
