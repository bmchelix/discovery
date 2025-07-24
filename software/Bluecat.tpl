
tpl 1.20 module ext.Bluecat;

metadata
    origin := 'community';
    publishers := 'Bluecat';
    tree_path:= 'Software', 'Active', 'Bluecat';
end metadata;

// .1.3.6.1.4.1.13315.100.210.1.8.2  replicationNodeStatus 
// Name/OID: replicationNodeStatus.0; Value (Integer): standalone (0)
//  INTEGER {unknown(-1),
// standalone(0),
// primary(1),
// standby(2)
// }

table bcnSysIdentification 1.0 // .1.3.6.1.4.1.13315.3.2.2.1
    "1.3.6.1.4.1.13315.3.2.2.1.1.0" -> "bcnSysIdProduct"; // Value (OID): .1.3.6.1.4.1.13315.2.2
    "1.3.6.1.4.1.13315.3.2.2.1.2.0" -> "bcnSysIdOSRelease"; //Value (OctetString): 9.2.0-919.GA.bcn
    "1.3.6.1.4.1.13315.3.2.2.1.3.0" -> "bcnSysIdSerial";
    "1.3.6.1.4.1.13315.3.2.2.1.5.0" -> "bcnSysIdPlatform";
    "1.3.6.1.4.1.13315.100.210.1.1.1.0" -> "version";
    "1.3.6.1.4.1.13315.3.1.6.2.1.2.1.2.0" -> "bcnLicenseType"; //  INTEGER {singleServer(1),multiServer(2)}
    "1.3.6.1.4.1.13315.3.1.6.2.1.2.1.7.0" -> "bcnLicenseValid"; //  INTEGER {true(1),false(2)}
end table;

table adonisObjects 1.0
    "1.3.6.1.4.1.13315.3.1.1.2.1.1.0" -> "bcnDhcpv4SerOperState"; //  INTEGER {running(1),notRunning(2),starting(3),stopping(4),fault(5)}
    "1.3.6.1.4.1.13315.3.1.2.2.1.1.0" -> "bcnDnsSerOperState"; //  INTEGER {running(1),notRunning(2),starting(3),stopping(4),fault(5)}
    "1.3.6.1.4.1.13315.3.1.4.2.1.1.0" -> "bcnNtpSerOperState"; //  INTEGER {running(1),notRunning(2),starting(3),stopping(4),fault(5)}
end table;

// // .1.3.6.1.4.1.13315.3.1.1.2.2.1.1 (bcnDhcpv4LeaseEntry)
// table bcnDhcpv4LeaseEntry 1.0
// 	"index" -> "index";
// 	"5" -> "mac"; //"bcnDhcpv4LeaseMacAddress";
// 	"6" -> "name"; //"bcnDhcpv4LeaseHostname";
// end table;
// 	// "1" -> "ip_addr"; //"bcnDhcpv4LeaseIP";

// // .1.3.6.1.4.1.13315.3.1.1.2.2.2.1 (bcnDhcpv4SubnetEntry)
// table bcnDhcpv4SubnetEntry 1.0
// 	"index" -> "index";
// 	"1" -> "subnet"; //"bcnDhcpv4SubnetIP";
// 	"2" -> "mask"; //"bcnDhcpv4SubnetMask";
// end table;

definitions defs 1.0
    """ Functions for modelling """
    type := function;
    define _create_detail(trig, detType, devInfo) -> detail
        """ create detail node for device""" 
        detail := model.Detail(key := text.hash("%detType%/%trig.key%"),
                                type := detType,
                                name := "%detType% on %trig.name%",
                                version := devInfo.version,
                                license_type := "",
                                vendor := trig.vendor
                                );
        if devInfo.bcnLicenseType = 1 then
            detail.license_type := "Single";
        elif devInfo.bcnLicenseType = 2 then
            detail.license_type := "Multi";
        end if;
        model.addDisplayAttribute(detail, [ "license_type", "vendor", "version" ]);
        model.rel.Detail(ElementWithDetail := trig, Detail := detail );
        
        return detail;
    end define;
end definitions;

pattern devices 1.0
    """ Pattern triggers on Bluecat SNMPManagedDevices and creates detail nodes for functionality"""

    overview
        tags bluecat;
    end overview;

    constants
        type  := "BlueCat";
    end constants;

    triggers
        on trig := SNMPManagedDevice created,confirmed where vendor = 'BlueCat Networks'; //and model = 'DNS/DHCP Server'
    end triggers;

    body
        devInfo := discovery.snmpGet(trig, bcnSysIdentification);
        if devInfo then
            log.debug(devInfo.bcnSysIdProduct);
            log.debug(devInfo.version);

            devFunctions := discovery.snmpGet(trig, adonisObjects);
            if devFunctions then
                if devFunctions.bcnDhcpv4SerOperState and not devFunctions.bcnDhcpv4SerOperState = 2 then
                    detType := "DHCP Server";
                    defs._create_detail(trig, detType, devInfo);
                end if;
                if devFunctions.bcnDnsSerOperState and not devFunctions.bcnDnsSerOperState = 2 then
                    detType := "DNS Server";
                    defs._create_detail(trig, detType, devInfo);
                end if;
                if devFunctions.bcnNtpSerOperState and not devFunctions.bcnNtpSerOperState = 2 then
                    detType := "NTP Server";
                    defs._create_detail(trig, detType, devInfo);
                end if;
            end if;
        end if;
    end body;
end pattern;
