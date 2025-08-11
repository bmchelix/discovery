tpl 1.18 module SKYDiscovery.CMDB.CMDB_Document;

from CMDB.TLS_Detail_Document			    import TLS_Document_Detail 1.5;
from CMDB.Host_ComputerSystem               import Host_ComputerSystem 2.0;
//from CMDB.SoftwareInstance_SoftwareServer   import SoftwareInstance_SoftwareServer 4.0;
//from CMDB.LoadBalancerInstance              import LoadBalancerInstance 2.3;
//from CMDB.Host_ManagementController         import Host_ManagementController 2.4;

syncmapping Document_Augment 1.0
    """
    TLS Detail nodes under SoftwareInstances, LoadBalancerServices or ManagementController
    mapped to BMC_Document.
	Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    """
    overview
	tags CMDB, Extension;
    end overview;

    mapping from TLS_Document_Detail.detail as detail

    end mapping;

body
	hosting_ci := Host_ComputerSystem.computersystem or none;

        if hosting_ci = none then
        document_ci := TLS_Document_Detail.document;
         
        if document_ci then
            document_ci.Department := "SKYDISCOVERY";
        end if;
        stop;
        end if;

        //determined the hosting_ci as "hosting_ci".
        sysname := hosting_ci.Name;
        newname := sysname;
        if sysname has substring "." then
        // Modify the HostName to only include content up to the first dot
            newname := text.split(sysname, ".")[0];
        end if;

        document_ci := TLS_Document_Detail.document;
        ciname := document_ci.Name;
        document_ci.ParentName := sysname;
        document_ci.CustCIName := newname;
        document_ci.Name := "%newname%-%ciname%"; 
        document_ci.Department := "SKYDISCOVERY";

end body;

end syncmapping;
