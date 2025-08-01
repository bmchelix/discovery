tpl 1.19 module SKYDiscovery.CMDB.SW_Cluster_SYNC;

from CMDB.SoftwareCluster_Cluster import SoftwareCluster_Cluster 1.5;



syncmapping SW_CLUSTER_CMDB_SYNC 1.0

    """
    Override the default CTI values for certain BMC_OPERATINGSYSTEM CIs.
    """
    overview
        tags CMDB, Extension;
    end overview;

        mapping from SoftwareCluster_Cluster.softwarecluster as softwarecluster
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body

        cicluster:= SoftwareCluster_Cluster.cluster_ci;
        cicluster.Department := "SKYDISCOVERY";

        verchk := cicluster.VersionNumber or none;
        if verchk = "None" or verchk = none then
        cicluster.VersionNumber := "NoData";
        end if;

        mfgnchk := cicluster.ManufacturerName or none;
        if mfgnchk = "None" or mfgnchk = none then
              cicluster.ManufacturerName := "unknown manufacturer";
        end if;

        ssvn := cicluster.VersionNumber;
        ssdtype := datatype(ssvn);
        cinamestart := cicluster.Name;
        
        if ssdtype = 'list' then
        cicluster.VersionNumber := '';
        end if;


    end body;

end syncmapping;