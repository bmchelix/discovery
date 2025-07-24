tpl 1.20 module si.simplivity;

metadata
    origin := 'community';
    description := "Simplivity component discovery";
    known_versions := "3.0", "3.5","4.0","4.1";
    publishers := "Simplivity";
    product_synonyms := "OVC", "Simplivity", "OmniCube";
    urls := "https://www.simplivity.com/omnistack-technology/";
    tree_path:= 'Software', 'Active', 'Simplivity';
end metadata;

from Common_Functions import functions 1.41;

pattern arbiter_pattern 1.0
    """
        CHANGE HISTORY:
            11-10-2016 Initial draft

        Arbiter runs as a Windows service although the vendor has a habit of changing the display name.
        The cmdline executable is usually the same and has not been seen to change.
        Local port = 22122 is the inbound connection
        Trigger on the Service
            Look for a Package to pull in the version info
            Create an SI
        Relationships are made from the ovc SI. Nothing to do from the arbiter end.            
    """ 
    
    overview
        tags Simplivity;
    end overview;
 
    constants
        type := 'Simplivity Arbiter';
    end constants;
     
    triggers
        on trig := DiscoveredService created, confirmed where cmdline matches 'svtarb.exe';
    end triggers;
 
    body
        host := related.host(trig);
        server_si := "";
        major_version := "";
        minor_version := "";
        patch := "";
        build := "";
        
        simplivity_packages := search (in host traverse Host:HostedSoftware:InstalledSoftware:Package where name has subword 'Simplivity Arbiter');
        if simplivity_packages then
            for simplivity_package in simplivity_packages do
                full_version := '%simplivity_package.version%';
                versions := text.split(full_version, ".");
                if versions then
                    major_version := versions[0];
                    minor_version := versions[1];
                    patch := versions[2];
                    build := versions[3];
                else
                    major_version := "unknown";
                    minor_version := "";
                    patch := "";
                    build := "unknown";
                end if;
            end for;
        end if;

        server_si := model.SoftwareInstance(type := type,
                                            name := "%type% on %host.name%",
                                            key := '%type%/%host.key%',
                                            pid := trig.pid,
                                            version := major_version + "." + minor_version + "." + patch,
                                            product_version := major_version + "." + minor_version,
                                            build := build,
                                            _tw_meta_data_attrs := ["version","build","pid"]
                                            );
    end body;
end pattern;


pattern ovc_pattern 1.0
    """
        CHANGE HISTORY:
            13-10-2016 Matt Lambie	Initial draft, cloned from arbiter extended

        OmniStack Virtual Controller (OVC) runs on an Ubuntu vm which has a /usr/bin/java process running where args matches:
            -Xmx256m -XX:-UseLargePages -Dfelix.config.properties=file:/var/svtfs/0/myconf/static/felix-osgi-config.properties -Dresourcebalancerconfig=/var/svtfs/0/myconf/static/resourcebalancer.properties -jar /var/tmp/build/java/libs/org.apache.felix.main-5.0.1.jar -b /var/tmp/build/java/resourcebalancer /var/tmp/resourcebalancer-cache-0
        RunCommand:
            svt-federation-show --output xml | xmlstarlet sel -T -t -m /CommandResult/Node -s A:T:U "vmName" -v "concat (mgmtIf/ip,'|',arbiterAddress,'|',hostName,'|',swVersion/verName,'|',clusterName)" -n
        Each OVC is related to a "Simplivity Arbiter" (Windows Service)
        Each OVC manages an ESX
        Each OVC is related to a VC Cluster
    """ 

    overview
        tags Simplivity;
    end overview;
 
    constants
       type := 'OmniStack Virtual Controller';
    end constants;
     
    triggers
        on trig := DiscoveredProcess created,confirmed where cmd = '/usr/bin/java' and args matches '/var/svtfs';
    end triggers;
 
    body
        host := related.host(trig);
        server_si := "";
        major_version := "";
        minor_version := "";
        patch := "";
        build := "";
        arbiter_type := 'Simplivity Arbiter';
         
        log.debug("%type%: Running Pattern on %host.name%");		
        
        //Grab Federation information
        federation_query := '/var/tmp/build/cli/svt-federation-show --output xml | /usr/bin/xmlstarlet sel -T -t -m /CommandResult/Node -s A:T:U "vmName" -v "concat (mgmtIf/ip,\'|\',arbiterAddress,\'|\',hostName,\'|\',swVersion/verName,\'|\',clusterName)" -n';
        run_fed_query := discovery.runCommand(host, federation_query);
        if run_fed_query then
            ovc_list := regex.extractAll(run_fed_query.result, regex "(.+)\r");
            for ovc in ovc_list do
                if ovc <> "" then
                    linesplit := text.split(ovc, "|");
                    if linesplit then
                        mgmtIP := linesplit[0];
                        arbiterIP := linesplit[1];
                        esxhost := linesplit[2];
                        full_version := linesplit[3];
                        clusterName := linesplit[4];
                        
                        // Only run against the result for this host - check mgmtIP matches one on the local host
                        ip_search := search (in host where __all_ip_addrs matches %mgmtIP%);
                        if ip_search then
                            log.info("OVC: mgmtIP - %mgmtIP% on %host.name%");
                            // Grab version information
                            full_version := regex.extract(full_version, regex "^Release\W(\S+)", raw '\1');
                            versions := text.split(full_version, ".");
                            if versions then
                                major_version := versions[0];
                                minor_version := versions[1];
                                patch := versions[2];
                                build := versions[3];
                            else
                                major_version := "unknown";
                                minor_version := "";
                                patch := "";
                                build := "unknown";
                            end if;
    
                            // Create an SI
                            server_si := model.SoftwareInstance(type := type,
                                                                name := "%type% on %host.name%",
                                                                key := '%type%/%host.key%',
                                                                arbiter := arbiterIP,
                                                                arbitername := "",
                                                                build := build,
                                                                cluster := "",
                                                                ESXhost := "",
                                                                instance := "%host.name%",
                                                                version := major_version + "." + minor_version + "." + patch,
                                                                product_version := major_version + "." + minor_version,
                                                                _tw_meta_data_attrs := ["version","build","arbiter","arbitername","ESXhost","cluster"]
                                                                );							
                            if server_si then
                                // Relate to arbiter
                                arbiter_query := functions.identify_host_perform_search(host, arbiterIP);
                                if arbiter_query then
                                    arbiter_si := functions.related_sis_search(host, '%arbiter_query.name%', arbiter_type);
                                    if arbiter_si then
                                        arbiter_rel := model.rel.Dependency(DependedUpon := arbiter_si, Dependant := server_si);
                                        if arbiter_rel then
                                            server_si.arbitername := '%arbiter_query.name%';
                                        end if;
                                    end if;
                                end if;

                                // Relate to Cluster
                                cluster_query := search (Cluster where name matches '%clusterName%' and type = 'vCenter Cluster');
                                if cluster_query then
                                    cluster_rel := model.rel.SoftwareService(ServiceProvider := server_si, Service := cluster_query);
                                    if cluster_rel then
                                        server_si.cluster := '%clusterName%';
                                    end if;
                                end if;

                                // Relate to ESX
                                esx_query := functions.identify_host_perform_search(host, esxhost);
                                if esx_query then
                                    esx_rel := model.uniquerel.Management(ManagedElement:=esx_query, Manager:=server_si, type := "OVC");
                                    if esx_rel then
                                        server_si.ESXhost := '%esxhost%';
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end for;
        end if;			
    end body;
end pattern;


identify SimpliVity_Arbiter 1.0
    tags inference.simple_identity.Application._Simplivity._Arbiter;
    DiscoveredProcess cmd -> simple_identity;
        windows_cmd 'svtarb' -> 'Simplivity Arbiter Service';
end identify;

identify SimpliVity_OVC 1.0
    tags inference.simple_identity.Application._Simplivity._OVC;
    DiscoveredProcess cmd , args -> simple_identity;
        unix_cmd '/usr/bin/java', regex '/var/svtfs' -> 'Simplivity OmniStack Virtual Controller';
end identify;