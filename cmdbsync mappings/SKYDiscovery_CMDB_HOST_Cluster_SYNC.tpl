tpl 1.19 module SKYDiscovery.CMDB.HOST_Cluster_SYNC;

from CMDB.Cluster import Cluster 3.0;



syncmapping HOST_CLUSTER_CMDB_SYNC 1.0
    """ Add one or more new attributes to the CI, based on attributes in the BMC Discovery all node.
    Department, ManufacturerName & VersionNumber """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from Cluster.cluster as cluster
        // No additional structure -- we are just modifying the
        // existing Product CI.
    end mapping;

    body
        cicluster:= Cluster.cluster_ci;
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