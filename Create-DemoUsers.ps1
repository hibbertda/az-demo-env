param (
    [parameter(position=0, mandatory=$true)][string]$userPrefix,                # Prefix for user accounts to build usernames
    [parameter(position=1, mandatory=$true)][int]$userCount,                    # Count of users to create
    [parameter(position=2, mandatory=$false)][switch]$createGroup = $false,     # Create a group and add all users
    [parameter(position=3, mandatory=$false)][switch]$createSP = $false,        # Create service principal
    [parameter(position=4, mandatory=$false)][int]$SPExperationDays = 15        # Number of days the SP will be valid
)
Function New-RandomPassword{
    Param(
        [ValidateRange(8, 32)]
        [int] $Length = 16
    )   
    $AsciiCharsList = @()   
    foreach ($a in (33..126)){
        $AsciiCharsList += , [char][byte]$a 
    }
    #RegEx for checking general AD Complex passwords
    $RegEx = "(?=^.{8,32}$)((?=.*\d)(?=.*[A-Z])(?=.*[a-z])|(?=.*\d)(?=.*[^A-Za-z0-9])(?=.*[a-z])|(?=.*[^A-Za-z0-9])(?=.*[A-Z])(?=.*[a-z])|(?=.*\d)(?=.*[A-Z])(?=.*[^A-Za-z0-9]))^.*"
 
    do {
        $Password = ""
        $loops = 1..$Length
        Foreach ($loop in $loops) {
            $Password += $AsciiCharsList | Get-Random
        }
    }
    until ($Password -match $RegEx )   
    return $Password   
}

Clear-Host
# Test for active connection to AzureAD
try {
    $result = Get-AzureADTenantDetail -ErrorAction Stop
    if (-not $result.ObjectID) {
        throw"Please login (connect-AzureAD) and set the proper subscription context before proceeding."
    }

}
catch {
    throw "Please login and set the proper subscription context before proceeding."
}

# If create group true create a new AAD Group
if ($createGroup){
    
    $groupConfig = New-AzureADGroup -Description "$($userPrefix) - Demo Group" `
        -DisplayName "$($userPrefix)-group" `
        -MailEnabled $false `
        -SecurityEnabled $true `
        -MailNickName "$($userPrefix)-group"
    $groupConfig
}

# IF Create Service Principal
if ($createSP){
    Import-Module -Name Az.Resources
    $spName = "sp-"+$userPrefix

    Write-host -ForegroundColor Green "Creating Service Principal"
    Write-host -ForegroundColor Green "The SP password will be valid for $($SPExperationDays) days."

    # Create SP password - Good for 15 days
    #$spPass = [System.Web.Security.Membership]::GeneratePassword(10,2)
    $spPass = New-RandomPassword(10)

    $spCred = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{`
        StartDate=get-date; `
        EndDate=$(Get-date).addDays($SPExperationDays);`
        Password=$spPass`
    }

    # Create new service principal
    $sp = New-AzADServicePrincipal `
        -DisplayName $spName `
        -PasswordCredential $spCred

    # Export SP information
    $spConfig = [PSCustomObject] @{
        DisplayName = $sp.DisplayName
        Secret = $spPass
        ApplicationID = $sp.ApplicationId
        ID = $sp.Id
    }
    $spOutputPath = $userPrefix+"SPOutput.csv"
    $spConfig | Export-Csv -NoTypeInformation -Path $spOutputPath
}

# Create user accounts
Write-host -ForegroundColor Green "Creating User Accounts"
$userAccountCompleted = @()
$i = 0

$domainlist = Get-AzureADDomain | Where-Object IsVerified -eq $true
# IF multipul domains exists prompt
if ($domainlist.count -gt 1){
    Write-host -ForegroundColor Yellow "Multiple Domains found. Select desired domain for user UPN:"

    [int]$listittr = 1
    $domainlist | ForEach-Object {
        write-host "[$listittr] - $($_.name)"
        $listittr++
    }

    [int]$response = $(Read-Host -Prompt "Select Domain")
    $upnDomain = $domainlist[$($response - 1)].name
}
# ELSE - select domain name
else {
    $upnDomain = $domainlist.name
}

# Create Accounts
do {
    # Generate Password
    # $pass = [System.Web.Security.Membership]::GeneratePassword(10,2)
    $pass = New-RandomPassword(10)
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = $pass

    # Define account options
    $useroption = [PSCustomObject] @{
        DisplayName = $userPrefix+"User"+$i
        Password = $pass
        MailNickname = $userPrefix+"User"+$i
        UPN = $userPrefix+"User"+$i+"@"+$upndomain
        ObjectID = ""
    }

    # Create account
    write-host -ForegroundColor Green "Creating user: $($useroption.displayname)"
    $accountConfig = New-AzureADUser `
        -AccountEnabled $true `
        -DisplayName $useroption.DisplayName `
        -PasswordProfile $PasswordProfile `
        -MailNickname $useroption.MailNickname `
        -UserPrincipalName $useroption.upn
        
    if ($createGroup){
        Add-AzureADGroupMember `
            -ObjectId $groupConfig.ObjectID `
            -RefObjectId $accountConfig.ObjectID
    }

    $useroption.ObjectID = $accountConfig.ObjectID
    $userAccountCompleted += $useroption
    $i++
} while ($i -ne $userCount)

# Export AAD users
$outputPath = $userPrefix+"userOutput.csv"
$userAccountCompleted | Format-Table
$userAccountCompleted | Export-Csv -NoTypeInformation -Path $outputPath
