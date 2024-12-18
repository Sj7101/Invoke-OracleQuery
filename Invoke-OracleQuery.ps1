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

        foreach ($queryItem in $queries) {
            $queryName = $queryItem.QueryName
            $query = $queryItem.Query
            $command = $connection.CreateCommand()
            $command.CommandText = $query

            $reader = $command.ExecuteReader()

            if ($reader.Read()) {
                # Adjusting to skip blank items and retrieve meaningful results
                $values = @()
                for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                    $fieldValue = $reader.GetValue($i)
                    if ($fieldValue -ne "" -and $fieldValue -ne $null) {
                        $values += $fieldValue
                    }
                }
                
                # Use the last non-blank value as the result
                $resultObject | Add-Member -MemberType NoteProperty -Name $queryName -Value ($values[-1])
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
