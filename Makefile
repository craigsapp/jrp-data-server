##
## Programmer:    Craig Stuart Sapp <craig@ccrma.stanford.edu>
## Creation Date: Tue Dec 12 12:53:27 PST 2023
## Last Modified: Tue Dec 12 12:53:34 PST 2023
## Syntax:        GNU Makefile
## Filename:      Makefile
## vim:           ts=3
##
## Description:   Makefile to run tasks for data-server-jrp repository.
##
## Usage:         Type "make" to see list of common make targets.  To update
##                everything type "make update" if the server has already
##                been set up.
##

.PHONY: kern

##############################
##
## Configuration variables:
##

# KERNREPOS: This is a list of all of the directories where Humdrum files
# are located that should be incorporated into this data server for the
# files.
KERNREPOS =  ../jrp-scores ../1520s-project-scores/humdrum ../tasso-scores


# TARGETDIR: The directory into which symbolic links to Humdrum files in the
# KERNREPOS directory list are located.
TARGETDIR = kern

# Log directory user/group for write permssions:
WEBSERVERUSER = apache
WEBSERVERGROUP = apache

# Location where activity logs are kept:
LOGDIR = logs



##############################
##
## all -- List makefile targets.
##

all:
	@echo
	@echo "Makefile targets:"
	@echo "   make kern           -- Create symbolic links to digital scores."
	@echo "   make update         -- Run \"make kern\" then update cache."
	@echo "   make update-nohup   -- Run \"make kern\" then update cache in background."
	@echo "   make count          -- Count the number of linked kern files."
	@echo
	@echo " Initializtion targets:";
	@echo "   make initialize     -- Initial setup before using system."
	@echo "   make check-programs -- Check if necessary programs are installed."
	@echo



##############################
##
## update -- Prepare kern directory, then update cache files.
##    The files in the ../humdrum-polish-scores repository should
##    be up to date before running this command
##    (and humdrum-chopin-first-editions).
##

un: update-nohup
nu: update-nohup
nohup-update: update-nohup
update-nohup: pull kern
	nohup make update >& nohup.out &
	@echo Saving processing text in nohup.out.
	# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
	@echo -e "\033[31mType \"tail -f nohup.out\" to monitor progress in realtime.\033[0m"

update: pull kern
	(cd cache; make update)



##############################
##
## check-programs: Check to see that all programs necessary to
##    generate derivative files in the cache are available on
##    the command-line.  This is good to run when installing,
##    but also good to check after the operating system has
##    been upgraded.
##

cp: check-programs
check-programs:
	bin/checkPrograms -v



##############################
##
## initialize -- First-time setup commands.
##

SETSEBOOL := $(shell which setsebool 2> /dev/null)
CHCON := $(shell which chcon 2> /dev/null)

initialize:
	-mkdir -p $(LOGDIR)
	chown -R $(WEBSERVERUSER).$(WEBSERVERGROUP) $(LOGDIR)

# SELinux setup:

# Allow webserver to execute scripts:
ifdef SETSEBOOL
	setsebool -P httpd_execmem 1
endif

# Allow the webserver to write to the logs directory:
ifdef CHCON
	chcon -R -t httpd_sys_content_t $(LOGDIR)
endif

# Allow the following scripts to be run by the webserver:
ifdef CHCON
	chcon system_u:object_r:httpd_exec_t:s0 bin/lyrics
endif



##############################
##
## pull: Get the latest version of the repositories.
##

pull:
	for repo in $(KERNREPOS);     \
	do                            \
		(cd $$repo && git pull);   \
	done



##############################
##
## kern -- create symbolic links to Humdrum files from data
##     repositories stored elsewhere (Add kern directories
##     KERNREPOS variable to include them in this system).
##

kern:
	bin/makeKernLinks -r -t $(TARGETDIR) $(KERNREPOS)
	@echo "kern directory has $$(ls kern/*.krn | wc -l | sed 's/^ +//') files"
	# Check for bad character encodings:
	-file kern/*.krn | grep -v UTF-8  | grep -v ASCII



##############################
##
## kern-verbose --
##

kv: kern-verbose
kern-verbose:
	bin/makeKernLinks -r -v -t $(TARGETDIR) $(KERNREPOS)
	@echo "kern directory has $$(ls kern/*.krn | wc -l | sed 's/^ +//') files"
	# Check for bad character encodings:
	-file kern/*.krn | grep -v UTF-8  | grep -v ASCII



##############################
##
## count-kern-files --
##

count: count-kern-files
count-kern-files:
	ls $(TARGETDIR)/*.krn | wc -l



##############################
##
## check-kern --
##

ck: check-kern
check-kern:
	humdrum kern/*.krn



##############################
##
## erase-purge --
##

ep: erase-purge
purge-erase: erase-purge
purged-erase: erase-purge
erase-purged: erase-purge
erase-purge:
	(cd cache; make erase-purge)





