-- ~ -- Pràctica 5

-- ~ Una nova ampliació de la B.D. : Cal que guardem els valors de referència de les proves segons el sexe i segons 
-- ~ l’edat del pacient.
-- ~ Els valors de referència d’una prova poden ser diferents per cada sexe i per cada rang d’edat. No  totes les 
-- ~ proves canvien segons el sexe i l’edat però algunes sí. 

-- ~ 1) Modificar l’estructura de la B.D. per tal de poder guardar i gestionar els valors de referència per edat i sexe.

-- ~ CREATE TABLE provestecnica (
  -- ~ idprovatecnica bigint NOT NULL,
  -- ~ idprova int ,
  -- ~ sexe varchar(1) NOT NULL, --0 no sexe, 1 femeni 2 masculi
  -- ~ edat_inicial int NOT NULL,
  -- ~ edat_final int NOT NULL,
  -- ~ dataprova timestamp NOT NULL ,
  -- ~ resultat_numeric boolean NOT NULL DEFAULT true,
  -- ~ minpat float NULL,
  -- ~ maxpat float NULL,
  -- ~ minpan float NULL,
  -- ~ maxpan float NULL,
  -- ~ alfpat varchar(10) NULL
-- ~ );

-- També s'hauràn de modificarse els INSERT de provestecnica amb nous camps i els INSERT 
-- de resultats amb els nous idprovatecnica. 


-- ~ 2) Modificar el procediment emmagatzemat que retorna la patologia d’un resultat per tal que busqui els valors de 
-- ~ referència corresponents al sexe i a l’edat del pacient. Si la funció no rep pacient o si i el pacient no té registrada
 -- ~ la data de naixement o si el pacient no té registrat el sexe es retornarà resultat patològic.


-- Extreure edat en anys de la data de naixement del pacient: 

-- ~ lab_clinic=# select date_part('year',age(timestamp 'data_analitica', timestamp '1996-07-12'));


CREATE OR REPLACE FUNCTION valorar_res(idprovatecnica bigint, idpacient bigint, resultats varchar)
RETURNS TEXT 
AS
$BODY$

DECLARE
	trobat boolean := False;
	searchsql_pacient varchar := '';
	resultat_search record;
	dades_prova record;
	min_pat float;
	max_pat float;
	min_panic float;
	max_panic float;
	resultat_con float;
	resultat_alpha varchar;
	resultat_final varchar;
	res_num boolean;
	alfpat text;
	datanaixement text;
	sexe_pac text;
	sexe_pac_conv text;
	edat_pac text;
	edat_pac_conv int;
	result_dades record;
	
BEGIN
	IF idpacient IS NULL THEN
		resultat_final := '2'; -- resultat patologic si no rebem idpacient
	ELSE
		searchsql_pacient := 'SELECT * FROM pacients WHERE idpacient = ' || idpacient || ';'; 
		FOR resultat_search IN EXECUTE(searchsql_pacient) LOOP
			IF resultat_search IS NULL THEN
				resultat_final := '4';
			ELSE
				datanaixement := cast (resultat_search.data_naix as varchar);
				sexe_pac := resultat_search.sexe;
				IF sexe_pac = 'F' THEN
					sexe_pac_conv := '1';
				ELSE
					sexe_pac_conv := '2';
				END IF;
			END IF;
		END LOOP;
		-- Si datanaixement o sexe del pacient es null retornem resultat patologic:
		IF (datanaixement IS NULL OR sexe_pac IS NULL) THEN
			resultat_final := '2';
		ELSE
			-- Variable amb l'edat del pacient: 
			edat_pac := extract(year from age(now(),resultat_search.data_naix));
			-- ~ edat_pac := 'SELECT date_part(''year'',age(timestamp ''' || datanaixement || '''));';
			edat_pac_conv := cast (edat_pac as numeric);
			
			searchsql_pacient := 'SELECT * FROM provestecnica WHERE idprovatecnica = ' || idprovatecnica || ';';

			FOR dades_prova IN EXECUTE(searchsql_pacient) LOOP
				trobat := True;
			-- Comprovem el camp resultat_numeric:
				res_num := dades_prova.resultat_numeric;
				IF res_num THEN 
					IF es_Numeric(resultats) THEN
						IF (dades_prova.sexe = '0' OR dades_prova.sexe = sexe_pac_conv) AND (edat_pac_conv BETWEEN dades_prova.edat_inicial AND dades_prova.edat_final) THEN
							resultat_con := cast (resultats as numeric);
							min_pat := dades_prova.minpat;
							max_pat := dades_prova.maxpat;
							min_panic := dades_prova.minpan;
							max_panic := dades_prova.maxpan;
						-- Comprovar resultat normal:
							IF resultat_con > min_pat AND resultat_con < max_pat THEN
								resultat_final := '1';
							-- Comprovar resultat patològic:
							ELSE
								IF (resultat_con <= min_pat AND resultat_con > min_panic) OR
									(resultat_con >= max_pat AND resultat_con < max_panic) THEN
										resultat_final := '2';
								-- Comprovar resultat pànic:
								ELSE
									IF resultat_con <= min_panic OR resultat_con >= max_panic THEN
										resultat_final := '3';
									END IF;
								END IF;
							END IF;
						-- ~ ELSE
							-- ~ resultat_final := '6';
						END IF;
					ELSE
						resultat_final := '3';
					END IF;
				ELSE
					-- Si res_num es False llavors tenim en compte el camp alfpat:
					alfpat := dades_prova.alfpat;
					IF resultats != alfpat THEN
						resultat_final := '2';
					ELSE
						resultat_final := '1';
					END IF;
				END IF;
			END LOOP;
			IF NOT trobat THEN
				resultat_final := '6';
			END IF;
		END IF;
	END IF;
RETURN resultat_final;
-- ~ EXCEPTION
		-- ~ WHEN others THEN RETURN '5';
END;
$BODY$
LANGUAGE 'plpgsql';

-- ~ select valorar_res(10600, 2, '80'); -- No patologic
-- ~ select valorar_res(10600, 4, '86'); -- Patologic
-- ~ select valorar_res(10600, 4, '40'); -- Panic
-- ~ select valorar_res(10600, 80, '40'); -- No existeix pacient
-- ~ select valorar_res(11600, 2, '40'); -- No existeix provatecnica

