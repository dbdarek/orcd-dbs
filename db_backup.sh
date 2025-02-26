#!/bin/bash

source ~/dbs/.bkp.cnf 

fullbkp() {
    DATE=$(date +${BKPDAY})
    NEW_BKPDIR=${BKPDIR}/${DATE}/full

    mkdir -p ${NEW_BKPDIR}

    mariabackup --backup --user=${BKPUSR} --password=${BKPASS} --host=${DBHOST} --parallel=2 \
        --stream=mbstream \
        --target-dir=${NEW_BKPDIR} \
        --extra-lsndir=${NEW_BKPDIR} | gzip > ${NEW_BKPDIR}/backup_base.gz
}

inc_bkp() {
    DATE=$(date +${BKPDAY})

    if [ -z $(ls -A ${BKPDIR}) ]; then
        echo "No full backup found - full backup will be performed"
        fullbkp  
        return
    fi
    
    # Find last full backup 
    LAST_BKP=$(ls -1d ${BKPDIR}/20* | sort -r | head -n 1 | cut -d'.' -f1)
    LAST_FULBKP="${LAST_BKP}/full"

    DAYTIME=$(date +%d_%H%M)
    NEW_BKPDIR=${LAST_FULBKP}/inc/${DAYTIME}
    
    mkdir -p ${NEW_BKPDIR}
    echo ${NEW_BKPDIR}

    mariabackup --backup --user=${BKPUSR} --password=${BKPASS} --host=${DBHOST} --parallel=1 \
        --target-dir=${NEW_BKPDIR} \
        --incremental-basedir=${LAST_FULBKP} \
        --extra-lsndir=${NEW_BKPDIR}/extra |  gzip > ${NEW_BKPDIR}/backup_inc_${DAYTIME}.gz 

}

expdb() {
    DATE=$(date +${BKPDAY})
    DAYTIME=$(date +%d_%H%M)

    NEW_BKPDIR=${BKPDIR}/${DATE}/exp

    DBS=$(mariadb -u $BKPUSR -p$BKPASS -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)
    
    mkdir -p ${NEW_BKPDIR}

    for DB in $DBS; do
       if [[ "$DB" != "information_schema" ]] && [[ "$DB" != "performance_schema" ]] && [[ "$DB" != "mysql" ]] && [[ "$DB" != _* ]] ; then
          echo "Exporting: $DB"
          mysqldump -u${BKPUSR} -p${BKPASS} --single-transaction --databases -B ${DB} | gzip > $NEW_BKPDIR/${DB}_${DAYTIME}_export.sql.gz
       fi
    done

}

EXPORT=false
FULBKP=false
INCBKP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--full)
      shift&&FULBKP=true||die
    ;;
    -i|--inc)
      shift&&INCBKP=true||die
    ;;
    -e|--export)
      shift&&EXPORT=true||die
    ;;
    *)
      echo "Option uknown: $1 - Exiting"
      exit 1
    ;;
  esac
  shift
done


# Main 

if ${EXPORT}; then
	expdb
elif ${FULBKP}; then
    	fullbkp
elif ${INCBKP}; then
        inc_bkp
else
   	if [[ $(date +%w) -eq 0 ]]; then 
      		fullbkp
   	else 				
      		inc_bkp
   	fi
fi

exit 0

