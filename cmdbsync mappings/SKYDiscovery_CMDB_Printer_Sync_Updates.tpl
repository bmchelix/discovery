tpl 1.5 module SKYDiscovery.CMDB.Printer_Sync_Updates;

from CMDB.Printer_Printer import Printer_Printer 2.0;

syncmapping Printer_Sync_Change 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    SystemName, Department, HostName, UnstructeredData & CustAssignedTo  """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from Printer_Printer.printer_node as printer_node
        // No additional structure -- we are just modifying the
        // existing ComputerSystem CI.
    end mapping;

    body
        managedby := "nodata";
        ownedby := "nodata";
        supportedby := "nodata";
        mandate := "nodata";
        assetdata := "nodata";

        computersystem := Printer_Printer.printer_ci;
        ClientName := 'clientname'; //you must update this with the client shortname IE gtoaut (use lower case)
        NewName := computersystem.Name;
        AppGrp := printer_node.applicationgrp;
        EnvGrp := printer_node.environment;

        if NewName has substring "." then
            // Modify the HostName to only include content up to the first dot
            NewName := text.split(NewName, ".")[0];
        end if;
        computersystem.Name := "%NewName%.%ClientName%";
        


        if computersystem.host_managedby <> "" then
            managedby := printer_node.host_managedby;
            assetdata := "mby:%managedby%";
        end if;

        if computersystem.host_ownedby <> "" then
            ownedby := printer_node.host_ownedby;
            assetdata := "%assetdata%,oby:%ownedby%";
        end if;

        if computersystem.host_supportedby <> "" then
            supportedby := printer_node.host_supportedby;
            assetdata := "%assetdata%,sby:%supportedby%";
        end if;

        if computersystem.host_mandate <> "" then
            mandate := printer_node.host_mandate;
            assetdata := "%assetdata%,man:%mandate%";
        end if;


        if assetdata <> "nodata" then
            computersystem.UnstructuredData := "%assetdata%";
        end if;

        computersystem.CustAssignedTo := "%ClientName%";
        computersystem.SystemName := "%NewName%";
        computersystem.HostName := "%NewName%";
        computersystem.Department := "SKYDISCOVERY";
        
    end body;

end syncmapping;