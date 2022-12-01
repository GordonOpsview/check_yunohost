# check_yunohost

A monitoring plugin (Nagios & Opsview compatible) to check Yunohost servers.
This plugin returns the results of the most recent Yunohost diagnosis.

**Usage:** `check_yunohost [-h] -a [<category>|all|last_diagnosis] [-c <Crit>] [-w <Warn>]`

### Options:
#### -a
 - **last_diagnosis**: Hours since last diagnosis was run. The default WARNING is 24 hours, and the default CRITICAL is 720 hours (30 days).
 - **base_system**: "Base System" category
 - **internet_connectivity**: "Internet Connectivity" category
 - **dns_records**: "dns records" category
 - **ports_exposure**: "Ports Exposure" category
 - **web**: "Web" category
 - **email**: "Email" category
 - **services_status_check**: "Services Status Check" category
 - **system_resources**: "System Resources" category
 - **system_configurations**: "System Configurations" category
 - **applications**: "Applications" category
 - **all**: Check all categories.

The Category checks will return WARNING if one or more items in the Yunohost diagnosis category has a WARNING status, and CRITICAL if one or more items have a CRITICAL status.

#### -c
- **Critical**: Only applicable to 'last_diagnosis'.
#### -w
- **Warning**: Only applicable to 'last_diagnosis'.
