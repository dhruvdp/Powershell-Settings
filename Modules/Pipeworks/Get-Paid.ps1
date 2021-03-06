function Get-Paid
{
    <#
    .Synopsis
        Gets you paid
    .Description
        Handles getting payments or payment confirmation information.
    .Example
        # A Sample Charge with the Stripe API
        Get-Paid -StripeKey sk_test_aElHsSizhc8XC0uESpNC1t64 -Currency usd -Amount 400 -CardNumber 4242424242424242 -ExpirationMonth 12 -ExpirationYear 2014 -CardVerficationCode 123
        

    #>
    [CmdletBinding(DefaultParameterSetName='Stripe')]
    param(
    # The charge amount
    [Parameter(Mandatory=$true,ParameterSetName='Stripe',Position=0)]
    [Parameter(Mandatory=$true,ParameterSetName='StripeToken',Position=0)]
    [Double]
    $Amount,

    # The charge currency
    [Parameter(Mandatory=$true,ParameterSetName='Stripe',Position=1)]
    [Parameter(Mandatory=$true,ParameterSetName='StripeToken',Position=1)]
    [string]
    $Currency,

    # The Stripe Token.  This is used to process payments that use the [Stripe Checkout form](https://stripe.com/docs/checkout)
    [Parameter(Mandatory=$true,ParameterSetName='StripeToken',Position=2)]
    [string]
    $StripeToken,

    # The card number
    [Parameter(Mandatory=$true,ParameterSetName='Stripe',Position=2)]
    [string]
    $CardNumber,

    # The Expiration Month
    [Parameter(Mandatory=$true,ParameterSetName='Stripe',Position=3)]
    [string]
    $ExpirationMonth,

    # The Expiration Year
    [Parameter(Mandatory=$true,ParameterSetName='Stripe',Position=4)]
    [string]
    $ExpirationYear,

    # The Card Verficiation Code
    [Parameter(Mandatory=$true,ParameterSetName='Stripe',Position=5)]
    [string]
    $CardVerficationCode,

    # The Stripe Key.  If provided once, it doesn't need to be provided again.
    [Parameter(ParameterSetName='Stripe')]
    [Parameter(ParameterSetName='StripeToken')]
    [string]
    $StripeKey,

    # The Secure setting containing the Stripe Key.  If provided once, it doesn't need to be provided again.
    [Parameter(ParameterSetName='Stripe')]
    [Parameter(ParameterSetName='StripeToken')]
    [string]
    $StripeKeySetting,

    # The PayPal Instant Payment Notification Info
    [Parameter(Mandatory=$true,ParameterSetName='ConfirmPayPalIPN')]
    [string]
    $IPNInfo
    )

    begin {
        $getStripeCred = {
            if (-not $script:CachedStripeCred -or $StripeKey -or $StripeKeySetting) {
                if (-not $StripeKey -and $StripeKeySetting) {
                    $StripeKey = Get-SecureSetting -Name $StripeKeySetting -ValueOnly
                }

                if (-not $StripeKey) {
                    Write-Error "Must provide a stripe key"
                    return
                }

                $script:CachedStripeCred = new-object Management.Automation.PSCredential "$StripeKey", (ConvertTo-SecureString -AsPlainText -Force -String " ")                
            }
        }.ToString()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Stripe') {
            
            Invoke-Expression $getStripeCred
            
            $data = "amount=$($Amount * 100)", 
                "currency=$Currency", 
                "card[number]=$CardNumber", 
                "card[exp_month]=$ExpirationMonth", 
                "card[exp_year]=$ExpirationYear", 
                "card[cvc]=$CardVerficationCode"           

            Get-Web -Url https://api.stripe.com/v1/charges -WebCredential $script:CachedStripeCred -Data $data -AsJson

        } elseif ($PSCmdlet.ParameterSetName -eq 'StripeToken') {
            


            Invoke-Expression $getStripeCred
            
            
            $data = "amount=$($Amount * 100)", 
                "currency=$Currency", 
                "card=$CardToken"

            Get-Web -Url https://api.stripe.com/v1/charges -WebCredential $script:CachedStripeCred -Data $data -AsJson

        } elseif ($PSCmdlet.ParameterSetName -eq 'ConfirmPayPalIPN') {

            $purchaseHistory = $userPart + "_Purchases"                        
            $req = [Net.HttpWebRequest]::Create("https://www.paypal.com/cgi-bin/webscr") 
            # //Set values for the request back
            $req.Method = "POST";
            $req.ContentType = "application/x-www-form-urlencoded"
            
            $strRequest = $IPNInfo + 
                "&cmd=_notify-validate";
            $req.ContentLength = $strRequest.Length;
 
            $parsed = [Web.HttpUtility]::ParseQueryString($strRequest)

            $streamOut = New-Object IO.StreamWriter $req.GetRequestStream()
            $streamOut.Write($strRequest);
            $streamOut.Close();
            $streamIn = New-Object IO.StreamReader($req.GetResponse().GetResponseStream());
            $strResponse = $streamIn.ReadToEnd();
            $streamIn.Close();
 
        }
               




    }
} 
