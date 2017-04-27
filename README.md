# ntnx-ps
Nutanix powershell scripts
First project is to automate the population of a test SQL instance with a cloned copy of a production SQL instance leveraging ESXi and Nutanix Volume Groups

Currently there are 4 scripts and 1 XML.
1. XML file contains the paths to the database files for SQL on the Test instance to attach to (driver letters  :()
2. Clone-vg.ps1 - Used with create or remove as a parameter. Creates or removes a restored from snapshot copy of a production SQL database to a running instance of SQL on another host. Workflow can be used to quickly populate multiple test/dev environments for production SQL.
3. attach-sql-db.ps1 - uses the xml file to attach SQL databases to test sql instance
4. remove-dql-db.ps1 - detaches the sql databases


# TODOs
#add error handling
#integrate into a single script with functions and logging
improve authentication / permissions 
integrate SQL db actions into script
determine approach to mount points
validate .... dang work....
