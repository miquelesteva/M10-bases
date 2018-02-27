psql -d lab_clinic -U postgres -f /var/tmp/M10-bases/copy_resultats.sql > /var/tmp/M10-bases/errorsDatabases/errorsimportResultats_$(date +%d-%m-%y_%H:%M).csv

#rm -f /var/tmp/M10-bases/nousresultats.csv
