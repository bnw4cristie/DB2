#! /bin/bash
##############################################################################
#
# changelog
# date      version remark
# 2023-11-10  0.1.2   some more tables added ()
# 2023-02-20  0.1.1   moved changelog to top, added some tables
# 2020-08-12  0.1.0   first version put to gitlab
# 2020-08-XX  0.0.1   initial coding using bash
#
##############################################################################
#
#  reorg-tables.sh
# 
#  doing all reorgs in one script call
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

# copy / edit following part and skip lines not needed

exit 99;  # so running this script should fail

db2 connect to tsmdb1 && \
db2 "reorg table tsmdb1.ACTIVITY_LOG            allow no access use REORG16K" && \
db2 "reorg table tsmdb1.AF_BITFILES             allow no access use REORG16K" && \
db2 "reorg table tsmdb1.AF_SEGMENTS             allow no access use REORG16K" && \
db2 "reorg table tsmdb1.ARCHIVE_OBJECTS         allow no access use REORG32K" && \
db2 "reorg table tsmdb1.AS_SEGMENTS             allow no access use REORG16K" && \
db2 "reorg table tsmdb1.BACKUP_OBJECTS          allow no access use REORG32K" && \
db2 "reorg table tsmdb1.BF_AGGREGATE_ATTRIBUTES allow no access use REORG16K" && \
db2 "reorg table tsmdb1.BF_AGGREGATED_BITFILES  allow no access use REORG16K" && \
db2 "reorg table tsmdb1.BF_BITFILE_EXTENTS      allow no access use REORG16K" && \
db2 "reorg table tsmdb1.BF_DEREFERENCED_CHUNKS  allow no access use REORG16K" && \
db2 "reorg table tsmdb1.GROUP_LEADERS           allow no access use REORG16K" && \
db2 "reorg table tsmdb1.EXPORT_OBJECTS          allow no access use REORG16K" && \
db2 "reorg table tsmdb1.REPLICATED_OBJECTS      allow no access use REORG8K"  && \
db2 "reorg table tsmdb1.SC_OBJECT_TRACKER       allow no access use REORG16K" && \
db2 "reorg table tsmdb1.SD_CHUNK_LOCATIONS      allow no access use REORG16K" && \
db2 "reorg table tsmdb1.SD_RECON_ORDER          allow no access use REORG16K" && \
db2 "reorg table tsmdb1.SD_REPLICATED_CHUNKS    allow no access use REORG16K" && \
db2 "reorg table tsmdb1.TSMMON_STATUS           allow no access use REORG16K"