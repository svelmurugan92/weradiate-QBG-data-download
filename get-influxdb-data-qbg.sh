#!/bin/bash

#
# Module: get-influxdb-data-qbg.sh
#
# Function:
#	Get raw influxdb as json (to stdout) from QBG
#
# Copyright:
#	See LICENSE file.
#
# Author:
#	Terry Moore, MCCI Corporation
#	Sungjoon Park, MCCI Corporation
#

typeset OPTPNAME="$(basename "$0")"
typeset OPTPDIR="$(dirname "$0")"

function _verbose {
	if [[ $OPTVERBOSE -ne 0 ]]; then
		echo -E "$OPTPNAME:" "$@" 1>&2
	fi
}

function _debug {
	if [[ $OPTDEBUG -ne 0 ]]; then
		echo -E "$OPTPNAME:" "$@" 1>&2
	fi
}

function _fatal {
	echo -E "$OPTPNAME: Fatal:" "$@" 1>&2
	exit 1
}


# this doesn't work well on Windows due to console issues!
typeset -r INFLUXDB_SERVER_DFLT="analytics.weradiate.com"
typeset -r INFLUXDB_DB_DFLT="thermosense"
typeset -r INFLUXDB_SERIES_DFLT="compost"
typeset -r INFLUXDB_USER_DFLT="ezra"
typeset -r INFLUXDB_QUERY_VARS_DFLT='mean("tWater")*9/5+32 as "tWater"'
typeset -r INFLUXDB_QUERY_WHERE_DFLT='"deviceid" = '\''device-02-6a'\'' AND time > now() -1d'
typeset -r INFLUXDB_QUERY_GROUP_DFLT='time(1ms)'
typeset -r INFLUXDB_QUERY_FILL_DFLT="none"
typeset -r TIMEZONE_DFLT='tz('\''America/New_York'\'')'
typeset -r PROBE_NAME_DFLT="device-02-6a"
typeset -i DAYS_DFLT=1

#### argument scanning:  usage ####
typeset -r USAGE="${PNAME} -[Dhpv d* f* g* q* r* S* s* t* u* w* z*]"

# produce the help message.
function _help {
	more 1>&2 <<.

Name:	$OPTPNAME

Function:
	Get influx data from specified server, as json.

Usage:
	$USAGE

Operation:
	A query is constructed and sent to the server, and data is returned.

Options:
	-h		displays help (this message), and exits.

	-v		talk about what we're doing.

	-D		operate in debug mode.

	-d {database}	the database within the server; default: $INFLUXDB_DB_DFLT.

	-f {fill}	the fill value. -f- means no fill clause. Default is
			$INFLUXDB_QUERY_FILL_DFLT

	-g {group}	the group clause. Default is $INFLUXDB_QUERY_GROUP_DFLT.

	-r {probe name} probe name. Defualt is $PROBE_NAME_DFLT.

	-p		pretty-print the output; -np minifies the output.

	-q {vars}	the variables to query. Default is:

			$INFLUXDB_QUERY_VARS_DFLT

	-S {fqdn}	domain name of server; default is $INFLUXDB_SERVER_DFLT.

	-s {series}	data series name; default is $INFLUXDB_SERIES_DFLT

	-t {days}	how many days to look back. Default is $DAYS_DFLT

	-u {userid}	the login to be used for the query; default is $INFLUXDB_USER_DFLT.

	-w {where}	the where clause. Default: $INFLUXDB_QUERY_WHERE_DFLT

	-z {timezone} the time zone zlause. Default: $TIMEZONE_DFLT

Positional arguments:
	No positional arguments are availalbe.

Examples:
	To fetch the last 36 days from default source and
	series, do the following. (The -v option causes the script to display
	the curl command.)

	\$ $OPTPNAME -v -t36 > data.json
	get-influxdb-data-qbg.sh: curl -G --basic --user ezra https://analytics.weradiate.com/influxdb:8086/query?pretty=true --data-urlencode db=thermosense --data-urlencode q=SELECT mean("tWater")*9/5+32 as "tWater" from "compost" where "deviceid" = 'device-02-6a' AND time > now() - 36d GROUP BY time(1ms) fill(none) tz('America/New_York')
	Enter host password for user 'ezra':
  	% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100 29977    0 29977    0     0  92236      0 --:--:-- --:--:-- --:--:-- 93096
	\$

	To get water temperature, pressure and battery data for sensor probe 5a for the last 7 days:

	\$ $OPTPNAME -q 'mean("tWater")*9/5+32 as "tWater",mean("p") as "p",mean("vBat") as "vBat"' -r 5a -v -t7 > data.json
	get-influxdb-data-qbg.sh: curl -G --basic --user ezra https://analytics.weradiate.com/influxdb:8086/query?pretty=true --data-urlencode db=thermosense --data-urlencode q=SELECT mean("tWater")*9/5+32 as "tWater",mean("p") as "p",mean("vBat") as "vBat" from "compost" where "deviceid" = 'device-02-6e' AND time > now() - 7d GROUP BY time(1ms) fill(none) tz('America/New_York')
	Enter host password for user 'ezra':
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100  6509    0  6509    0     0  47166      0 --:--:-- --:--:-- --:--:-- 47510
	\$
.
}

typeset -i OPTDEBUG=0
typeset -i OPTVERBOSE=0
typeset -i PRETTY=1
typeset INFLUXDB_SERVER="$INFLUXDB_SERVER_DFLT"
typeset INFLUXDB_DB="$INFLUXDB_DB_DFLT"
typeset INFLUXDB_SERIES="$INFLUXDB_SERIES_DFLT"
typeset INFLUXDB_USER="$INFLUXDB_USER_DFLT"
typeset INFLUXDB_QUERY_FILL="$INFLUXDB_QUERY_FILL_DFLT"
typeset INFLUXDB_QUERY_GROUP="$INFLUXDB_QUERY_GROUP_DFLT"
typeset INFLUXDB_QUERY_VARS="$INFLUXDB_QUERY_VARS_DFLT"
typeset INFLUXDB_QUERY_WHERE="$INFLUXDB_QUERY_WHERE_DFLT"
typeset TIMEZONE="$TIMEZONE_DFLT"
typeset PROBE_NAME="$PROBE_NAME_DFLT"
typeset -i DAYS=$DAYS_DFLT

typeset -i NEXTBOOL=1
while getopts hvnDd:f:g:pq:r:S:s:t:u:w:z: c
do
	if [ $NEXTBOOL -eq -1 ]; then
		NEXTBOOL=0
	else
		NEXTBOOL=1
	fi

	if [ $OPTDEBUG -ne 0 ]; then
		echo "Scanning option -${c}" 1>&2
	fi

	case $c in
	D)	OPTDEBUG=$NEXTBOOL;;
	h)	_help
		exit 0
		;;
	n)	NEXTBOOL=-1;;
	v)	OPTVERBOSE=$NEXTBOOL;;
	d)	INFLUXDB_DB="$OPTARG";;
	f)	INFLUXDB_QUERY_FILL="$OPTARG";;
	g)	INFLUXDB_QUERY_GROUP="$OPTARG";;
	p)	PRETTY=$NEXTBOOL;;
	q)	INFLUXDB_QUERY_VARS="$OPTARG";;
	S)	INFLUXDB_SERVER="$OPTARG";;
	s)	INFLUXDB_SERIES="$OPTARG";;
	r)	PROBE_NAME="$OPTARG"
		if [[ "$OPTARG" == "1a" ]]; then
			PROBE_NAME="device-02-6a"
		elif [[ "$OPTARG" == "3a" ]]; then
			PROBE_NAME="device-02-6d"
		elif [[ "$OPTARG" == "5a" ]]; then
			PROBE_NAME="device-02-6e"
		elif [[ "$OPTARG" == "1b" ]]; then
			PROBE_NAME="device-03-b2"
		elif [[ "$OPTARG" == "3b" ]]; then
			PROBE_NAME="device-02-6c"
		elif [[ "$OPTARG" == "5b" ]]; then
			PROBE_NAME="device-03-b3"
		else
			_fatal "-t #: not a valid probe name: $OPTARG"
		fi
		;;
	t)	DAYS="$OPTARG"
		if [[ "$DAYS" != "$OPTARG" ]]; then
			_fatal "-t #: not a valid number of days: $OPTARG"
		fi
		INFLUXDB_QUERY_WHERE="\"deviceid\" = '$PROBE_NAME' AND time > now() - ${DAYS}d"
		;;
	u)	INFLUXDB_USER="$OPTARG";;
	w)	INFLUXDB_QUERY_WHERE="$OPTARG";;
	z)	TIMEZONE="$OPTARG";;
	\?)	echo "$USAGE"
		exit 1;;
	esac
done

#### get rid of scanned options ####
shift $((OPTIND - 1))

if [[ $# != 0 ]]; then
	_fatal "extra arguments:" "$@"
fi

if [[ $PRETTY -ne 0 ]]; then
	INFLUXDB_OPTPRETTY="pretty=true"
else
	INFLUXDB_OPTPRETTY="pretty=false"
fi

#### calculate the vars from the query. input is a comma-separated list of specs.
#### each spec is either a simple name, or 'expr as label'
function _expandquery {
	{ printf "%s\n" "$@" |
		awk 'BEGIN { FS=","; OFS="," }
		     { for (i=1; i <= NF; ++i)
		     	{
			if ($i ~ /^[a-zA-Z0-9_-]+$/)
				$i = "mean(\"" $i "\") as \"" $i "\""
		     	}
			print;
		     }
		' ; } || _fatal "_expandquery failed:" "$@"
}

typeset QUERY_VAR_STRING
_expandquery "$INFLUXDB_QUERY_VARS" >/dev/null
QUERY_VAR_STRING="$(_expandquery "$INFLUXDB_QUERY_VARS")"

typeset QUERY_FILL_STRING
if [[ "$INFLUXDB_QUERY_FILL" != "-" ]]; then
	QUERY_FILL_STRING=" fill($INFLUXDB_QUERY_FILL)"
else
	QUERY_FILL_STRING=
fi

typeset QUERY_GROUP_STRING
if [[ "$INFLUXDB_QUERY_GROUP" != "-" ]]; then
	QUERY_GROUP_STRING=" GROUP BY $INFLUXDB_QUERY_GROUP"
else
	QUERY_GROUP_STRING=
fi

typeset QUERY_STRING='SELECT '"${QUERY_VAR_STRING}"' from "'"${INFLUXDB_SERIES}"'" where '"${INFLUXDB_QUERY_WHERE}""${QUERY_GROUP_STRING}${QUERY_FILL_STRING}"' '"${TIMEZONE}" || _fatal "_expandquery failed"
#typeset QUERY_STRING='SELECT '"${QUERY_VAR_STRING}"' from "'"${INFLUXDB_SERIES}"'" where '"${INFLUXDB_QUERY_WHERE}"' '"${TIMEZONE}" || _fatal "_expandquery failed"
_verbose curl -G --basic --user "${INFLUXDB_USER}" \
	"https://${INFLUXDB_SERVER}/influxdb:8086/query?${INFLUXDB_OPTPRETTY}" \
	--data-urlencode "db=${INFLUXDB_DB}" \
	--data-urlencode "q=$QUERY_STRING"

curl -G --basic --user "${INFLUXDB_USER}" \
	"https://${INFLUXDB_SERVER}/influxdb:8086/query?${INFLUXDB_OPTPRETTY}" \
	--data-urlencode "db=${INFLUXDB_DB}" \
	--data-urlencode "q=$QUERY_STRING"

# end of file
