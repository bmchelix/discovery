tpl 1.18 module SKYDiscovery.CMDB.CMDB_BusinessService_Dependant;
 
from CMDB.Dependant_Services import Dependant_Services 2.1;
 
syncmapping BusinessService_Dependant_Augment 1.0
"""
    update the manufacturer of businessservices
    """
    overview
        tags CMDB, Extension;
    end overview;
 
    mapping from Dependant_Services.source_node
            as source_node
    end mapping;
 
body
    dependant_node := Dependant_Services.dependant_node or none;

        if dependant_node = none then
            stop;
        end if;

dependant_kind := model.kind(dependant_node);

if dependant_kind = "BusinessService" or dependant_kind = "BusinessApplicationInstance" or dependant_kind = "TechnicalService" then
	dependant_ci := Dependant_Services.dependant_ci;
              if dependant_ci = none or dependant_ci = void then
stop;
else
	dependant_ci.ManufacturerName := "DiscoveryService";
              end if;
end if;

end body; 
end syncmapping;