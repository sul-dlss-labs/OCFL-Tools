
# Results codes DRAFT

## OK

For times where you want to explicitly report success.

```
O111 Placeholder code

O200 'OCFL 3.5.1 Inventory ID is OK.'
O200 'OCFL 3.5.1 Inventory Type is OK.'
O200 = <Inventory Value> is OK.
O200 'All discovered files in contentDirectory are referenced in inventory.'
O200 'All discovered files in contentDirectory match stored digest values.'
O200 'All digests successfully verified.'

```

## Informational

We're not passing judgement, we're just letting you know something neat.

```
I111 Placeholder code
I101 "OCFL 3.3.1 version #{version} does not contain a contentDirectory."
I200 = <generic informational msg>
I220 "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} is a supported digest algorithm."
```



## Errors

Any error code means the resulting object has failed validation, and is not a valid OCFL object.

```
E111 Placeholder code

E010 "OCFL 3.1 Version directory #{directory} contains directories other than designated content directory"
E011 "OCFL 3.1 Version directory #{directory} contains files other than an inventory and inventory digest"
E012 "OCFL 3.1 Version directory #{directory} does not contain the contentDirectory specified in the inventory"
E013 "OCFL 3.1 Expected version directory #{directory} missing from directory list #{directories}"
E014 "OCFL 3.5.3 Found #{version_count} versions, but highest version is #{highest_version}"
E015 "OCFL 3.5.3 Expected version sequence not found. Expected version #{count}, found version #{my_versions[count]}."
E016 "OCFL 3.5.3.1 version #{version} is missing #{key} block."

E050 "OCFL 3.5.3.1 Digests missing! #{unique_checksums.length} digests in versions vs. #{@my_victim.manifest.length} digests in manifest."
E051 "OCFL 3.5.3.1 Checksum #{checksum} not found in manifest!"

E100 "Object root directory #{dir} is empty."
E101 "Object root contains noncompliant files: #{files}"
E102 "Object root does not include required file #{file}"
E103 'Object root does not include required NamAsTe file.'
E104 "Object root contains multiple NamAsTe files: #{files}"
E105 'Required NamAsTe file in object root directory has no content!'
E106 'Required NamAsTe file in object root directory does not contain expected string.'
E107 "Required NamAsTe file in object root is for unexpected OCFL version: #{ocfl_version}"

E200 'OCFL 3.5.1 Object ID not found'
E201 'OCFL 3.5.1 Object ID cannot be 0 length'
E202 'OCFL 3.5.1 Object ID cannot be nil'

E211 'Inventory head cannot be 0'
E212 'OCFL 3.5.1 Inventory Head cannot be nil'
E213 'OCFL 3.5.1 Inventory Head cannot be an Integer'
E214 "OCFL 3.5.1 Inventory Head version #{version} does not match expected version #{target_version}"
E215 "Expected inventory file #{file} not found."
E216 "Expected key #{key} not found in inventory file #{file}"

E220  Algorithm not found
E221  Algorithm cannot be 0 length
E222  Algorithm cannot be nil
E223  "OCFL 3.5.1 Algorithm #{digestAlgorithm} is not valid for OCFL use."

E230 'OCFL 3.5.1 Required OCFL key type not found.'
E231 'OCFL 3.5.1 Required OCFL key type does not match expected value.'

E250 'OCFL 3.5.2 there MUST be a manifest block.'
E251 'OCFL 3.5.2 manifest block cannot be empty.'

E260 "OCFL 3.5.3.1 logical path syntax error: #{error_details}"

E270 "OCFL 3.7 version state mismatch between inventory files: #{error_details}"

E911 'An unknown error has occurred.'
```

## Warnings

Issues that do not make the resulting object non-compliant, but are not ideal.

```
W111 Placeholder code

W101 "OCFL 3.3 version directory should not contain any directories other than the designated content sub-directory. Additional directories found: #{version_dirs}"
W102 "OCFL 3.3.1 version #{version} contentDirectory should not be empty."
W201 'OCFL 3.5.1 Inventory ID present, but does not appear to be a URI.'
W220 "OCFL 3.5.1 #{@my_victim.digestAlgorithm.downcase} SHOULD be SHA512."
W270 "OCFL 3.7 version message mismatch between inventory files: #{warn_details}"
W271 "OCFL 3.7 version created mismatch between inventory files: #{warn_details}"
W272 "OCFL 3.7 version user mismatch between inventory files: #{warn_details}"

```
