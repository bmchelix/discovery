tpl 1.19 module SKYDiscovery.CMDB.Port_SYNC;

from CMDB.NetworkInterface_Endpoints import NetworkInterface_Endpoints 3.0;
from CMDB.Host_ComputerSystem  import Host_ComputerSystem 2.0;


syncmapping PORT_CMDB_SYNC 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    Name & Department """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from NetworkInterface_Endpoints.ni_node as ni_node
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
        lanep := NetworkInterface_Endpoints.lan_ep;

        netport := NetworkInterface_Endpoints.net_port;

        hosting_ci := Host_ComputerSystem.computersystem;
        sysname := hosting_ci.Name;
        
        NewName := text.lower("%sysname%");

        if NewName has substring "." then
            // Modify the HostName to only include content up to the first dot
            NewName := text.split(NewName, ".")[0];
        end if;

        sysosname := "%NewName%";
                
        cinamestart := netport.Name;
        netport.Name := "%sysosname%-%cinamestart%";
        netport.Department := "SKYDISCOVERY";

        if ni_node.mac_addr then
            cinamestartep := lanep.Name;
            lanep.Name := "%sysosname%-%cinamestartep%";
            lanep.Department := "SKYDISCOVERY";
        end if;

    end body;

end syncmapping;

syncmapping IP_CMDB_SYNC 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    Name & Department """
    overview
        tags CMDB, Extension;
    end overview;
    mapping from NetworkInterface_Endpoints.ip_node as ip_node
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
        ipep := NetworkInterface_Endpoints.ip_ep;

        hosting_ciipep := Host_ComputerSystem.computersystem;
        sysnameipep := hosting_ciipep.Name;
        
        NewNameipep := text.lower("%sysnameipep%");

        if NewNameipep has substring "." then
            // Modify the HostName to only include content up to the first dot
            NewNameipep := text.split(NewNameipep, ".")[0];
        end if;

        sysosnameipep := "%NewNameipep%";

        if ipep then
            cinamestartipep := ipep.Name;
            ipep.Name := "%sysosnameipep%-%cinamestartipep%";
            ipep.Department := "SKYDISCOVERY";
        end if;

    end body;

end syncmapping;