tpl 1.19 module cmdb_ext_ComputerSystem_customAttrib;

metadata
    origin := 'community';
	description := 'Add attributes over TKU set values';
	last_update := '12 July 2021';
    tree_path := 'CMDBsync', 'Extended', 'ComputerSystem', 'Custom Attributes';
end metadata;

from CMDB.Host_ComputerSystem import Host_ComputerSystem 2.4;
from CMDB.NetworkDevice_ComputerSystem import NetworkDevice_ComputerSystem 2.1;
from CMDB.Printer_Printer import Printer_Printer 2.0;
from CMDB.SNMPManagedDevice_ComputerSystem import SNMPManagedDevice_ComputerSystem 2.1;
from CMDB.StorageSystem_ComputerSystem import StorageSystem_ComputerSystem 2.3;

syncmapping ext_cmdb_ComputerSystem_custom_attrib 1.3
    """
        Add attributes once the TKU has run.
        Saves importing and maintaining the entire code and requiring updating everytime the TKU is changed.

        Rule No		Rule Details
        1   		Set custom attributes

        HISTORY:
            12-07-2021 - Created
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

        // Custom attribute to record source of data in BMC.ASSET
        computersystem.OriginSource := "Discovery";
    end body;
end syncmapping;

