tpl 1.19 module cmdb_ext_ComputerSystem_Case_Upper;

metadata
    origin := "community";
    description := 'Update attributes to upper case';
    last_update := '08 June 2018';
    tree_path := 'community', 'CMDBsync', 'Extended', 'ComputerSystem', 'UpperCase';
end metadata;

from CMDB.Host_ComputerSystem import Host_ComputerSystem 2.4;
from CMDB.NetworkDevice_ComputerSystem import NetworkDevice_ComputerSystem 2.1;
from CMDB.Printer_Printer import Printer_Printer 2.0;
from CMDB.SNMPManagedDevice_ComputerSystem import SNMPManagedDevice_ComputerSystem 2.1;
from CMDB.StorageSystem_ComputerSystem import StorageSystem_ComputerSystem 2.3;

syncmapping ext_cmdb_ComputerSystem_uppercase 1.0
    """ Modify and/or add attributes once the TKU has run.
        Saves importing and maintaining the entire code and requiring updating everytime the TKU is changed.

        Rule No  Rule Details
        1        Convert name, serialnumber, shortdescription, domain and host name to upper case

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
        computersystem := Host_ComputerSystem.computersystem or
                          NetworkDevice_ComputerSystem.device_cs or
                          SNMPManagedDevice_ComputerSystem.device_cs or
                          StorageSystem_ComputerSystem.computersystem or
                          Printer_Printer.printer_ci;
        
        if device.dns_domain then
            dns_domain := text.upper(device.dns_domain);
        else
            dns_domain := "";
        end if;
        
        if device.serial then
            serial := text.upper(device.serial);
        else
            serial := "";
        end if;
        
        if device.name <> "" then
            normalized_name := text.upper(device.name);
        else
            normalized_name := device.name;
        end if;

        ci_HostName := text.upper(normalized_name);    

        log.info("hostname set to %normalized_name%");
        
        computersystem.Name                := normalized_name;
        computersystem.ShortDescription    := normalized_name;
        computersystem.SerialNumber        := serial;
        computersystem.Domain            := dns_domain;
        computersystem.HostName            := ci_HostName;
    end body;
end syncmapping;
