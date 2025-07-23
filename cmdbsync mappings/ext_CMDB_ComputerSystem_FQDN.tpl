tpl 1.19 module cmdb_ext_ComputerSystem_fqdn;

metadata
    origin := "community";
    description := 'Convert fqdn to shortname ';
    last_update := '08 June 2018';
    tree_path := 'CMDBsync', 'Extended', 'ComputerSystem', 'FQDN';
end metadata;

from CMDB.Host_ComputerSystem import Host_ComputerSystem 2.4;
from CMDB.NetworkDevice_ComputerSystem import NetworkDevice_ComputerSystem 2.1;
from CMDB.Printer_Printer import Printer_Printer 2.0;
from CMDB.SNMPManagedDevice_ComputerSystem import SNMPManagedDevice_ComputerSystem 2.1;
from CMDB.StorageSystem_ComputerSystem import StorageSystem_ComputerSystem 2.3;

syncmapping ext_cmdb_ComputerSystem_fqdn 1.0
    """ Modify and/or add attributes once the TKU has run.
        Saves importing and maintaining the entire code and requiring updating everytime the TKU is changed.

        Rule No  Rule Details
        1        Set Name & ShortDescription to shortname not fqdn

        HISTORY:
            08-06-2018 - Created
    """
    
    overview
        tags CMDB,custom_mapping;
        datamodel 0, 1, 2, 3, 4, 5, 6;
    end overview;

    mapping from Host_ComputerSystem.host // mapping on the TKU code ensures execution order is AFTER oob code and protects against "flip flopping of values being forwarded into CMDB
            from NetworkDevice_ComputerSystem.device
            from Printer_Printer.printer_node
            from SNMPManagedDevice_ComputerSystem.device
            from StorageSystem_ComputerSystem.storagesystem
                as device 
    end mapping;

    body
        computersystem :=  Host_ComputerSystem.computersystem or
                           NetworkDevice_ComputerSystem.device_cs or
                           SNMPManagedDevice_ComputerSystem.device_cs or
                           StorageSystem_ComputerSystem.computersystem or
                           Printer_Printer.printer_ci;
        
        // Convert all FQDN to hostname (required as nix based devices tend to have fqdn style names
        if device.name <> "" then
            if device.name has substring "." then
                normalized_name := text.split(device.name, ".")[0];
            else
                normalized_name := device.name;
            end if;
        else
            normalized_name := device.name;
        end if;
        ci_HostName := normalized_name;
        log.info("hostname set to %normalized_name%");
        
        computersystem.Name    := normalized_name;
        computersystem.ShortDescription := normalized_name;
    end body;
end syncmapping;
