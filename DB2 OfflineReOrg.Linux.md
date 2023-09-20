# DB2 OfflineReOrg _using temporary table space_
<!--
##############################################################################
# changelog
# date          version remark
# 2023-09-20    0.2.0   adding this comments, Copyrights into file 
#                       and do some beautifications ;-)
# 2022-XX-XX    0.1.0   adding the checkboxes, putting under Apache 2.0 license
# 2020-XX-XX    0.0.1   initial coding inside internal GWDG documentation
#
##############################################################################
#
#   Db2-OfflineReorg.Linux.md
#    
#   A template for the workflow of a Db2 Offline Reorganisation -- Linux Version
#
#   The Author:
#   (C) 2020 -- 2023 Bjørn Nachtwey, tsm@bjoernsoe.net
#
#   Grateful Thanks to the Companies, who allowed to do the development
#   (C) 2023         Cristie Data Gmbh, www.cristie.de
#   (C) 2020 -- 2023 GWDG, www.gwdg.de
#
##############################################################################
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
##############################################################################
-->

As now this pad may be used by others, I added some sources at the bottom :-)

# Short track for Linux Servers



(2023) by tsm@bjoernsoe.net, bjoern.nachtwey@cristie.de

## Assumptions

- the instance user is named `tsmXYZ` , 
  it's home directory is `/tsmXYZ` 
  the server config is located at `/tsmXYZ/config`

  => can easily replaced by `sed -e 's#tsmXYZ#<real user name#g' <this file> > <new file>`

- there's a path `/OfflineReOrg` or a symlink of this name directing to a folder containing the script and where to put the output

- the path for the temporary dbspace is given by the variable `$tpath`, 
  e.g. by `export tpath=/stageX/`

## [ToDO|WIP|Done] determine potential of ReOrg

=> last I observered the reorg reclaims about 50% more space than estimated by the script provided by IBM [1] :-)

```bash
su - tsmXYZ
perl -f /OfflineReorg/bin/analyze_DB2_formulas.pl
```

## [ ] Get Pagessize and estimate temporary space

_as instance user_ run script `db-selects.sh` [2]

```bash
su - tsmXYZ

tsmXYZ@tsmhostX:~> bash /OfflineReOrg/bin/db-selects.sh
                  Tabname ;    object-Count ; est. time (sec) ;    object-space ;    space needed ;   Pagesize
             ACTIVITY_LOG ;         1203346 ;           8.595 ;       202646496 ;        0.189 GB ;        16K
              AF_SEGMENTS ;        20836284 ;         148.831 ;       727963200 ;        0.678 GB ;        16K
              AF_BITFILES ;        20836041 ;         148.829 ;       788334976 ;        0.734 GB ;        16K
          ARCHIVE_OBJECTS ;           34588 ;           0.247 ;         8592990 ;        0.008 GB ;        32K
              AS_SEGMENTS ;        20836284 ;         148.831 ;      3428519168 ;        3.193 GB ;        16K
           BACKUP_OBJECTS ;       763629399 ;        5454.500 ;    327958790144 ;      305.435 GB ;        32K
  BF_AGGREGATE_ATTRIBUTES ;        16531482 ;         118.082 ;       577663040 ;        0.538 GB ;        16K
   BF_AGGREGATED_BITFILES ;       585727419 ;        4183.770 ;     21671911424 ;       20.183 GB ;        16K
       BF_BITFILE_EXTENTS ;               0 ;           0.000 ;               0 ;        0.000 GB ;        16K
   BF_DEREFERENCED_CHUNKS ;               0 ;           0.000 ;               0 ;        0.000 GB ;        16K
            GROUP_LEADERS ;       309856174 ;        2213.260 ;     11763646464 ;       10.956 GB ;        16K
           EXPORT_OBJECTS ;               0 ;           0.000 ;               0 ;        0.000 GB ;        16K
        SC_OBJECT_TRACKER ;        87935418 ;         628.110 ;      1574498304 ;        1.466 GB ;        16K
       REPLICATED_OBJECTS ;               0 ;           0.000 ;              -1 ;       -0.000 GB ;         8K
            TSMMON_STATUS ;         3715341 ;          26.538 ;       292830496 ;        0.273 GB ;        16K
```

CAUTION:

- estimated times are completely inaccurate
- estimated space requirement fits reasonably

BEWARE:
`ARCHIVE_OBJECTS` and `BACKUP_OBJECTS` are of size *32K*, `REPLICATED_OBJECTS` uses 8K!

## [ ] Stop any activity

_e.g. stop server and restart in MAINT mode_

```bash
su - tsmXYZ

cd config
dsmserv MAINT
```

## [ ] Do a DB backup having a fallback option!

_The author_ suggests a local file based devclass with using 
`NUMStreams=<something more than 1>`

## [ ] Create temporary paths

```bash
tpath=/tstageX/
smx=tsmXYZ
su -c "mkdir $tpath/temp1-8K " $smx && ln -s $tpath/temp1-8K  /temp1-8K
su -c "mkdir $tpath/temp2-16K" $smx && ln -s $tpath/temp2-16K /temp2-16K
su -c "mkdir $tpath/temp3-32K" $smx && ln -s $tpath/temp3-32K /temp3-32K
```

## [ ] Create temporary tables

_as instance user while TSM is still running_

```bash
su - tsmXYZ

db2 connect to tsmdb1 

db2 "CREATE SYSTEM TEMPORARY TABLESPACE REORG8K PAGESIZE 8K MANAGED BY SYSTEM USING ('/temp1-8K') BUFFERPOOL REPLBUFPOOL1 DROPPED TABLE RECOVERY OFF"
db2 "CREATE SYSTEM TEMPORARY TABLESPACE REORG16K PAGESIZE 16K MANAGED BY SYSTEM USING ('/temp2-16K') BUFFERPOOL IBMDEFAULTBP DROPPED TABLE RECOVERY OFF"
db2 "CREATE SYSTEM TEMPORARY TABLESPACE REORG32K PAGESIZE 32K MANAGED BY SYSTEM USING ('/temp3-32K') BUFFERPOOL LARGEBUFPOOL1 DROPPED TABLE RECOVERY OFF"
```

## [ ] Stop TSM server

## [ ] Prepare Reorg

_as instance user_

```bash
su - tsmXYZ

db2 connect to tsmdb1

db2 force application all

db2stop

db2start

db2 connect to tsmdb1

db2 "DROP TABLESPACE TEMPSPACE1"
db2 "DROP TABLESPACE LGTMPTSP"
db2 update db cfg for tsmdb1 using auto_tbl_maint off
```

## [ ] Start Reorg

_typically the pagesize is always the same nevertheless what's the DB2 size is_

**recommended to use a screen!**

```bash
screen -S DO_REORG
```

_as instance user_

```bash
su - tsmXYZ

db2 connect to tsmdb1

db2 "reorg table tsmdb1.ACTIVITY_LOG allow no access use REORG16K"
db2 "reorg table tsmdb1.AF_BITFILES allow no access use REORG16K"
db2 "reorg table tsmdb1.AF_SEGMENTS allow no access use REORG16K"
db2 "reorg table tsmdb1.ARCHIVE_OBJECTS allow no access use REORG32K"
db2 "reorg table tsmdb1.AS_SEGMENTS allow no access use REORG16K"
db2 "reorg table tsmdb1.BACKUP_OBJECTS allow no access use REORG32K"
db2 "reorg table tsmdb1.BF_AGGREGATE_ATTRIBUTES allow no access use REORG16K"
db2 "reorg table tsmdb1.BF_AGGREGATED_BITFILES allow no access use REORG16K"
db2 "reorg table tsmdb1.BF_BITFILE_EXTENTS allow no access use REORG16K"
db2 "reorg table tsmdb1.EXPORT_OBJECTS allow no access use REORG16K"
db2 "reorg table tsmdb1.GROUP_LEADERS allow no access use REORG16K"
db2 "reorg table tsmdb1.SC_OBJECT_TRACKER allow no access use REORG16K"
db2 "reorg table tsmdb1.REPLICATED_OBJECTS allow no access use REORG8K"
db2 "reorg table tsmdb1.TSMMON_STATUS allow no access use REORG16K"
```

Hints:

1) use a `screen` for this operation, so connection issues will not interrupt the process and will not lead to a broken Db2
2) copy _trailing blank line_ also, so _all_ commands will be executed step-by-step

## [ ] Monitor ReOrg

**suggested to use a screen**

```bash
screen -S watch-reorg
```

_as instance user_

```bash
su - tsmXYZ

db2 connect to tsmdb1 && watch 'db2pd -d tsmdb1 -reorg'
```

## [ ] Finish ReOrg

_as instance user_

```bash
su - tsmXYZ

db2 connect to tsmdb1

db2 "create system temporary tablespace TEMPSPACE1 pagesize 16k bufferpool ibmdefaultbp"
db2 "create system temporary tablespace LGTMPTSP pagesize 32k bufferpool largebufpool1"
db2 "drop tablespace REORG8K"
db2 "drop tablespace REORG16K"
db2 "drop tablespace REORG32K"
db2 update db cfg for tsmdb1 using auto_tbl_maint on
```

## [ ] Start the server in MAINT mode

_as instance user_

```bash
su - tsmXYZ

cd /tsmXYZ/config

dsmserv MAINT
```

## [ ] Do runstats

**recommended to use a screen!**

```bash
screen -S RUNSTATS
```

_as instance user_

```bash
su - tsmXYZ

db2 connect to tsmdb1

db2 "RUNSTATS ON TABLE tsmdb1.ACTIVITY_LOG WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.AF_BITFILES WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.AF_SEGMENTS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.ARCHIVE_OBJECTS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.AS_SEGMENTS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"

db2 "RUNSTATS ON TABLE tsmdb1.BACKUP_OBJECTS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.BF_AGGREGATED_BITFILES WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.BF_AGGREGATE_ATTRIBUTES WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.BF_BITFILE_EXTENTS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"

db2 "RUNSTATS ON TABLE tsmdb1.EXPORT_OBJECTS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.GROUP_LEADERS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"

db2 "RUNSTATS ON TABLE tsmdb1.SC_OBJECT_TRACKER WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
db2 "RUNSTATS ON TABLE tsmdb1.REPLICATED_OBJECTS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"

db2 "RUNSTATS ON TABLE tsmdb1.TSMMON_STATUS WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL"
```

Hint: once again, copy a trailing blank line :-)

## [ ] Monitor Runstats

**suggested to use a screen!**

```bash
screen -S WATCH
```

_as instance user_

```bash
su tsmXYZ

db2 connect to tsmdb1

watch 'db2pd -d tsmdb1 -runstats | grep -A3 -B3 "In Progress"'
```

**as long as this command shows anything, the runstats are still running**

## [ ] WAIT FOR RUNSTATS TO COMPLETE

**DO NOT RESTART instance as long as runstats are still running!**

## [ ] Either (re)start server in operational mode or go on in MAINT-Mode

## [ ] Free space using "alter tablespace"

* do new analysis using the perl script again

```bash
su - tsmXYZ

cd /OfflineReorg/tsmXYZ

perl /OfflineReorg/bin/analyze_DB2_formulas.pl
```

* free space as suggested

```bash
tsmXYZ@tsmhostX:/OfflineReorg/tsmXYZ> cat <newest folder>/summary.out 
BEGIN SUMMARY
"db2 alter tablespace USERSPACE1 reduce max" will return = 38.6G to the operating system file system
"db2 alter tablespace IDXSPACE1 reduce max" will return = 40.3G to the operating system file system
"db2 alter tablespace BACKOBJDATASPACE reduce max" will return =178.0G to the operating system file system
"db2 alter tablespace BACKOBJIDXSPACE reduce max" will return =291.6G to the operating system file system
"db2 alter tablespace BFBFEXTDATASPACE reduce max" will return =  9.2G to the operating system file system
"db2 alter tablespace BFBFEXTIDXSPACE reduce max" will return = 76.3G to the operating system file system
If BACKUP_OBJECTS were to be off line reorganized the estimated savings is Table   16 GB, Index    0 GB
If BF_AGGREGATED_BITFILES were to be off line reorganized the estimated savings is Table    1 GB, Index    0 GB
If AS_SEGMENTS were to be off line reorganized the estimated savings is Table    0 GB, Index    0 GB
If GROUP_LEADERS were to be off line reorganized the estimated savings is Table    0 GB, Index    0 GB
If AF_BITFILES were to be off line reorganized the estimated savings is Table    0 GB, Index    0 GB
If EXPORT_OBJECTS were to be off line reorganized the estimated savings is Table    0 GB, Index    0 GB
If AF_SEGMENTS were to be off line reorganized the estimated savings is Table    0 GB, Index    0 GB
Total estimated savings 17 GB
END SUMMARY
```

* free space as suggested

```bash
su - tsmXYZ

db2 connect to tsmdb1

db2 alter tablespace USERSPACE1 reduce max
db2 alter tablespace IDXSPACE1 reduce max
db2 alter tablespace BACKOBJDATASPACE reduce max
db2 alter tablespace BACKOBJIDXSPACE reduce max
db2 alter tablespace BFBFEXTDATASPACE reduce max
db2 alter tablespace BFBFEXTIDXSPACE reduce max
```

## [ ] restart server in operational mode if not already done

## [ ] check if empty and remove folders for temporary tables

```bash
tpath=/tstageX

ls -la /temp*-*K/

rm -f /temp1-8K  && rm -rf $tpath/temp1-8K
rm -f /temp2-16K && rm -rf $tpath/temp2-16K
rm -f /temp3-32K && rm -rf $tpath/temp3-32K
```

## [ ] Check if usage of db-volumes is decreasing

```bash
df -k /db*

watch "df -k /db*"
```

or issue periodically (inside dsm admin CLI)

```dsmadmc
q dbs
```

## Sources

[1] Analysis script as mentioned above: 

* https://www.ibm.com/support/pages/sites/default/files/inline-files/$FILE/analyze_DB2_formulas_v1_14.zip

* https://www.ibm.com/support/pages/system/files/inline-files/analyze_DB2_formulas_v1_15.zip

[2] DB2 scripts: https://gitlab-ce.gwdg.de/bnachtw/TSM-Scripts/-/tree/master/DB2-scripts

----

# DB2 Offline Reorganization Guide by IBM

https://www.ibm.com/support/pages/resolving-and-preventing-issues-related-database-growth-and-degraded-performance-tivoli-storage-manager-v711200-and-later-servers#offline_table

# Further Information
## Reclaimable Tables
due to the [IBM Documentation](https://www.ibm.com/support/pages/steps-reclaim-all-available-space-reclaimable-storage-dms-automatic-storage-tablespace) the following commands shows all tables that are suitable for Reorganization 

```
db2 "SELECT varchar(tbsp_name, 30) as tbsp_name, tbsp_type, RECLAIMABLE_SPACE_ENABLED FROM TABLE(MON_GET_TABLESPACE('',-2))"
```
issueing it shows
```
~$ db2 "SELECT varchar(tbsp_name, 30) as tbsp_name, tbsp_type, RECLAIMABLE_SPACE_ENABLED FROM TABLE(MON_GET_TABLESPACE('',-2))"

TBSP_NAME                      TBSP_TYPE  RECLAIMABLE_SPACE_ENABLED
------------------------------ ---------- -------------------------
SYSCATSPACE                    DMS                                1
TEMPSPACE1                     SMS                                0
USERSPACE1                     DMS                                1
IDXSPACE1                      DMS                                1
LARGEIDXSPACE1                 DMS                                1
LARGESPACE1                    DMS                                1
LGTMPTSP                       SMS                                0
REPLTBLSPACE1                  DMS                                1
REPLIDXSPACE1                  DMS                                1
TSMTEMP                        SMS                                0
ARCHOBJDATASPACE               DMS                                1
ARCHOBJIDXSPACE                DMS                                1
BACKOBJDATASPACE               DMS                                1
BACKOBJIDXSPACE                DMS                                1
BFABFDATASPACE                 DMS                                1
BFABFIDXSPACE                  DMS                                1
BFBFEXTDATASPACE               DMS                                1
BFBFEXTIDXSPACE                DMS                                1
DEDUPTBLSPACE1                 DMS                                1
DEDUPIDXSPACE1                 DMS                                1
DEDUPTBLSPACE2                 DMS                                1
DEDUPIDXSPACE2                 DMS                                1
DEDUPTBLSPACE3                 DMS                                1
DEDUPIDXSPACE3                 DMS                                1
DEDUPTBLSPACE4                 DMS                                1
DEDUPIDXSPACE4                 DMS                                1
DEDUPTBLSPACE5                 DMS                                1
DEDUPIDXSPACE5                 DMS                                1
SYSTOOLSPACE                   DMS                                1
SYSTOOLSTMPSPACE               SMS                                0

  30 record(s) selected.
```
as it looks, only tables of `TBSP_TYPE='DMS'` are suitable, so the select can be modified like this
`db2 "SELECT varchar(tbsp_name, 30) as tbsp_name FROM TABLE(MON_GET_TABLESPACE('',-2)) WHERE tbsp_type='DMS'"`
giving 
```
~$ db2 "SELECT varchar(tbsp_name, 30) as tbsp_name FROM TABLE(MON_GET_TABLESPACE('',-2)) WHERE tbsp_type='DMS'"

TBSP_NAME
------------------------------
SYSCATSPACE
USERSPACE1
IDXSPACE1
LARGEIDXSPACE1
LARGESPACE1
REPLTBLSPACE1
REPLIDXSPACE1
ARCHOBJDATASPACE
ARCHOBJIDXSPACE
BACKOBJDATASPACE
BACKOBJIDXSPACE
BFABFDATASPACE
BFABFIDXSPACE
BFBFEXTDATASPACE
BFBFEXTIDXSPACE
DEDUPTBLSPACE1
DEDUPIDXSPACE1
DEDUPTBLSPACE2
DEDUPIDXSPACE2
DEDUPTBLSPACE3
DEDUPIDXSPACE3
DEDUPTBLSPACE4
DEDUPIDXSPACE4
DEDUPTBLSPACE5
DEDUPIDXSPACE5
SYSTOOLSPACE

  26 record(s) selected.
``` 
### Derive db2 selects from table of "reclaimable tables"
```

```