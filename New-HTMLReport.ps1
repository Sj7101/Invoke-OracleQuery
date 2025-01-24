function Build-HTMLReport {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CustomObjects,   # Main array

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]]$ServiceNow,      # Below main array

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]]$TASKS,           # Below ServiceNow

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]]$PATCHING,        # Last table

        [string]$Description,
        [string]$FooterText
    )

    # Helper function to build one table per object in a given array
    function Build-ObjectTables {
        param(
            [PSCustomObject[]]$Objects,
            [string]$Heading       # e.g. "ServiceNow Items"
        )

        if (!$Objects -or $Objects.Count -eq 0) {
            return ""  # No HTML if array is empty or null
        }

        $htmlSnippet = @"
    <div style="width:100%">
        <h1>$Heading</h1>
    </div>
"@

        foreach ($obj in $Objects) {
            # Use the 'Name' property as the table heading if present
            $tableHeading = $obj.Name

            $htmlSnippet += @"
    <div class="table-container">
        <h2>$tableHeading</h2>
        <table>
"@
            foreach ($prop in $obj.PSObject.Properties) {
                # Skip the 'Name' property since we used it as <h2>
                if ($prop.Name -eq 'Name') { continue }

                $propName  = $prop.Name
                $propValue = $prop.Value

                # If the property is 'Link' or 'URL', turn $obj.Name into clickable text
                if ($propName -in @('Link','URL')) {
                    $propValue = "<a href='$propValue' target='_blank'>$($obj.Name)</a>"
                }

                $htmlSnippet += "<tr><td>$propName</td><td>$propValue</td></tr>"
            }
            $htmlSnippet += "</table></div>"
        }

        return $htmlSnippet
    }

    #-------------------------------
    # Start the main HTML document
    #-------------------------------
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

    # 1) Main data (CustomObjects)
    $html += Build-ObjectTables -Objects $CustomObjects -Heading "Main Items"

    # 2) ServiceNow
    if ($ServiceNow) {
        $html += Build-ObjectTables -Objects $ServiceNow -Heading "ServiceNow Items"
    }

    # 3) TASKS
    if ($TASKS) {
        $html += Build-ObjectTables -Objects $TASKS -Heading "TASKS"
    }

    # 4) PATCHING
    if ($PATCHING) {
        $html += Build-ObjectTables -Objects $PATCHING -Heading "Patching"
    }

    # Close containers + Footer
    $html += @"
</div>
<pre>
$FooterText
</pre>
</body>
</html>
"@

    # Write the HTML file
    $OutputPath = "D:\PowerShell\Test\CustomReport.html"
    $html | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "HTML report generated at $OutputPath"
}