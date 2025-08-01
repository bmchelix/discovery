// This is a template pattern module containing a CMDB syncmapping
//
// Names surrounded by double dollar signs like $$pattern_name$$ should all be 
// replaced with values suitable for the pattern.
//
// Text prefixed with // like these lines are comments that extend to
// the end of the line.
//
// This pattern is in the public domain.

tpl 1.19 module SKYDiscovery.CMDB.Net_Port_SYNC;

from CMDB.Device_Endpoints import Device_Endpoints 2.0;
from CMDB.NetworkDevice_ComputerSystem  import NetworkDevice_ComputerSystem 2.0;
from CMDB.SNMPManagedDevice_ComputerSystem import SNMPManagedDevice_ComputerSystem 2.0;
from CMDB.Printer_Printer                  import Printer_Printer 2.0;
from CMDB.StorageSystem_ComputerSystem     import StorageSystem_ComputerSystem 2.0;
from CMDB.StorageProcessor_HardwarePackage import StorageProcessor_HardwarePackage 2.0;

syncmapping NET_PORT_CMDB_SYNC 1.0

    """
    Override the default CTI values for certain BMC_OPERATINGSYSTEM CIs.
    """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from Device_Endpoints.ni_node as ni_node
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
        lanep := Device_Endpoints.lan_ep;
        netport := Device_Endpoints.net_port;
        hosting_ci := NetworkDevice_ComputerSystem.device_cs or
                          SNMPManagedDevice_ComputerSystem.device_cs or
                          Printer_Printer.printer_ci or
                          StorageProcessor_HardwarePackage.processor_ci or
                          StorageSystem_ComputerSystem.computersystem;

        sysname := hosting_ci.Name;
        
        NewName := text.lower("%sysname%");

        if NewName has substring "." then
        // Modify the HostName to only include content up to the first dot
        NewName := text.split(NewName, ".")[0];
        end if;

        sysosname := "%NewName%";
                
        cinamestart := netport.Name;


        netport.Name := "%sysosname%-%cinamestart%";

    if ni_node.mac_addr then
        cinamestartep := lanep.Name;
        lanep.Name := "%sysosname%-%cinamestartep%";
        lanep.Department := "SKYDISCOVERY";
    end if;

    end body;

end syncmapping;

syncmapping IP_PORT_CMDB_SYNC 1.0

    """
    Override the default CTI values for certain BMC_OPERATINGSYSTEM CIs.
    """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from Device_Endpoints.ip_node as ip_node
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body

        ipep := Device_Endpoints.ip_ep;
        hosting_ciipep := NetworkDevice_ComputerSystem.device_cs or
                          SNMPManagedDevice_ComputerSystem.device_cs or
                          Printer_Printer.printer_ci or
                          StorageProcessor_HardwarePackage.processor_ci or
                          StorageSystem_ComputerSystem.computersystem;

        sysnameciipep := hosting_ciipep.Name;
    
        NewNameciipep  := text.lower("%sysnameciipep%");

        if NewNameciipep  has substring "." then
        // Modify the HostName to only include content up to the first dot
        NewNameciipep := text.split(NewNameciipep, ".")[0];
        end if;

        sysosnameciipep := "%NewNameciipep%";
    if ipep then     
        cinamestartciipep := ipep.Name;
        ipep.Name := "%sysosnameciipep%-%cinamestartciipep%";
        ipep.Department := "SKYDISCOVERY";
    end if;

    end body;

end syncmapping;