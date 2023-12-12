##
## Programmer:    Craig Stuart Sapp <craig@ccrma.stanford.edu>
## Creation Date: Tue Dec 12 12:53:08 PST 2023
## Last Modified: Tue Dec 12 12:53:14 PST 2023
## Filename:      ...jrp-data-server/cgi-bin/Makefile
## Syntax:        GNU makefile
##
## Description: This Makefile automates cgi-bin script installation.
##

CGIBIN = /var/www/cgi-bin

all:
	-rm $(CGIBIN)/jrp-data-server
	cp jrp-data-server.pl $(CGIBIN)/jrp-data-server
	chmod 0755	$(CGIBIN)/jrp-data-server

selinux:
	semanage fcontext -a -t httpd_sys_script_exec_t /var/www/cgi-bin/jrp-data-server
	restorecon /var/www/cgi-bin/jrp-data-server




