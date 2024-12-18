# Load the config outside of the functions (already done presumably)
# Example:
# $Script:Config = Get-Content "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json
# Add-Type -Path $Script:Config.AssemblyPath

function New-DatabaseQueryObject {
    param(
        [Parameter(Mandatory=$true)]
        $DBObject
    )

    # Start with a base PSCustomObject that includes DBName and System
    $NewObject = [PSCustomObject]@{
        DBName = $DBObject.DBName
        System = $DBObject.System
    }

    # Dynamically add a property for each query, using the query's name as the property name
    foreach ($query in $DBObject.Queries) {
        $NewObject | Add-Member -NotePropertyName $query.QueryName -NotePropertyValue $null
    }

    return $NewObject
}

function Get-EncryptedPassword {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PasswordFilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$KeyFilePath
    )

    if (-Not (Test-Path $PasswordFilePath)) {
        throw "Password file not found at '$PasswordFilePath'."
    }
    if (-Not (Test-Path $KeyFilePath)) {
        throw "Key file not found at '$KeyFilePath'."
    }

    # Read the encrypted password as a secure string using the provided key
    $securePasswordString = Get-Content -Path $PasswordFilePath | ConvertTo-SecureString -Key (Get-Content -Path $KeyFilePath)

    # Convert the secure string back to plain text
    $password = ([System.Net.NetworkCredential]::new('', $securePasswordString)).Password
    return $password
}

function Populate-DatabaseQueryResults {
    param(
        [Parameter(Mandatory=$true)]
        $DBObject,

        [Parameter(Mandatory=$true)]
        $NewObject
    )

    # Decrypt the password
    $password = Get-EncryptedPassword -PasswordFilePath $DBObject.PasswordPath -KeyFilePath $DBObject.KeyPath

    # Add the password to the connection string
    $connectionStringWithPassword = "$($DBObject.ConnectionString);Password=$password"

    # Create and open the connection
    $conn = New-Object Oracle.DataAccess.Client.OracleConnection($connectionStringWithPassword)
    try {
        $conn.Open()
    } catch {
        throw "Failed to open connection to $($DBObject.DBName): $_"
    }

    try {
        foreach ($query in $DBObject.Queries) {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $query.Query

            $results = @()
            $cols = @()

            try {
                $reader = $cmd.ExecuteReader()
                $cols = for ($i=0; $i -lt $reader.FieldCount; $i++) {
                    $reader.GetName($i)
                }

            while ($reader.Read()) {
                $row = @{}
                for ($i=0; $i -lt $reader.FieldCount; $i++) {
                    if ($reader.IsDBNull($i)) {
                        $value = $null
                    } else {
                        # Use GetOracleValue instead of GetValue
                        $oracleVal = $reader.GetOracleValue($i)
                        # Convert it to a string representation
                        $value = $oracleVal.ToString()
                    }
                    $row[$cols[$i]] = $value
                }
                $results += $row
            }
                $reader.Close()

            } catch {
                Write-Error "Query execution failed for '$($query.QueryName)' on $($DBObject.DBName): $_"
            } finally {
                $cmd.Dispose()
            }
            # Assigning the last column of the last row to the object property
            if ($results.Count -gt 0) {
                $lastRow = $results[-1]
                $lastCol = $cols[-1]
                $NewObject."$($query.QueryName)" = $lastRow[$lastCol]
            } else {
                # No results returned, so set it to "failed to query host"
                $NewObject."$($query.QueryName)" = "failed to query host"
            }
        }
    } catch {
        Write-Error "Error while processing queries for $($DBObject.DBName): $_"
    } finally {
        $conn.Close()
        $conn.Dispose()
    }

    return $NewObject
}

# Main logic: Iterate through each database and process it
foreach ($db in $Script:Config.DataBases) {
    Write-Host "Connecting to $($db.DBName)"
    $NewObject = New-DatabaseQueryObject -DBObject $db
    $T = Populate-DatabaseQueryResults -DBObject $db -NewObject $NewObject
    # $T now contains the populated object with query results
    $T
}
