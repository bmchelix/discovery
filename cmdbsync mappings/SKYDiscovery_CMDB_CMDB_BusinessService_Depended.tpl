tpl 1.18 module SKYDiscovery.CMDB.CMDB_BusinessService_Depended;
 
from CMDB.Depended_Services import Depended_Services 2.1;
 
syncmapping BusinessService_Depended_Augment 1.0
"""
    update the manufacturer of businessservices on Depended nodes
    """
    overview
        tags CMDB, Extension;
    end overview;
 
    mapping from Depended_Services.source_node
            as source_node

    end mapping;
 
body

    depended_node := Depended_Services.depended_node or none;

        if depended_node = none then
            stop;
        end if;

depended_kind := model.kind(depended_node);

if depended_kind = "BusinessService" or depended_kind = "BusinessApplicationInstance" or depended_kind = "TechnicalService" then
	depended_ci := Depended_Services.depended_ci;
              if depended_ci = none or depended_ci = void then
stop;
else
	depended_ci.ManufacturerName := "DiscoveryService";
              end if;
end if;
end body;
 
end syncmapping;