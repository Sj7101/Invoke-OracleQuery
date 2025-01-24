function Build-HTMLReport {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$CustomObjects,   # single array of PSCustomObject
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
        .red { background-color: #ffcccc; }
        .yellow { background-color: #ffffcc; }
        .green { background-color: #ccffcc; }
    </style>
</head>
<body>
<h1>Custom HTML Report</h1>

<pre>
$Description
</pre>

<div class="container">
"@

    # Create a separate table for each object in $CustomObjects
    foreach ($obj in $CustomObjects) {
        # You can customize the heading however you want
        $tableHeading = $obj.Name  # or any property you'd like to use as a title

        $html += @"
    <div class="table-container">
        <h2>$tableHeading</h2>
        <table>
"@

        # If you want each property as a row (PropertyName | Value):
        foreach ($prop in $obj.PSObject.Properties) {
            # Skip the 'Name' prop if that’s just your heading
            if ($prop.Name -ne 'Name') {
                $value = $prop.Value

                # Apply color logic if you want. For example, if property is 'PercentFree':
                $cellClass = ""
                if ($prop.Name -eq "PercentFree") {
                    $percentValue = [double]($value -replace '[^0-9.]', '')
                    if    ($percentValue -ge 0 -and $percentValue -le 20) { $cellClass = "red" }
                    elseif($percentValue -gt 20 -and $percentValue -le 30){ $cellClass = "yellow" }
                    elseif($percentValue -gt 30 -and $percentValue -le 40){ $cellClass = "green" }
                }

                $html += if ($cellClass) {
                    "<tr><td>$($prop.Name)</td><td class='$cellClass'>$value</td></tr>"
                }
                else {
                    "<tr><td>$($prop.Name)</td><td>$value</td></tr>"
                }
            }
        }

        $html += "</table></div>"
    }

    $html += @"
</div>

<pre>
$FooterText
</pre>

</body>
</html>
"@

    $OutputPath = "G:\Users\Shawn\Desktop\CustomReport.html"
    $html | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "HTML report generated at $OutputPath"
}

# Example usage:
$Description = @"
This is the description at the top.
"@

$FooterText = @"
This is the footer text below.
"@

# Each PSCustomObject will appear as its own table
$allObjects = @(
    [PSCustomObject]@{ Name = "Server1"; TotalSize = "576 Gb"; UsedSpace = "255.62 Gb"; FreeSpace = "321.16 Gb"; PercentFree = "29 %" },
    [PSCustomObject]@{ Name = "Server2"; TotalSize = "580 Gb"; UsedSpace = "224.38 Gb"; FreeSpace = "321.16 Gb"; PercentFree = "19 %" },
    [PSCustomObject]@{ Name = "Server3"; TotalSize = "580 Gb"; UsedSpace = "124.38 Gb"; FreeSpace = "321.16 Gb"; PercentFree = "38 %" },
    [PSCustomObject]@{ Name = "Server4"; TotalSize = "580 Gb"; UsedSpace = "124.38 Gb"; FreeSpace = "321.16 Gb"; PercentFree = "78 %" }
)

Build-HTMLReport -CustomObjects $allObjects -Description $Description -FooterText $FooterText
