#log directory
$loghere = ""

cd $loghere
md -force ".\inactiveobjects2_logs"

Import-Module activedirectory
write-host "active directory cleanup script.  finds, disables, and moves inactive AD objects"

#disable objects older than this number of days
$days = (Get-Date).Adddays(-180)

#search below this ou
$ou = ""

#exclude these ous:
$excludedous = `
"",
""

#inactive ou
$inactiveou = ""

#log file information
$logdate = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$logfile = ".\inactiveobjects2_logs\MOVED_OBJECTS_"+$logdate+".log"
$date = get-date
$disabled = 0
$moved = 0

write-host "searching for objects that haven't been logged into since $days..."

#initial log setup
add-content $logfile -value "
ACTIVE DIRECTORY CLEANUP SCRIPT
`n
FINDS AND DISABLES INACTIVE OBJECTS
`n
QUESTIONS?  EMAIL M.CRUPI@PITT.EDU
`n
INITIATED AT $date 
`n
SEARCHING FOR INACTIVE OBJECTS...
"

#make regex from excludedous
$excludedregex = ""
foreach ($z in $excludedous){
$y = $z + "|"
$excludedregex += $y
}
$excludedregex = $excludedregex -replace ".$"

write-host "the following objects will be ignored, because they are in excluded ou's:"

#notify user of ignored objects
$ignored = get-adcomputer `
-filter {LastLogonTimeStamp -lt $days} `
-searchbase $ou `
-properties lastlogondate |
where {$_.DistinguishedName -notlike ("*" + $inactiveou + "*")} |
?{$_.DistinguishedName -match $excludedregex}

foreach ($object in $ignored){
write-host "name: " $($object.name) "last logged on: " $($object.lastlogondate)
}

#find old objects
$inactivecomputers = get-adcomputer `
-filter {LastLogonTimeStamp -lt $days} `
-searchbase $ou `
-properties lastlogondate |
where {$_.DistinguishedName -notlike ("*" + $inactiveou + "*")} |
?{$_.DistinguishedName -notmatch $excludedregex}

#disable old objects
foreach ($pc in $inactivecomputers){
#shortou variable is used to make log files more readable
$shortou = $pc -replace "",""
add-content $logfile -value "
LAST LOGON TO $shortou WAS $($pc.LastLogonDate)
"
#put a whatif here for testing this script without disabling objects
Set-ADComputer $pc -Enabled $false
add-content $logfile -value "DISABLED $($pc.name)"
$disabled++
}

add-content $logfile -value "
`n
SEARCHING FOR DISABLED *AND* INACTIVE OBJECTS...
"

#find disabled/inactive objects, excludes excluded
$disabledinactive = get-adcomputer `
-filter {
LastLogonTimeStamp -lt $days 
-and Enabled -eq $false 
} `
-searchbase $ou `
-properties lastlogondate |
?{$_.DistinguishedName -notlike ("*" + $inactiveou + "*")} |
?{$_.DistinguishedName -notmatch $excludedregex}


write-host "searching for objects that haven't been logged into since $days, that are also disabled"
#notify user of ignored objects
write-host "the following objects will be ignored, because they are in excluded ou's:"

$ignoreddisabled = get-adcomputer `
-filter {LastLogonTimeStamp -lt $days} `
-searchbase $ou `
-properties lastlogondate |
where {$_.DistinguishedName -notlike ("*" + $inactiveou + "*")} |
?{$_.DistinguishedName -match $excludedregex}

foreach ($object in $ignoreddisabled){
write-host "name: " $($object.name) "last logged on: " $($object.lastlogondate)
}

#moves disabled/inactive objects from their native ou into the disabled ou
ForEach ($computer in $disabledinactive) {
$shortou = $computer -replace "",""
add-content $logfile -value "
LAST LOGON TO $shortou WAS $($computer.LastLogonDate) AND OBJECT IS DISABLED
"
#whatif goes here for testing
Move-ADObject $computer -TargetPath $inactiveou
add-content $logfile -value "
MOVED $($computer.name) TO $inactiveou.
"
$moved++
}

add-content $logfile -value "
FINISHED!
`n
TOTAL OBJECTS DISABLED: $disabled
`n
TOTAL OBJECTS MOVED: $moved
"

write-host "
success!
$disabled objects disabled
$moved objects moved
see log at $logfile
"