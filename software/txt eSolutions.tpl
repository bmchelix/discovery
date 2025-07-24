tpl 1.20 module ext.txt.e_solutions;

metadata
    origin := 'community';
    product_synonyms := 'TXT';
    publishers := 'TXT eSolutions';
    tree_path:= 'Software', 'Passive', 'TXT eSolutions';
end metadata;

pattern performserver 1.0
    """
        From IIS webapps, create SI for the backend txt servers.
        Traverse to any related loadbalancer services and add the listening ports to the SI
    VERSION CONTROL:
        21-06-2022 Initial draft
    """

    overview
        tags txt, performserver, cdmi;
    end overview;

    constants
        si_type := "Perform Server";
        si_vendor := "TXT eSolutions"; 
    end constants;

    triggers
        on trig := SoftwareComponent created, confirmed where type = 'Microsoft IIS Website' and instance matches 'PerformServer';
    end triggers;

    body
        region := none;
        full_version := none;
        major_version := none;
        minor_version := none;
        lbPorts := [];

        if trig.instance = 'PerformServer' or trig.instance = 'TXTPerformServer' then
            region := 'EMEA';
        elif trig.instance = 'TXTPerformServerUS' then
            region := 'AMER';
        elif trig.instance = 'TXTPerformServerAsia' then
            region := 'APAC';
        else
            log.debug("Unknown region, stopping...");
            stop;
        end if;

        iisSis := trig.#ContainedSoftware:SoftwareContainment:SoftwareContainer:SoftwareInstance;
        webapps := trig.#DependedUpon:Dependency:Dependant:SoftwareComponent;
        host := related.host(iisSis[0]);

        installed_package := (search (in host traverse Host:HostedSoftware:InstalledSoftware:Package where vendor = 'TXT e-solutions' and name matches 'TXTPERFORM'))[0];
        if installed_package then
            full_version := '%installed_package.version%';
            versions := text.split(full_version, ".");
            if versions then
                major_version := versions[0];
                minor_version := versions[1];
            end if;
        end if;
        
        si := model.SoftwareInstance(key := '%si_vendor%/%si_type%/%host.key%',
                                    type := '%si_vendor% %si_type%',
                                    name := '%si_vendor% %si_type% on %host.name%',
                                    version := full_version,
                                    product_version := major_version + "." + minor_version,
                                    database := '',
                                    backend := '',
                                    instance := ''
                                    );
        if si then
            model.addDisplayAttribute(si, [ 'database', 'backend', 'instance' ]);
            model.rel.HostedSoftware(RunningSoftware := si, Host := host);
            model.rel.Dependency(DependedUpon := iisSis, Dependant := si);

            region_detail := model.Detail(key		:= '%si.key%/%region%',
                                        type	:= 'TXT region',
                                        name	:= 'TXT region - ' + region,
                                        region	:= region
                                        );
            model.rel.Detail(ElementWithDetail := si, Detail := region_detail );
            model.rel.Dependency(DependedUpon := trig, Dependant := region_detail);
            model.rel.Dependency(DependedUpon := webapps, Dependant := region_detail);
            for webapp in webapps do
                if webapp.potential_rdbms_connection_strings then
                    for string in webapp.potential_rdbms_connection_strings do
                        dbString := regex.extract(string, regex '\\(\S*)', raw '\1');
                        if dbString then
                            si.database := dbString;
                            sqlSis := search (SoftwareInstance where type = 'Microsoft SQL Server' and instance = '%dbString%');
                            if sqlSis then
                                model.rel.Dependency(DependedUpon := sqlSis, Dependant := si);
                            end if;
                        end if;
                    end for;
                end if;
            end for;

            // backend servers
            lbAppSvcs := search ( in host traverse ServiceHost:SoftwareService:Service:LoadBalancerMember 
                                            traverse ContainedMember:Containment:Container:LoadBalancerPool 
                                            traverse ContainedPool:Containment:Container:LoadBalancerService where (port = 5500 or port = 5501 or port = 5502));
            if lbAppSvcs then
                lbAppSvc := lbAppSvcs[0];
                si.backend := lbAppSvc.dns_names[0];
                si.instance := lbAppSvc.dns_names[0];
                for lbAppSvc in lbAppSvcs do
                    lbPort := text.toNumber(lbAppSvc.port);
                    if lbPort not in lbPorts then
                        list.append(lbPorts, lbPort);
                    end if;
                end for;
                si.listening_ports := lbPorts;
            end if;
        end if;
    end body;
end pattern;

///////////////////////////////////////////////////////////////////////////////

pattern frontend 1.0
    """
        Trigger on RDS si, check for an installed packege node by TXT. Matches create a new SI for the Presentation Server.
        Traverse to any related loadbalancer services and add the listening ports to the SI

        VERSION CONTROL:
            21-06-2022 Initial draft
    """

    overview
        tags txt, webservers, cdmi;
    end overview;

    constants
        si_type := "Presentation Server";
        si_vendor := "TXT"; 
    end constants;

    triggers
        on trig := SoftwareInstance created, confirmed where type = 'Microsoft Remote Desktop Services' ;
    end triggers;

    body
        if not trig.#ServiceProvider:SoftwareService:Service:LoadBalancerMember then
            stop;
        end if;

        host := related.host(trig);
        full_version := none;
        major_version := none;
        minor_version := none;
        build := none;
        lbPorts := [];

        installed_packages := search (in host traverse Host:HostedSoftware:InstalledSoftware:Package where vendor = 'TXT e-solutions' and name matches 'Excel Add-In');
        if not installed_packages then
            stop;
        else
            installed_package := installed_packages[0];
            full_version := '%installed_package.version%';
            versions := text.split(full_version, ".");
            if versions then
                major_version := versions[0];
                minor_version := versions[1];
                build := versions[2];
            end if;
        end if;
        
        si := model.SoftwareInstance(key := '%si_vendor%/%si_type%/%host.key%',
                                    type := '%si_vendor% %si_type%',
                                    name := '%si_vendor% %si_type% on %host.name%',
                                    version := full_version,
                                    product_version := major_version + "." + minor_version,
                                    build := build,
                                    instance := '',
                                    environment := '',
                                    frontend := ''
                                    );
        if si then
            model.addDisplayAttribute(si, [ 'instance', 'environment', 'frontend' ]);
            model.rel.HostedSoftware(RunningSoftware := si, Host := host);

            // frontend servers
            lbUserSvcs := trig.#ServiceProvider:SoftwareService:Service:LoadBalancerMember.#ContainedMember:Containment:Container:LoadBalancerPool.#ContainedPool:Containment:Container:LoadBalancerService;
            if lbUserSvcs then
                lbUserSvc := lbUserSvcs[0];
                lbPort := text.toNumber(lbUserSvc.port);
                if lbPort not in lbPorts then
                    list.append(lbPorts, lbPort);
                end if;
                si.instance := lbUserSvc.dns_names[0];
                si.frontend := lbUserSvc.dns_names[0];
                if 'qa' in lbUserSvc.dns_names[0] or 'QA' in lbUserSvc.name then
                    si.environment := 'QA';
                elif 'dev' in lbUserSvc.dns_names[0] or 'DEV' in lbUserSvc.name then
                    si.environment := 'Development';
                else
                    si.environment := 'Production';
                end if;
                si.listening_ports := lbPorts;
            end if;
        end if;
    end body;
end pattern;

///////////////////////////////////////////////////////////////////////////////

