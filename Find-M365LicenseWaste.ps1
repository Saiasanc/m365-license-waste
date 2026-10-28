<#
  Find-M365LicenseWaste.ps1  v0.2
  Flags licensed users who are disabled, never signed in (after a grace period),
  or inactive N+ days, and estimates monthly cost. Read-only.
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