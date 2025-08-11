tpl 1.5 module SKYDiscovery.CMDB.Network_Sync_Updates;

from CMDB.NetworkDevice_ComputerSystem     import NetworkDevice_ComputerSystem 2.1;

syncmapping Network_Change 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    Name, CustAssignedTo, SystemName, HostName, Department & UnstructuredData """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from NetworkDevice_ComputerSystem.device as host
    end mapping;

    body
        device_cs := NetworkDevice_ComputerSystem.device_cs;
        ClientName := 'clientname'; //you must update this with the client shortname IE gtoaut (use lower case)
        NewName := device_cs.Name;
        
        managedby := "nodata";
        ownedby := "nodata";
        supportedby := "nodata";
        mandate := "nodata";
        assetdata := "nodata";

        if NewName has substring "." then
            // Modify the HostName to only include content up to the first dot
            NewName := text.split(NewName, ".")[0];
        end if;
        device_cs.Name := "%NewName%.%ClientName%";
        device_cs.CustAssignedTo := "%ClientName%";
        device_cs.SystemName := "%NewName%";
        device_cs.HostName := "%NewName%";
        device_cs.Department := "SKYDISCOVERY";

        if host.managedby <> "" then
            managedby := host.managedby;
            assetdata := "mby:%managedby%";
        end if;

        if host.ownedby <> "" then
            ownedby := host.ownedby;
            assetdata := "%assetdata%,oby:%ownedby%";
        end if;

        if host.supportedby <> "" then
            supportedby := host.supportedby;
            assetdata := "%assetdata%,sby:%supportedby%";
        end if;

        if host.mandate <> "" then
            mandate := host.mandate;
            assetdata := "%assetdata%,man:%mandate%";
        end if;


        if assetdata <> "nodata" then
            device_cs.UnstructuredData := "%assetdata%";
        end if;

    end body;

end syncmapping;