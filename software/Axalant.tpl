tpl 1.19 module si.Axalant;

metadata
	origin := 'community';
    categories := 'Engineering Applications';
	publishers := 'Axalant';
    tree_path := 'community', 'Software', 'Passive', 'Axalant';
	last_update := '06 July 2021';
end metadata;

definitions defs 1.0
    """ Repeatable tasks """
    define modelSI(sitype, vendor, hostname, hostkey)
        """ Create SI """ model.SoftwareInstance(key := vendor + sitype + '/%hostkey%',
                                type := vendor + ' ' + sitype,
                                name := vendor + ' ' + sitype + ' on %hostname%',
                                short_name := vendor + ' ' + sitype
                                );
    end define;
end definitions;

pattern Axalant_Core 1.0
    """ Build Axalant Core software instance """

    overview
        tags Axalant;
    end overview;

 	constants
        vendor := 'Axalant';
		sitype := 'Axalant Core';
 	end constants;

    triggers
        on node := DiscoveredProcess where cmd matches '(?i)(?:^|\\W|_)(bin\\/java)(?:$|\\W|_)' and args matches '(?i)(?:^|\\W|_)(server\\/axalant\\/ini)(?:$|\\W|_)';
    end triggers;

    body
        host := related.host(node);
        defs.modelSI(sitype,vendor,'%host.name%','%host.key%');
    end body;
end pattern;

pattern Axalant_Client 1.0
    """ Build Axalant (Client Session) software instance """

    overview
        tags Axalant;
    end overview;

 	constants
        vendor := 'Axalant';   
		sitype := 'Axalant Client';
 	end constants;

    triggers
        on node := DiscoveredProcess where cmd matches '(?i)(?:^|\\W|_)(axalant)(?:$|\\W|_)' and args matches '(?i)(?:^|\\W|_)(x\\:\\/app\\/plm)(?:$|\\W|_)';
    end triggers;

    body
        host := related.host(node);
        defs.modelSI(sitype,vendor,'%host.name%','%host.key%');
    end body;
end pattern;

