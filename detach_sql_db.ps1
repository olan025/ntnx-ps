#
# Load configuration XML file.
#
[xml]$databases = Get-Content ".\AttachDatabasesConfig.xml"

#
# Get SQL Server database (MDF/LDF).
#
ForEach ($database in $databases.SQL.Databases) {
    $mdfFilename = $database.MDF
    $ldfFilename = $database.LDF
    $DBName = $database.DB_Name

    #
    # Detach SQL Server database
    #
    Add-PSSnapin SqlServerCmdletSnapin* -ErrorAction SilentlyContinue
    If (!$?) {Import-Module SQLPS -WarningAction SilentlyContinue}
    If (!$?) {"Error loading Microsoft SQL Server PowerShell module. Please check if it is installed."; Exit}
$attachSQLCMD = @"
USE [master]
GO
sp_detach_db $DBName
GO
"@
    Invoke-Sqlcmd $attachSQLCMD -QueryTimeout 3600 -ServerInstance 'WIN-GVMFM7PE61V'

}