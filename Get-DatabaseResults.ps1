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
        
        # Track whether multiple rows are returned
        $rowIndex = 0

        while ($reader.Read()) {
            $rowProperties = @{} # Temporarily store values for dynamic columns

            # Dynamically handle all columns returned by the query
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $columnName = $reader.GetName($i)  # Get the column name
                $columnValue = $reader.GetValue($i) # Get the column value
                $rowProperties[$columnName] = $columnValue
            }

            # Handle multiple rows dynamically by appending an index to the property name
            $propertySuffix = if ($rowIndex -eq 0 -and $reader.HasRows -eq $false) { '' } else { " :: Row $rowIndex" }
            $propertyName = "$queryName$propertySuffix"

            # Add the row properties to the result object
            $resultObject[$propertyName] = [pscustomobject]$rowProperties
            $rowIndex++
        }

        $reader.Close()
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
