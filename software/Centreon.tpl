tpl 1.19 module si.Centreon;

metadata
	origin := 'community';
	description := "Centreon system and network monitoring software";
    categories := 'Monitoring';
	publishers := 'Centreon';
    tree_path := 'community', 'Software', 'Passive', 'Centreon';
	last_update := '06 July 2021';
end metadata;

definitions defs 1.0
    """ Repeatable tasks """
    define modelSI(sitype, vendor, hostname, hostkey)
        """ Create SI """ model.SoftwareInstance(
                    key := vendor + sitype + '/%hostkey%',
                    type := vendor + ' ' + sitype,
                    name := vendor + ' ' + sitype + ' on %hostname%',
                    short_name := vendor + ' ' + sitype
        );
    end define;
end definitions;


pattern Centreon_Broker 1.0
    """ Build Centreon_Broker software instance """
    overview
        tags Centreon;
    end overview;

 	constants
        vendor := 'Centreon';    
		sitype := 'Broker';
 	end constants;

    triggers
        on node := DiscoveredProcess where cmd = '/usr/sbin/cbd' and args = '/etc/centreon-broker/central-broker.xml';
    end triggers;

    body
        host := related.host(node);
        defs.modelSI(sitype,vendor,'%host.name%','%host.key%');
    end body;
end pattern;

pattern Centreon_Core 1.0
    """ Build Centreon_Core software instance """

    overview
        tags Centreon;
    end overview;

 	constants
        vendor := 'Centreon';   
		sitype := 'Core';
 	end constants;

    triggers
        on node := DiscoveredProcess where cmd = '/usr/bin/perl' and args matches '(?i)(?:^|\\W|_)(logfile\\=\\/var\\/log\\/centreon\\/centcore\\.log)(?:$|\\W|_)' and args matches '(?i)(?:^|\\W|_)(usr\\/share\\/centreon\\/bin\\/centcore)(?:$|\\W|_)' and args matches '(?i)(?:^|\\W|_)(config\\=\\/etc\\/centreon\\/conf\\.pm)(?:$|\\W|_)';
    end triggers;

    body
        host := related.host(node);
        defs.modelSI(sitype,vendor,'%host.name%','%host.key%');
    end body;
end pattern;

pattern Centreon_Engine 1.0
    """ Build Centreon_Engine software instance """

    overview
        tags Centreon;
    end overview;

 	constants
        vendor := 'Centreon';   
		sitype := 'Monitoring';
 	end constants;

    triggers
        on node := DiscoveredProcess where cmd = '/usr/sbin/centengine' and args = '/etc/centreon-engine/centengine.cfg';
    end triggers;

    body
        host := related.host(node);
        defs.modelSI(sitype,vendor,'%host.name%','%host.key%');
    end body;
end pattern;
