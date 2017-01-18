monitor-http-server
===================

Simple script to monitor if servers are responding (status 200) or not.

## Screenshot
 ![Sample output](https://raw.github.com/edouard-lopez/monitor-http-server/master/http-monitor-server-screenshot.png)

## Dependencies

You need to have a **mail server** configured to be able to send notification.

* `mail` command to send notification.
* [stylerc](https://github.com/edouard-lopez/stylerc): bash output style ;
* [toolboxrc](https://github.com/edouard-lopez/toolboxrc): some stupid utilities ;

## Install

The project use two submodules, the instructions below cover an *out of the box* installation process:

```
git clone git@github.com:edouard-lopez/monitor-http-server.git
cd monitor-http-server
git submodule init && git submodule update # install the submodules
```

## Usage

First you need to edit the file `monitor-list.txt` and add some servers URLs (using their [FQDN](https://en.wikipedia.org/wiki/Fully_qualified_domain_name)).

Note that lines starting with a `#` (dash) are ignored.

	# ignored hosts
	# http://wont-be.tested.com/
	# test
	http://my.website.com/

Then you are good to go and run your first test

	bash ./monitor-servers.sh 
    # or
	bash ./monitor-servers.sh my@email.org ./monitoring-list.txt
