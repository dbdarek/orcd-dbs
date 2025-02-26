
Backup database run  db_backup.sh
--------------------------------------------

Script will run daily creating new full backup every Sunday, 
	and incremental for the latest full every day of the week

if option "-f|--full" is used it will force new full backup

if option "-i|--inc" is used it will force new incremental backup

if option "-e|--exp" is used it will create logical dump/export"


To Restore database from full/inc backup(s)
--------------------------------------------

Create new directory where we can prepare the backup:  # mkdir ./mariadb

uncompress the base backup:

$ pigz backup_base.gz -dc -p 2 | mbstream --directory=./mariadb -x --parallel=2  Sync the backup with changes contained in the InnoDB redo log

prepare it - sync the base backup with changes contained in the InnoDB redo log

$ mariabackup --prepare \
  --target-dir=./mariadb 

apply the incremental changes to the base full backup:

$ mariabackup --prepare \
   --target-dir=./mariadb \
   --incremental-dir=/mariadb/bkp/full/inc/DAYTIME
 
use the mariabackup --copy-back option to copy the backup to data directory

$ mariabackup --copy-back \
   --target-dir=./mariadb


recover Point-in-Time 
use binary Logs to restore to desired point in time.

$ mysqlbinlog --start-position=START_POSITION binlog.000001 | mysql -u username -p 
