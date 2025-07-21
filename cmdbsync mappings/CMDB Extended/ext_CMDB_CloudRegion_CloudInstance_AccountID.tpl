tpl 1.21 module cmdb_ext_CloudInstance_AccountID;

metadata
    origin := "community";
    description := 'Set AccountID to either the Azure Subscription ID or AWS Account ID';
    last_update := '16 May 2023';
    tree_path := 'CMDBsync', 'Extended', 'CloudRegion', 'AccountID';
end metadata;

from CMDB.CloudRegion_CloudInstance import CloudRegion_CloudInstance 1.2;

syncmapping ext_CloudRegion_CloudInstance_AccountId 1.0
    """
        16/05/2023     created
    """
    overview
        tags CMDB, Core_Mapping;
        datamodel 0, 1, 2, 3, 4, 5, 6;
    end overview;

    // pull in the discovery node mapping from the OOTB cloud region module
    mapping 
        from CloudRegion_CloudInstance.region_node as region_node   
    end mapping;

    body
        region_ci := CloudRegion_CloudInstance.region_ci;
        
        if region_node.subscription_id and region_ci.ManufacturerName = 'Microsoft' and region_ci.Item = 'Cloud Region' then
            region_ci.AccountID := region_node.subscription_id;
        elif region_node.account_id and region_ci.ManufacturerName = 'Amazon' and region_ci.Item = 'Cloud Region' then
            region_ci.AccountID := region_node.account_id;
        end if;
    end body;
end syncmapping;

