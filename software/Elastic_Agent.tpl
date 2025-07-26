tpl 1.19 module si.elastic.agent;

metadata
    origin := 'community';
    categories := 'Performance Management Software';
    publishers := 'Elastic';
    tree_path := 'community', 'Software', 'Passive', 'Elastic';
    last_update := '06 July 2021';
end metadata;

pattern Elastic_Agent 1.0
    """ Create Elastic Agent software instance and relate TKU created beat SIs. """


    metadata
        products       := 'Agent';
        urls           := 'https://www.elastic.co/docs/reference/fleet/';
    end metadata;

    overview
        tags Elastic, community;
    end overview;

     constants
        vendor := 'Elastic';
        sitype := 'Elastic Agent';
     end constants;

    triggers
        on node := DiscoveredProcess where cmd matches windows_cmd 'elastic-agent' or cmd matches unix_cmd 'elastic-agent';;
    end triggers;

    body
        host := related.host(node);       
        si_node := model.SoftwareInstance(key := sitype + '/%host.key%',
                        type := sitype,
                        name := sitype + ' on %host.name%',
                        short_name := sitype
                        );

        if si_node then
            beat_sis := search(in host traverse Host:HostedSoftware:RunningSoftware:SoftwareInstance where type has substring 'Elastic' and type has substring 'beat');
            if beat_sis then
                for beat_si in beat_sis do
                    model.setContainment(beat_si, si_node);
                end for;
            end if;
        end if;
    end body;
end pattern;

