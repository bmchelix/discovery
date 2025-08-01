tpl 1.18 module SKYDiscovery.CMDB.CMDB_BAI_Application;

from CMDB.BAI_Application						 import BAI_Application 2.11;

syncmapping BAI_Application_Augment 1.0
 """
    Change the default ComputerSystem HostName and TokenId to take
    only the first component of compound dot-separated hostnames.
    """
    overview
        tags CMDB, Extension;
    end overview;

    mapping from BAI_Application.bai
            from BAI_Application.md_bai
    as bai

        // No additional structure -- we are just modifying the
        // existing ComputerSystem CI.
    end mapping;

    body

BAIApplication := BAI_Application.md_application or BAI_Application.application or none;
       
if BAIApplication = none or BAIApplication = void then
          stop;
end if;
 
BAIApplication.ManufacturerName := "DiscoveryService";
 
end body;

end syncmapping;