-- Accedim a la bdd: 
\c lab_clinic

-- ~ -- Creem la taula resultats_nous: 
-- ~ CREATE TABLE resultats_nous AS 
-- ~ SELECT * FROM resultats LIMIT 0;

-- ~ -- Eliminem la columna idresultat de la nova taula: 
-- ~ ALTER TABLE resultats_nous DROP COLUMN idresultat;

-- Eliminem la columna dataresultat de la nova taula: 
-- ~ ALTER TABLE resultats_nous DROP COLUMN dataresultat;

-- Insertem els registres a la taula: 
\COPY resultats_nous FROM '/var/tmp/M10-bases/nousresultats.csv' WITH DELIMITER ';';

-- Cridem a la funció:

select select_resultat()
