<#PSScriptInfo
.VERSION 0.3.0
.GUID 5f00d7f3-7f5d-49de-a222-cfe929396932
.AUTHOR Micky
.COMPANYNAME
.COPYRIGHT (c) 2026 Micky. MIT License.
.TAGS Microsoft365 Office365 M365 PowerShell MSP License LicenseManagement MicrosoftGraph Entra CostSavings
.LICENSEURI https://github.com/Saiasanc/m365-license-waste/blob/main/LICENSE
.PROJECTURI https://github.com/Saiasanc/m365-license-waste
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
0.3.0 - First PowerShell Gallery release. Grace period for new accounts; fixed totals line.
.PRIVATEDATA
#>

#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Identity.DirectoryManagement

<#
.SYNOPSIS
  Finds wasted Microsoft 365 licenses and estimates their monthly cost.

.DESCRIPTION
  Read-only scan of a Microsoft 365 tenant. Flags licensed users who are disabled,
  have never signed in (after a grace period for new accounts), or have been inactive
  for N+ days. Estimates monthly and yearly cost from approximate US list prices and
  exports the results to CSV. Never changes users, licenses or settings.

.PARAMETER InactiveDays
  Days since last sign-in before a user counts as inactive. Default 90.

.PARAMETER GraceDays
  New accounts younger than this are not flagged as "never signed in". Default 30.

.PARAMETER OutFile
  Path of the CSV report. Default .\M365-License-Waste.csv

.EXAMPLE
  .\Find-M365LicenseWaste.ps1

.EXAMPLE
  .\Find-M365LicenseWaste.ps1 -InactiveDays 60 -GraceDays 14 -OutFile .\report.csv
#>
param(
    [int]$InactiveDays = 90,
    [int]$GraceDays    = 30,
    [string]$OutFile   = ".\M365-License-Waste.csv"
)

# Approximate US list prices per user per month (edit as needed)
$Prices = @{
    'SPB'                      = 22.00   # Business Premium
    'O365_BUSINESS_PREMIUM'    = 12.50   # Business Standard
    'O365_BUSINESS_ESSENTIALS' = 6.00    # Business Basic
    'ENTERPRISEPACK'           = 23.00   # Office 365 E3
    'ENTERPRISEPREMIUM'        = 38.00   # Office 365 E5
    'SPE_E3'                   = 36.00   # Microsoft 365 E3
    'SPE_E5'                   = 57.00   # Microsoft 365 E5
}

Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All","Organization.Read.All" -NoWelcome

$skuMap = @{}
Get-MgSubscribedSku | ForEach-Object { $skuMap[$_.SkuId] = $_.SkuPartNumber }

$cutoff      = (Get-Date).AddDays(-$InactiveDays)
$graceCutoff = (Get-Date).AddDays(-$GraceDays)

$users = Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,AccountEnabled,AssignedLicenses,SignInActivity,CreatedDateTime

$results = foreach ($u in $users) {
    if (-not $u.AssignedLicenses) { continue }

    $last = $u.SignInActivity.LastSignInDateTime
    $reason = if (-not $u.AccountEnabled)                                   { 'Disabled but licensed' }
              elseif (-not $last -and $u.CreatedDateTime -lt $graceCutoff)  { 'Never signed in' }
              elseif ($last -and $last -lt $cutoff)                         { "Inactive $InactiveDays+ days" }
              else                                                          { $null }
    if (-not $reason) { continue }

    foreach ($lic in $u.AssignedLicenses) {
        $sku  = $skuMap[$lic.SkuId]
        $cost = if ($Prices.ContainsKey($sku)) { $Prices[$sku] } else { 0 }
        [pscustomobject]@{
            User        = $u.DisplayName
            UPN         = $u.UserPrincipalName
            Reason      = $reason
            License     = $sku
            LastSignIn  = $last
            Created     = $u.CreatedDateTime
            MonthlyCost = $cost
        }
    }
}

$results | Export-Csv $OutFile -NoTypeInformation
$total = ($results | Measure-Object MonthlyCost -Sum).Sum

$results | Format-Table User, Reason, License, MonthlyCost -AutoSize
Write-Host ('Flagged licenses: {0}   Estimated waste: ${1:N2}/month  (${2:N2}/year)' -f @($results).Count, $total, ($total*12)) -ForegroundColor Yellow
Write-Host "Saved to $OutFile"