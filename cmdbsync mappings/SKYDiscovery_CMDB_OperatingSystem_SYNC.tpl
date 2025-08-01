// This is a template pattern module containing a CMDB syncmapping
// that overrides the Category, Type and Item for BMC_Product
// CIs mapped from particular BMC Discovery SoftwareInstance nodes.
//
// Names surrounded by double dollar signs like $$pattern_name$$ should all be 
// replaced with values suitable for the pattern.
//
// Text prefixed with // like these lines are comments that extend to
// the end of the line.
//
// This pattern is in the public domain.

tpl 1.19 module SKYDiscovery.CMDB.OperatingSystem_SYNC;

from CMDB.Host_OperatingSystem import Host_OperatingSystem 2.2;
from CMDB.Host_ComputerSystem  import Host_ComputerSystem 2.0;


syncmapping OS_CMDB_SYNC 1.0

    """
    Override the default CTI values for certain BMC_OPERATINGSYSTEM CIs.
    """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from Host_OperatingSystem.host as host
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
        managedby := "nodata";
        ownedby := "nodata";
        supportedby := "nodata";
        mandate := "nodata";
        assetdata := "nodata";

        osystem := Host_OperatingSystem.opsys;
        hosting_ci := Host_ComputerSystem.computersystem;
        sysname := hosting_ci.Name;
        AppGrp := hosting_ci.applicationgrp;
        NewName := text.lower("%sysname%");

        if NewName has substring "." then
        // Modify the HostName to only include content up to the first dot
        NewName := text.split(NewName, ".")[0];
        end if;

        sysosname := "%NewName%";
                
        cinamestart := osystem.Name;

        if host.os_managedby <> "" then
        managedby := host.os_managedby;
        assetdata := "mby:%managedby%";
        end if;

        if host.os_ownedby <> "" then
        ownedby := host.os_ownedby;
        assetdata := "%assetdata%,oby:%ownedby%";
        end if;

        if host.os_supportedby <> "" then
        supportedby := host.os_supportedby;
        assetdata := "%assetdata%,sby:%supportedby%";
        end if;

        if host.os_mandate <> "" then
        mandate := host.os_mandate;
        assetdata := "%assetdata%,man:%mandate%";
        end if;


        if assetdata <> "nodata" then
        osystem.UnstructuredData := "%assetdata%";
        end if;

         if AppGrp then
         AppGrp := text.replace("%AppGrp%", "['", "");
         AppGrp := text.replace("%AppGrp%", "']", "");
         CustName := text.lower("%AppGrp%");
         hosystem.CITag := "%AppGrp%";
         end if;

        osystem.Name := "%sysosname%-%cinamestart%";
        osystem.Department := "SKYDISCOVERY";

       verchk := osystem.VersionNumber or none;
        if verchk = "None" or verchk = none then
        osystem.VersionNumber := "NoData";
        end if;

    end body;

end syncmapping;

  