tpl 1.20 module si.ubiquiti.unifi;

metadata
    origin := 'community';
    description := '';
    product_synonyms := "unifi";
    tree_path := 'Software', 'Active', 'Ubiquiti', 'Unifi';
end metadata;

definitions local_functions 1.0
    """	local functions """
    type := function;

    define _updateSi(fileContent, dhcp_si, devScope := none) -> si_updated
        """	add attributes from dnsmasq conf file """ 

        leaseCount   := none;
        dcsis        := none;

        // add SI details
        if "dhcp-lease-max" in fileContent then
            leaseCount := regex.extract(fileContent, regex 'dhcp\-lease\-max\=(\d+)', raw '\1');
            if leaseCount then
                log.debug(leaseCount);
                si_updated.leases := text.toNumber(leaseCount);
                model.addDisplayAttribute(si_updated, "leases");
            end if;
        end if;
        if "strict-order" in fileContent then
            si_updated.strict_order := true;
            model.addDisplayAttribute(si_updated, "strict_order");
        end if;
        if "dhcp-authoritative" in fileContent then
            si_updated.authorised := true;
            model.addDisplayAttribute(si_updated, "authorised");
        end if;
        if "no-hosts" in fileContent then
            si_updated.no_hosts := true;
            model.addDisplayAttribute(si_updated, "no_hosts");
        end if;
        if "no-ping" in fileContent then
            si_updated.no_ping := true;
            model.addDisplayAttribute(si_updated, "no_ping");
        end if;

        return si_updated;
    end define;

end definitions;

pattern udm 1.0
    """CHANGE HISTORY:
        24-03-2023 Initial draft

        Unifi Dream Machine does not provide SNMP access to logon can only be via ssh. Unfortunately the usual candidate_serial commands do not work on the unifi-os.
        Serial is just the MAC of the device although better to look in the right place so: grep serialno /proc/ubnthal/system.info
    """
    overview
        tags unifi, udm;
    end overview;

    triggers
        on trig := Host confirmed where vendor = 'UniFi';
    end triggers;

    body
        host := related.host(trig);

        //missing serial number
        grabSerial := 'grep serialno /proc/ubnthal/system.info';
        grabSerial_run := discovery.runCommand(host, grabSerial);
        if grabSerial_run then
            extractSerial := regex.extract(grabSerial_run.result, regex 'serialno=(\S+)', raw '\1');
            if extractSerial then
                trig.serial := extractSerial;
                log.debug(extractSerial);
            end if;
        end if;
    end body;
end pattern;

//////////////////////////////////////////////////////////////////////////////////

pattern dnsmasq_dhcp_server 1.0
    """
        Create a DHCP Server si where dnsmasq is configured.
        Take versioning from the package

        CHANGE HISTORY:
            24-03-2023 Initial draft
    """
    overview
        tags unifi, udm, dhcp;
    end overview;

    constants
        si_type := 'DHCP Server';
    end constants;

    triggers
        on trig := DiscoveredProcess created, confirmed where cmd matches 'dnsmasq' and args matches 'conf';
    end triggers;

    body
        host := related.host(trig);
        dhcp_si := none;

        if trig.args has substring 'conf-file' then
            extractFile := regex.extract(trig.args, regex 'conf-file=(\S+)\W', raw '\1');
            if extractFile then
                confFile := discovery.fileGet(host, '%extractFile%');
                if confFile and confFile.content and "dhcp-range" in confFile.content then
                    dhcp_si := model.SoftwareInstance( key := '%si_type%/%host.key%',
                                                        name := '%si_type% on %host.name%',
                                                        short_name := 'DHCP',
                                                        type := si_type
                                                        );
                    detNode := local_functions._updateSi(confFile.content, dhcp_si, host.scope);
                end if;
            end if;
        elif trig.args has substring 'conf-dir' then
            extractDir := regex.extract(trig.args, regex 'conf-dir=(\S+)\W', raw '\1');
            if extractDir then
                lsConfDir := 'ls -larth %extractDir% | grep conf';
                lsConfDir_run := discovery.runCommand(host, lsConfDir);
                if lsConfDir_run then
                    extractFiles := regex.extractAll(lsConfDir_run.result, regex '\s(\S+.conf)');
                    for extractFile in extractFiles do
                        confFile := discovery.fileGet(host, '%extractDir%/%extractFile%');
                        if confFile and confFile.content then
                            dhcp_si := model.SoftwareInstance( key := '%si_type%/%host.key%',
                                                                name := '%si_type% on %host.name%',
                                                                short_name := 'DHCP',
                                                                type := si_type
                                                                );
                            dhcp_si_upd := local_functions._updateSi(confFile.content, dhcp_si, host.scope);
                        end if;
                    end for;
                end if;
            end if;
        end if;

        if dhcp_si_upd then
            dhcp_si_upd.authoritative := void;
            packages := model.findPackages(host, ['dnsmasq']);
            for pkg in packages do
                if pkg.name = 'dnsmasq' then
                    dhcp_si_upd.version := pkg.version;
                    dhcp_si_upd.product_version := pkg.version;
                end if;
            end for;
        end if;
    end body;
end pattern;
