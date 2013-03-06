#!/bin/bash
# DESCRIPTION
#	Check all website given in the list file
#
# USAGE
#	./monitor-servers.sh elopez@ajlsm.com ./custom-list.txt
#

scriptDir="$(dirname "$0")" # emplacement du script
# . "$scriptDir"/toolbox.sh # charge quelques function utiles (today, etc.). Le
. "$scriptDir"/style.sh # include some style

#clear
emailTo="${1:-elopez@ajlsm.com}"
appList="${2:-"$scriptDir"/monitor-list.txt}" # URL to pleade

while read -r line
do
	[[ "$line" = \#* ]] && continue # ignore lines starting by '#'
  site="${line#*//}" # remove the protocole
  site="${site%/*}" # remove trailing slash

  printf "[i] Checking ${_value}%s${_normal}...\n\t" "${site}"
	"$scriptDir"/monitor-app.sh "$emailTo" "$line"
done < "$appList"
