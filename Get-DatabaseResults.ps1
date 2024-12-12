function Get-DatabaseResults {
    param (
        [Parameter(Mandatory)]
        [string]$ConnectionString,
        [Parameter(Mandatory)]
        [array]$Queries
    )

    # Initialize the Oracle connection
    $connection = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($ConnectionString)
    $connection.Open()

    # Initialize a hashtable to build the PSCustomObject
    $resultObject = @{}

    # Iterate through each query
    foreach ($query in $Queries) {
        # Get the query name and text
        $queryName = $query.QueryName
        $queryText = $query.QueryText

        # Create a command to execute the query
        $command = $connection.CreateCommand()
        $command.CommandText = $queryText

        # Execute the query and get the result
        $reader = $command.ExecuteReader()
        
        # Temporary storage for multiple rows
        $rows = @()

        while ($reader.Read()) {
            $rowProperties = @{} # Temporarily store values for dynamic columns

            # Dynamically handle all columns returned by the query
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $columnName = $reader.GetName($i)  # Get the column name
                $columnValue = $reader.GetValue($i) # Get the column value
                $rowProperties[$columnName] = $columnValue
            }

            # Add the row properties to the collection of rows
            $rows += [pscustomobject]$rowProperties
        }

        $reader.Close()

        # Process single or multiple rows
        if ($rows.Count -eq 1) {
            # Single row, add it directly with QueryName as the property name
            $resultObject[$queryName] = $rows[0]
        } elseif ($rows.Count -gt 1) {
            # Multiple rows, add each with "QueryName :: Status Code (value from Status)"
            foreach ($row in $rows) {
                # Construct the property name dynamically based on "Status"
                $status = $row.Status # Replace "Status" with the actual column name if different
                $propertyName = "$queryName :: Status Code $status"
                $resultObject[$propertyName] = $row.Count # Replace "Count" with the actual value column
            }
        }
    }

    # Close the connection
    $connection.Close()

    # Convert the hashtable to a PSCustomObject and return it
    return [pscustomobject]$resultObject
}

# Example usage
$queries = @(
    @{ QueryName = 'Query1'; QueryText = 'SELECT Status, Count FROM YourTable' },
    @{ QueryName = 'Query2'; QueryText = 'SELECT MAX(Salary) AS MaxSalary FROM Employees' }
)

$connectionString = "Your Oracle Connection String Here"
$result = Get-DatabaseResults -ConnectionString $connectionString -Queries $queries

# Output the result
$result
