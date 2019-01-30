# Left this for reference - This script was intended to be used from on of the lab machines
# to check the status of the attendees :)
$pool = New-RunspacePool -ThrottleLimit 20
$count = (Get-ADComputer -Filter 'Name -like "Student*"').Count

while ($true)
{
    $jobs = foreach ($i in (1..$count))
    {
        $sb = {
            param($i) 
            Invoke-RestMethod -Method Get -Uri $('http://student{0:d2}/DoesItWork' -f $i)
        }
        Start-RunspaceJob -ScriptBlock $sb -RunspacePool $pool -Argument $i
    }

    $result = $jobs | Receive-RunspaceJob
    $result | Sort DoesItWork
    Start-Sleep -Seconds 10
}



foreach ($i in 1..20)
{

    $sqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $sqlConnection.ConnectionString = "Server=sql01.contoso.com;Database=Student{0:d2};Trusted_Connection=yes" -f $i
    $sqlCommand = New-Object -TypeName System.Data.SqlClient.SqlCommand
    $sqlCommand.Connection = $sqlConnection
    $sqlCommand.CommandText = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
    try 
    {
        $sqlConnection.Open()
    }
    catch 
    {
        continue
    }
    
    $reader = $sqlCommand.ExecuteReader()
    while ($reader.Read())
    {
        Write-Host "Found table $($reader['TABLE_NAME']) on SQL01!"
    }
    $sqlConnection.Close()
}