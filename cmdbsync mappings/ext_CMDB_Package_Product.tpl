tpl 1.20 module cmdb_ext_Package_Product;

metadata
    origin := "community";
    description := 'Package nodes mapped to BMC_Product';
    last_update := '06 September 2022';
    tree_path := 'community', 'CMDBsync', 'Extended', 'Package -> BMC_Product';
end metadata;

from CMDB.SyncConfig          import Config              1.2;
from CMDB.Host_ComputerSystem import Host_ComputerSystem 2.5;

syncmapping Package_Product 2.3
    """ Map Product nodes to BMC_Product class.
        Consumes basics from SoftwareInstance mappings such as default_publisher from the SyncConfig.

        Rule No  Rule Details
        1        Create BMC_Product CI for each Product node

        History
            06-09-2022 - created
    """
    overview
        tags CMDB, Core_Mapping;
        datamodel 0, 1, 2, 3, 4, 5, 6;
    end overview;

    mapping from Host_ComputerSystem.host as host
        traverse Host:HostedSoftware:InstalledSoftware:Package as package
            product -> BMC_Product;
        end traverse;
    end mapping;

    body
        computersystem := Host_ComputerSystem.computersystem;

        for each package do
            publisher    := package.vendor;
            product_name := package.name;
            product_category := "BMC Discovered";

            if not publisher and Config.default_publisher then
                publisher := Config.default_publisher;
            end if;

            product := none;

            if product_name then
                if package.version then
                    product_desc := "%product_name% %package.version%";
                else
                    product_desc := product_name;
                end if;

                product_key := "%host.key%/%product_name%/%package.version%";
                name := "%product_name%:%package.version%";
                if Config.cs_in_ci_name then
                    name := "%name% : %computersystem.Name%";
                end if;

                product := sync.BMC_Product(
                    key              := product_key,
                    Name             := name,
                    NameFormat       := "ProductName:Version",
                    ShortDescription := product_desc,
                    Description      := package.description,
                    BuildNumber      := package.revision,
                    ManufacturerName := publisher,
                    MarketVersion    := package.version,
                    Model            := product_name,
                    VersionNumber    := package.version,
                    Company          := computersystem.Company,
                    Category         := "Software",
                    Type             := "Software Application/System",
                    Item             := "BMC Discovered"
                );

                sync.rel.BMC_HostedSystemComponents(
                    Source      := computersystem,
                    Destination := product,
                    Name        := "INSTALLEDSOFTWARE"
                );

            end if;
        end for;
    end body;
end syncmapping;

