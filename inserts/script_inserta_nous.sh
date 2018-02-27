psql -d centremedic -U postgres -f /var/tmp/M10-bases/practica2.sql > /var/tmp/M10-bases/errorsDatabases/errorsimportPacients_$(date +%d-%m-%y_%H:%M).csv

#rm -f /var/tmp/M10-bases/nouspacients.csv
