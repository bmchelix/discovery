tpl 1.19 module cmdb_ext_SoftwareServer_UserName;

metadata
    origin := "community";
    description := "Add username attribute to SoftwareServer class";
    tree_path := 'community', 'CMDBsync', 'Extended', 'SoftwareServer', 'Username';
    last_update := '28 August 2020';
end metadata;

from CMDB.SoftwareInstance_SoftwareServer import SoftwareInstance_SoftwareServer 4.3;

syncmapping ext_SoftwareInstance_SoftwareServer_username 1.0
    """ Add attributes once the TKU has run.
        Saves importing and maintaining the entire code and requiring updating everytime the TKU is changed.

        Rule No		Rule Details
        1   		Set custom attributes - username from primary process/service

        HISTORY:
            28-08-2020 - Created.

        NOTES:
            Relies on a custom class attribute in the CMDB
    """

    overview
        tags CMDB, Extension, Custom;
    end overview;

    mapping from SoftwareInstance_SoftwareServer.softwareinstance as softwareinstance
    end mapping;

    body

        // Map the CDM ApplicationService node "softwareserver" variable
        softwareserver := SoftwareInstance_SoftwareServer.softwareserver;

        // Update Username attribute in CDM
        if softwareserver then
            softwareserver.UserName := softwareinstance.username;
        end if;
    end body;
end syncmapping;
