tpl 1.18 module SKYDiscovery.CMDB.CMDB_Database;

from CMDB.Database							 import Database 2.4;
from CMDB.Host_ComputerSystem                import Host_ComputerSystem 2.0;
from CMDB.MFPart_ComputerSystem              import MFPart_ComputerSystem 2.0;

syncmapping Database_Augment 1.0
"""
Add one or more new attributes to the BMC_IPEndpoint CI, based
on attributes in the BMC Discovery all node.
"""
overview
	tags CMDB, Extension;
end overview;

mapping from Database.database_node as database_node
end mapping;

body
	hosting_ci := Host_ComputerSystem.computersystem or
				MFPart_ComputerSystem.computersystem or none;

        if hosting_ci = none then
        database_ci := Database.database_ci;
         
        if database_ci then
            database_ci.Department := "SKYDISCOVERY";
        end if;
        stop;
        end if;

	sysname := hosting_ci.Name;
	newname := sysname;
        if sysname has substring "." then
            // Modify the HostName to only include content up to the first dot
            newname := text.split(sysname, ".")[0];
        end if;
	

	database_ci := Database.database_ci;
        ciname := database_ci.Name;
	database_ci.ParentName := sysname;
	database_ci.CustCIName := newname;
        database_ci.Name := "%newname%-%ciname%";
        database_ci.Department := "SKYDISCOVERY";

end body;

end syncmapping;
