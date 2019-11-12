
# Results codes DRAFT

## OK

O111 Placeholder code

O200 'OCFL 3.5.1 Inventory ID is OK.'
O200 'OCFL 3.5.1 Inventory Type is OK.'
O200 = <Inventory Value> is OK.

## Informational

I111 Placeholder code

I200 = <generic informational msg>
I220 "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm.")

## Errors

E111 Placeholder code

E010	OCFL 3.1 Version directory #{directory} contains directories other than designated content directory
E011	OCFL 3.1 Version directory #{directory} contains files other than an inventory and inventory digest
E012	OCFL 3.1 Version directory #{directory} does not contain the content directory specified in the inventory
E013	OCFL 3.1 Expected version directory #{directory} missing from directory list #{directories}
E014 "OCFL 3.5.3 Found #{version_count} versions, but highest version is #{highest_version}"
E015 "OCFL 3.5.3 Expected version sequence not found. Expected version #{count}, found version #{my_versions[count]}."
E016 "OCFL 3.5.3.1 version #{version} is missing #{key} block."

E050 "OCFL 3.5.3.1 Digests missing! #{unique_checksums.length} digests in versions vs. #{@my_victim.manifest.length} digests in manifest."
E051 "OCFL 3.5.3.1 Checksum #{checksum} not found in manifest!"

E200 'OCFL 3.5.1 Object ID not found'
E201 'OCFL 3.5.1 Object ID cannot be 0 length'
E202 'OCFL 3.5.1 Object ID cannot be nil')

E211 'Inventory head cannot be 0'
E212 'OCFL 3.5.1 Inventory Head cannot be nil'
E213 'OCFL 3.5.1 Inventory Head cannot be an Integer'
E214 "OCFL 3.5.1 Inventory Head version #{version} does not match expected version #{target_version}"

E220  Algorithm not found
E221  Algorithm cannot be 0 length
E222  Algorithm cannot be nil
E223  "OCFL 3.5.1 Algorithm #{@my_victim.digestAlgorithm} is not valid for OCFL use.

E250 'OCFL 3.5.2 there MUST be a manifest block.'
E251 'OCFL 3.5.2 manifest block cannot be empty.'

E911 'An unknown error has occurred.'

## Warnings

W111 Placeholder code

W220 "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} SHOULD be SHA512."