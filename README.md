
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

Want early access? **[Join the waitlist](#)** (founding members get lifetime Pro at a discount).

## License

MIT
