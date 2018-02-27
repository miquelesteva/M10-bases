
-- ~ Modificar permisos al postgres (ja que si no ens donarà error de permisos). 

-- ~ postgres=# create user isx41536245 password 'jupiter';
-- ~ CREATE ROLE
-- ~ postgres=# alter role isx41536245 with superuser;

-- Crear un arxiu de mostra amb dades per fer els inserts. Grabarlo format csv i delimiter ; 

-- Connexió a la base de dades centremedic: 
-- ~ \c centremedic

-- Copiem els nous pacients: 
-- ~ \COPY pacients_nous FROM '/var/tmp/M10-bases/nouspacients.csv' with delimiter ';';


--------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_pacients (nom varchar, cognom varchar, dni varchar, 
data_naix varchar, sexe varchar, adreca varchar, ciutat varchar, c_postal varchar, 
telefon varchar, email varchar, num_ss varchar, num_cat varchar, nie varchar, passaport varchar) 
RETURNS TEXT AS
$BODY$
DECLARE

	update1 text;
	update2 text;
	update3 text;
	update4 text;
	searchsql text;
	resultat text;
	var_fila record;
	existeix int := 0;

BEGIN
	

	update1 := 'UPDATE pacients SET';
	
	IF dni != '' THEN -- Si és diferent de '' significa que ja existeix, per tant el busquem i el mostrem.
		searchsql := 'SELECT * FROM pacients WHERE dni = ''' || dni || ''';';
		
		FOR var_fila IN EXECUTE(searchsql) LOOP
			existeix := 0;
		END LOOP;		
	END IF;

	IF existeix != 0 THEN
		update3 := ' WHERE dni = ''' || dni || ''';';
	END IF;
	
	IF nom IS NOT NULL THEN
		update2 := 'nom = ''' || nom || '''';
	END IF;
	
	IF cognom IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 || ', cognom = ''' || cognom || '''';
		ELSE
			update2 := 'cognom = ''' || cognom || '''';
		END IF;
	END IF;
	
	IF data_naix IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 || ', data_naix= ''' || data_naix || '''';
		ELSE
			update2 := 'data_naix = ''' || data_naix || '''';
		END IF;
	END IF;
	
	IF sexe IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 || ', sexe = ''' || sexe || '''';
		ELSE
			update2 := 'sexe = ''' || sexe || '''';
		END IF;
	END IF;
	
	IF adreca IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 || ', adreca = ''' || adreca || '''';
		ELSE
			update2 := ' adreca = ''' || adreca || '''';
		END IF;
	END IF;
	
	IF ciutat IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 || ', ciutat = ''' || ciutat || '''';
		ELSE
			update2 := ' ciutat = ''' || ciutat || '''';
		END IF;
	END IF;
	
	IF c_postal IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 || ', c_postal = ''' || c_postal || '''';
		ELSE
			update2 := ' c_postal = ''' || c_postal || '''';
		END IF;
	END IF;
	
	IF telefon IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 ', telefon = ''' || telefon || '''';
		ELSE
			update2 := ' telefon = ''' || telefon || '''';
		END IF;
	END IF;
	
	IF email IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 ', email = ''' || email || '''';
		ELSE
			update2 := ' email = ''' || email || '''';
		END IF;
	END IF;

	IF num_ss IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 ', num_ss = ''' || num_ss || '''';
		ELSE
			update2 := ' num_ss = ''' || num_ss || '''';
		END IF;
	END IF;
	
	IF num_cat IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 ', num_cat = ''' || num_cat || '''';
		ELSE
			update2 := ' num_cat = ''' || num_cat || '''';
		END IF;
	END IF;
	
	IF nie IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 ', nie = ''' || nie || '''';
		ELSE
			update2 := ' nie = ''' || nie || '''';
		END IF;
	END IF;
	
	IF passaporte IS NOT NULL THEN
		IF update2 != '' THEN
			update2 := update2 ', passaport = ''' || passaport || '''';
		ELSE
			update2 := ' passaport = ''' || passaport || '''';
		END IF;
	END IF;
	
	update4 := update1 || update2 || update3;
	EXECUTE(update4);
	
	RETURN 0;

	EXCEPTION
		WHEN unique_violation THEN RETURN 5; --'ERROR, UNIQUE VIOLATION';
		WHEN not_null_violation THEN RETURN 6; --'ERROR, NOT NULL VIOLATION';
		WHEN foreign_key_violation THEN RETURN 7; --'FOREIGN KEY VIOLATION';
		WHEN check_violation THEN RETURN 8; --'ERROR, CHECK VIOLATION';
		WHEN others THEN RETURN 15; --'ANOTHER ERROR';

END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;

----------------------------------------------------------------------------------------------------

select update_pacients('Miquel Ferran', NULL, '41536245Q', NULL, NULL, 'de la pau', NULL, NULL, '661570483', NULL, NULL, NULL, NULL, NULL);

----------------------------------------------------------------------------------------------------

-- Funció select pacient: 

CREATE OR REPLACE FUNCTION select_pacient () 
RETURNS TEXT AS 
$BODY$
DECLARE

	searchsql text;
	var_fila record;
	estatInsert text;
	estatUpdate text;
	esborrar text;
	
BEGIN
	searchsql := 'SELECT * FROM pacients_nous;';
	
	FOR var_fila IN EXECUTE(searchsql) LOOP
	
		estatInsert := insert_pacients(var_fila.nom, var_fila.cognom, var_fila.dni, var_fila.data_naix, var_fila.sexe, 
						var_fila.adreca, var_fila.ciutat, var_fila.c_postal, var_fila.telefon, var_fila.email, var_fila.num_ss, 
						var_fila.num_cat, var_fila.nie, var_fila.passaporte);
		
		IF estatInsert = 2 THEN
			estatUpdate := update_pacients(var_fila.nom, var_fila.cognom, var_fila.dni, var_fila.data_naix, var_fila.sexe, 
							var_fila.adreca, var_fila.ciutat, var_fila.c_postal, var_fila.telefon, var_fila.email, var_fila.num_ss, 
							var_fila.num_cat, var_fila.nie, var_fila.passaporte);
				
				RAISE NOTICE 'Resultat del update: %', estatUpdate || ' : ' || var_fila.dni || ' : ' || var_fila.nom || ' : ' || var_fila.cognom;
		
		ELSEIF estatInsert = 1 OR estatInsert > 4 THEN
			RAISE NOTICE 'Error al fer INSERT: %', estatInsert || ' : ' || var_fila.dni || ' : ' || var_fila.nom || ' : ' || var_fila.cognom;
		
		END IF;
	END LOOP;
	
	esborrar := 'DELETE FROM pacients_nous';
	EXECUTE(esborrar);
	
	RETURN 0;
	
	EXCEPTION
		WHEN unique_violation THEN RETURN 5; --'ERROR, UNIQUE VIOLATION';
		WHEN not_null_violation THEN RETURN 6; --'ERROR, NOT NULL VIOLATION';
		WHEN foreign_key_violation THEN RETURN 7; --'FOREIGN KEY VIOLATION';
		WHEN check_violation THEN RETURN 8; --'ERROR, CHECK VIOLATION';
		WHEN others THEN RETURN 15; --'ANOTHER ERROR';
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;
