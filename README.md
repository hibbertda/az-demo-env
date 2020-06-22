# Azure Demo Day - Setup
## PowerShell script: create-demousers.ps1
Scripts and processes to automate the build out for a group Azure Demo.

The easiest way to get started using these examples is to used the [Azure Cloud Shell (ACS)](https://shell.azure.com). ACS has all of the tools required to run all of these templates already baked in, without needing to install anything locally to your workstation.

[![Launch Cloud Shell](https://shell.azure.com/images/launchcloudshell.png "Launch Cloud Shell")](https://shell.azure.com/powershell)

The easiest way to get the script is to clone this GIT repository inside of the Azure Cloud Shell. ASC has all of the software required to pull a GIT repository installed by default. 

```bash
git clone https://github.com/hibbertda/az-demo-env.git
```

**Note:** These are based on a series of basic scripts and procedures I have used to setup demo environments. 

### Azure AD Identities

**Example**:

```powershell
Create-DemoUsers.ps1 -userPrefix team1 -userCount 10 -createGroup -createSP
```

|Parameters||
|-|-|
|userPrefix|Prefix name for all of the user accounts / groups created by the script.|
|userCount|The number of accounts to create. The count will be used when generating account names.|
|createGroup|[switch] Enables the option to create an AAD group and add all team members created. By default no group is created.|
|createSP|[switch] Create a service principal|

When the script is a completed a series of CSV files are exported to the current user directory with the information on the created identities.

```csv
# Service Principal
"DisplayName","Secret","ApplicationID","ID"
"sp-test15","...","...","..."

# User Accounts
"DisplayName","Password","MailNickname","UPN","ObjectID"
"team1User0","n|)LdDM5p5","team1User0","team1User0@...","..."
"team1User1","l^LWbpR.qK","team1User1","team1User1@...","..."
```
