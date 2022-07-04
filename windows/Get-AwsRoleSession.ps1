<#
.Synopsis
    Takes cached credentials for a role session and dumps into environment variables
    Requires adding a config variable to profile in .aws/config file, matching the AssumedRoleArn in cache file
    Example: arn:aws:sts::XXXXXXXXXXXX:assumed-role/xjg-admin-cross-account-role/admin
    I believe the format is the follwoing arn:aws:sts::{account_id}:assumed-role/{role_name}/{role_session_name}
    All of this should be static
.EXAMPLE
    Get-AwsRoleSession <profile>
.EXAMPLE
    Get-AwsRoleSession -AwsProfile <profile>
#>
function Get-AwsRoleSession {
    [CmdletBinding()]
    Param
    (
        # AWS Profile
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
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

        $RoleArn = (aws configure get role_arn --profile $AwsProfile)
        if ($RoleArn -eq $null) {
            Write-Host "No role found for profile: $AwsProfile. Does this profile use a role?" 
            break
        }
        
        $AssumedRoleArn = (aws configure get assumed_role_arn --profile $AwsProfile)
        
        if ($AssumedRoleArn -eq $null) {
            Write-Host "No assumed_role_arn found for profile: $AwsProfile. Please add an assumed_role_arn to the profile in ~/.aws/config"
            break
        }
    }
    Process {
        $CacheFile = Get-CacheFile $AwsProfile $AssumedRoleArn $true
        
        if ($CacheFile -eq $false) {
            Write-Host "Unable to find cached credentials for profile: $AwsProfile" -ForegroundColor Red
            return
        }
        
        $Env:AWS_PROFILE = $AwsProfile
        $Env:AWS_ACCESS_KEY_ID = $CacheFile.AccessKeyId
        $Env:AWS_SECRET_ACCESS_KEY = $CacheFile.SecretAccessKey
        $Env:AWS_SESSION_TOKEN = $CacheFile.SessionToken

        Write-Host "Session started for $AwsProfile" -ForegroundColor Green
    }
    End {
    }
}


function Get-CacheFile {
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        $AwsProfile,
        [Parameter(Mandatory = $true,
            Position = 1)]
        $RoleArn,
        [Parameter(Mandatory = $true,
            Position = 2)]
        $Retry
    )
    
    $files = Get-ChildItem ~/.aws/cli/cache/
    
    foreach ($file in $files) {
        $json = Get-Content $file | ConvertFrom-Json
        if ($json.AssumedRoleUser.Arn -eq $RoleArn) {
            return $json
        }
    }
    
    if ($Retry -eq $true) {
        $res=(aws sts get-caller-identity --profile $AwsProfile)
        return Get-CacheFile $AwsProfile $RoleArn $false
    } else {
        return $false
    }
    
}