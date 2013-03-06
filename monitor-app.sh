#!/bin/bash
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
. "$scriptDir"/toolbox.sh # charge quelques function utiles (today, etc.). Le
. "$scriptDir"/style.sh # include some style

# Email To ?
EMAIL_TO="${1:-me@host.com}"
LOGS_DIR="$scriptDir"/logs

# Remove the scheme (https?) and the trailing slash
# @param	string	application URL
function getSiteName() {
	appUrl="$1"
  site="${appUrl#*//}" # remove the protocole
  site="${site%/*}" # remove trailing slash

  echo "$site"
}

# Get the HTTP status code
# @param	string	application URL
function getHttpCode() {
  appUrl="$1"
	curl -A "$EMAIL_TO bot: status monitor" -s -o /dev/null -w "%{http_code}" "$appUrl"/version.xml
}

# entry point
# @param	string	application URL
function doThings() {
	appUrl="$1"
	site="$(getSiteName "$appUrl")"
	httpCode=$(getHttpCode "$appUrl")
	notify=1 # par défaut on envoi un message !

	case "$httpCode" in
	200)
		msg="[i] Pleade is ${_info}running${_normal} on %s%s\n"
		notify=0	# don't send any notification when everything is ok
		unset httpCode # remove the code (less noise in the logs)
		;;
	3??)
		msg="[!] Page ${_warning}redirection${_normal} on %s [error: %s].\n\tCheck the resulting page is valid\n"
		notify=0	# don't send any notification when everything is ok
		;;
	4??)
		msg="[!] Client ${_error}error${_normal} on %s [error: %s]!\n\tCheck your connectivity\n"
		;;
	500)
		msg="[!] Internal ${_error}Server Error${_normal} on %s [error: %s]!\n\t${_error}Restart Tomcat${_normal}\n"
		;;
	503)
		msg="[!] Service ${_error}Unavailable${_normal} on %s [error: %s]!\n\t${_error}Restart Tomcat${_normal}\n"
		;;
	5??)
		msg="[!] Server ${_error}error${_normal} on %s [error: %s]!\n"
		;;
	*)
		msg="[!] Unknown ${_error}error${_normal} on %s [error: %s]\n"
		;;
	esac

	subject="$(printf "[Monitor] %s [error: %s] @ %s" "$site" "$httpCode" "$(now)")"
	message="$(printf "$msg" "$appUrl" "$httpCode")"
	logEvent "$appUrl" "$message"

	if (( $notify != 0 ))
	then
		sendNotification "$subject" "$message"
	else
		printf "$message\n" #"$(getSiteName "$appUrl")"
	fi
}


# Write message into log files (app and aggregate)
# @param	string	application URL
# @param	string	message to log
function logEvent() {
	appUrl="$1"
	message="[$(now)] $2"
	site="$(getSiteName "$appUrl")"
	site="${site/\//-}" # pour avoir un nom de fichier valide

	appLog="$LOGS_DIR"/monitor-"$(today)"-"$site".log # one file per app
	metaLog="$LOGS_DIR"/monitor-meta-"$(today)".log # aggregate one file per day

	echo $message >> "$appLog" # add to app log
	echo $message >> "$metaLog" # add to meta log
}


# Send mail notification
# @param	string	subject of the mail
# @param	string	message of the mail
function sendNotification() {
	subject="$1"
	message="$2"

	echo $message | mail -v -s "$subject" "$EMAIL_TO" # send email
}

[[ ! -d "$LOGS_DIR" ]] && mkdir -p "$LOGS_DIR" # create log dir
doThings "$2" # || { echo "[!] Could not execute pleade-monitor.sh ($@)" >&2; exit 1; }




