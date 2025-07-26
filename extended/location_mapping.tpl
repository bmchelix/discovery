// Default based on Config block is to not model Location nodes
// Tables should be updated for given environment and Location names should exist & match with CMDB Sites before deploying to production.
// Config block is set to create based on ip & subnet by default, update tables and enable config block to use naming conventions.

tpl 1.20 module mskuLocations;

metadata
    origin := 'community';
    tkn_name := 'Helper Functions';
    tree_path := 'community', 'Common', 'Locations';
end metadata;

table subnet_location_region 1.0
 '192.168.8.0/24' -> 'Worthing','United Kingdom','EMEA','GBR';
 '192.168.255.0/24' -> 'Barcelona','Spain','EMEA','ESP';
 '172.20.0.0/16' -> 'unknown','Azure','Cloud',none; // eg Amsterdam WEurope
 default -> 'unknown', 'unknown', 'unknown', none;
end table;

table superscope_location 1.0
 '10.20.0.0/16' -> 'United Kingdom','GBR';
 '10.30.0.0/16' -> 'Spain','ESP';
 '10.40.0.0/16' -> 'Mexico','MEX';
 '172.20.0.0/16' -> 'Azure',none; // WEurope, Amsterdam
 '172.21.0.0/16' -> 'Azure',none;
 '172.21.0.0/18' -> 'Azure',none; // NEurope, Ireland
 '172.21.64.0/18' -> 'Azure',none; // NEurope, Ireland
 '172.25.0.0/16' -> 'AWS',none;
 '172.26.0.0/16' -> 'Azure',none;
 '172.26.0.0/18' -> 'Azure',none; // NEurope, Ireland
 '172.28.0.0/16' -> 'Azure',none;
 '172.28.0.0/18' -> 'Azure',none;
 default -> 'unknown',none;
end table;

table hostname_location 1.0
    'ARE' -> 'unknown', 'United States of America', 'EMEA';
    'AUS' -> 'unknown', 'Australia', 'AsiaPac';
    'BRA' -> 'unknown', 'Brazil', 'Americas';
    'CHN' -> 'unknown', 'China', 'AsiaPac';
    'ESP' -> 'unknown', 'Spain', 'EMEA';
    'GBR' -> 'unknown', 'United Kingdom', 'EMEA';
    'HKG' -> 'unknown', 'Hong Kong', 'AsiaPac';
    'JAP' -> 'unknown', 'Japan', 'AsiaPac';
    'KOR' -> 'unknown', 'South Korea', 'AsiaPac';
    'MEX' -> 'unknown', 'Mexico', 'Americas';
    'NLD' -> 'unknown', 'Netherlands', 'EMEA';
    'SGP' -> 'unknown', 'Singapore', 'AsiaPac';
    'TWN' -> 'unknown', 'Taiwan', 'AsiaPac';
    'UK'  -> 'unknown', 'United Kingdom', 'EMEA';
    'USA' -> 'unknown', 'USA', 'Americas';
    default -> 'unknown', 'unknown', 'unknown';
end table;

table ip_mask_to_decimal 1.0
	'max' -> 4294967295;
	'32' -> 4294967295;
	'31' -> 4294967294;
	'30' -> 4294967292;
	'29' -> 4294967288;
	'28' -> 4294967280;
	'27' -> 4294967264;
	'26' -> 4294967232;
	'25' -> 4294967168;
	'24' -> 4294967040;
	'23' -> 4294966784;
	'22' -> 4294966272;
	'21' -> 4294965248;
	'20' -> 4294963200;
	'19' -> 4294959104;
	'18' -> 4294950912;
	'17' -> 4294934528;
	'16' -> 4294901760;
	'15' -> 4294836224;
	'14' -> 4294705152;
	'13' -> 4294443008;
	'12' -> 4293918720;
	'11' -> 4292870144;
	'10' -> 4290772992;
	'9' -> 4286578688;
	'8' -> 4278190080;
	'7' -> 4261412864;
	'6' -> 4227858432;
	'5' -> 4160749568;
	'4' -> 4026531840;
	'3' -> 3758096384;
	'2' -> 3221225472;
	'1' -> 2147483648;
	default       -> '';
end table;

definitions ip_controls 1.0
    """ Functions to help calculate if IP Subnets are within a superscope """
    type := function;
    
    define calc_power_of(base, pow, value) -> int_power_of
        """returns the power of a given number"""
        arraypow := [pow];
        int_power_of := 0;
        if pow = 4 then
            int_power_of := value * base * base * base * base;
        elif pow = 3 then
            int_power_of := value * base * base * base;
        elif pow = 2 then
            int_power_of := value * base * base;
        elif pow = 1 then
            int_power_of := value * base;
        end if;       
        return int_power_of; 
    end define;
    
    define convert_ip_decimal(ip) -> uintIPAddress
        """Returns IP in Int format from Octet form"""

        digits := text.split(ip, '.');
        numeric_ip := 0;
        count := 3;
        for num in digits do
            numeric_ip := numeric_ip + (calc_power_of(256, count, text.toNumber(num)));
            count := count -1;
        end for;

        return numeric_ip;
    end define;

    define calc_start_finish(ip) -> NetStartEndDec
        """Returns IP in Int format from Octet form"""
        
        log.debug("Called Function: 'calc_start_finish' on '%ip%'");

        tmpip := text.split(ip, '/');       
        subnet := convert_ip_decimal(tmpip[0]);
        log.debug("SubnetStart on '%ip%': %subnet%");
        mask := ip_mask_to_decimal[tmpip[1]];
        log.debug("SubnetMask on '%ip%': %mask%");
        net_start := subnet & mask;
        log.debug("net_start: %net_start%");
        net_broadcast := subnet | ((~ mask) & 4294967295);
        log.debug("net_broadcast on '%ip%': %net_broadcast%");
        
        Network := table();
        Network.Start := net_start;
        Network.Broadcast := net_broadcast;
        return Network;
    end define;
end definitions;

configuration controls 1.0
    """ controls """
    'Model Locations'       modelLocations  := false;
    'Model Hostnames'       modelHostnames  := false;
    'Model Subnets'         modelSubnets    := true;
    'Model Cloud Regions'   modelCloud      := true;
    'Subnet Prefix'         cusPrefix       := [ '10.', '172.' ];
end configuration;

/////////////////////////////////////////////

pattern subnet_locations 1.0
    """ Create Location nodes based on subnets
        - Use Config block to limit candidate subnets to those within the given list of 1st octets
        - Using superscopes/netscopes in the lookup tables allows for trickle down population against Subnets although depends on discovering the superscopes/netscopes, often found on NetworkDevices or in Active Directory Site & Services
        - adds .site & .country to Subnet node
        - Creates parent/child locations for Region, Country & Site; ideally only Site should be mapped to nodes to protect from errors during cmdbsync

    Change History...
        2022-04-12   Initital Version
    """

    metadata
        categories := 'Location Management';
        additional_attributes := 'Locations';
    end metadata;

    overview
        tags location, subnet;
    end overview;

    constants
        type := 'Location Mapping';
    end constants;

    triggers
        on trig := Subnet created, confirmed where type = 'IPv4Subnet';
    end triggers;

    body
        octects := text.split('%trig.ip_address_range%', '.');
        prefix := octects[0] + '.';
        
        if prefix in controls.cusPrefix then
            if not controls.modelSubnets then
                trig.country := void;
                trig.site := void;
            else
                // Set attributes for the network start and end on the Subnet node
                // Cuts down on repeated processing during the disco run
                if (trig.networkstart = none) then
                    tmp_networkrange := table();
                    tmp_networkrange := ip_controls.calc_start_finish('%trig.ip_address_range%');
                    trig.networkstart := tmp_networkrange.Start;
                    trig.networkend := tmp_networkrange.Broadcast;
                end if;

                // Stop here if not set to model Locations
                if not controls.modelLocations then
                    stop;
                end if;

                // Create Location and map given subnet
                emptySubnets := search (in trig traverse Subnet:DeviceSubnet:DeviceOnSubnet:IPAddress);
                if not emptySubnets then
                    // no ips hanging off this subnet, stopping
                    stop;
                end if;

                objCountry := none;
                objLocation := none;
                objRegion := none;
                SubnetMapped := none;
                superscope_lookup := none;
                superscope_list := [];

                subnet_lookup := subnet_location_region['%trig.ip_address_range%'];
                if subnet_lookup then
                    subn_location := subnet_lookup[0];
                    subn_country  := subnet_lookup[1];
                    subn_region   := subnet_lookup[2];
                    subn_code     := subnet_lookup[3];

                    if (text.lower(subn_region) <> 'unknown') then
                        regionkey := text.hash('%subn_region%/REGION');
                        objRegion := model.Location(
                                                    key  := regionkey,
                                                    name := '%subn_region%',
                                                    description := 'Global region derived from static lookup',
                                                    type := 'Major'
                                                    );
                    end if;

                    if (text.lower(subn_country) <> 'unknown') then
                        countrykey := text.hash('%subn_country%/COUNTRY');
                        objCountry := model.Location(
                                                    key  := countrykey,
                                                    name := '%subn_country%',
                                                    description := 'Global location derived from static lookup',
                                                    abbreviation := '%subn_code%',
                                                    type := 'Major'
                                                    );
                    end if;

                    if (text.lower(subn_location) <> 'unknown') then
                        objLocation := model.Location(
                                                    key  := text.hash('%subn_location%/SITE'),
                                                    name := '%subn_location%',
                                                    description := 'Location derived from static lookup',
                                                    abbreviation := '%subn_code%',
                                                    type := 'Minor'
                                                    );
                        SubnetMapped := true;
                    end if;

                    if objRegion and objCountry then
                        model.rel.LocationContainment(LocationContainer := objRegion, ContainedLocation := objCountry);
                    end if;

                    if objCountry and objLocation then
                        model.rel.LocationContainment(LocationContainer := objCountry, ContainedLocation := objLocation);
                    end if;
                    
                    if objLocation then
                        model.uniquerel.Location(ElementInLocation := trig, Location := objLocation);
                    // elif objCountry and not objLocation then
                    //     model.rel.Location(ElementInLocation := trig, Location := objCountry);
                    end if;
                end if;

                // If no match to location table then check within any other superscope subnet for a Location relationship                
                if not SubnetMapped and not trig.networkstart = none then
                    // Existing
                    lowerSubnets := search (Subnet where type = 'IPv4Subnet' and not ip_address_range = '%trig.ip_address_range%' and (networkstart <= %trig.networkstart% and networkend >= %trig.networkend%) );
                    if lowerSubnets then
                        for lowerSubnet in lowerSubnets do
                            log.debug('%trig.ip_address_range%: Found an existing lower subnet class we can use - %lowerSubnet.ip_address_range%');
                            lowerLocations := search ( in lowerSubnet traverse ElementInLocation:Location:Location:Location);
                            if lowerLocations then
                                model.rel.Location(ElementInLocation := trig, Location := lowerLocations);
                                model.rel.Collection(Collection := lowerSubnet, Member := trig);
                            end if;
                        end for;
                    end if;
                end if;
            end if;
        end if;

    end body;
end pattern;

/////////////////////////////////////////////

pattern cloud_locations 1.0
    """ Pattern to add Locations based on cloud regions

    Change History...
        2024-04-02   Initital Version
    """

    metadata
        categories := 'Location Management';
        additional_attributes := 'Locations';
    end metadata;

    overview
        tags location, cloud;
    end overview;

    constants
        type := 'Location Mapping';
    end constants;

    triggers
        on trig := CloudRegion created, confirmed where location defined;
    end triggers;

    body
        // Stop here if not set to model Locations
        if not controls.modelLocations then
            stop;
        end if;

        // check for VMs
        hosting_vm := search (in trig traverse ServiceProvider:CloudService:Service:CloudService traverse Host:HostedSoftware:RunningSoftware:VirtualMachine);
        if not hosting_vm then
            log.debug('No virtual machines under this region, stopping');
            stop;
        end if;
        
        objCountry := none;
        objLocation := none;
        nodeCountry := none;
        nodeLocation := none;

        loca := text.split(trig.location, ',');
        if size(loca) = 2 then
            log.debug('Found country and location');
            objCountry := loca[1];
            objLocation := loca[0];
        else
            log.debug('Found only location');
            objCountry := trig.location;
        end if;

        if objCountry then
            countrykey := text.hash('%objCountry%/COUNTRY');
            nodeCountry := model.Location(
                                        key             := countrykey,
                                        name            := '%objCountry%',
                                        description     := 'Global location derived from cloud region',
                                        abbreviation    := '%objCountry%',
                                        type            := 'Major',
                                        cloud           := true
                                        );
        end if;

        if objLocation then
            nodeLocation := model.Location(
                                        key             := text.hash('%objLocation%/SITE'),
                                        name            := '%objLocation%',
                                        description     := 'Location derived from cloud region',
                                        abbreviation    := '%objLocation%',
                                        type            := 'Minor',
                                        cloud           := true
                                        );
            model.uniquerel.Location(ElementInLocation := trig, Location := nodeLocation);

            if nodeCountry and nodeLocation then
                model.rel.LocationContainment(LocationContainer := nodeCountry, ContainedLocation := nodeLocation);
            end if;
        end if;

    end body;
end pattern;

/////////////////////////////////////////////

pattern locations_set_cloud 1.0
    """ Add .cloud to cloud locations.

    Change History...
        2022-04-12   Initital Version
    """

    metadata
        categories := 'Location Management';
        additional_attributes := 'Locations';
    end metadata;

    overview
        tags location, subnet;
    end overview;

    constants
        type := 'Location Mapping';
    end constants;

    triggers
        on trig := Location created, confirmed where type = 'Country' and (name = 'Azure' or name = 'AWS');
    end triggers;

    body
        trig.cloud := true;
        childsites := search (in trig traverse LocationContainer:LocationContainment:ContainedLocation:Location);
        for childsite in childsites do
            childsite.cloud := true;
        end for;
    end body;
end pattern;

/////////////////////////////////////////////

pattern map_ip_host 0.1
    """
        CHANGE HISTORY:
        2021-05-25 Initial draft

        Use only the last "scanned by" address to reduce processing and to avoid flipflopping Location relationships
    """
    overview
        tags location;
    end overview;

    constants
        type := 'Host Location Mapping';
    end constants;

    triggers
        on trig := Host created, confirmed;
    end triggers;

    body
        LocationMapped := false;
        da := none;

        das := search (in trig traverse InferredElement:Inference:Associate:DiscoveryAccess where _last_marker);
        if size(das) = 0 then
            log.debug('NO DA, stopping: %trig.name%');
            stop;
        else
            da := das[0];
        end if;

        // Usually no IP address node found for vCenter appliances so lets use the discoveryacess endpoint ip
        if trig.os_type = 'VMware vCenter Appliance' then
            octects := text.split('%da.endpoint%', '.');
            classC := octects[0] + '.' + octects[1] + octects[2] +'.0/24';
            classC_locations := search (Subnet where ip_address_range = '%classC%' traverse ElementInLocation:Location:Location:Location);
            if classC_locations then
                for classC_location in classC_locations do
                    set_location := model.uniquerel.Location(ElementInLocation := trig, Location := classC_location);
                    LocationMapped := true;
                end for;
            end if;
        else
            // Grab all IPs on the device
            all_ips := search (in trig traverse DeviceWithAddress:DeviceAddress:IPv4Address:IPAddress);
            for ip in all_ips do
                // Only run on the IP that Discovery scanned on
                if (ip.ip_addr = da.endpoint) then
                    // Find the subnet
                    locations := search (in ip traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                                traverse ElementInLocation:Location:Location:Location);
                    if size(locations) = 1 then
                        for location in locations do
                            set_location := model.uniquerel.Location(ElementInLocation := trig, Location := location);
                            LocationMapped := true;
                        end for;
                    end if;
                // Check if using a NAT to scan and therefore da.endpoint will not be in the device.ip_addr
                elif size(all_ips) = 1 and (ip.ip_addr <> da.endpoint) then
                    locations := search (in ip traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                                traverse ElementInLocation:Location:Location:Location);
                    if size(locations) = 1 then
                        for location in locations do
                            set_location := model.uniquerel.Location(ElementInLocation := trig, Location := location);
                            LocationMapped := true;
                        end for;
                    end if;
                end if;
            end for;
        end if;

        if LocationMapped = false then
            if trig.cloud then
                // Use cloud regions to create Locations
                cloudHost_regions := search (in trig traverse ContainedHost:HostContainment:HostContainer:VirtualMachine 
                                            traverse RunningSoftware:HostedSoftware:Host:CloudService
                                            traverse Service:CloudService:ServiceProvider:CloudRegion
                                            traverse ElementInLocation:Location:Location:Location);
                if cloudHost_regions then
                    for cloudHost_region in cloudHost_regions do
                        set_location := model.uniquerel.Location(ElementInLocation := trig, Location := cloudHost_region);
                        LocationMapped := true;
                    end for;
                end if;
            elif trig.virtual then
                // Hosts of virtual machines eg ESX
                vmHost_locations := search (in trig traverse ContainedHost:HostContainment:HostContainer:VirtualMachine 
                                            traverse RunningSoftware:HostedSoftware:Host:Host
                                            traverse ElementInLocation:Location:Location:Location);
                if vmHost_locations then
                    for vmHost_location in vmHost_locations do
                        set_location := model.uniquerel.Location(ElementInLocation := trig, Location := vmHost_location);
                        LocationMapped := true;
                    end for;
                end if;
            // Usually no IP address node found for vCenter appliances so lets use the discoveryacess endpoint ip
            elif not trig.os_type = 'VMware vCenter Appliance' then
                octects := text.split('%da.endpoint%', '.');
                classC := octects[0] + '.' + octects[1] + octects[2] +'.0/24';
                classC_locations := search (Subnet where ip_address_range = '%classC%' traverse ElementInLocation:Location:Location:Location);
                if classC_locations then
                    for classC_location in classC_locations do
                        set_location := model.uniquerel.Location(ElementInLocation := trig, Location := classC_location);
                        LocationMapped := true;
                    end for;
                end if;
            end if;
        end if;

        if not LocationMapped = true then
            log.debug('%trig.name%: No location mapped');
        end if;
    end body;
end pattern;

/////////////////////////////////////////////

pattern map_ip_network 0.1
    """
        CHANGE HISTORY:
        2021-05-25   Initial draft

        Use only the last "scanned by" address to reduce processing and to avoid flipflopping Location relationships
    """
    overview
        tags location;
    end overview;

    constants
        type := 'NetworkDevice Location Mapping';
    end constants;

    triggers
        on trig := NetworkDevice created, confirmed;
    end triggers;

    body
        objCountry := none;
        objLocation := none;
        locations := none;
        LocationMapped := false;
        da := none;

        if trig.type = 'Device in Stack' then
            locations := search ( in trig traverse StackMember:DeviceStack:Stack:NetworkDevice traverse ElementInLocation:Location:Location:Location);
        elif trig.type = 'Access Point' then
            locations := search (in trig traverse DeviceWithAddress:DeviceAddress:IPv4Address:IPAddress
                                            traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                            traverse ElementInLocation:Location:Location:Location);
        else
            // das := search(in trig traverse InferredElement:Inference:Associate:DiscoveryAccess);
            das := search (in trig traverse InferredElement:Inference:Associate:DiscoveryAccess where _last_marker);
            if size(das) = 0 then
                log.debug('NO DA, stopping: %trig.name%');
                stop;
            else
                da := das[0];
                // Grab all IPs on the device
                all_ips := search (in trig traverse DeviceWithAddress:DeviceAddress:IPv4Address:IPAddress);
                for ip in all_ips do
                    // Only run on the IP that Discovery scanned on
                    if (ip.ip_addr = da.endpoint) then
                        // Find the subnet
                        locations := search (in ip traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                                    traverse ElementInLocation:Location:Location:Location);
                    // Check if using a NAT to scan and therefore da.endpoint will not be in the device.ip_addr
                    elif size(all_ips) = 1 and (ip.ip_addr <> da.endpoint) then
                        locations := search (in ip traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                                    traverse ElementInLocation:Location:Location:Location);
                    end if;
                end for;
            end if;
        end if;

        if locations then
            for location in locations do
                set_location := model.uniquerel.Location(ElementInLocation := trig, Location := location);
                LocationMapped := true;
            end for;
        end if;

        if not LocationMapped = true then
            log.debug('%trig.name%: No location mapped');
        end if;
    end body;
end pattern;

/////////////////////////////////////////////

pattern map_ip_printer 0.1
    """
        CHANGE HISTORY:
        2021-05-25   Initial draft

        Use only the last "scanned by" address

    """
    overview
        tags location;
    end overview;

    constants
        type := 'Printer Location Mapping';
    end constants;

    triggers
        on trig := Printer created, confirmed;
    end triggers;

    body

        LocationMapped := false;
        da := none;

        das := search (in trig traverse InferredElement:Inference:Associate:DiscoveryAccess where _last_marker);
        if size(das) = 0 then
            log.debug('NO DA, stopping: %trig.name%');
            stop;
        else
            da := das[0];
        end if;

        // for da in das do
            // Grab all IPs on the device
            all_ips := search (in trig traverse DeviceWithAddress:DeviceAddress:IPv4Address:IPAddress);
            for ip in all_ips do
                // Only run on the IP that Discovery scanned on
                if (ip.ip_addr = da.endpoint) then
                    // Find the subnet
                    locations := search (in ip traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                                traverse ElementInLocation:Location:Location:Location);
                    if locations then
                        for location in locations do
                            if location.type = 'Site' then
                                set_location := model.uniquerel.Location(ElementInLocation := trig, Location := location);
                                LocationMapped := true;
                            end if;
                        end for;
                    end if;
                // Check if using a NAT to scan and therefore da.endpoint will not be in the device.ip_addr
                elif size(all_ips) = 1 and (ip.ip_addr <> da.endpoint) then
                    locations := search (in ip traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                                traverse ElementInLocation:Location:Location:Location);
                    if locations then
                        for location in locations do
                            set_location := model.uniquerel.Location(ElementInLocation := trig, Location := location);
                            LocationMapped := true;
                        end for;
                    end if;
                end if;
            end for;
        // end for;

        if not LocationMapped = true then
            log.debug('%trig.name%: No location mapped');
        end if;
    end body;
end pattern;

/////////////////////////////////////////////

pattern map_ip_storage 1.1
    """ """
    overview
        tags Location;
    end overview;

    constants
        type := 'Storage Location Mapping';
    end constants;

    triggers
        on trig := StorageDevice created, confirmed;
    end triggers;

    body
        locations := none;
        da := none;

        das := search (in trig traverse InferredElement:Inference:Associate:DiscoveryAccess where _last_marker);
        if size(das) = 0 then
            log.debug('NO DA, stopping: %trig.name%');
            stop;
        else
            da := das[0];
        end if;

        // Grab all IPs on the storagesystem (assuming the storagesystems are all in the same location as the storagedevice!)
        all_ips := search (in trig traverse Manager:Management:ManagedElement:StorageSystem traverse DeviceWithAddress:DeviceAddress:IPv4Address:IPAddress);
        for ip in all_ips do
            // Only run on the IP that Discovery scanned on
            if (ip.ip_addr = da.endpoint) or (size(all_ips) = 1 and (ip.ip_addr <> da.endpoint)) then
                // Find the subnet
                locations := search (in ip traverse DeviceOnSubnet:DeviceSubnet:Subnet:Subnet where type = 'IPv4Subnet'
                                            traverse ElementInLocation:Location:Location:Location);
            end if;
        end for;

        if locations then
            for location in locations do
                set_location := model.uniquerel.Location(ElementInLocation := trig, Location := location);
                subsystems := search (in trig traverse Manager:Management:ManagedElement:StorageSystem);
                for subsystem in subsystems do
                    set_location_subsystem := model.uniquerel.Location(ElementInLocation := subsystem, Location := location);
                end for;
            end for;
        end if;

    end body;
end pattern;

/////////////////////////////////////////////

pattern map_ip_hostcontainer 1.0
    """ """
    overview
        tags Location;
    end overview;

    constants
        type := 'HostContainer Location Mapping';
    end constants;

    triggers
        on trig := HostContainer created, confirmed;
    end triggers;

    body
        // Check if there is a location on the Hosts that make up this HostContainer
        locations := search (in trig traverse HostContainer:HostContainment:ContainedHost:Host traverse ElementInLocation:Location:Location:Location);
        for location in locations do
            set_location := model.uniquerel.Location(ElementInLocation := trig, Location := location);
        end for;
    end body;
end pattern;

/////////////////////////////////////////////

pattern map_name_host 1.0
    """
    Map location based on hostname

    Change History...
    2022-04-12   Initital Version
    """

    metadata
        categories := 'Location Management';
        additional_attributes := 'Locations';
    end metadata;

    overview
        tags location;
    end overview;

    constants
        type := 'Location Mapping';
    end constants;

    triggers
        on trig := Host created, confirmed;
    end triggers;

    body
        if controls.modelHostnames then
            objCountry := none;
            objLocation := none;
            location_lookup := none;


            lookup_regex := regex.extract(trig.name, regex '^(\w{2}\w{3})', raw '\1');
            if lookup_regex then
                location_lookup := hostname_location['%lookup_regex%'];
                if location_lookup[1] = 'unknown' then
                    lookup_regex := regex.extract(trig.name, regex '^(\w{2})', raw '\1');
                    if lookup_regex then
                        location_lookup := hostname_location['%lookup_regex%'];
                    end if;
                end if;
            else
                lookup_regex := regex.extract(trig.name, regex '^(\w{2})', raw '\1');
                if lookup_regex then
                    location_lookup := hostname_location['%lookup_regex%'];
                end if;
            end if;

            if location_lookup and location_lookup[1] <> 'unknown' then
                dev_location := location_lookup[0];
                dev_country  := location_lookup[1];
                if (text.lower(dev_country) <> 'unknown') then
                    log.debug('%type%: Country is: %dev_country%');
                    if not controls.modelLocations then
                        trig.country := dev_country;
                    else
                        objCountry := model.Location(key  := text.hash('%dev_country%'),
                                                    name := '%dev_country%',
                                                    description := 'Global location derived from static lookup',
                                                    abbreviation := '%dev_country%'
                                                    );
                    end if;
                end if;

                if (text.lower(dev_location) <> 'unknown') then
                    log.debug('%type%: Location is: %dev_location%');
                    if not controls.modelLocations then
                        trig.site := dev_location;
                    else
                        objLocation := model.Location(key  := text.hash('%dev_location%'),
                                                    name := '%dev_location%',
                                                    description := 'Location derived from static lookup',
                                                    abbreviation := '%dev_location%'
                                                    );
                    end if;
                elif dev_location then
                    sitecode := regex.extract(trig.name, regex '^\w{2}(\w{3})', raw '\1');
                    if sitecode then
                        trig.site := sitecode;
                    end if;
                end if;

                if objCountry and objLocation then
                    model.rel.LocationContainment(LocationContainer := objCountry, ContainedLocation := objLocation);
                end if;
                            
                if objLocation then
                    model.uniquerel.Location(ElementInLocation := trig, Location := objLocation);
                // elif objCountry and not objLocation then
                //     model.rel.Location(ElementInLocation := trig, Location := objCountry);
                end if;
            end if;
        end if;
    end body;
end pattern;

/////////////////////////////////////////////

pattern map_name_network 1.0
    """
    Map location based on sysname

    Change History...
    2022-04-12   Initital Version
    """

    metadata
        categories := 'Location Management';
        additional_attributes := 'Locations';
    end metadata;

    overview
        tags location;
    end overview;

    constants
        type := 'Location Mapping';
    end constants;

    triggers
        on trig := NetworkDevice created, confirmed;
    end triggers;

    body
        if controls.modelHostnames then
            objCountry := none;
            objLocation := none;
            location_lookup := none;

            lookup_regex := regex.extract(trig.name, regex '^(\w{3}\d{4})', raw '\1');
            if lookup_regex then
                location_lookup := hostname_location['%lookup_regex%'];
                if location_lookup[1] = 'unknown' then
                    lookup_regex := regex.extract(trig.name, regex '^(\w{3})', raw '\1');
                    if lookup_regex then
                    location_lookup := hostname_location['%lookup_regex%'];
                    end if;
                end if;
            else
                lookup_regex := regex.extract(trig.name, regex '^(\w{3})', raw '\1');
                if lookup_regex then
                    location_lookup := hostname_location['%lookup_regex%'];
                end if;
            end if;

            if location_lookup and location_lookup[1] <> 'unknown' then
                dev_location := location_lookup[0];
                dev_country  := location_lookup[1];
                if (text.lower(dev_country) <> 'unknown') then
                    log.debug('%type%: Country is: %dev_country%');
                    if not controls.modelLocations then
                        trig.country := dev_country;
                    else
                        objCountry := model.Location(key  := text.hash('%dev_country%'),
                                                    name := '%dev_country%',
                                                    description := 'Global location derived from static lookup',
                                                    abbreviation := '%dev_country%'
                                                    );
                    end if;
                end if;

                if (text.lower(dev_location) <> 'unknown') then
                    log.debug('%type%: Location is: %dev_location%');
                    if not controls.modelLocations then
                        trig.site := dev_location;
                    else
                        objLocation := model.Location(key  := text.hash('%dev_location%'),
                                                    name := '%dev_location%',
                                                    description := 'Location derived from static lookup',
                                                    abbreviation := '%dev_location%'
                                                    );
                    end if;
                elif dev_location then
                    sitecode := regex.extract(trig.name, regex '^\w{3}(\d{4})', raw '\1');
                    if sitecode then
                        trig.site := sitecode;
                    end if;
                end if;

                if objCountry and objLocation then
                    model.rel.LocationContainment(LocationContainer := objCountry, ContainedLocation := objLocation);
                end if;
                            
                if objLocation then
                    model.uniquerel.Location(ElementInLocation := trig, Location := objLocation);
                // elif objCountry and not objLocation then
                //     model.rel.Location(ElementInLocation := trig, Location := objCountry);
                end if;
            end if;
        end if;
    end body;
end pattern;
