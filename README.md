# ntnx-ps
Nutanix powershell scripts
First project is to automate the population of a test SQL instance with a cloned copy of a production SQL instance leveraging ESXi and Nutanix Volume Groups

Currently there are 4 scripts and 1 XML.
1. XML file contains the paths to the database files for SQL on the Test instance to attach to (driver letters  :()
2. Clone-vg.ps1 - creates a "clone" (actually a restored to new location) copy of a volume group that has a protection schedule, add's the Test SQL instance IP to the iSCSI initators on the new vg, configures the windows iscsi client to see the new disks
3. attach-sql-db.ps1 - uses the xml file to attach SQL databases to test sql instance
4. remove-dql-db.ps1 - detaches the sql databases
5. remove-vg.ps1 - remove the protection group


#TODOs
add error handling
integrate into a single script with functions and logging
