monitor-http-server
===================

Simple script to monitor if servers are responding (status 200) or not.

## Screenshot
 ![Sample output](https://raw.github.com/edouard-lopez/monitor-http-server/master/http-monitor-server-screenshot.png)

## Dependencies

* [stylerc](https://github.com/edouard-lopez/stylerc): bash output style ;
* [toolboxrc](https://github.com/edouard-lopez/toolboxrc): some stupid utilities ;
* `mail` command to send notification (need to be correctly setup).

## Usage

First you need to edit the file `monitor-list.txt` and add some servers URLs (using their [FQDN](https://en.wikipedia.org/wiki/Fully_qualified_domain_name)).

Note that lines starting with a `#` (dash) are ignored.

	# ignored hosts
	# http://wont-be.tested.com/
	# test
	http://my.website.com/

Then you are good to go and run your first test

	bash ./monitor-servers.sh me@host.com ./monitor-list-default.txt
