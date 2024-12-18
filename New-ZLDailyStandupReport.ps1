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

# Example usage:
# Assuming $Script:Config is already loaded from your JSON,
# and you want to process the first database item:
# $DBObject = $Script:Config.DataBases[0]
# $resultObject = New-DatabaseQueryObject -DBObject $DBObject
# $resultObject



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
    $password = Get-DecryptedPassword -PasswordFilePath $DBObject.PasswordPath -KeyFilePath $DBObject.KeyPath

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
                        $row[$cols[$i]] = $reader.GetValue($i)
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
                # No results returned, so just set it to $null
                $NewObject."$($query.QueryName)" = $null
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


























Add-Type -Path "D:\apps\ODAC_64\odp.net\bin\4\Oracle.DataAccess.dll"

