#!/usr/bin/env bash
# DESCRIPTION
#	check if a given URL is returning a HTTP 200 or not.
#
# USAGE
#		1. We need to install (http://doc.ubuntu-fr.org/cron#autres_considerations) :
#			sudo apt-get install mailutils
#		2. Add the recipient to the crontab :
#			MAILTO="me@host.com"
#		3. Run :
#			./pleade-monitor.sh me@host.com http://example.com/


scriptDir="$(dirname "$0")" # emplacement du script
. "$scriptDir"/toolboxrc # charge quelques function utiles (today, etc.). Le
. "$scriptDir"/stylerc # include some style

# Email To ?
EMAIL_TO="${1:-me@host.com}"
LOGS_DIR="$scriptDir"/logs

# Remove the scheme (https?) and the trailing slash
# @param	string	application URL
function getSiteName() {
	local appUrl="$1"
  local site="${appUrl#*//}" # remove the protocole
  local site="${site%/*}" # remove trailing slash

  echo "$site"
}

# Get the HTTP status code
# @param	string	application URL
function getHttpCode() {
  local appUrl="$1"
	curl -A "$EMAIL_TO bot: status monitor" -s -o /dev/null -w "%{http_code}" "$appUrl"/version.xml
}

# entry point
# @param	string	application URL
function doThings() {
	local appUrl="$1"
	local site="$(getSiteName "$appUrl")"
	local httpCode=$(getHttpCode "$appUrl")
	local notify=1 # assumption is that there is a problem

	case "$httpCode" in
	200)
		msg=$(printf "[i] Pleade is %s on %%s%%s\n" "$(_info "running")")
		notify=0	# don't send any notification when everything is ok
		unset httpCode # remove the code (less noise in the logs)
		;;
	3??)
		msg=$(printf "[!] Page %s on %%s [error: %%s].\n\tCheck the resulting page is valid\n" "$(_warning "redirection")")
		notify=0	# don't send any notification when everything is ok
		;;
	4??)
		msg=$(printf "[!] Client %s on %%s [error: %%s]!\n\tCheck your connectivity\n" "$(_error "error")")
		;;
	500)
		msg=$(printf "[!] Internal %s on %%s [error: %%s]!\n\t%s\n"" $(_error "Server Error")" "$(_error "Restart Tomcat")")
		;;
	503)
		msg=$(printf "[!] Service %s on %%s [error: %%s]!\n\t%s\n" "$(_error "Unavailable")" "$(_error "Restart Tomcat")")
		;;
	5??)
		msg=$(printf "[!] Server %s on %%s [error: %%s]!\n" "$(_error "error")")
		;;
	*)
		msg=$(printf "[!] Unknown %s on %%s [error: %%s]\n" "$(_error "error")")
		;;
	esac

	subject="$(printf "[Monitor] %s [error: %s] @ %s" "$site" "$httpCode" "$(now)")"
	message="$(printf "$msg" "$appUrl" "$httpCode")"
	logEvent "$appUrl" "$message"

	if (( $notify != 0 ))
	then
		sendNotification "$subject" "$message"
	else
		printf "+++$message\n" #"$(getSiteName "$appUrl")"
	fi
}


# Write message into log files (app and aggregate)
# @param	string	application URL
# @param	string	message to log
function logEvent() {
	local appUrl="$1"
	local message=$(printf "[%s] %s\n" "$(now)" "$2")
	local site="$(getSiteName "$appUrl")"
	local site="${site/\//-}" # pour avoir un nom de fichier valide

	local appLog="$LOGS_DIR"/monitor-"$(today)"-"$site".log # one file per app
	local metaLog="$LOGS_DIR"/monitor-meta-"$(today)".log # aggregate one file per day

	echo $message >> "$appLog" # add to app log
	echo $message >> "$metaLog" # add to meta log
}


# Send mail notification
# @param	string	subject of the mail
# @param	string	message of the mail
function sendNotification() {
	local subject="$1"
	local message="$2"

	echo $message | mail -v -s "$subject" "$EMAIL_TO" # send email
}

[[ ! -d "$LOGS_DIR" ]] && mkdir -p "$LOGS_DIR" # create log dir
doThings "$2" # || { echo "[!] Could not execute pleade-monitor.sh ($@)" >&2; exit 1; }




