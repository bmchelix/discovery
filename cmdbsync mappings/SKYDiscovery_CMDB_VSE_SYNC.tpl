tpl 1.19 module SKYDiscovery.CMDB.VSE_SYNC;

from CMDB.SoftwareInstance_VirtualSystemEnabler import VirtualMachine_VirtualSystemEnabler 2.0;


syncmapping VSE_CMDB_SYNC 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    Department, VersionNumber, ManufacturerName """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from VirtualMachine_VirtualSystemEnabler.vm_node as vm_node
        // No additional structure -- we are just modifying the
        // existing VSE CI.
    end mapping;

    body
       

        vsechk := VirtualMachine_VirtualSystemEnabler.vm_node or none;
        vseci := VirtualMachine_VirtualSystemEnabler.vse;

        vseci.Department := "SKYDISCOVERY";

        verchk := vseci.VersionNumber or none;
        if verchk = "None" or verchk = none then
            vseci.VersionNumber := "NoData";
        end if;

        mfgnchk := vseci.ManufacturerName or none;
        if mfgnchk = "None" or mfgnchk = none then
            vseci.ManufacturerName := "unknown manufacturer";
        end if;

        ssvn := vseci.VersionNumber;
        ssdtype := datatype(ssvn);
        cinamestart := vseci.Name;
        
        if ssdtype = 'list' then
            vseci.VersionNumber := '';
        end if;

    end body;

end syncmapping;

  