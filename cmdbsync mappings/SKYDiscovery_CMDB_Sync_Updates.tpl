// This is a template pattern module containing a CMDB syncmapping
// that changes the HostName attribute of BMC_ComputerSystem so it
// never contains a dot.
//
// Text prefixed with // like these lines are comments that extend to
// the end of the line.
//
// This pattern is in the public domain.

tpl 1.5 module SKYDiscovery.CMDB.Sync_Updates;

from CMDB.Host_ComputerSystem import Host_ComputerSystem 2.0;

syncmapping Host_Name_Change 1.0
    """
    Change the default ComputerSystem HostName and TokenId to take
    only the first component of compound dot-separated hostnames.
    """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from Host_ComputerSystem.host as host
        // No additional structure -- we are just modifying the
        // existing ComputerSystem CI.
    end mapping;

    body
        managedby := "nodata";
        ownedby := "nodata";
        supportedby := "nodata";
        mandate := "nodata";
        assetdata := "nodata";

        computersystem := Host_ComputerSystem.computersystem;
        ClientName := 'clientname'; //you must update this with the client shortname IE gtoaut (use lower case)
        NewName := computersystem.Name;
        AppGrp := host.applicationgrp;
        EnvGrp := host.environment;
        HLoc := host.locationdata;

        if NewName has substring "." then
            // Modify the HostName to only include content up to the first dot
            NewName := text.split(NewName, ".")[0];
        end if;
        barcode := host.barcodedata;
        whid := host.whid;

        computersystem.Name := "%NewName%.%ClientName%";
          computersystem.Department := "SKYDISCOVERY";      


        if computersystem.host_managedby <> "" then
        managedby := host.host_managedby;
        assetdata := "mby:%managedby%";
        end if;

        if computersystem.host_ownedby <> "" then
        ownedby := host.host_ownedby;
        assetdata := "%assetdata%,oby:%ownedby%";
        end if;

        if computersystem.host_supportedby <> "" then
        supportedby := host.host_supportedby;
        assetdata := "%assetdata%,sby:%supportedby%";
        end if;

        if computersystem.host_mandate <> "" then
        mandate := host.host_mandate;
        assetdata := "%assetdata%,man:%mandate%";
        end if;


        if assetdata <> "nodata" then
        computersystem.UnstructuredData := "%assetdata%";
        end if;


        if barcode then
        barcode := text.replace("%barcode%", "['", "");
        barcode := text.replace("%barcode%", "']", "");
        computersystem.CustEmpNo := "%barcode%";
        end if;
        if whid then
        whid := text.replace("%whid%", "['", "");
        whid := text.replace("%whid%", "']", "");
        computersystem.CustCIName := "%whid%";
        computersystem.ShortDescription := "%whid%";
        end if;
        computersystem.CustAssignedTo := "%ClientName%";
        computersystem.SystemName := "%NewName%";
        computersystem.HostName := "%NewName%";
        if EnvGrp then
        EnvGrp := text.replace("%EnvGrp%", "['", "");
        EnvGrp := text.replace("%EnvGrp%", "']", "");
        computersystem.SystemEnvironment := "%EnvGrp%";
        end if;
        if AppGrp then
        AppGrp := text.replace("%AppGrp%", "['", "");
        AppGrp := text.replace("%AppGrp%", "']", "");
        computersystem.CITag := "%AppGrp%";
        end if;
        if HLoc then
        HLoc := text.replace("%HLoc%", "['", "");
        HLoc := text.replace("%HLoc%", "']", "");
        computersystem.CityName := "%HLoc%";
        end if;



    end body;

end syncmapping;