<#
.Synopsis
    Starts an AWS session that requires MFA
.EXAMPLE
    Get-AwsSession <token>
.EXAMPLE
    Get-AwsMfaSession -MfaToken <token> -AwsProfile <profile>
#>
function Get-AwsMfaSession {
    [CmdletBinding()]
    Param
    (
        # MFA Token
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $MfaToken,

        # AWS Profile
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        $AwsProfile
    )

    Begin {
        if ($Env:AWS_PROFILE -eq $null) {
            if ($AwsProfile -eq $null) {
                Write-Host "Enter the name of the AWS profile to use: " -NoNewLine
                $AwsProfile = Read-Host
            }
        } else {
            if ($AwsProfile -eq $null) {
                $AwsProfile = $Env:AWS_PROFILE
            } else {
                Write-Host "Overriding AWS_PROFILE environment variable with: $AwsProfile"
            }
        }
        
        Write-Host "Using AWS_PROFILE: $AwsProfile"
        
        if ($MfaToken -eq $null) {
            Write-Host "Enter the MFA token: " -NoNewLine
            $MfaToken = Read-Host
        }
    }
    Process {
        $mfa_serial = (aws configure get mfa_serial --profile $AwsProfile)
        write-host $mfa_serial
        
        try {
            $creds = (aws sts get-session-token --serial-number $mfa_serial --token-code $MfaToken --profile $AwsProfile |
            ConvertFrom-Json).Credentials

            if ($creds -eq $null) {
                Write-Host "Failed to start session" -ForegroundColor Red
                return
            }

            $Env:AWS_PROFILE = $AwsProfile
            $Env:AWS_ACCESS_KEY_ID = $creds.AccessKeyId
            $Env:AWS_SECRET_ACCESS_KEY = $creds.SecretAccessKey
            $Env:AWS_SESSION_TOKEN = $creds.SessionToken

            Write-Host "Session started for $AwsProfile" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to start session" -ForegroundColor Red
            return
        }
    }
    End {
    }
}