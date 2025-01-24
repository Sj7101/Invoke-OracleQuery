function Build-HTMLReport {
    param(
        [PSCustomObject[]]$allObjects,
        [string]$Description,
        [string]$FooterText
    )

    $html = @"
<html>
<head>
<style>
  body { font-family: Arial; }
  .container { display: flex; flex-wrap: wrap; }
  .table-container { width: 48%; margin: 1%; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
  th, td { border: 1px solid #000; padding: 8px; }
  th { background-color: #f2f2f2; }
</style>
</head>
<body>
<h1>Custom HTML Report</h1>
<pre>
$Description
</pre>
<div class="container">
"@

    # BUILD ONE TABLE PER PSCustomObject
    foreach ($obj in $allObjects) {
        $html += @"
    <div class="table-container">
        <h2>$($obj.Name)</h2> <!-- For example, if each object has a 'Name' property -->
        <table>
"@
        # For each property in the PSCustomObject, create a row with 2 columns: PropertyName | Value
        foreach ($prop in $obj.PSObject.Properties) {
            $propName  = $prop.Name
            $propValue = $prop.Value
            $html += "<tr><th>$propName</th><td>$propValue</td></tr>"
        }

        $html += "</table></div>"
    }

    $html += @"
</div> <!-- end container -->
<pre>
$FooterText
</pre>
</body>
</html>
"@

    $OutputPath = "C:\Temp\test.html"
    $html | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "HTML report generated at $OutputPath"
}



# $ObjectArray is the array of PSCustomObjects (e.g., $allObjects)
$firstObj = $ObjectArray[0]
# Build header columns from property names in the first object
foreach ($prop in $firstObj.PSObject.Properties.Name) {
    $htmlSnippet += "<th>$prop</th>"
}

# Then build one row for each object in $ObjectArray
foreach ($row in $ObjectArray) {
    $htmlSnippet += "<tr>"
    foreach ($prop in $row.PSObject.Properties.Name) {
        $value = $row.$prop
        $htmlSnippet += "<td>$value</td>"
    }
    $htmlSnippet += "</tr>"
}


Write-Host "Count of top-level array: $($allObjects.Count)"
Write-Host "Type of the first item: $($allObjects[0].GetType().FullName)"
