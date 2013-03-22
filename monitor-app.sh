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
#			./monitor-app.sh me@host.com http://example.com/


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
		msg="$(printf "[%s] Server is %s on: %%s%%s" \
						"$(_valid "$httpCode")" \
						"$(_valid "running")"
					)"
		notify=0	# don't send any notification when everything is ok
		unset httpCode # remove the code (less noise in the logs)
		;;
	3??) # 301
		# msg="$(printf "[%s] Page %-40s on: %%s %s %s" \
		msg="$(printf "[%s] Page %s on: %%s %s %s" \
						"$(_warning "$httpCode")" \
						"$(_warning "redirection")" \
						"$(_valid "->\t")" \
						"$(_warning "Check the resulting page is valid")"
					)"
		notify=0	# don't send any notification when everything is ok
		;;
	4??)
		msg="$(printf "[%s] Client %s on: %%s %s %s" \
						"$(_error "$httpCode")" \
						"$(_error "Error")" \
						"$(_valid "->\t")" \
						"$(_warning "Check your connectivity")"
					)"
		;;
	500)
		msg="$(printf "[%s] Internal %s on: %%s %s %s" \
						"$(_error "$httpCode")" \
						"$(_error "Server Error")" \
						"$(_valid "->\t")" \
						"$(_error "Restart Tomcat")"
					)"
		;;
	503)
		msg="$(printf "[%s] Service %s on: %%s %s %s" \
						"$(_error "$httpCode")" \
						"$(_error "Unavailable")" \
						"$(_valid "->\t")" \
						"$(_error "Restart Tomcat")"
					)"
		;;
	5??)
		msg="$(printf "[%s] Server %s on: %%s %s %s" \
						"$(_error "$httpCode")" \
						"$(_error "error")" \
						"$(_valid "->\t")" \
						"$(_error "Check manually")"
					)"
		;;
	*)
		msg="$(printf "[%s] Unknown %s on: %%s %s %s" \
						"$(_error "$httpCode")" \
						"$(_error "error")" \
						"$(_valid "->\t")" \
						"$(_error "Check manually")"
					)"
		;;
	esac

	subject="$(printf "[Monitor] %s [error: %s] @ %s" "$site" "$httpCode" "$(now)")"
	message="$(printf "$msg\n" "${appUrl:0:40}")"
	logEvent "$appUrl" "$message"

	if (( $notify != 0 ))
	then
		printf "$message\n" #"$(getSiteName "$appUrl")"
		sendNotification "$subject" "$message"
	else
		printf "$message\n" #"$(getSiteName "$appUrl")"
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
doThings "$2" # || { echo "[!] Could not execute monitor-app.sh ($@)" >&2; exit 1; }




