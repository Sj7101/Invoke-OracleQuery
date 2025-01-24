function Build-HTMLReport {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CustomObjects,  # Main array of PSCustomObject
        [Parameter(Mandatory = $false)]
        [PSCustomObject[]]$ServiceNow,     # Secondary array of PSCustomObject (optional)
        [string]$Description,
        [string]$FooterText
    )

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Custom HTML Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        .container { display: flex; flex-wrap: wrap; }
        .table-container { width: 48%; margin: 1%; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        pre { white-space: pre-wrap; font-size: 16px; }
    </style>
</head>
<body>
<h1>Custom HTML Report</h1>

<pre>
$Description
</pre>

<div class="container">
"@

    #--- 1) Build tables for the main array ($CustomObjects) ---
    foreach ($obj in $CustomObjects) {
        # Use the 'Name' property (if it exists) as a heading
        $tableHeading = $obj.Name

        $html += @"
    <div class="table-container">
        <h2>$tableHeading</h2>
        <table>
"@
        # Create one row per property (2 columns: PropertyName | Value)
        foreach ($prop in $obj.PSObject.Properties) {
            # Optionally skip the 'Name' prop if used only as a heading
            if ($prop.Name -eq 'Name') { continue }

            $propName  = $prop.Name
            $propValue = $prop.Value

            # If the property value starts with http:// or https://,
            # we'll make it a clickable link. Otherwise, just plain text.
            if ($propValue -is [string] -and $propValue -match '^https?://') {
                $propValue = "<a href='$propValue' target='_blank'>$propValue</a>"
            }

            $html += "<tr><td>$propName</td><td>$propValue</td></tr>"
        }

        $html += "</table></div>"
    }

    #--- 2) Build tables for the ServiceNow array (if it’s passed) ---
    #    (Same layout approach: one table per object)
    if ($ServiceNow -and $ServiceNow.Count -gt 0) {
        # You could add a new heading or just continue in the same container
        $html += @"
    <div style="width:100%">
        <h1>ServiceNow Items</h1>
    </div>
"@

        foreach ($obj in $ServiceNow) {
            $tableHeading = $obj.Name  # or maybe $obj.Ticket, or whatever you want as the heading

            $html += @"
    <div class="table-container">
        <h2>$tableHeading</h2>
        <table>
"@
            foreach ($prop in $obj.PSObject.Properties) {
                # If your heading property is also 'Name' or something else, skip it if you want
                if ($prop.Name -eq 'Name') { continue }

                $propName  = $prop.Name
                $propValue = $prop.Value

                # Convert to clickable link if it starts with http:// or https://
                if ($propValue -is [string] -and $propValue -match '^https?://') {
                    $propValue = "<a href='$propValue' target='_blank'>$propValue</a>"
                }

                $html += "<tr><td>$propName</td><td>$propValue</td></tr>"
            }

            $html += "</table></div>"
        }
    }

    $html += @"
</div>

<pre>
$FooterText
</pre>

</body>
</html>
"@

    $OutputPath = "D:\PowerShell\Test\CustomReport.html"
    $html | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "HTML report generated at $OutputPath"
}
