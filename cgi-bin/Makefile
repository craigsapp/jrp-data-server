##
## Programmer:    Craig Stuart Sapp <craig@ccrma.stanford.edu>
## Creation Date: Tue Dec 12 12:53:08 PST 2023
## Last Modified: Tue Dec 12 12:53:14 PST 2023
## Filename:      ...data-server-jrp/cgi-bin/Makefile
## Syntax:        GNU makefile
##
## Description: This Makefile automates cgi-bin script installation.
##

CGIBIN = /var/www/cgi-bin

all:
	rm $(CGIBIN)/data-server-jrp
	cp data-server-jrp.pl $(CGIBIN)/data-server-jrp
	chmod 0755	$(CGIBIN)/data-server-jrp

selinux:
	semanage fcontext -a -t httpd_sys_script_exec_t /var/www/cgi-bin/data-server-jrp
	restorecon /var/www/cgi-bin/data-server-jrp




