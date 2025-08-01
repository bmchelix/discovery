tpl 1.18 module SKYDiscovery.CMDB.CMDB_BusinessService;
 
from CMDB.BusinessService import BusinessService 1.2;
 
syncmapping BusinessService_Augment 1.0
"""
    update the manufacturer of businessservices
    """
    overview
        tags CMDB, Extension;
    end overview;
 
    mapping from BusinessService.bs
            from BusinessService.md_bs
            as bs
    end mapping;
 
body
	business_service := BusinessService.md_business_service or BusinessService.business_service or none;
        
        if business_service = none or business_service = void then
           stop;
	end if;
 
	business_service.ManufacturerName := "DiscoveryService";
 
end body;
 
end syncmapping;