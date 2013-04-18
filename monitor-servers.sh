#!/usr/bin/env bash
# DESCRIPTION
#	Check all website given in the list file
#
# USAGE
#	./monitor-servers.sh me@host.com ./custom-list.txt
#

scriptDir="$(dirname "$0")" # emplacement du script
# . "$scriptDir"/toolboxrc # charge quelques function utiles (today, etc.). Le
. "$scriptDir"/stylerc # include some style

#clear
emailTo="${1:-me@host.com}"
srvList="${2:-"$scriptDir"/monitor-list-default.txt}" # URL to server


# @description check if requirement are met and display message
# @return    void
function checkRequirement() {
  if ! type mail 2> /dev/null; then
    printf "%s Requirement %s %s\t %s\n" \
            "$_w" \
            "$(_warning "missing")" \
            "$(_valid "->")" \
            "$(_warning "Install and configure a 'mail' server")"
  fi
}

# @description monitor the list of provider server, send mail to given adress
# @param    $1|$srvList  list of server to monitor
# @param    $2|$emailTo  target email adress
# @return    void
function monitor()
{
  local srvList="$1"
  local emailTo="$2"

  while read -r line
  do
    [[ "$line" = \#* ]] && continue # ignore lines starting by '#'
    site="${line#*//}" # remove the protocole
    site="${site%/*}" # remove trailing slash

    printf "Checking %s...\n\t" "$(_value ${site})"
    "$scriptDir"/monitor-app.sh "$emailTo" "$line"
  done < "$srvList"
}

# start
checkRequirement
monitor "$srvList" "$emailTo"
