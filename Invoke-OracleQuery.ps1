function Invoke-OracleQuery {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DBObject
    )

    # Extract information from $DBObject
    $ConnectionString = $DBObject.ConnectionString
    $DBName = $DBObject.DBName
    $UserName = $DBObject.UserName
    $PasswordFilePath = $DBObject.PasswordPath
    $KeyFilePath = $DBObject.KeyPath
    $queries = $DBObject.Queries
    $System = $DBObject.System

    # Load the encrypted password from the .txt file
    if (-Not (Test-Path $PasswordFilePath)) {
        throw "Password file not found at '$PasswordFilePath'."
    }
    if (-Not (Test-Path $KeyFilePath)) {
        throw "Key file not found at '$KeyFilePath'."
    }
    $securePasswordString = Get-Content -Path $PasswordFilePath | ConvertTo-SecureString -Key (Get-Content -Path $KeyFilePath)
    $password = [System.Net.NetworkCredential]::new('', $securePasswordString).Password

    # Add password to the connection string
    $connectionStringWithPassword = "$ConnectionString;Password=$password"

    # Initialize the result object with the name of $System
    $resultObject = New-Object PSObject -Property @{ }
    $resultObject.PSObject.TypeNames.Insert(0, $System)
    $resultObject | Add-Member -MemberType NoteProperty -Name "DBName" -Value $DBName

    # Create a new Oracle connection
    try {
        $connection = New-Object Oracle.DataAccess.Client.OracleConnection($connectionStringWithPassword)
        $connection.Open()

        foreach ($queryName in $queries.PSObject.Properties.Name) {
            $query = $queries.$queryName
            $command = $connection.CreateCommand()
            $command.CommandText = $query

            $reader = $command.ExecuteReader()

            if ($reader.Read()) {
                $value = $reader.GetValue(0)
                $resultObject | Add-Member -MemberType NoteProperty -Name $queryName -Value $value
            }
        }

        return $resultObject
    } catch {
        throw "An error occurred while executing the queries: $_"
    } finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# Usage Example:
$results = Invoke-OracleQuery -DBObject $SomeDBObject

# Display the results
$results | Format-Table -AutoSize
