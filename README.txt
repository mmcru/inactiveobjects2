ACTIVE DIRECTORY CLEANUP SCRIPT

FINDS AND DISABLES OBJECTS THAT HAVEN'T BEEN LOGGED INTO IN X DAYS

YOU MAY WANT TO ADJUST THE FOLLOWING VARIABLES:

$loghere:  log files are stored under this directory, log folder will be created if it doesn't exist
$days:  this calculates a past date, default is set to -180, which would go back 180 days into the past
$ou:  this is the base search ou.  script traverses every ou under this one
$excludedous:  these ou's will be ignored, needs to be a string or an array of strings
$inactiveou:  disabled and inactive objects will be moved here, string of the full ou path

questions?  email mmcru@outlook.com
