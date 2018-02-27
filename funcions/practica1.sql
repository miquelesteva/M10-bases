-- ~ CREATE OR REPLACE FUNCTION dni_correct(dni varchar)
-- ~ RETURNS text AS
-- ~ $$
-- ~ DECLARE
 	-- ~ resultat varchar := '0';
 	-- ~ partnum numeric(8);
	-- ~ partlletra varchar;
 	-- ~ lletres varchar := 'TRWAGMYFPDXBNJZSQVHLCKE';
 	-- ~ posicio int;
	-- ~ lletra varchar;
 	resultat varchar;
-- ~ BEGIN
 	-- ~ IF char_length(dni) != 9 THEN
		 -- ~ resultat := '1';
	-- ~ RETURN resultat;
	-- ~ ELSE
 		-- ~ partnum = substr (dni, 1, 8);
 		-- ~ posicio := cast (partnum as int) % 23;
 		-- ~ partlletra = substr (dni, 9, 1);
 				
		-- ~ lletra = substring('TRWAGMYFPDXBNJZSQVHLCKE' from posicio +1 for 1);
		
		-- ~ IF lletra <> partlletra THEN
			-- ~ resultat := '2';
		ELSE
			resultat := 'LLETRA DNI CORRECTA';
		-- ~ END IF;
	
	-- ~ END IF;
	-- ~ RETURN resultat;
-- ~ END;
-- ~ $$
-- ~ LANGUAGE 'plpgsql' IMMUTABLE;


-------------------------------------------------------------------

--Nick

create or replace function cal_dni(dni varchar(9))
RETURNS TEXT
AS $$
DECLARE
resultado int:= 0;
partnum numeric(8);
lletra text;
operations integer;
COD text;
res text;

BEGIN
IF char_length(dni) != 9 then
	resultado := 1;
ELSE
	partnum := substr(dni,1,8);
	lletra := substr(dni,9);
	operations := partnum%23;
	COD:='TRWAGMYFPDXBNJZSQVHLCKE';
	res:= substr(COD,operations+1,1);
	IF res != lletra then
		resultado := 2;
	ELSE
		resultado := 0;
	END IF;
END IF; 
RETURN resultado;

END;
$$ LANGUAGE plpgsql;

-- resultat = 1: longitud incorrecta
-- resultat = 2: lletra incorrecta
-----------------------------------------------------------------------

--Vlad

CREATE OR REPLACE FUNCTION dni_correct(dni varchar)
RETURNS text AS
$$
DECLARE

 	ret int := 0;
 	partnum numeric(8);
 	lletras varchar := 'TRWAGMYFPDXBNJZSQVHLCKE';
 	modul int;
 	lletraresultat varchar(1);
 	lletradni varchar(1);
BEGIN
 	IF char_length(dni) != 9 THEN
		 ret := 1;
	ELSE
 		partnum = substr (dni, 1, 8);
 		modul := cast (partnum as int) % 23;
 		
 		lletraresultat := substring(lletras from modul + 1  for 1);
		lletradni := right(dni,1);

		IF lletraresultat <>  lletradni THEN
			ret := 2;
		END IF;
		
	END IF;
RETURN ret;
EXCEPTION WHEN others THEN
	RETURN 5;
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE;

---------------------------------------------------------------------

CREATE TABLE pacients (
  idpacient serial NOT NULL PRIMARY KEY,
  nom varchar(15) NOT NULL,
  cognom varchar(30) NOT NULL,
  dni varchar(9),
  data_naix date NOT NULL,
  sexe varchar(1) NOT NULL,
  adreca varchar(20) NOT NULL,
  ciutat varchar(30) NOT NULL,
  c_postal varchar(10) NOT NULL,
  telefon varchar(9) NOT NULL,
  email varchar(30) NOT NULL,
  num_ss varchar(12) ,
  num_cat varchar(20) ,
  nif varchar(20),
  passaporte varchar(20) 
);

ALTER TABLE pacients
	ADD constraint uniqueDni
	UNIQUE (dni);

CREATE OR REPLACE FUNCTION insert_pacients(nom varchar, cognom varchar, dni varchar, data_naix varchar, sexe varchar, 
adreca varchar, ciutat varchar, c_postal varchar, telefon varchar, email varchar, num_ss varchar, 
num_cat varchar, nif varchar, passaporte varchar) 
RETURNS TEXT AS

$BODY$
DECLARE
	resultat int := 0; -- resultat ok
	searchsql text;
	dni_retornat varchar;
	res_select record;
	sentencia text;
BEGIN
	-- Cridem a la funció del DNI per comprovar que és correcte: 
	dni_retornat = dni_correct(dni);
	
	IF dni IS NULL OR dni_retornat = 0 THEN
		searchsql := 'SELECT * FROM pacients WHERE dni = ''' || dni || ''';';
	
		FOR res_select in EXECUTE(searchsql) LOOP
			IF res_select IS NOT NULL THEN
				return 2;
			END IF;
		END LOOP;

		sentencia := 'INSERT INTO pacients (nom, cognom, dni, data_naix, sexe, adreca, ciutat, 
		c_postal, telefon, email, num_ss, num_cat, nif, passaporte) VALUES 
		(''' || nom || ''',''' || cognom || ''',''' || dni || ''',''' || to_date(data_naix, 'DD-MM-YYY') 
		|| ''',''' || sexe || ''',''' || adreca || ''',''' || ciutat || ''',''' || c_postal || ''',''' || 
		telefon || ''',''' || email || ''',''' || num_ss || ''',''' || num_cat || ''',''' || nif || ''',''' 
		|| passaporte || ''')';

		RAISE NOTICE 'contigut de la variable sentencia: %',sentencia;
		
		EXECUTE(sentencia);
		
		RETURN 0;
	ELSE
		RETURN 1;
	
	END IF;
	
	EXCEPTION
		WHEN unique_violation THEN RETURN 5; --'ERROR, UNIQUE VIOLATION';
		WHEN not_null_violation THEN RETURN 6; --'ERROR, NOT NULL VIOLATION';
		WHEN foreign_key_violation THEN RETURN 7; --'FOREIGN KEY VIOLATION';
		WHEN check_violation THEN RETURN 8; --'ERROR, CHECK VIOLATION';
		WHEN others THEN RETURN 15; --'ANOTHER ERROR';
	
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;

select insert_pacients('miquel','esteva','41536245Q','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7','44444','55555','64333');

-- Error dni massa llarg:
select insert_pacients('andreu','gomila','415362455Q','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7','44444','55555','64333');

-- Error dni amb lletra incorrecta: 
select insert_pacients('marta','esteva','41536244S','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7','44444','55555','64333');


-- postgres=# select insert_pacients('miquel','esteva','41536245Q','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7',NULL,NULL,NULL);

-- Amb aquest insert (3 nulls al final) em petava...


-- ~ postgres=# select insert_pacients('miquel','esteva','41536245Q','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7',NULL,NULL,NULL);
-- ~ NOTICE:  contigut de la variable sentencia: <NULL>
-- ~ ERROR:  query string argument of EXECUTE is null
-- ~ CONTEXT:  PL/pgSQL function insert_pacients(character varying,character varying,character varying,character varying,character varying,character varying,character varying,character varying,character varying,character varying,character varying,character varying,character varying,character varying) line 10 at EXECUTE


-----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION insert_pacients2(nom varchar, cognom varchar, dni varchar, data_naix varchar, sexe varchar, adreca varchar, ciutat varchar, c_postal varchar, telefon varchar, email varchar, num_ss varchar, num_cat varchar, nif varchar, passaporte varchar)
RETURNS TEXT AS

$BODY$
DECLARE
	sentencia text;
	dni_retornat varchar;
	
BEGIN
	dni_retornat = dni_correct(dni);
	
	IF dni_retornat = '1' THEN
	
	EXECUTE 'INSERT INTO pacients (nom, cognom, dni, data_naix, sexe, adreca, ciutat, c_postal, telefon, email, num_ss, num_cat, nif, passaporte) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)' using nom,cognom,dni,to_date(data_naix, 'DD-MM-YYY'),sexe,adreca,ciutat,c_postal,telefon,email,num_ss,num_cat,nif,passaporte;
		
	RETURN '1';
	
	EXCEPTION
		WHEN unique_violation THEN RETURN 'ERROR, UNIQUE VIOLATION';
		WHEN not_null_violation THEN RETURN 'ERROR, NOT NULL VIOLATION';
		WHEN foreign_key_violation THEN RETURN 'FOREIGN KEY VIOLATION';
		
	END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;


select insert_pacients2('miquel','esteva','41536245Q','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7',NULL,NULL,NULL);
select insert_pacients2('andreu','gomila','41536245Q','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7',NULL,NULL,NULL);

-- ERROR UNIQUE: fem un altre insert amb nom i dni igual que un altre registre ja insertat. 

postgres=# select insert_pacients2('miquel','esteva','41536245Q','03-03-1988','M','amigo 18','bcn','08021','680716697','miquel.esteva9@gmail.com','1285789dcv7',NULL,NULL,NULL);
    insert_pacients2     
-------------------------
 ERROR, UNIQUE VIOLATION
(1 row)

