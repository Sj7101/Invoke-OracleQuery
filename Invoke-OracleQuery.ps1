function Invoke-OracleQuery {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$Query
    )

    # Load the Oracle Data Provider assembly
    Write-Host "Loading Assembly DLL"
    $assemblyPath = "C:\path\to\Oracle.ManagedDataAccess.dll"
    if (-Not (Test-Path $assemblyPath)) {
        throw "Oracle.ManagedDataAccess.dll not found at '$assemblyPath'. Please update the path."
    }

    [void][Reflection.Assembly]::LoadFile($assemblyPath)

    # Create a new Oracle connection
    Write-Host "Creating Oracle Connection"
    $connection = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($ConnectionString)

    try {
        Write-Host "Opening Oracle Connection"
        $connection.Open()

        # Create a new Oracle command
        Write-Host "Creating Oracle Command"
        $command = $connection.CreateCommand()
        $command.CommandText = $Query

        # Execute the command
        Write-Host "Executing Oracle command"
        $reader = $command.ExecuteReader()

        $results = @()

        Write-Host "Building PSCustomObj with returned data"
        while ($reader.Read()) {
            $row = [PSCustomObject]@{}

            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $columnName = $reader.GetName($i)
                $value = $reader.GetValue($i)
                $row | Add-Member -MemberType NoteProperty -Name $columnName -Value $value
            }

            $results += $row
        }

        return $results
    }
    catch {
        Write-Error "An error occurred: $_"
    }
    finally {
        Write-Host "Closing connection"
        $connection.Close()
    }
}

# Load the Oracle Data Provider for .NET
#Add-Type -Path "C:\Oracle\ODP.NET\bin\4\Oracle.DataAccess.dll"

# Connection string variables
$oracleServer = "your_oracle_server"
$oraclePort = "1521"  # Default port for Oracle
$oracleSID = "your_SID"
$oracleUser = "your_username"
$oraclePassword = "your_password"

# Construct the connection string
$connectionString = "Data Source=(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=$oracleServer)(PORT=$oraclePort)))(CONNECT_DATA=(SERVER=DEDICATED)(SID=$oracleSID)));User Id=$oracleUser;Password=$oraclePassword;"


# Define your Oracle connection string
#$connectionString = "User Id=your_username;Password=your_password;Data Source=your_datasource"

# Define your SQL query
$sqlQuery = "SELECT * FROM your_table"

# Invoke the function
$results = Invoke-OracleQuery -ConnectionString $connectionString -Query $sqlQuery

# Display the results
$results | Format-Table -AutoSize
