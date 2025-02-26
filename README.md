To Backup database run  db_backup.sh
--------------------------------------------

Script will run daily creating new full backup every Sunday, 
	and incremental for the latest full every day of the week

if option "-f|--full" is used it will force new full backup

if option "-i|--inc" is used it will force new incremental backup

if option "-e|--exp" is used it will create logical dump/export"


To Restore database from full/inc backup(s)
--------------------------------------------

Create new directory where we can prepare the backup:  

# mkdir ./mariadb

Uncompress the latest full/base backup:

# pigz backup_base.gz -dc -p 2 | mbstream --directory=./mariadb -x --parallel=2  

Prepare it - sync the base backup with changes contained in the InnoDB redo log 

# mariabackup --prepare \
  --target-dir=./mariadb 

Apply the incremental changes to the full backup:

# mariabackup --prepare \
   --target-dir=./mariadb \
   --incremental-dir=/mariadb/bkp/full/inc/DAYTIME
 
Use the mariabackup --copy-back option to copy the backup to data directory

# mariabackup --copy-back \
   --target-dir=./mariadb

Point-in-Time Recovery 
Use Binary Logs to restore to desired point in time, apply binary logs in sequence

# mysqlbinlog --start-position=START_POSITION binlog.000001 | mysql -u username -p 
