tpl 1.19 module ext.symantec.enterprisevault;

metadata
	origin := 'community';
    description := 'Symantec EnterpriseVault';
	publishers := 'Symantec';
    tree_path := 'Software', 'Active', 'Symantec', 'Enterprise Vault';
end metadata;

from SupportingFiles.RDBMS_Functions import rdbms_functions 1.18;

pattern ext_Symantec_Enterprise_Vault 1.0
	"""
		Extend TKU discovery to scrape the registry and find the DB and Server that Enterprise Vault is using to create a database detail rel"

		CHANGE HISTORY:
			01-06-2021 Initial draft
	"""
    overview
 		tags Messaging, Enterprise, Vault;
    end overview;

 	constants
 		type := "Enterprise Vault";
		ev_reg_key := raw 'HKEY_LOCAL_MACHINE\SOFTWARE\KVS\Enterprise Vault';
		ev_reg_databaseName := raw '\Directory\DirectoryService\databaseName';
		ev_reg_SQLServerName := raw '\Directory\DirectoryService\SQLServer Name';
		ev_reg_Exchange_Servers  := raw '\Admin\FindMailboxesSelectedServers';
 	end constants;

    triggers
 		on trig := SoftwareInstance created, confirmed where type matches regex '(?i)Symantec\s+Veritas\s+Enterprise\s+Vault';
    end triggers;

    body
		host := related.host(trig);
		log.debug("%type%: Running Pattern on %host.name%");

		//Scrape the Reg to find the Exchange Server(s) that Enterprise Vault is using for Archiving.
		ev_reg_key_result := discovery.registryKey(host, ev_reg_key + ev_reg_Exchange_Servers);

		if ev_reg_key_result then
			trig.ev_exchange_servers := ev_reg_key_result.value;
		end if;

		sc := model.SoftwareComponent(
			key         := text.hash('%host.key%/%type%/' + trig.type),
			type        := '%type% ' + trig.type,
			name        := '%type% ' + trig.type + ' on ' + host.name,
			is_required := true
			);

		model.addContainment(trig, sc);
		model.setRemovalGroup(sc, "removalgrp_%type%");

		//Scrape the Reg to find the DB Server and Name that Enterprise Vault is using.
		db_host := discovery.registryKey(host, ev_reg_key + ev_reg_SQLServerName);
		db_instance := discovery.registryKey(host, ev_reg_key + ev_reg_databaseName);
		db_name := discovery.registryKey(host, ev_reg_key + ev_reg_databaseName);
		db_type := "Microsoft SQL Server";

		if db_host and db_name then
			trig.db_type := db_type;
			trig.db_name := db_name.value;
			trig.db_server_name := db_host.value;
			//Search for the DB SI
			if db_host.value = "local" then
				db_host.value := "localhost";
			elif db_host.value matches regex '(?i)\\' then
				db_host.value := regex.extract(db_host.value, regex '\\(.*)', raw '\1');
			end if;

			db_sis := rdbms_functions.related_rdbms_sis_search(host, db_host.value, db_type, '' , '', db_name.value, table());
			if size(db_sis) = 1 then
				log.debug("db_si found");
				comm_rel := model.uniquerel.Communication(Client := trig, Server := db_sis, type := "Enterprise_Vault_DB_link");
				dbrel := model.rel.Dependency(DependedUpon := db_sis, Dependant := trig );
			end if;
		end if;
    end body;
end pattern;
