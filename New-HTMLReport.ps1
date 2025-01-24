function Build-HTMLReport {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CustomObjects,  # multiple objects -> one table *per* object, 2-wide layout

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
    #           This is used for $CustomObjects, each item is a separate table.
    #---------------------------------------------------------------------
    function Build-MultiObjectTables {
        param(
            [PSCustomObject[]]$ObjArray,
            [string]$SectionHeading
        )

        if (!$ObjArray -or $ObjArray.Count -eq 0) { return "" }

        # We'll add an H1 or H2 heading for this block
        $htmlBlock = @"
    <div style="width:100%">
        <h1>$SectionHeading</h1>
    </div>
"@

        # For each object in the array, build a separate table
        foreach ($obj in $ObjArray) {
            # We'll use the object’s 'Name' property (if any) for the table <h2>:
            $tableHeading = $obj.Name

            $htmlBlock += @"
    <div class="table-container">
        <h2>$tableHeading</h2>
        <table>
"@
            # For each property in the PSCustomObject, create rows: PropertyName | Value
            foreach ($prop in $obj.PSObject.Properties) {
                if ($prop.Name -eq 'Name') {
                    # We already used 'Name' as the table heading
                    continue
                }

                $propName  = $prop.Name
                $propValue = $prop.Value

                # If the property is 'Link' or 'URL', make it a clickable link
                # but display the same object's Name as the link text
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
    #           (all properties in one table, in a single row or row-based)
    #           We'll do a standard row of headers, then one row of values.
    #           If you prefer "PropertyName | Value" rows, we can do that too.
    #---------------------------------------------------------------------
    function Build-SingleObjectTable {
        param(
            [PSCustomObject]$Obj,
            [string]$SectionHeading
        )

        if (!$Obj) { return "" }  # If null, return no HTML

        # We'll gather all property names from $Obj
        $properties = $Obj.PSObject.Properties.Name

        # Option A) Each property is a column in one row
        #           (one <tr> total for the data).
        # Option B) Each property is its own row. 
        # Let’s do Option A for demonstration (column-based).
        
        # Start the block with a heading
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

        # Create one row of <td> for the object’s values
        foreach ($p in $properties) {
            $propValue = $Obj.$p

            # If the property name is Link or URL, turn it into a clickable link
            # but display the Name property as link text
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

    # Output to D:\PowerShell\Test\CustomReport.html
    $OutputPath = "D:\PowerShell\Test\CustomReport.html"
    $html | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "HTML report generated at $OutputPath"
}
