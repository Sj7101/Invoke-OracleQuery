function Invoke-OracleQuery {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $true)]
        [string]$PasswordFilePath,

        [Parameter(Mandatory = $true)]
        [string]$KeyFilePath
    )

    # Load the Oracle Data Provider assembly
    $assemblyPath = "D:\apps\oracle\ODAC_64\odp.net\4\Oracle.DataAccess.dll"
    if (-Not (Test-Path $assemblyPath)) {
        throw "Oracle.DataAccess.dll not found at '$assemblyPath'. Please update the path."
    }

    try {
        # Load the assembly using LoadFile
        [System.Reflection.Assembly]::LoadFile($assemblyPath) | Out-Null
    } catch {
        throw "Failed to load Oracle.DataAccess.dll from '$assemblyPath'. Error: $_"
    }

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

    # Create a new Oracle connection
    try {
        $connection = New-Object Oracle.DataAccess.Client.OracleConnection($connectionStringWithPassword)
    } catch {
        throw "Failed to create Oracle connection. Verify if the assembly was loaded properly. Error: $_"
    }

    try {
        $connection.Open()

        # Create a new Oracle command
        $command = $connection.CreateCommand()
        $command.CommandText = $Query

        # Execute the command
        $reader = $command.ExecuteReader()

        $results = @()

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
        Write-Error "An error occurred while executing the query: $_"
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# Usage Example:
$connectionString = "User Id=zlrepmon;Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=danuxz9200si.domain.com)(PORT=3203))(CONNECT_DATA=(SERVICE_NAME=u11msgzl_uat)))"
$query = "SELECT employee_id, first_name, last_name FROM employees WHERE department_id = 10"
$passwordFilePath = "C:\path\to\password.txt"
$keyFilePath = "C:\path\to\keyfile.key"

$results = Invoke-OracleQuery -ConnectionString $connectionString -Query $query -PasswordFilePath $passwordFilePath -KeyFilePath $keyFilePath

# Display the results
$results | Format-Table -AutoSize


# Usage Example:
$connectionString = "User Id=zlrepmon;Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=danuxz9200si.domain.com)(PORT=3203))(CONNECT_DATA=(SERVICE_NAME=u11msgzl_uat)))"
$query = "SELECT employee_id, first_name, last_name FROM employees WHERE department_id = 10"
$passwordFilePath = "C:\path\to\password.txt"
$keyFilePath = "C:\path\to\keyfile.key"

$results = Invoke-OracleQuery -ConnectionString $connectionString -Query $query -PasswordFilePath $passwordFilePath -KeyFilePath $keyFilePath

# Display the results
$results | Format-Table -AutoSize



<#

# Path to the DLL
$DllPath = "C:\Path\To\Your\File.dll"

try {
    Write-Output "Loading COM assembly..."
    $comObject = New-Object -ComObject $DllPath
    Write-Output "COM assembly successfully registered."
} catch {
    Write-Error "Failed to register COM assembly: $_"
}




OraProvCfg.exe /action:config  /force /product:odp /frameworkversion:v4.0.30319 /providerpath:%ORACLE_CLIENT_HOME%\odp.net\bin\4\Oracle.DataAccess.dll

OraProvCfg.exe /action:gac /providerpath:%ORACLE_CLIENT_HOME%\odp.net\bin\4\Oracle.DataAccess.dll

OraProvCfg.exe /action:gac /providerpath:%ORACLE_CLIENT_HOME%\odp.net\PublisherPolicy\4\Policy.4.112.Oracle.DataAccess.dll

OraProvCfg.exe /action:gac /providerpath:%ORACLE_CLIENT_HOME%\odp.net\PublisherPolicy\4\Policy.4.121.Oracle.DataAccess.dll

OraProvCfg.exe /action:gac /providerpath:%ORACLE_CLIENT_HOME%\odp.net\PublisherPolicy\4\Policy.4.122.Oracle.DataAccess.dll

#>