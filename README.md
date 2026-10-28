# M365 License Waste Finder

**Find the Microsoft 365 licenses you're paying for and nobody is using.**

A free, read-only PowerShell script that scans a Microsoft 365 tenant and flags licensed users who are:

- **Disabled but still licensed**
- **Never signed in** (after a 30-day grace period for new accounts)
- **Inactive for 90+ days**

It then estimates what those licenses cost you per month and per year, and exports everything to CSV.

## Example output

```
User          Reason                License MonthlyCost
----          ------                ------- -----------
Casey Morgan  Disabled but licensed SPB           22.00
Taylor Brooks Disabled but licensed SPB           22.00

Flagged licenses: 2   Estimated waste: $44.00/month  ($528.00/year)
```

## Requirements

- PowerShell 7+
- Microsoft Graph PowerShell module: `Install-Module Microsoft.Graph -Scope CurrentUser`
- An admin account that can consent to: `User.Read.All`, `AuditLog.Read.All`, `Organization.Read.All`
- Sign-in activity data requires Entra ID P1 or higher (included in Business Premium and E3/E5)

## Usage

```powershell
.\Find-M365LicenseWaste.ps1
```

Options:

```powershell
.\Find-M365LicenseWaste.ps1 -InactiveDays 60 -GraceDays 14 -OutFile .\report.csv
```

## Is it safe?

Yes. The script is **read-only**. It never changes users, licenses or settings. Read the code; it's one short file.

## Pricing note

Monthly costs use approximate US list prices for common SKUs. Edit the `$Prices` table at the top of the script to match what you actually pay.

## Coming soon: Pro version for MSPs

- Scan **all your client tenants** in one run
- MFA gaps, stale guest accounts and admin role sprawl
- **Branded PDF report** you can hand to clients
- Scheduled runs and month-over-month changes

Want early access? **[Join the waitlist](https://tally.so/r/xVVL95)** (founding members get lifetime Pro at a discount).

## License

MIT
