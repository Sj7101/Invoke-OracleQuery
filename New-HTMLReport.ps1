function Build-HTMLReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$CustomObjects,  # Array of arrays of PowerShell custom objects in a specific order

        [Parameter(Mandatory = $true)]
        [string]$Description,   # Text before the tables

        [Parameter(Mandatory = $true)]
        [string]$FooterText     # Text after the tables
    )

    #-------------------------------------------
    # Helper function to build HTML for one array
    # of PSCustomObjects. This returns a string
    # containing a <div class="table-container">
    # block with a table.
    #-------------------------------------------
    function Get-TableHtml {
        param(
            [Parameter(Mandatory)]
            [PSObject[]]$ObjectArray,
            [string]$Heading = "Untitled"
        )

        # If the array is empty, return nothing
        if (!$ObjectArray) { return "" }

        # Create a snippet with <h2> + one table
        $htmlSnippet = @"
    <div class="table-container">
        <h2>$Heading</h2>
        <table>
            <tr>
"@

        # Build a table header from the first object's properties
        $firstObj = $ObjectArray[0]
        foreach ($prop in $firstObj.PSObject.Properties.Name) {
            $htmlSnippet += "<th>$prop</th>"
        }
        $htmlSnippet += "</tr>"

        # Rows for each object in this array
        foreach ($row in $ObjectArray) {
            $htmlSnippet += "<tr>"
            foreach ($prop in $row.PSObject.Properties.Name) {
                $value = $row.$prop
                # No conditional coloring for now - just a normal cell
                $htmlSnippet += "<td>$value</td>"
            }
            $htmlSnippet += "</tr>"
        }

        $htmlSnippet += "</table></div>"

        return $htmlSnippet
    }

    #-------------------------------------------
    # Start the full HTML Document
    #-------------------------------------------
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

    #-------------------------------------------
    # Build tables in the desired order:
    #   0 -> All Objects
    #   1 -> INC
    #   2 -> CHG
    #   3 -> Patching
    #-------------------------------------------
    if ($CustomObjects.Count -ge 1) {
        $html += Get-TableHtml -ObjectArray $CustomObjects[0] -Heading "All Objects"
    }
    if ($CustomObjects.Count -ge 2) {
        $html += Get-TableHtml -ObjectArray $CustomObjects[1] -Heading "INC Objects"
    }
    if ($CustomObjects.Count -ge 3) {
        $html += Get-TableHtml -ObjectArray $CustomObjects[2] -Heading "CHG Objects"
    }
    if ($CustomObjects.Count -ge 4) {
        $html += Get-TableHtml -ObjectArray $CustomObjects[3] -Heading "Patching"
    }

    #-------------------------------------------
    # Close container and add footer
    #-------------------------------------------
    $html += @"
    </div>  <!-- end .container -->

    <pre>
$FooterText
    </pre>

</body>
</html>
"@

    #-------------------------------------------
    # Write HTML to file
    #-------------------------------------------
    $OutputPath = "G:\Users\Shawn\Desktop\CustomReport.html"
    $html | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "HTML report generated at $OutputPath"
}
