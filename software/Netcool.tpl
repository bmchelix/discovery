tpl 1.19 module ext.netcool;

metadata
    origin:= 'community';
    tree_path := 'community', 'Software', 'Active', 'Netcool';
end metadata;

configuration cus_NetcoolConfig 1.0
    """Configuration Details for Netcool Integration"""
    "Netcool Database" ncdb := "ITNMDB";
end configuration;

definitions cus_DB2Queries 1.0
    """Netcool DB2 Database Server Queries"""
    type := sql_discovery;
    group := "IBM DB2 RDBMS";

    define EdgeDeviceQuery
        """Returns list of network devices and edge devices"""
        query := "select ANAME, AMAINNODEENTITYNAME, AMAINNODEENTITYIPADDRESS, ZNAME, ZMAINNODEENTITYNAME, ZMAINNODEENTITYIPADDRESS, AIFNAME, AIFINDEX from NCIM.ESN_BMC_L2CONNECTIONS";
    end define;
end definitions;

pattern NetcoolIntegration 1.0
    """
        The database name should be specified in the pattern configuration. 
        Relate Network relationships based on configurations in the Netcool database 

        Change History:
            2019-06-12 1.0 - Created.
    """

    overview
        tags custom, NetworkDevice, edge, db2;
    end overview;

    constants
        database_instance:= "itnminst";
    end constants;

    triggers
        on si:= SoftwareInstance created, confirmed where type = "IBM DB2 Database Server" and instance = database_instance;
    end triggers;

    body
        host:= related.host(si);
        port:= si.port;
        edge_mappings:= [];

        if port then
            // Extract list of Network Edge Devices and Clients on given port
            edge_mappings:= cus_DB2Queries.EdgeDeviceQuery(endpoint := host, port := port, database_name := '%cus_NetcoolConfig.ncdb%');
        else
            // Extract list of Network Edge Devices and Clients on default port
            edge_mappings:= cus_DB2Queries.EdgeDeviceQuery(endpoint := host, database_name := '%cus_NetcoolConfig.ncdb%');
        end if;

        if not edge_mappings then
            log.warn("No results found on %si.name%, stopping.");
            stop;
        end if;

        for result in edge_mappings do
            aifIndex:= result.aifindex;
            a_node_identity:= result.amainnodeentityname;
            z_node_identity:= result.zmainnodeentityname;
            zName:= result.zname;

            core_switch:= regex.extract(a_node_identity, regex "^(\S+?)\.", raw "\1", no_match:= a_node_identity);
            edge_switch:= regex.extract(z_node_identity, regex "^(\S+?)\.", raw "\1", no_match:= z_node_identity);
            edge_interface:= regex.extract(zName, regex "\[\s+(.*)\s+\]", raw "\1");

            if edge_interface then
                core_interfaces:= search(NetworkDevice, SNMPManagedDevice where lower(name) = '%core_switch%' or lower(name) = '%a_node_identity%' traverse DeviceWithInterface:DeviceInterface:InterfaceOfDevice:NetworkInterface where ifindex = %aifIndex%);
                edge_interfaces:= search(NetworkDevice, SNMPManagedDevice where lower(name) = '%edge_switch%' or lower(name) = '%z_node_identity%' traverse DeviceWithInterface:DeviceInterface:InterfaceOfDevice:NetworkInterface where interface_name = "%edge_interface%");

                esize:= size(edge_interfaces);
                if not esize > 0 then
                    edge_interfaces:= search(IPAddress where '%z_node_identity%' in lower(fqdns)
                                            traverse IPv4Address:DeviceAddress:DeviceWithAddress: where kind(#) = 'SNMPManagedDevice' or kind(#) = 'NetworkDevice'
                                            traverse DeviceWithInterface:DeviceInterface:InterfaceOfDevice:NetworkInterface where interface_name = '%edge_interface%'
                                            );
                end if;

                if size(edge_interfaces) > 0 and size(core_interfaces) > 0 then
                    coreIface:= core_interfaces[0];
                    edgeIface:= edge_interfaces[0];

                    net_rel:= model.rel.NetworkLink(EdgeDevice := coreIface, EdgeClient := edgeIface, source:= "Netcool");
                    model.setRemovalGroup(net_rel, "edges");
                    log.info("Created NetworkLink relationship from Core Switch %coreIface.name% to Edge Switch %edgeIface.name%!");
                end if;
            end if;
        end for;
    end body;
end pattern;
