tpl 1.5 module SKYDiscovery.CMDB.SoftwareServer_SYNC;

from CMDB.SoftwareInstance_SoftwareServer import SoftwareInstance_SoftwareServer 4.0;
from CMDB.Host_ComputerSystem               import Host_ComputerSystem 2.0;

syncmapping SoftwareServer_CMDB_SYNC 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    CustCIName, Department, VersionNumber, ParentName, ParentCITag & UnstructuredData """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from SoftwareInstance_SoftwareServer.softwareinstance as softwareinstance
        // No additional structure -- we are just modifying the
        // existing SoftwareServer CI.
    end mapping;

    body

        hosting_ci := Host_ComputerSystem.computersystem or none;


        if hosting_ci = none then
            softwareserver := SoftwareInstance_SoftwareServer.softwareserver;
         
            if softwareserver then
                softwareserver.Department := "SKYDISCOVERY";
                verchk := softwareserver.VersionNumber;
                if verchk = none or verchk = "None" then
                    softwareserver.VersionNumber := "NoData";
                end if;

                if softwareinstance.managedby <> "" then
                    managedby := softwareinstance.managedby;
                    assetdata := "mby:%managedby%";
                end if;

                if softwareinstance.ownedby <> "" then
                    ownedby := softwareinstance.ownedby;
                    assetdata := "%assetdata%,oby:%ownedby%";
                end if;

                if softwareinstance.supportedby <> "" then
                    supportedby := softwareinstance.supportedby;
                    assetdata := "%assetdata%,sby:%supportedby%";
                end if;

                if softwareinstance.mandate <> "" then
                    mandate := softwareinstance.mandate;
                    assetdata := "%assetdata%,man:%mandate%";
                end if;

                if assetdata <> "nodata" then
                    softwareserver.UnstructuredData := "%assetdata%";
                end if;
                softwareserver.Department := "SKYDISCOVERY";
            end if;
            stop;
        end if;

        sysname := hosting_ci.Name;
        
        managedby := "nodata";
        ownedby := "nodata";
        supportedby := "nodata";
        mandate := "nodata";
        assetdata := "nodata";

        softwareserver := SoftwareInstance_SoftwareServer.softwareserver;
        cinamestart := softwareserver.Name;
        ciname := text.replace("%cinamestart%", "listening on ", "");

        newname := sysname;

        if sysname has substring "." then
            // Modify the HostName to only include content up to the first dot
            newname := text.split(sysname, ".")[0];
        end if;
        clusnamerev := "NODATA";
        clusname := "NODATA";
        cisoftserv := text.replace("%cinamestart%", "on %sysname%", "");       

        if cinamestart has substring " on " then
            clusname := text.split(cinamestart, " on ")[-1];
            clusname := text.split(clusname, ".")[0];
        end if;

        if softwareinstance.managedby <> "" then
            managedby := softwareinstance.managedby;
            assetdata := "mby:%managedby%";
        end if;

        if softwareinstance.ownedby <> "" then
            ownedby := softwareinstance.ownedby;
            assetdata := "%assetdata%,oby:%ownedby%";
        end if;

        if softwareinstance.supportedby <> "" then
            supportedby := softwareinstance.supportedby;
            assetdata := "%assetdata%,sby:%supportedby%";
        end if;

        if softwareinstance.mandate <> "" then
            mandate := softwareinstance.mandate;
            assetdata := "%assetdata%,man:%mandate%";
        end if;


        if assetdata <> "nodata" then
            softwareserver.UnstructuredData := "%assetdata%";
        end if;

        softwareserver.CustCIName := "%newname%";
        softwareserver.ParentName := "%sysname%";
        softwareserver.ParentCITag := "%clusname%";
        softwareserver.Department := "SKYDISCOVERY";

        verchk := softwareserver.VersionNumber or none;

        if verchk = "None" or verchk = none then
            softwareserver.VersionNumber := "NoData";
        end if;
    end body;

end syncmapping;

  