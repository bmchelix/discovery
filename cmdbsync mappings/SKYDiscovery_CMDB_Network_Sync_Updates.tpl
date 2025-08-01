// This is a template pattern module containing a CMDB syncmapping
// that changes the HostName attribute of BMC_ComputerSystem so it
// never contains a dot.
//This is for Network Devices
//
// Text prefixed with // like these lines are comments that extend to
// the end of the line.
//

tpl 1.5 module SKYDiscovery.CMDB.Network_Sync_Updates;

from CMDB.NetworkDevice_ComputerSystem     import NetworkDevice_ComputerSystem 2.1;

syncmapping Network_Change 1.0
    """
    Change the default ComputerSystem HostName and TokenId to take
    only the first component of compound dot-separated hostnames.
    """
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