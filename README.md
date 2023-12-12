Data server for https://data.josqu.in
===========================================

This repository contains the files for the https://josqu.in website
that serves score data files for the Josquin Research Project.



## Primary files ##

The primary data is stored in Humdrum files.  These are initially
linked (or less preferably copied) to the `./kern` directory).   The
[./Makefile](https://github.com/craigsapp/data-jrp/blob/main/Makefile)
contains a list of the source location for all Humdrum files to be
added to the `./kern` directory.    Adjust the `KERNREPOS` variable
in the Makefile to point to directories that contain source Humdrum 
files that will be managed by the server.


Then
the command:

```bash
make kern
```

Creates symbolic links from the source locations into the `./kern`
directory.  Once links to Humdrum files are in the `./kern` directory,
the caching process can begin.

This data server is designed to manage digital scores for the
Josquin Research Project.

| Project | Repository |
| --- | --- |
| jrp-scores | https://github.com/josquin-research-project/jrp-scores |

## Cache preparation ##

The `./cache` directory stores a copy of the Humdrum data as well as
derivative formats and analyses created from each file.  An MD5 checksum
is calculated for each Humdrum file to create an 8-digit ID for that file
to uniquely identify the contents.  The Humdrum file is then copied to a
subdirectory named with that ID.  All translations and analysis files
related to the Humdrum file are also placed in the same subdirectory.

### Cache maintenance commands ###

First, create an index that maps file IDs, century enumerations and SQL enumerations
that link to the MD5-derived cache ID:

```bash
cd cache
make index
```

This will read all of the files in `./kern` to create the index
file `./cache/index-new.hmd`.

Next, copy the Humdrum files into the cache with this command:

```bash
make copy-kern
```

This will insert any new Humdrum files into the cache that are not already
in the cache.


Next, create derivative files (data translations and analyses) with the following
command:

```bash
make derivatives
```

This will create data conversion and pre-compiled analyses for each new
Humdrum file.


After derivatives have been created, the new version of the database can be
activated by typing the command:

```bash
make publish
```

This will move `./cache/index.hmd` to `./cache/index-old.hmd` and then move
`./cache/index-new.hmd` to `./cache/index.hmd`.   The file `./cache/index.hmd`
is used to map various file identifier systems to the cached version of the
Humdrum file.

Optionally, run the command:

```bash
make purge
```

to remove older and deleted versions of the Humdrum files from the cache
system.   These files will be placed in the `./cache/purge` folder for review.


There is also a command to do all of the above steps at one time (except purging)
in the base directory:

```bash
make update
```

Or to run the update process in the backgroud using `nohup`:

```bash
make un
```


## URL data access ##

Data and analysis files stored in the cache directory can be
accessed on the web via the following example URLs.  The primary
data server is at https://data.josqu.in .

<dl markdown="1">

<dt> 
<a href="https://data.josqu.pl/Jos2721">https://data.josqu.in/Jos2721</a> (primary server)
</dt>
<dd markdown="1"> Return Humdrum data for JRP ID `Jos2721`. </dd>

<dt> <a href="https://data.josqu.in/Jos2721">https://data.josqu.in/Jos2721.krn</a> </dt>
<dd> Explicitly request Humdrum data (default behavior if no data format specified). </dd>

<dt> <a href="https://data.josqu.in/Jos2721?format=krn">https://data.josqu.in/Jos2721format=krn</a> </dt>
<dd> Verbose request for Humdrum data using URL parameter. </dd>

<dt> <a href="https://data.josqu.in/Jos2721?format=kern">https://data.josqu.in/Jos2721?format=kern</a> </dt>
<dd> Alternate verbose request for Humdrum data using URL parameter. </dd>

<dt> <a href="https://data.josqu.in/Jos2721.mei">https://data.josqu.in/Jos2721.mei</a> </dt>
<dd> Request MEI conversion of file. </dd>

<dt> <a href="https://data.josqu.in/Jos2721.musicxml">https://data.josqu.in/Jos2721.musicxml</a> </dt>
<dd> Request MusicXML conversion of file. </dd>

<dt> <a href="https://data.josqu.in/Jos2721.xml">https://data.josqu.in/Jos2721.xml</a> </dt>
<dd> Alternate request MusicXML conversion of file. </dd>

<dt> <a href="https://data.josqu.in/Jos2721-La_Bernardinakrn">https://data.josqu.in/Jos2721-La_Bernardina.krn</a> </dt>
<dd> Full filename can be given (but from and after first `_` in filename will be ignored internally). </dd>

<dt> <a href="https://data.josqu.in/Jos2721-La_Bernardina.musicxml">https://data.josqu.in/Jos2721-La_Bernardina.musicxml</a> </dt>
<dd> Full filename access to MusicXML conversion. </dd>

<dt> <a href="https://data.josqu.in/random">https://data.josqu.in/random</a> </dt>
<dd> Get a random Humdrum file. </dd>

<dt> <a href="https://data.josqu.in/random.musicxml">https://data.josqu.in/random.musicxml</a> </dt>
<dd> Get a random MusicXML conversion. </dd>

</dl>



## Setup ##

See also https://bit.ly/jrp-maintenance


### Apache web server ###

An example Apache web server configuration is given in
[cgi-bin/apache.config](https://github.com/craigsapp/jrp-data-server/blob/main/cgi-bin/apache.config).
The important part of the configuration is:

```apache
RewriteEngine On
RewriteRule ^/([^?]*\?(.*))$ /cgi-bin/jrp-data-server?id=$1&$2 [NC,PT,QSA]
RewriteRule ^/([^?]*)$ /cgi-bin/jrp-data-server?id=$1 [NC,PT,QSA]
Header add Access-Control-Allow-Origin "*"
```

The `Header` line is important in order to allow [cross-origin access](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing) to
the data files.

The rewrite rules are used to simplify the URLs for data access.  Access to the data appears as if
it were a static file, but the server converts this filename into an id parameter that is passed
on to the [jrp-data-server](https://github.com/craigsapp/jrp-data-server/blob/main/cgi-bin/jrp-data-server.pl) CGI script.



### CGI script ###

The interface between the URL and internal access to data is done with
the CGI script [cgi-bin/jrp-data-server.pl](https://github.com/craigsapp/jrp-data-server/blob/main/cgi-bin/jrp-data-server.pl).  Copy
this file (via [cgi-bin/Makefile](https://github.com/craigsapp/jrp-data-server/blob/main/cgi-bin/Makefile)) to the
location for CGI scripts for the server.



### Support software  ###

Here is a description of support software needed to create derivatives files for the cache.


#### verovio ####

Install verovio on the server with these commands:

```bash
git clone https://github.com/rism-digital/verovio
cd verovio/tools
./.configure
make
make install
```

Note that `cmake` is required (and must first be installed if not available).

Verify that verovio was installed by running the command:

```bash
which verovio
```

which should reply `/usr/local/bin/verovio`.


#### aton2json ####

The aton2json program can be installed with these commands:

```bash
npm install -g posix-argv-parser
npm install -g aton2json
wget https://raw.githubusercontent.com/craigsapp/ATON/master/example/cli/aton2json -O /usr/local/bin/aton2json
```

Verify that `aton2json` was installed by running the command:

```bash
which aton2json
```

which should reply `/usr/local/bin/aton2json`


## SELinux notes ##

To allow CGI scripts to run programs in a shell when [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux), 
turn on the general permission with the command:

```bash
setsebool -P httpd_execmem 1
```

Then give permissions to run a particular program:

```bash
chcon system_u:object_r:httpd_exec_t:s0 program-file
```

For data access logging, the log directory should be given SELinux permissions:

```bash
chcon -R -t httpd_sys_content_t logs
```

And the web server should be made owner of the log directory.



