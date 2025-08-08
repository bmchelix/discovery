// This is a template pattern module containing a CMDB syncmapping
//
// Names surrounded by double dollar signs like $$pattern_name$$ should all be 
// replaced with values suitable for the pattern.
//
// Text prefixed with // like these lines are comments that extend to
// the end of the line.
//
// This pattern is in the public domain.

tpl 1.19 module SKYDiscovery.CMDB.Net_OperatingSystem_SYNC;

from CMDB.NetworkDevice_OperatingSystem import NetworkDevice_OperatingSystem 2.0;
from CMDB.NetworkDevice_ComputerSystem  import NetworkDevice_ComputerSystem 2.0;


syncmapping NET_OS_CMDB_SYNC 1.0

    """
    Override the default CTI values for certain BMC_OPERATINGSYSTEM CIs.
    """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from NetworkDevice_OperatingSystem.device as device
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
       
        osystem := NetworkDevice_OperatingSystem.device_os;
        hosting_ci := NetworkDevice_ComputerSystem.device_cs;
        sysname := hosting_ci.Name;
        
        NewName := text.lower("%sysname%");

        if NewName has substring "." then
        // Modify the HostName to only include content up to the first dot
        NewName := text.split(NewName, ".")[0];
        end if;

        sysosname := "%NewName%";
                
        cinamestart := osystem.Name;

        osystem.Name := "%sysosname%-%cinamestart%";
        osystem.Department := "SKYDISCOVERY";

        verchk := osystem.VersionNumber or none;
        if verchk = "None" or verchk = none then
        osystem.VersionNumber := "NoData";
        end if;

        ssvn := osystem.VersionNumber;
        ssdtype := datatype(ssvn);
        cinamestart := osystem.Name;
        
        if ssdtype = 'list' then
        osystem.VersionNumber := '';
        end if;

    end body;

end syncmapping;