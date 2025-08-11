tpl 1.19 module SKYDiscovery.CMDB.Product_SYNC;

from CMDB.SoftwareInstance_Product import SoftwareInstance_Product 1.6;
from CMDB.RuntimeEnvironment_Product import RuntimeEnvironment_Product 2.0;
from CMDB.Host_ComputerSystem               import Host_ComputerSystem 2.0;

syncmapping Product_CMDB_SYNC 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    Name, Department & VersionNumber """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from SoftwareInstance_Product.softwareinstance as softwareinstance
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
        hosting_ci := Host_ComputerSystem.computersystem or none;

        if hosting_ci = none then
            softwareserver := SoftwareInstance_Product.product;
            if softwareserver then
                softwareserver.Department := "SKYDISCOVERY";
                verchk := softwareserver.VersionNumber or none;
                if verchk = "None" or verchk = none then
                    softwareserver.VersionNumber := "NoData";
                end if;
            end if;
            stop;
        end if;

        sysname := hosting_ci.Name;

        NewName := text.lower("%sysname%");
        if NewName has substring "." then
            // Modify the HostName to only include content up to the first dot
            NewName := text.split(NewName, ".")[0];
        end if;
        
        softwareserver := SoftwareInstance_Product.product;
         
        if softwareserver then
            ciname := softwareserver.Name;

            softwareserver.Name := "%NewName%-%ciname%";
            softwareserver.Department := "SKYDISCOVERY";
    
            verchk := softwareserver.VersionNumber or none;
            if verchk = "None" or verchk = none then
                softwareserver.VersionNumber := "NoData";
            end if;

            ssvn := softwareserver.VersionNumber;
            ssdtype := datatype(ssvn);
            cinamestart := softwareserver.Name;
            
            if ssdtype = 'list' then
                softwareserver.VersionNumber := '';
            end if;

        end if;
    end body;

end syncmapping;


syncmapping Product_RTENV_CMDB_SYNC 1.0

    """
    Override the default CTI values for certain BMC_Product CIs.
    """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from RuntimeEnvironment_Product.runtime_env as runtime_env
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
        hosting_ci := Host_ComputerSystem.computersystem or none;

        if hosting_ci = none then
        runtimeenvironement := RuntimeEnvironment_Product.product;
         
        if runtimeenvironement then
            runtimeenvironement.Department := "SKYDISCOVERY";
        end if;
        stop;
        end if;


        sysname := hosting_ci.Name;
        NewName := text.lower("%sysname%");
        if NewName has substring "." then
        // Modify the HostName to only include content up to the first dot
        NewName := text.split(NewName, ".")[0];
        end if;
        
        runtimeenvironement := RuntimeEnvironment_Product.product;
                
         
        if runtimeenvironement then
        ciname := runtimeenvironement.Name;

        runtimeenvironement.Name := "%NewName%-%ciname%";
        runtimeenvironement.Department := "SKYDISCOVERY";
        verchk := runtimeenvironement.VersionNumber or none;
        if verchk = "None" or verchk = none then
        runtimeenvironement.VersionNumber := "NoData";
        end if;

        ssvn := runtimeenvironement.VersionNumber;
        ssdtype := datatype(ssvn);
        cinamestart := runtimeenvironement.Name;

        if ssdtype = 'list' then
        runtimeenvironement.VersionNumber := '';
        end if;

        end if;

    end body;

end syncmapping;