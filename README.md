# ntnx-ps
Nutanix powershell scripts
First project is to automate the population of a test SQL instance with a cloned copy of a production SQL instance leveraging ESXi and Nutanix Volume Groups

Currently 1 script with an XML config file for DBs
1. XML file contains the paths to the database files for SQL on the Test instance to attach to (driver letters  :()
2. Clone-vg.ps1 - Used with create or remove as a parameter. Creates or removes a restored from snapshot copy of a production SQL database to a running instance of SQL on another host. Workflow can be used to quickly populate multiple test/dev environments for production SQL.
