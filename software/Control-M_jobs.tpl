// Copyright (c) 2025 BMC Software, Inc.
// All rights reserved.
//
// Custom TPL created by community and not BMC
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


// Models BMC Control-M (onprem) jobs and folders.
// 
// Usage steps
// 1) Import TPL
// 2) Add to outpost Control-M API Credentials
// 3) Add to outpost SSH/windows credentials for hosts running Control-M/Server, EM, and agents (if not already configured)
// 4) Run discovery scan against hosts running Control-M Server, EM, and agents. (TPLs only trigger if at least one EM and one server software instances are found and modeled)
// 5) Search for "Control-M Job". If any were discovered and modeled they'll be under "Deployment".
// 6) Open visualization for any job.
// 7) Change "Display" option to "All directly connected nodes->Directly Connected"
//
// Jobs (Deployments) will be connected to Collections: Folders, subfolders, applications, and subapplications.
//
// Jobs may also be connected to Control-M/Server and Agent responsible for it, if they have been discovered
//
// Jobs may also be connected to connection profiles, if the corresponding CIs have been discovered.
//
// See github below for additional resources:
// https://github.com/rulhoa/bmc-ctm-2-helix-integration
//

tpl 1.19 module ControlM_Apps;

metadata
    origin    := 'TKU';
    tkn_name  := 'Control-M';
    tree_path := 'System and Network Management Software', 'Workload Scheduling and Automation Software', 'BMC CONTROL-M';
end metadata;

from SearchFunctions    import SearchFunctions    1.5;
from ControlM_RH        import apiFunctions       1.0;
from DiscoveryFunctions import DiscoveryFunctions 1.31;

table CONNECTIONS_MAPPING 1.0
    'Tableau'      -> ['Tableau Server Application Manager', ''];
    'PostgreSQL'   -> ['PostgreSQL Database Server', '5432'];
    'MSSQL'        -> ['Microsoft SQL Server', '51486'];
    'Hadoop'       -> ['Apache Hadoop DataNode', ''];
    'DB2'          -> ['IBM DB2 Database Server', '50000'];
    'Oracle'       -> ['Oracle Database Server', ''];
    'Sybase'       -> ['Sybase ASE Database Server', '5000'];
    'PeopleSoft'   -> ['Oracle PeopleSoft Enterprise Pure Internet Architecture', ''];
    'SAP'          -> ['SAP Application Server', ''];
    'Jenkins'      -> ['Jenkins Continuous Integration Server', ''];
    'Kubernetes'   -> ['Kubernetes Cluster', ''];
    'FileTransfer' -> ['', '21'];
    'FTP'          -> ['', '21'];
    'SFTP'         -> ['', '22'];
    'WebServices'  -> ['', '80'];
    default        -> ['', ''];
end table;

table TARGET_TYPES 1.0
    'web_servers' -> ['Apache Webserver', 'IBM HTTP Server',
        'Oracle HTTP Server', 'HP Apache-based Web Server',
        'HP HP-UX Apache-based Web Server',
        'Red Hat JBoss Enterprise Web Server',
        'Apache HTTPD-based Webserver',
        'JBoss Core Services Apache HTTP Server',
        'Microsoft IIS Webserver', 'Nginx Webserver',
        'Apache Tomcat Application Server',
        'Oracle GlassFish Server Domain Administration Server',
        'Oracle GlassFish Server', 'Oracle WebLogic Server',
        'BEA WebLogic Application Server',
        'IBM WebSphere Application Server',
        'Red Hat JBoss Application Server', 'WildFly'];
    'ftp_servers' -> ['Microsoft IIS FTP Server',
        'BMC TrueSight Server Automation TFTP Server',
        'Attachmate Reflection for Secure IT (F-SECURE) SFTP Server',
        'SSH Tectia Server'];
    default -> [];
end table;

definitions ctmAppFunctions 1.0
    '''Control-M API Jobs functions'''
    type := function;

    define model_connection_profile(host, profiles_decoded, profiles, root, agents, servers) -> profiles
        '''
        '''
        if datatype(profiles_decoded) = 'table' then
            for cp_name in profiles_decoded do
                profile   := profiles_decoded[cp_name];
                full_type := table.get(profile, 'Type', '');
                if full_type and full_type matches regex '\:' then
                    split_type := text.split(full_type, ':');
                    count_split := size(split_type);
                    if count_split >= 3 then
                        cp_type     := split_type[1];
                        target_type := split_type[2];
                    elif count_split >= 2 then
                        cp_type     := split_type[1];
                        target_type := '';
                    else
                        continue;
                    end if;
                else
                    continue;
                end if;

                target_agent := table.get(profile, 'TargetAgent', '');
                port         := table.get(profile, 'Port',        '');
                cp_host      := table.get(profile, 'Host',        '');
                location     := table.get(profile, 'Location',    '');
                hostname     := table.get(profile, 'HostName',    '');
                k8s_url      := table.get(profile, 'Kubernetes Cluster URL', '');
                target_server := table.get(profile, 'TargetCTM',              '');

                attrs := table(
                    target_type     := target_type,
                    port            := port,
                    target_agent    := target_agent,
                    cp_host         := cp_host,
                    location        := location,
                    hostname        := hostname,
                    k8s_url         := k8s_url,
                    target_server   := target_server,
                    user            := table.get(profile, 'User',                      ''),
                    db_name         := table.get(profile, 'DatabaseName',              ''),
                    region          := table.get(profile, 'Region',                    ''),
                    app_id          := table.get(profile, 'ApplicationID',             ''),
                    subscription_id := table.get(profile, 'SubscriptionID',            ''),
                    domain_name     := table.get(profile, 'ActiveDirectoryDomainName', ''),
                    repository      := table.get(profile, 'Repository',                ''),
                    int_svc         := table.get(profile, 'IntegrationService',        ''),
                    security_domain := table.get(profile, 'SecurityDomain',            ''),
                    sid             := table.get(profile, 'SID',                       ''),
                    centralized     := table.get(profile, 'Centralized',               ''),
                    base_URL        := table.get(profile, 'BaseURL',                   ''),
                    description     := table.get(profile, 'Description',               ''),
                    driver          := table.get(profile, 'Driver',                    '')
                );
                display_attrs := DiscoveryFunctions.trimEmptyDisplayAttrs(attrs);

                type       := 'Control-M ' + cp_type + ' Connection Profile';
                name       := type + ' ' + cp_name;
                short_name := cp_type + ' Connection Profile ' + cp_name;
                key        := '%cp_name%/Control-M Connection Profile/%root.key%';
                // connection_profile_node:= model.AdminCollection(
                connection_profile_node:= model.Detail(
                    key             := key,
                    type            := type,
                    name            := name,
                    short_name      := short_name,
                    cp_host         := attrs.cp_host,
                    location        := attrs.location,
                    hostname        := attrs.hostname,
                    k8s_url         := attrs.k8s_url,
                    port            := attrs.port,
                    user            := attrs.user,
                    node_type       := attrs.node_type,
                    target_type     := attrs.target_type,
                    db_name         := attrs.db_name,
                    region          := attrs.region,
                    app_id          := attrs.app_id,
                    subscription_id := attrs.subscription_id,
                    target_server   := attrs.target_server,
                    target_agent    := attrs.target_agent,
                    domain_name     := attrs.domain_name,
                    repository      := attrs.repository,
                    int_svc         := attrs.int_svc,
                    security_domain := attrs.security_domain,
                    sid             := attrs.sid,
                    centralized     := attrs.centralized,
                    base_URL        := attrs.base_URL,
                    description     := attrs.description,
                    driver          := attrs.driver
                );
                model.setRemovalGroup(connection_profile_node, 'EM_API');
                profiles[key] := connection_profile_node;
                model.addDisplayAttribute(
                    connection_profile_node, display_attrs);

                // link to control-m server
                // model.rel.Collection(
                //     Collection := connection_profile_node,
                //     Member     := root);

                // link connection profile to control-m agent
                // if target_agent and target_agent in agents then
                //     model.rel.Collection(
                //         Collection := connection_profile_node,
                //         Member     := agents[target_agent]);
                // elif target_server and target_server in servers then
                //     model.rel.Collection(
                //         Collection := connection_profile_node,
                //         Member     := servers[target_server]);
                // end if;

                // link si, sc, db
                if hostname and not cp_host then
                    cp_host := hostname;
                end if;
                if location and not cp_host then
                    // "http://example.com/serverpolicy/Request.asmx?wsdl"
                    cp_host := regex.extract(location,
                        regex '(?:ht|f)tps?://(\S+?)[/\?]', raw '\1');
                end if;
                if k8s_url and not cp_host then
                    cp_host := regex.extract(k8s_url,
                        regex 'https?://(\S+)', raw '\1');
                end if;

                // search managed node
                if not cp_host or not target_type
                        or not target_type in CONNECTIONS_MAPPING
                        or not target_agent
                        or not target_agent in agents then
                    log.debug('not enough info for linking %cp_name%');
                    continue;
                end if;

                if not port then
                    port := CONNECTIONS_MAPPING[target_type][1];
                end if;

                if cp_type = 'Database' then
                    link_sis := SearchFunctions.getSoftwareNodes(
                        host,
                        port          := port,
                        software_type := CONNECTIONS_MAPPING[target_type][0],
                        node_address  := cp_host);
                elif target_type in ['FTP', 'SFTP', 'WebServices'] then
                    hosts, _ := SearchFunctions.getHostingNodes(host, cp_host);
                    if not hosts then
                        continue;
                    end if;
                    if target_type = 'WebServices' then
                        types := TARGET_TYPES['web_servers'];
                    else
                        types := TARGET_TYPES['ftp_servers'];
                    end if;
                    link_sis := search (in hosts
                        traverse Host:HostedSoftware::SoftwareInstance
                        where type in %types%);
                else
                    link_sis := SearchFunctions.getSoftwareNodes(
                        host,
                        node_address  := cp_host,
                        software_type := CONNECTIONS_MAPPING[target_type][0]);
                end if;

                if link_sis then // and size(link_sis) = 1 then
                    link_si := link_sis[0];

                    // link managed si, sc, db to connection profile, when it was collection
                    // model.rel.Collection(
                    //     Collection := connection_profile_node,
                    //     Member     := link_si);

                    // model.rel.Detail(ElementWithDetail := link_si,
                    //     Detail := connection_profile_node);

                    // link managed si, cs, db to agent
                    if target_agent and target_agent in agents then
                        // save agent for linking with job
                        target_agent_node      := agents[target_agent];
                        assign_agent           := key + '/AGENT';
                        profiles[assign_agent] := target_agent_node;
                        model.rel.Management(
                            Manager        := target_agent_node,
                            ManagedElement := link_si);
                    end if;
                end if;
            end for;
        end if;
        return profiles;
    end define;

    define get_app_node(details, app_name, subapp_name) -> subapp_node, details
        '''

        '''
        if app_name and subapp_name then
            server_key  := table.keys(details)[0];
            server_si   := details[server_key];
            app_type    := 'Control-M Application';
            app_key     := app_name + '/' + app_type + '/' + server_key;
            subapp_type := 'Control-M SubApplication';
            subapp_key  := subapp_name + '/' + subapp_type + '/' + app_key;

            if app_key in details then
                app_node := details[app_key];
            else
                app_node := model.Collection(
                    key :=  app_key,
                    type := app_type,
                    name := '%app_type% %app_name%');
                details[app_key] := app_node;
                model.rel.Collection(
                    Member := server_si, Collection := app_node);
            end if;

            if subapp_key in details then
                subapp_node := details[subapp_key];
            else
                subapp_node := model.Collection(
                    key  :=  subapp_key,
                    type := subapp_type,
                    name := '%subapp_type% %subapp_name%');
                details[subapp_key] := subapp_node;
                model.rel.Collection(
                    Member := subapp_node, Collection := app_node);
            end if;
            return subapp_node, details;
        else
            return none, details;
        end if;
    end define;

    define parse_jobs(details, root_key, jobs, profiles, hosts) -> details
        '''
            Models Jobs
        '''

        if not datatype(jobs) = 'list' then
            return details;
        end if;

        root       := details[root_key];
        server_key := table.keys(details)[0];

        for job in jobs do
            if not datatype(job) = 'table' then
                continue;
            end if;

            full_type := table.get(job, 'Type', '');
            if full_type and full_type matches regex '\:' then
                split_type := text.split(full_type, ':');
                if size(split_type) >= 1 then
                    job_type := split_type[1];
                else
                    continue;
                end if;
            else
                continue;
            end if;

            // model job
            name := table.get(job, 'Name', '');
            if not name then
                continue;
            end if;

            connection_profile := table.get(job, 'ConnectionProfile', '');
            hostgroup          := table.get(job, 'Host',              '');
            service            := table.get(job, 'ServiceName',       '');
            app                := table.get(job, 'Application',       '');
            subapp             := table.get(job, 'SubApplication',    '');

            attrs := table(
                connection_profile := connection_profile,
                hostgroup   := hostgroup,
                app         := app,
                subapp      := subapp,
                service     := service,
                createdby   := table.get(job, 'CreatedBy',   void),
                run_as      := table.get(job, 'RunAs',       void),
                command     := table.get(job, 'Command',     void), //Job:command
                filepath    := table.get(job, 'FilePath',    void), //Job:script
                filename    := table.get(job, 'FileName',    void), //Job:script
                script      := table.get(job, 'Script',      void), //Job:EmbeddedScript
                query       := table.get(job, 'Query',       void), //Job:Database:EmbeddedQuery
                preference  := table.get(job, 'Priority',    void),
                scheduler   := table.get(job, 'When',        void),
                description := table.get(job, 'Description', void)
            );
            display_attrs := DiscoveryFunctions.trimEmptyDisplayAttrs(attrs);

            type       := 'Control-M ' + job_type + ' Job';
            key        := name + '/' + type + '/' + root_key;
            name       := type + ' ' + name;
            short_name := 'Control-M ' + job_type + ' Job ' + name;
            deployment := model.Deployment(
                key                := key,
                name               := name,
                short_name         := short_name,
                type               := type,
                app                := attrs.app,
                subapp             := attrs.subapp,
                createdby          := attrs.createdby,
                run_as             := attrs.run_as,
                command            := attrs.command,
                filepath           := attrs.filepath,
                filename           := attrs.filename,
                script             := attrs.script,
                query              := attrs.query,
                preference         := attrs.preference,
                service            := attrs.service,
                scheduler          := attrs.scheduler,
                description        := attrs.description,
                connection_profile := attrs.connection_profile,
                hostgroup          := attrs.hostgroup
            );
            model.setRemovalGroup(deployment, 'EM_API');
            model.addDisplayAttribute(deployment, display_attrs);
            model.rel.Collection(Member := deployment, Collection := root);

            // add link to agent if it exists on the same host?

            details[key] := deployment;

            // Extract hostgroup info.
            if hostgroup then
                hostgroup_key := '%hostgroup%/Control-M Hostgroup/%server_key%';
                if hostgroup_key in profiles then
                    // Hostgroup detail should be already modeled
                    profile := profiles[hostgroup_key];
                    model.rel.Collection(
                        Member := profile , Collection := deployment);
                elif hostgroup in hosts then
                    // Find single remote host or agent host
                    member       := hosts[hostgroup];
                    member_agent := search(in member
                        traverse Host:HostedSoftware:RunningSoftware:SoftwareInstance
                        where type = 'Control-M/Agent Listener');
                    if member_agent then
                        member := member_agent;
                    end if;
                    model.rel.Collection(
                        Member := member , Collection := deployment);
                end if;
            end if;

            // Extract connection profiles info.
            if connection_profile then
                connection_profile_key := '%connection_profile%/' +
                    'Control-M Connection Profile/%server_key%';
                if connection_profile_key in profiles then
                    profile := profiles[connection_profile_key];
                    // link job to connection profile, requires taxonomy update
                    model.rel.Detail(
                        ElementWithDetail := deployment, Detail := profile);
                end if;
                // link agent, if assinged
                assign_agent := connection_profile_key + '/AGENT';
                if assign_agent in profiles then
                    assigned_agent := profiles[assign_agent];
                    model.rel.Collection(
                        Collection := deployment,
                        Member     := assigned_agent);
                end if;
            end if;

            // model service
            if service then
                server_key := table.keys(details)[0];
                server_si  := details[server_key];
                svc_key    := '%service%/Control-M Service/%server_key%';
                if not svc_key in details then
                    svc_node := model.Collection(
                        key        := svc_key,
                        type       := 'Control-M Service',
                        name       := 'Control-M Service %service%',
                        short_name := 'Service %service%');
                    model.setRemovalGroup(svc_node, 'EM_API');
                    details[svc_key] := svc_node;
                else
                    svc_node := details[svc_key];
                end if;

                // link to job
                model.rel.Collection(
                    Member := deployment, Collection := svc_node);

                // link to control-m server si
                model.rel.Collection(
                    Member := server_si,  Collection := svc_node);

            end if;

            // model app, subapp, link them to job
            subapp_node, details := ctmAppFunctions.get_app_node(
                details, app, subapp);
            if subapp_node then
                model.rel.Collection(
                    Member := deployment,  Collection := subapp_node);
            end if;
        end for;
        return details;
    end define;

    define parse_folder(includes, root_key, details, folder_name, folder,
            profiles, hosts) -> includes, details
        '''
            Extracts subfolders and jobs from folder. Models Folder
            Returns table with subfolders for for the next loop run and
            details table, which contails all modelled details.
        '''
        subfolders  := table();
        app         := void;
        subapp      := void;
        folder_type := table.get(folder, 'Type');

        if folder_type in ['Folder', 'SubFolder'] then
            for i in folder do
                if datatype(folder[i]) = 'table' then
                    // check if there are SubFolders
                    if table.get(folder[i], 'Type') = 'SubFolder' then
                        // Append SubFolders for the next run in the loop
                        subfolders[i] := folder[i];
                    end if;
                end if;
            end for;

            app    := table.get(folder, 'Application',    void);
            subapp := table.get(folder, 'SubApplication', void);
        end if;

        type       := 'Control-M ' + folder_type;
        name       := type + ' ' + folder_name;
        short_name := folder_type + ' ' + folder_name;
        folder_key := folder_name + '/Control-M Folder/' + root_key;
        root       := details[root_key];

        attrs := table(
            app    := app,
            subapp := subapp
        );
        display_attrs := DiscoveryFunctions.trimEmptyDisplayAttrs(attrs);

        folder_node := model.Collection(
            key        := folder_key,
            type       := type,
            name       := name,
            short_name := short_name,
            app        := attrs.app,
            subapp     := attrs.subapp);
        model.setRemovalGroup(folder_node, 'EM_API');
        model.addDisplayAttribute(folder_node, display_attrs);

        if model.kind(root) = 'SoftwareInstance' then
            model.rel.Collection(
                Member     := root,
                Collection := folder_node);
        elif model.kind(root) = 'Collection' then
            model.rel.Collection(
                Member     := folder_node,
                Collection := root);
        end if;

        details[folder_key]  := folder_node;
        includes[folder_key] := subfolders;

        // Extract list of jobs from the folder
        jobs := table.get(folder, 'Jobs', []);
        if jobs then
            details := ctmAppFunctions.parse_jobs(
                details, folder_key, jobs, profiles, hosts);
        end if;

        return includes, details;
    end define;
end definitions;

pattern ControlM_Apps 1.0
    '''
        Triggers on Control-M EM, exraxts jobs, models apps and services as
        details, links them to SIs and hosts, on which their jobs deppends.
    '''

    metadata
        publishers := 'BMC';
        products   := 'Control-M';
        categories := 'Workload Scheduling and Automation Software';
        urls       := 'https://www.bmc.com/it-solutions/control-m.html';
    end metadata;

    overview
        tags TKU, TKU_2024_00_00, restful, ControlM, Jobs;
    end overview;

    constants
        job_type         := 'Control-M Job';
        cp_type          := 'Control-M Connection Profile';
        hg_type          := 'Control-M Hostgroup';
        connection_types := ['Database', 'AWS', 'Azure', 'Hadoop', 'Backup',
            'Informatica', 'Airflow', 'FileTransfer', 'OEBS', 'PeopleSoft',
            'SAP', 'WebServices', 'Web Services REST', 'Web Services SOAP',
            'Tableau', 'Jenkins', 'Kubernetes'];
        // Full list of all possible, but that is too much to run in loop for each agent.
        // connection_types : ['ADF', 'AWS', 'AWS Athena', 'AWS Backup',
                // 'AWS Batch', 'AWS CloudFormation', 'AWS Data Pipeline',
                // 'AWS DynamoDB', 'AWS ECS', 'AWS EMR', 'AWS Glue',
                // 'AWS Glue DataBrew', 'AWS Lambda',
                // 'AWS Mainframe Modernization', 'AWS QuickSight', 'AWS SNS',
                // 'AWS Sagemaker', 'AWS Step Functions', 'AWSEC2', 'Airbyte',
                // 'Airflow', 'ApplicationIntegrator', 'Automation Anywhere',
                // 'Azure', 'Azure Backup', 'Azure Batch Accounts',
                // 'Azure Databricks', 'Azure DevOps', 'Azure HDInsight',
                // 'Azure Logic Apps', 'Azure Machine Learning',
                // 'Azure Resource Manager', 'Azure Synapse', 'Azure VM',
                // 'AzureFunctions', 'Boomi', 'DBT', 'Database', 'Databricks',
                // 'FileTransfer', 'GCP Batch', 'GCP BigQuery', 'GCP DataFlow',
                // 'GCP Dataplex', 'GCP Dataprep', 'GCP Dataproc',
                // 'GCP Deployment Manager', 'GCP Functions', 'GCP VM',
                // 'GCP Workflows', 'GCPDF', 'Hadoop', 'IP4-GROUP', 'Informatica',
                // 'Informatica CS', 'Jenkins', 'Kubernetes', 'Micro Focus Linux',
                // 'Micro Focus Windows', 'OCI VM', 'OEBS', 'PeopleSoft',
                // 'Power BI', 'Qlik Cloud', 'SAP', 'Snowflake', 'Snowflake IdP',
                // 'TRIFACTA', 'Tableau', 'Talend Data Management', 'Terraform',
                // 'UI Path', 'Web Services REST', 'Web Services SOAP',
                // 'WebServices'];
    end constants;

    triggers
        on em_si := SoftwareInstance created, confirmed
            where type = 'Control-M/Enterprise Manager Server';
    end triggers;

    body
        host             := model.host(em_si);
        servers          := table();
        servers_decoded  := apiFunctions.api_call(host,
            '/automation-api/config/servers');

        // Find Control-M Servers
        if servers_decoded then
            for server in servers_decoded do
                if server.name then
                    ctm_server_SI := SearchFunctions.getSoftwareNodes(host,
                        node_address  := server.name,
                        software_type :='Control-M/Server');
                    if ctm_server_SI and size(ctm_server_SI) = 1 then
                        servers[server.name] := ctm_server_SI[0];
                    elif server.host then
                        ctm_server_SI := SearchFunctions.getSoftwareNodes(host,
                            node_address  := server.host,
                            software_type :='Control-M/Server');
                        if ctm_server_SI and size(ctm_server_SI) = 1 then
                            servers[server.name] := ctm_server_SI[0];
                        else
                            // If the server was not found, it could be because
                            // we got the local FQDN from Control-M and
                            // getSoftwareNodes doesn't check that.
                            // We'll try removing the domain and rerun the
                            // search:
                            host_without_domain := regex.extract(server.host,
                                regex '^([^\.]+)', raw '\1'); // e.g. "myhost.bmc.com" -> "myhost"
                            ctm_server_SI := SearchFunctions.getSoftwareNodes(host,
                                node_address  := host_without_domain,
                                software_type :='Control-M/Server');
                            if ctm_server_SI and size(ctm_server_SI) = 1 then
                                servers[server.name] := ctm_server_SI[0];
                            end if;
                        end if;
                    end if;
                end if;
            end for;
        else
            log.info('Failed to run API call. Stopping');
            model.suppressRemovalGroup('EM_API');
            stop;
        end if;

        agents := table();
        for ctm_server_name in servers do
            folders := apiFunctions.api_call(host,
                '/automation-api/deploy/jobs?format=json&useArrayFormat=true' +
                '&server=%ctm_server_name%&folder=*');
            if not folders then
                continue;
            end if;

            root                    := servers[ctm_server_name];
            hosts                   := table();
            details                 := table();
            profiles                := table();
            remotehost_status       := table();
            details[root.key]       := root;
            folder_groups           := table();
            folder_groups[root.key] := folders;

            // Extract agent IDs
            agents_decoded := apiFunctions.api_call(host,
                '/automation-api/config/server/%ctm_server_name%/agents');
            if datatype(agents_decoded) = 'table' then
                if datatype(agents_decoded.agents) = 'list' then
                    for agent in agents_decoded.agents do
                        if agent.status and agent.nodeid then
                            agent_SI := SearchFunctions.getSoftwareNodes(host,
                                node_address  := agent.nodeid,
                                software_type :='Control-M/Agent Listener');
                            if agent_SI and size(agent_SI) = 1 then
                                agents[agent.nodeid] := agent_SI[0];
                                model.rel.Communication(
                                    Client := agent_SI[0], Server := root);
                            end if;
                            remotehost_status[agent.nodeid] := agent.status;
                        end if;
                        rm_hosts, node_type := SearchFunctions.getHostingNodes(
                            host, agent.nodeid);
                        if rm_hosts and node_type = 'Host' then
                            hosts[agent.nodeid] := rm_hosts[0];
                        end if;
                    end for;
                end if;
            end if;

            // model hostgroups
            hostgroups_agents_decoded := apiFunctions.api_call(host,
               '/automation-api/config/server/%ctm_server_name%/hostgroups/agents');

            if datatype(hostgroups_agents_decoded) = 'list' then
                for hostgroup in hostgroups_agents_decoded do
                    hg_name    := table.get(hostgroup, 'hostgroup',  '');
                    hg_members := table.get(hostgroup, 'agentslist', []);
                    if hg_name and hg_members
                            and datatype(hg_members) = 'list' then
                        online       := [];
                        offline      := [];
                        member_nodes := [];
                        for member in hg_members do
                            if datatype(member) = 'table' and 'host' in member then
                                member_id := member['host'];
                                member_node, _ := SearchFunctions.getHostingNodes(
                                    host, member_id);
                                if member_node then
                                    list.append(member_nodes, member_node[0]);
                                end if;
                                if member_id in remotehost_status then
                                    // Check status in remotehost_status table
                                    if remotehost_status[member_id] = 'Available' then
                                        list.append(online,  member_id);
                                    else
                                        list.append(offline, member_id);
                                    end if;
                                end if;
                            end if;
                        end for;
                        attrs := table(
                            hg_tag   := table.get(hostgroup, 'tag', void),
                            online   := online,
                            offline  := offline,
                            instance := hg_name);
                        display_attrs := DiscoveryFunctions.trimEmptyDisplayAttrs(attrs);

                        name    := hg_type + ' %hg_name%';
                        key     := '%hg_name%/%hg_type%/%root.key%';

                        hostgroup_node:= model.AdminCollection(
                            key      := key,
                            type     := hg_type,
                            name     := name,
                            instance := attrs.instance,
                            tag      := attrs.hg_tag,
                            online   := attrs.online,
                            offline  := attrs.offline);
                        model.setRemovalGroup(hostgroup_node, 'EM_API');
                        model.addDisplayAttribute(hostgroup_node, display_attrs);
                        model.rel.Collection(
                            Collection := hostgroup_node,
                            Member     := root);
                        if member_nodes then
                            model.rel.Collection(
                                Collection := hostgroup_node,
                                Member     := member_nodes);
                        end if;
                        profiles[key] := hostgroup_node;
                    end if;
                end for;
            end if;

            // Control-M API v 9.21.100

            // Get currently local deployed connection profiles according to the search query as JSON.
            // > /deploy/connectionprofiles
            // args: ctm, server, agent, type
            // all args are mandatory so we should do a loop through hughe number of types

            // Get currently local deployed connection profiles according to the search query as JSON.
            // > /deploy/connectionprofiles/local
            // args: ctm, server, agent, type
            // all args are mandatory so we should do a loop through hughe number of types

            // Get currently centralized deployed connection profiles according to the search query as JSON.
            // > /deploy/connectionprofiles/centralized
            // args: type *, name * - to extract all
            // looks useful, but on our env reports nothing

            // Get currently deployed connection profiles status according to the search query as JSON.
            // > /deploy/connectionprofiles/centralized/status
            // args:
            // limit - if missed get all
            // name - * to get all
            // type - * to get all
            // looks useful, but on our env reports nothing

            // model centralized connection profiles
            profiles_decoded := apiFunctions.api_call(host,
                '/automation-api/deploy/connectionprofiles/centralized' +
                '?type=*&name=*');
            profiles := ctmAppFunctions.model_connection_profile(
                host, profiles_decoded, profiles, root, agents, servers);

            // model local connection profiles
            for agent_id in agents do
                // agent_node := agents[agent_id];
                // if agent_node.control_modules then
                    // check if possible for extract correct name in agent
                    // pattern, instead of uppercase
                    // [' OS ', ' AI ', ' DATABASE ', ' AP ', ' AWS ', ' BACKUP ',
                    // ' AZURE ', ' ETL_INFA ', ' HADOOP ', ' TESTPLUGIN']
                // end if;
                for connection_type in connection_types do
                    profiles_decoded := apiFunctions.api_call(host,
                        '/automation-api/deploy/connectionprofiles?server=' +
                        '%ctm_server_name%&agent=%agent_id%&type=' +
                        '%connection_type%');

                    profiles := ctmAppFunctions.model_connection_profile(
                        host, profiles_decoded, profiles, root, agents, servers);
                end for;
            end for;

            // model folders, apps, services and jobs
            for _ in number.range(100) do // 100 included folders limit
                includes := table();
                for root_key in folder_groups do
                    folders  := folder_groups[root_key];
                    for folder_name in folders do
                        folder := folders[folder_name];
                        includes, details := ctmAppFunctions.parse_folder(
                            includes, root_key, details, folder_name, folder,
                            profiles, hosts);
                    end for;
                end for;
                folder_groups := includes;
            end for;
        end for;
    end body;
end pattern;

