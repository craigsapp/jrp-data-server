##
## Programmer:    Craig Stuart Sapp <craig@ccrma.stanford.edu>
## Creation Date: Tue Dec 12 01:36:14 PM PST 2023
## Last Modified: Tue Dec 12 01:36:17 PM PST 2023
## Syntax:        GNU Makefile
## Filename:      cache/Makefile
## vim:           ts=3:nowrap
##
## Description:   Makefile to run cache tasks for nifc-humdrum-data repository.
##
##


##############################
##
## all -- List makefile targets that can be done with this makefile.
##

all:
	@echo
	@echo "First prepare files in ../kern directory before updating cache."
	@echo
	@echo "Minimal usage: \"make update\" then \"make erase-purge\"."
	@echo
	@echo "make update      == Make: index copy-kern derivatives publish purge."
	@echo "make cache-index == Create main cache index (cache-index-new.hmd)."
	@echo "make copy-kern   == Copy files from kern directory to cache using cache-index-new.hmd."
	@echo "make recopy-kern == Copy files from kern directory to cache using cache-index.hmd."
	@echo "make derivatives == Run analyses for new files."
	@echo "make indexes     == Create cached indexes after publication."
	@echo "make indexes-new == Create cached indexes before publication."
	@echo "make publish     == Activate the index for the new set of files. (Move cache-index-new.hmd to cache-index.hmd)"
	@echo "make purge       == Remove files no longer in index."
	@echo "make erase-purge == Remove files from purged directory."
	@echo "make erase-cache == Remove all files from cache."
	@echo
	@echo "See the Makefile's contents for other possible targets"
	@echo



##############################
##
## update -- Install new files, create derivative files and then
##     publish the new files when everything is ready.  And finally
##     purge old files from cache and generate music search indexes.
##
## Steps to update the cache are:
##
## 0. First you should place updated files in the ../kern directory (see
##                 ../Makefile for this process).
## 1. cache-index: Creates cache-index-new.hmd based on files in ../kern .
## 2. copy-kern:   Copy ../kern files into cache directories (based on the
##                 MD5 checksum of the files).
## 3. derivatives: Calculate data conversions and analyses of the original
##                 Humdrum file.
## 4. indexes-new: Create browsing indexes for website(s).
## 5. publish:     Move cache-index-new.hmd to cache-index.hmd
## 6. purge:       Move unused cached files to the purged directory.  You can
##                 Examine them to see if the should be purged, and if so,
##                 the command "make erase-purged" will delete them.
## 7. cache-thema: Create repertory-wide music search indexes.
##

update: cache-index copy-kern derivatives indexes-new publish purge cache-thema generate-musicxml



##############################
##
## install-scripts -- Install necessary scripts in /usr/local/bin.  Mostly
##     this is just bin/humdrum2musicxml.  This should only need to be
##     done once.
##

is: install-scripts
install-scripts:
	(cd bin && make install)



##############################
##
## cache-index -- Create new cache index.  Reads files from ../kern and
##      creates an index of various IDs for each file.  The index
##      is stored in a temporary file with a "-new" prefix so that
##      the old set of files can be served while new derivative files
##      and indexes are prepared.
##

index: cache-index
ci: cache-index
cache-index:
	bin/makeCacheIndex > cache-index-new.hmd



##############################
##
## copy-kern -- Copy kern files into cache.
##

ck: copy-kern
kern: copy-kern
copy: copy-kern
copy-kern:
	bin/copyKernToCache -i cache-index-new.hmd

rk: recopy-kern
recopy: recopy-kern
recopy-kern:
	bin/copyKernToCache -i cache-index.hmd



##############################
##
## publish -- Publish new data files.
##

publish:
	-mv cache-index.hmd cache-index-old.hmd
	mv cache-index-new.hmd cache-index.hmd



##############################
##
## purge -- Remove old content from cache (stored in "purged" directory for review).
##

purge:
	bin/purgeCache
	@echo
	@echo Purged entries:
	-ls purged
	@echo
	@echo "Check purged directory contents and then type"
	@echo "\"make erase-purge\" if the purged contents should be deleted"



##############################
##
## erase-purge -- Delete purged files.
##

erase-purged: erase-purge
erase-purge:
	rm -rf purged/*



##############################
##
## clean-index: Remove old cache index.
##

clean-index:
	rm -f cache-index-old.hmd



##############################
##
## clean --
##

clean: clean-index erase-purge



##############################
##
## erase-cache -- Remove all contents from cache.
##

super-clean: erase-cache
make ec: erase-cache
erase-cache:
	rm -f ?



##############################
##
## Indexes:  -new targets should be run before "make publish", and non-new
##     versions should be run after "make publish".  The difference
##     is related to which index file is read for preparing the indexes.
##

indexes-new: indexes-new-jrp siglum-index instrument-index-new
indexes: indexes-jrp siglum-index instrument-index

indexes-new-jrp: jrp-score-index-new jrp-lyrics-index-new jrp-composer-index jrp-pitch-index instrument-index-new
indexes-jrp: jrp-score-index jrp-lyrics-index jrp-composer-index jrp-pitch-index instrument-index


jrp-score-index-new:
	@mkdir -p indexes
	-rm -f indexes/jrp-score-index.aton.gz
	-rm -f indexes/jrp-score-index.json.gz
	bin/makeJrpScoreIndex -i cache-index-new.hmd > indexes/jrp-score-index.aton
	(cd indexes; aton2json jrp-score-index.aton | sed 's/^{"ENTRY"://; s/}[]]}$$/}]/' > jrp-score-index.json)
	(cd indexes; gzip jrp-score-index.json)
	(cd indexes; gzip jrp-score-index.aton)

jrp-score-index:
	@mkdir -p indexes
	-rm -f indexes/jrp-score-index.aton.gz
	-rm -f indexes/jrp-score-index.json.gz
	bin/makeJrpScoreIndex -i cache-index.hmd > indexes/jrp-score-index.aton
	(cd indexes; aton2json jrp-score-index.aton | sed 's/^{"ENTRY"://; s/}[]]}$$/}]/' > jrp-score-index.json)
	(cd indexes; gzip jrp-score-index.json)
	(cd indexes; gzip jrp-score-index.aton)


lyrics-index-new: jrp-lyrics-index-new
lyrics-index: jrp-lyrics-index


jrp-lyrics-index-new:
	@mkdir -p indexes
	-rm -f indexes/jrp-lyrics-index.txt.gz
	bin/makeJrpLyricsIndex -i cache-index-new.hmd > indexes/jrp-lyrics-index.txt
	(cd indexes; gzip jrp-lyrics-index.txt)


jrp-lyrics-index:
	@mkdir -p indexes
	-rm -f indexes/jrp-lyrics-index.txt.gz
	bin/makeJrpLyricsIndex -i cache-index.hmd > indexes/jrp-lyrics-index.txt
	(cd indexes; gzip jrp-lyrics-index.txt)


instrument-index-new:
	@mkdir -p indexes
	-rm -f indexes/instrument-index.json.gz
	bin/makeInstrumentIndex -i cache-index-new.hmd > indexes/instrument-index.json
	(cd indexes; gzip instrument-index.json)

instrument-index:
	@mkdir -p indexes
	-rm -f indexes/instrument-index.json.gz
	bin/makeInstrumentIndex -i cache-index.hmd > indexes/instrument-index.json
	(cd indexes; gzip instrument-index.json)


composer-index: jrp-composer-index


jrp-composer-index:
	-rm -f indexes/jrp-composer-index.aton.gz
	-rm -f indexes/jrp-composer-index.json.gz
	wget "https://script.google.com/macros/s/AKfycby5J8xq1V8bNpA567Kw3yiQ5EcfS3EvMDRZTrogBxfrL5Q93fSJhACZ42FuhuRoESkZSQ/exec?format=json" -O indexes/jrp-composer-index.json
	wget "https://script.google.com/macros/s/AKfycby5J8xq1V8bNpA567Kw3yiQ5EcfS3EvMDRZTrogBxfrL5Q93fSJhACZ42FuhuRoESkZSQ/exec?format=aton" -O indexes/jrp-composer-index.aton
	(cd indexes; gzip jrp-composer-index.aton)
	(cd indexes; gzip jrp-composer-index.json)


siglum-index:
	-rm -f indexes/siglum-index.aton.gz
	-rm -f indexes/siglum-index.json.gz
	wget "https://script.google.com/macros/s/AKfycbyU-HOlZUia8oMVS3jcIwUpZ5kneM23uJDF_aFtXib6UgNnybNVpSV3ozd72SiP8aVz8w/exec?format=json" -O indexes/siglum-index.json
	wget "https://script.google.com/macros/s/AKfycbyU-HOlZUia8oMVS3jcIwUpZ5kneM23uJDF_aFtXib6UgNnybNVpSV3ozd72SiP8aVz8w/exec?format=aton" -O indexes/siglum-index.aton
	(cd indexes; gzip siglum-index.aton)
	(cd indexes; gzip siglum-index.json)


##############################
##
## derivatives -- MusicXML files are no longer generated with this
##     make target, so run "make generate-musicxml" to make them.
##

derivative: derivatives
derivatives: other-derivatives
	bin/makeDerivatives

other-derivatives: regenerate-spreadsheet-new


##############################
##
## Generate all derivatives in the makeDerivatives system:
##
##   keyscape:  Convert Humdrum files into keyscape plot images.
##   lyrics:    Extract lyrics by part from file.
##   mei:       Convert Humdrum files to MEI files.
##   midi:      Convert Humdrum files to MIDI files.
##   mp3:       Convert MIDI files into MP3 files.
##   musicxml:  Convert Humdrum files to MusicXML files.
##   prange:    Convert Humdrum files into prange plot images.
##   thema:     Generate thema search indexes.
##   wordlist:  Generate word list from lyrics in file.

generate-all:
	bin/makeDerivatives

regenerate-all:
	bin/makeDerivatives -f

missing-all:
	@bin/listMissingDerivatives -mcf

erase-all: erase-mei erase-musicxml erase-midi erase-mp3 erase-keyscape erase-prange erase-thema erase-wordlist erase-lyrics


##############################
##
## MEI conversions.
##

generate-mei:
	bin/makeDerivatives -d mei

regenerate-mei:
	bin/makeDerivatives -f -d mei

missing-mei:
	@bin/listMissingDerivatives -d mei -mcf

erase-mei:
	bin/eraseDerivatives -d mei



##############################
##
## Musedata conversions.
##

generate-musedata:
	bin/makeDerivatives -v -d musedata

regenerate-musedata:
	bin/makeDerivatives -f -d musedata

missing-musedata:
	@bin/listMissingDerivatives -d musedata -mcf

erase-musedata:
	bin/eraseDerivatives -d musedata



##############################
##
## MusicXML conversions.
##

generate-musicxml:
	bin/makeDerivatives -v -d musicxml

regenerate-musicxml:
	bin/makeDerivatives -f -d musicxml

missing-musicxml:
	@bin/listMissingDerivatives -d musicxml -mcf

erase-musicxml:
	bin/eraseDerivatives -d musicxml



##############################
##
## MIDI conversions.
##

gmid: generate-midi
midg: generate-midi
midi-generate: generate-midi
generate-midi:
	bin/makeDerivatives -v -d midi

regenerate-midi:
	bin/makeDerivatives -f -d midi

missing-midi:
	@bin/listMissingDerivatives -d midi -mcf

delete-midi: erase-midi
erase-midi:
	bin/eraseDerivatives -d midi



##############################
##
## MP# conversions.
##

mp3g: generate-mp3
gmp3: generate-mp3
mp3-generate: generate-mp3
generate-mp3:
	bin/makeDerivatives -v -d mp3

regenerate-mp3:
	bin/makeDerivatives -f -d mp3

missing-mp3:
	@bin/listMissingDerivatives -d mp3 -mcf

delete-mp3: erase-mp3
erase-mp3:
	bin/eraseDerivatives -d mp3



##############################
##
## timemap conversions.
##

: generate-timemap
gtimemap: generate-timemap
timemap-generate: generate-timemap
generate-timemap:
	bin/makeDerivatives -v -d timemap

regenerate-timemap:
	bin/makeDerivatives -f -d timemap

missing-timemap:
	@bin/listMissingDerivatives -d timemap -mcf

erase-timemap:
	bin/eraseDerivatives -d timemap



##############################
##
## Keyscape conversions.
##

generate-keyscape:
	bin/makeDerivatives -v -d keyscape

regenerate-keyscape:
	bin/makeDerivatives -f -d keyscape

missing-keyscape:
	@bin/listMissingDerivatives -d keyscape -mcf

erase-keyscape:
	bin/eraseDerivatives -d keyscape



##############################
##
## Prange conversions.
##

generate-prange:
	bin/makeDerivatives -v -d prange

regenerate-prange:
	bin/makeDerivatives -f -d prange

missing-prange:
	@bin/listMissingDerivatives -d prange -mcf

erase-prange:
	bin/eraseDerivatives -d prange



##############################
##
## Activity conversions.
##

generate-activity:
	bin/makeDerivatives -v -d activity

regenerate-activity:
	bin/makeDerivatives -f -d activity

missing-activity:
	@bin/listMissingDerivatives -d activity -mcf

erase-activity:
	bin/eraseDerivatives -d activity



##############################
##
## Incipit conversions.
##

generate-incipit:
	bin/makeDerivatives -v -d incipit

regenerate-incipit:
	bin/makeDerivatives -f -d incipit

missing-incipit:
	@bin/listMissingDerivatives -d incipit -mcf

erase-incipit:
	bin/eraseDerivatives -d incipit



##############################
##
## Thema search indexes.
##

generate-thema:
	bin/makeDerivatives -v -d thema

regenerate-thema:
	bin/makeDerivatives -f -d thema

missing-thema:
	@bin/listMissingDerivatives -d thema -mcf

erase-thema:
	bin/eraseDerivatives -d thema
	rm -f indexes/jrp-pitch-index.txt.gz



##############################
##
## Lyrics word list
##

generate-wordlist:
	bin/makeDerivatives -v -d wordlist

regenerate-wordlist:
	bin/makeDerivatives -f -d wordlist

missing-wordlist:
	@bin/listMissingDerivatives -d wordlist -mcf

erase-wordlist:
	bin/eraseDerivatives -d wordlist



##############################
##
## Lyrics
##

generate-lyrics:
	bin/makeDerivatives -v -d lyrics

regenerate-lyrics:
	bin/makeDerivatives -f -d lyrics

missing-lyrics:
	@bin/listMissingDerivatives -d lyrics -mcf

erase-lyrics:
	bin/eraseDerivatives -d lyrics


#
# Do "make cache-thema" after purging old entries from the cache:
# (do not do at derivative generation step that individual
# work thema files are created).
#

cache-thema: jrp-pitch-index
thema-cache: jrp-pitch-index
ct: jrp-pitch-index
tc: jrp-pitch-index

jrp-thema-pitch-index: jrp-pitch-index
jrp-cache-thema: jrp-pitch-index
jrp-thema-cache: jrp-pitch-index
jrp-pitch-index:
	-rm -f indexes/jrp-pitch-index.txt.gz
	bin/makeJrpPitchIndex > indexes/jrp-pitch-index.txt
	gzip indexes/jrp-pitch-index.txt


###########################################################################
##
## Data preparations that do not use the makeDerivatives system:
##

##############################
##
## Download metadata from the POPC-2 Google spreadsheet --
##

generate-spreadsheet-new: regenerate-spreadsheet-new

generate-spreadsheet: regenerate-spreadsheet

#regenerate-spreadsheet: erase-spreadsheet
regenerate-spreadsheet:
	bin/makeSpreadsheetInfo

#regenerate-spreadsheet-new: erase-spreadsheet
regenerate-spreadsheet-new:
	bin/makeSpreadsheetInfo -i cache-index-new.hmd

erase-spreadsheet:
	rm ?/*/*-spreadsheet.aton



