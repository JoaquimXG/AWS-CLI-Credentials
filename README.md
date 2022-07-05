# Managing AWS CLI Environment Variables

- [Managing AWS CLI Environment Variables](#managing-aws-cli-environment-variables)
  - [Overview](#overview)
  - [Key Variables](#key-variables)
  - [Accounts Without MFA](#accounts-without-mfa)
    - [In Config Files](#in-config-files)
    - [As Environment Variables](#as-environment-variables)
  - [Multiple Accounts/Profiles](#multiple-accountsprofiles)
  - [Accounts With MFA](#accounts-with-mfa)
    - [Manual Setup](#manual-setup)
    - [Automated Setup (Scripted)](#automated-setup-scripted)
  - [Roles](#roles)
    - [Standard Usage](#standard-usage)
    - [Automated Usage (Scripted)](#automated-usage-scripted)
  - [Script Usage](#script-usage)
    - [Unix](#unix)
      - [awsmfa](#awsmfa)
      - [awsrole](#awsrole)
    - [Windows](#windows)
      - [Get-AwsMfaSession](#get-awsmfasession)
      - [Get-AwsRoleSession](#get-awsrolesession)

AWS Environment variable management is only required for AWS accounts that require MFA or access a role that requires MFA. Accounts without MFA should read **Without MFA** and don't require the scripts. 

## Overview

The AWS CLI uses a simple credential management system with some complications regarding MFA, roles, or multiple acounts. 

The included scripts for both Windows and Unix, remove these complications allowing for sessions to be started with a single command, e.g., `awsrole`. Some initial setup is required, detailed below. The scripts are not required for accounts without MFA or accounts accessing roles without MFA.

## Key Variables

At its core the system uses the following environment variables. 

| Variable              | Description                                                     |
| --------------------- | --------------------------------------------------------------- |
| AWS_PROFILE           | The name of the currently active profile                        |
| AWS_ACCESS_KEY_ID     | Unique access key ID for an AWS account, effectively a username |
| AWS_SECRET_ACCESS_KEY | Secret component of the access key, effectively a password      |
| AWS_SESSION_TOKEN     | Short term credential, required for roles/accounts with MFA     |

These variables can also be set in two files `~/.aws/config` and `~/.aws/credentials` which can be generated interactively using `aws configure` for the simplest configurations as shown below. 

## Accounts Without MFA

When using an account that does not require MFA, only your access key ID and secret access key are required. 
These can either be set in the environment variables or in the `~/.aws/config` and `~/.aws/credentials` files. 

### In Config Files

```ini
# ~/.aws/credentials
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

```ini
# ~/.aws/config
[default]
region = us-east-1
output = json
```

### As Environment Variables

```bash
# Unix
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

```powershell
# Windows (PowerShell)
$Env:AWS_ACCESS_KEY_ID = XXXXXXXXXXXXXXXXXXXX
$Env:AWS_SECRET_ACCESS_KEY = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Multiple Accounts/Profiles

Configuration for multiple accounts can be managed in the configuration files. Each set of credentials is stored under a profile name, e.g., `personal`

```ini
# ~/.aws/credentials
[personal]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

```ini
# ~/.aws/config
[profile personal]
region = eu-west-2
output = json
```

You can switch between profiles by setting the AWS_PROFILE environment variable to the profile name, e.g.,

```bash
# Unix
export AWS_PROFILE=personal
```

```powershell
# Windows (PowerShell)
$Env:AWS_PROFILE = "personal"
```

## Accounts With MFA

Accounts with MFA must use an MFA token to generate temporary credentials to use in place of the static credentials stored in `~/.aws/credentials`.  You will need the unique serial for your MFA device which can be found in the AWS Management Console under the Security Credentials section.

### Manual Setup

Temporary credentials can be gathered manually, e.g.,

```bash
# Unix or Windows
aws sts get-session-token --serial-number arn:aws:iam:<your-account-id>:mfa/<your-mfa-serial> --token-code <mfa-token>
```

This command generates a JSON response with the following fields:
```json
{
    "Credentials": {
        "AccessKeyId": "XXXXXXXXXXXXXXXXXXXX",
        "SecretAccessKey": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "SessionToken": "IQoJb3JpZ2luX2VjEG0aCWV1LXdlc3QtMSJHMEUCIQD+2w8Tp7zAVl3g5NBgEpYGLXPniiRYjO780XpYG/CKhAIgZcA0AwD8c3TGBpzOVMH/1aUTaaVW5/yJMYmK5fvXwGMq+AEIlv//////////ARAAGgwyOTc2NDk3MjI4NTYiDLUSPcEH7zSr8tWU9CrMAejwZpJT1uBbzDUF7QDlL8g81Xt4QMENKXELBWLb4r8NpUbKUk6ahhpIsrgp14dPBqxhCF0I1WWyH4f2ktqeRK25Q/mpwg2kaZCifenOI/H6RGovbwt/O0veprLMVBQ3eoiI0FA9wh4cf5MBNSI+9OsrTccuoTy8P28M5lvuiL3uOvs3AwzNZkOXN9s1EUkMhYx/s8hkHY0jD5rxWGePNPGlm5kKvBfk3eGdq6jEtX/6Z0w4YztmS6LZIFXnrXH7k4VXZL972M6SCPP5VzCwpo2WBjqYAau20Tk6JyNq/r73KqJv6n1JxsxTcR3ndsXa/8C7RyzzLAhQz9Agd5USObksw0zi9ujycOB1EMqxFcsDfv9cFtF4kE3Ecry5Z+CeZpo40aWKKZqgQ4mgdc6VDmkSbggHP02+qwbA23DlC3smAOIGs3vCgtaN64dgG2X5M38T5vyujZcWk3IovT2cdbET0+jLiBhSP4zpP9hZ",
        "Expiration": "2022-07-05T08:53:04+00:00"
    }
}
```

The generated temporary credentials can then must be added either to the config files or exported to the environment variables. As these credentials are temporary, it is likely more convenent to set them as environment variables.

### Automated Setup (Scripted)

Alternatively you can use one of the scripts to configure these variables for you. 
You must first add `mfa_serial` to `~/.aws/config` for a profile that requires MFA, e.g.,

```ini
[profile personal]
region = eu-west-2
output = json
mfa_serial = arn:aws:iam::XXXXXXXXXXXX:mfa/XXXXXX
```

The script will then be able to pull this value and generate temporary credentials for you.

```bash
# Unix
source awsmfa <mfa-token>
```

```powershell
# Windows (PowerShell)
Get-AwsMfaSession <mfa-token>
```

Temporary credentials will be exported to the environment.

## Roles

### Standard Usage

CLI profiles can be used to easily manage access to roles, both with and without MFA. You just need to include the role that will be used for the profile and the source profile that will be used to access the role, if MFA is required you must also specify the mfa serial, e.g.,

```ini
[profile role-example]
region = eu-west-2
output = json
mfa_serial = arn:aws:iam::XXXXXXXXXXXX:mfa/XXXXXX
source_profile = personal
role_arn = arn:aws:iam::XXXXXXXXXXXX:role/<your-role-name>
```

You will then activaet the profile by setting the AWS_PROFILE environment variable to the profile name and run any CLI commands that require access to the role. You will be prompted to enter an MFA token. 

Additional configuration is available to extend the role session duaration and to set a role session name. 

```ini
role_session_name = <your-role-session-name>
duration_seconds = 43200
```

A role sesion name may be required when assuming the role whilst the duration must be lower than the maximum allowed by the role.


### Automated Usage (Scripted)

The standard usage above will not add temporary credentials to the environment, they are instead stored in a cache file under `~/.aws/cli/cache/` and are only loaded by the CLI when the profile is active. Sometimes it is desirable to have the temporary credentials available in the environment, e.g., when running a script that will use the role.

The included scripts both simplify the process of entering a role session and will bring the temporary credentials from the cache file into the environment.

You must include a non standard parameter `assumed_role_arn` in the profile, this is partially computed using a `role_session_name` so this must also be included. The format for `assumed_role_arn` is below.

```ini
role_session_name = <your-role-session-name>
assumed_role_arn = arn:aws:sts::XXXXXXXXXXXX:assumed-role/<your-role-name>/<your-role-session-name>
```

You can then run the scripts for Unix and Windows:

```bash
# Unix
source awsrole
```

```powershell
# Windows (PowerShell)
Get-AwsRoleSession 
```

## Script Usage

For all scripts, you can either set the AWS_PROFILE before running the script or the script will prompt for the profile name when running.

### Unix

Suggested to add both scripts to your path, e.g., `/home/<user>/bin/`

#### awsmfa

`mfa_serial` must be set for the profile in `~/.aws/config` for this script to work.

```text
Usage: awsmfa <mfa-token>
```

#### awsrole

You must include a non standard parameter `assumed_role_arn` in the profile, this is partially computed using a `role_session_name` so this must also be included. The format for `assumed_role_arn` is below.

```ini
role_session_name = <your-role-session-name>
assumed_role_arn = arn:aws:sts::XXXXXXXXXXXX:assumed-role/<your-role-name>/<your-role-session-name>
```

```text
Usage: awsrole
```

### Windows

Suggested to add `Import-Module <script>` for both scripts in `$profile`. 

#### Get-AwsMfaSession

`mfa_serial` must be set for the profile in `~/.aws/config` for this script to work.

```powershell
Get-AwsMfaSession <mfa-token>
# Or with profile
Get-AwsMfaSession <mfa-token> <profile>
# Or with named parameters
Get-AwsMfaSession -MfaToken <mfa-token> -AwsProfile <profile>
```

#### Get-AwsRoleSession

`mfa_serial` and `role_arn` must be set for the profile in `~/.aws/config` for this script to work.

You must include a non standard parameter `assumed_role_arn` in the profile, this is partially computed using a `role_session_name` so this must also be included. The format for `assumed_role_arn` is below.

```ini
role_session_name = <your-role-session-name>
assumed_role_arn = arn:aws:sts::XXXXXXXXXXXX:assumed-role/<your-role-name>/<your-role-session-name>
```

```powershell
Get-AwsRoleSession
# Or with profile
Get-AwsRoleSession <profile>
# Or with named parameters
Get-AwsRoleSession -AwsProfile <profile>
```