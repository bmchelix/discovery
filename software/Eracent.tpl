tpl 1.19 module si.Eracent;

metadata
	origin := 'community';
	description := "Eracent EPA";
	//product_synonyms := '';
	publishers := 'Eracent';
    tree_path := 'Software', 'Active', 'Eracent Endpoint Analyzer';
	last_update := '05 May 2021';
end metadata;



pattern Eracent_End_Point_Analyzer 1.0
    """ Pattern to create an SI from discovered Eracent processes
	Triggers on running process and queryies WMI for version info

 	CHANGE HISTORY:
	 	01-06-2021 Initial draft
	"""

    metadata
        publishers := 'Eracent Corporation';
    end metadata;

    overview
        tags EPA, endpointanalyzer, eracent;
    end overview;

    triggers
        on node := DiscoveredProcess where cmd matches '(?i)\\bEracentEPAService\\.exe$' or args matches '(?i)\\bepa\\.sh -B';
    end triggers;

    body
        host := related.host(node);
		full_version := "";
		short_version := "";

		if host.os_type = "Windows" then
			log.debug("Triggered on Windows host. Attempting to get product version");
			path := text.replace(node.cmd, '\\', '\\\\');
			wmi_query := "SELECT Version FROM CIM_DataFile where Name='%path%'";
			wmi_results := discovery.wmiQuery(host, wmi_query, raw 'root\CIMV2');
			if wmi_results and wmi_results[0].Version then
				full_version := wmi_results[0].Version;
				short_version := regex.extract(full_version, regex '(^\d+\.\d+)', raw '\1');
				log.debug("Full Version: %full_version%");
				log.debug("Product Version: %short_version%");
			end if;
		end if;

        model.SoftwareInstance(	key := text.hash('Eracent End Point Analyzer' + '/%host.key%'),
								short_name := 'Eracent End Point Analyzer',
								name := 'Eracent End Point Analyzer' + ' on %host.name%',
								type := 'Eracent End Point Analyzer',
								version := full_version,
								product_version := short_version
								);
    end body;
end pattern;
