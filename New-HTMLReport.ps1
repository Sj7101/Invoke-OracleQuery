function Build-HTMLReport {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CustomObjects,  # multiple objects -> one table per object, 2-wide layout

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$ServiceNow,       # single object -> one table only
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$TASKS,            # single object -> one table only
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$PATCHING,         # single object -> one table only

        [string]$Description,
        [string]$FooterText
    )

    #---------------------------------------------------------------------
    # Helper 1: Build multiple tables (one per object) for an array
    #---------------------------------------------------------------------
    function Build-MultiObjectTables {
        param(
            [PSCustomObject[]]$ObjArray,
            [string]$SectionHeading
        )

        if (!$ObjArray -or $ObjArray.Count -eq 0) { return "" }

        $htmlBlock = @"
    <div style="width:100%">
        <h1>$SectionHeading</h1>
    </div>
"@

        foreach ($obj in $ObjArray) {
            $tableHeading = $obj.Name
            $htmlBlock += @"
    <div class="table-container">
        <h2>$tableHeading</h2>
        <table>
"@
            foreach ($prop in $obj.PSObject.Properties) {
                if ($prop.Name -eq 'Name') { continue }
                $propName  = $prop.Name
                $propValue = $prop.Value

                # If the property is 'Link' or 'URL', convert to clickable link
                if ($propName -in @('Link','URL')) {
                    $propValue = "<a href='$propValue' target='_blank'>$($obj.Name)</a>"
                }

                $htmlBlock += "<tr><td>$propName</td><td>$propValue</td></tr>"
            }
            $htmlBlock += "</table></div>"
        }

        return $htmlBlock
    }

    #---------------------------------------------------------------------
    # Helper 2: Build a single table for a single PSCustomObject
    #---------------------------------------------------------------------
    function Build-SingleObjectTable {
        param(
            [PSCustomObject]$Obj,
            [string]$SectionHeading
        )

        if (!$Obj) { return "" }

        $properties = $Obj.PSObject.Properties.Name

        $htmlBlock = @"
    <div style="width:100%">
        <h1>$SectionHeading</h1>
    </div>
    <div class="table-container">
        <table>
            <tr>
"@

        # Create <th> for each property
        foreach ($p in $properties) {
            $htmlBlock += "<th>$p</th>"
        }
        $htmlBlock += "</tr><tr>"

        # Create one row of <td> for the object's values
        foreach ($p in $properties) {
            $propValue = $Obj.$p

            if ($p -in @('Link','URL')) {
                $propValue = "<a href='$propValue' target='_blank'>$($Obj.Name)</a>"
            }

            $htmlBlock += "<td>$propValue</td>"
        }

        $htmlBlock += "</tr></table></div>"

        return $htmlBlock
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

    # 1) Multiple-object section (Main Items)
    $html += Build-MultiObjectTables -ObjArray $CustomObjects -SectionHeading "Main Items"

    # 2) Single-object: ServiceNow
    $html += Build-SingleObjectTable -Obj $ServiceNow -SectionHeading "ServiceNow"

    # 3) Single-object: TASKS
    $html += Build-SingleObjectTable -Obj $TASKS -SectionHeading "Tasks"

    # 4) Single-object: PATCHING
    $html += Build-SingleObjectTable -Obj $PATCHING -SectionHeading "Patching"

    # Close containers + Footer
    $html += @"
</div>
<pre>
$FooterText
</pre>
</body>
</html>
"@

    #---------------------------------------------------------------------
    # Output to file AND return the HTML string
    #---------------------------------------------------------------------
    $OutputPath = "D:\PowerShell\Test\CustomReport.html"
    $html | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "HTML report generated at $OutputPath"

    # Return the HTML so the caller can use it in Send-MailMessage, etc.
    return $html
}
