-- ~ 1) Ampliar la funció que valora un resultat per tal que pugui valorar resultats numèrics i resultats no numèrics. 
-- ~ Per això caldrà tenir en compte el valor del camp «resultat_numeric boolean» de la taula «provestecnica» i també caldrà 
-- ~ afegir un nou camp a taula provestecnica : alfpat varchar(10).
-- ~ Exemple de proves amb resultat no numèric serien :
-- ~ idprovatecnica#idprova#sexe#dataprova#esultat_numeric#minpat#maxpat#minpan#maxpan#alfpat
-- ~ 5001#206#0#2018#01#25#F#####POS
-- ~ 5002#207#0#2018#01#25#F#####-
-- ~ 5003#208#0#2018#01#25#F#####NEG

-- Modifiquem la taula per afegir la columna alfpat i eliminar els not null:
ALTER TABLE provestecnica ADD COLUMN alfpat varchar(10);
ALTER TABLE provestecnica ALTER COLUMN minpat DROP NOT NULL;
ALTER TABLE provestecnica ALTER COLUMN maxpat DROP NOT NULL;
ALTER TABLE provestecnica ALTER COLUMN minpan DROP NOT NULL;
ALTER TABLE provestecnica ALTER COLUMN maxpan DROP NOT NULL;

-- Insertem nous registres: 

INSERT INTO catalegproves (idprova, nom_prova, descripcio, acronim) VALUES ('666', 'VIH', 'test VIH', 'VIH');

INSERT INTO provestecnica (idprovatecnica, idprova, sexe, dataprova, resultat_numeric, minpat, maxpat, minpan, maxpan, alfpat) VALUES (default, '666', 'F', CURRENT_TIMESTAMP,'f', NULL, NULL, NULL, NULL, 'Negatiu');

select insert_resultats(6,13,'Negatiu');

-- Funció modificada: 

CREATE OR REPLACE FUNCTION valorar_res(idprovatecnica bigint, idpacient bigint, resultats varchar)
RETURNS TEXT 
AS
$BODY$

DECLARE

	searchsql_pacient varchar := '';
	resultat_search varchar;
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
	
BEGIN
	searchsql_pacient := 'SELECT idpacient FROM pacients WHERE idpacient = ' || idpacient || ';'; 
	EXECUTE(searchsql_pacient) INTO resultat_search;
	-- No existeix el pacient:
	IF resultat_search IS NULL THEN
		resultat_final := '4';
	ELSE
		searchsql_pacient := 'SELECT * FROM provestecnica WHERE idprovatecnica = ' || idprovatecnica || ';';
		FOR dades_prova IN EXECUTE(searchsql_pacient) LOOP
		-- Comprovem el camp resultat_numeric:
			res_num := dades_prova.resultat_numeric;
			IF res_num THEN
				IF es_Numeric(resultats) THEN
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
				ELSE
					resultat_final := '3';
				END IF;
			ELSE
				RAISE NOTICE 'res num: %',res_num;
				-- Si res_num es False llavors tenim en compte el camp alfpat:
				alfpat := dades_prova.alfpat;
				IF resultats != alfpat THEN
					resultat_final := '2';
				ELSE
					resultat_final := '1';
				END IF;
			END IF;
		END LOOP;
	END IF;
RETURN resultat_final;
EXCEPTION
		WHEN others THEN RETURN '5';
END;
$BODY$
LANGUAGE 'plpgsql';

select valorar_res(1,1,'99'); -- normal
select valorar_res(2,1,'101'); -- patologic
select valorar_res(2,1,'115'); -- panic
select valorar_res(13,4,'Negatiu'); -- No patologic
select valorar_res(13,4,'Positiu'); -- Patologic
select valorar_res(3,1000,'88'); -- no existeix el pacient

-----------------------------------------------------------------------------------

-- ~ 2) Informe de resultats amb Historial del pacient : 
-- ~ Per aquesta part de la pràctica caldrà desenvolupar com a mínim 2 procediments enmagatzemants principals:

-- ~ 2.1) InformeHistorial(idpacient, idanalitica)
-- ~ Aquesta funció serà similar a la de la part 4 de la pràctica 3 però mostrarà els resultats anteriors d’un 
-- ~ pacient. La funció rebrà idpacient i idanalitica. Si no rep analítica es buscarà l’última analítica del pacient.
-- ~ Per cada prova que hi hagi a l’analítica, mostrarà tots els resultats anteriors que hi hagi a la Base de Dades 
-- ~ per aquell pacient. Els resultats d’una mateixa prova es mostraran ordenats des del més nou al més vell.

CREATE OR REPLACE FUNCTION informe_historial(idpacient bigint, idanalitica bigint default NULL)
RETURNS TEXT
AS
$BODY$

DECLARE
	search_nom_pac text;
	resultat_search record;
	nom text;
	cognoms text;
	resultat_final text := '';
	searchsql text;
	dades1 record;
	id_analitica bigint;
	data_resultat timestamp;
	dades2 record;
	id_prova_tec bigint;
	search_proves text;
	dades3 record;
	resul text;
	crida_funcio text;
	num_prova int;
	nom_resultat text;
	dades4 record;
	codi_prova int;
	minpat float;
	maxpat float;
	minpan float;
	maxpan float;
	alfpat text;
	valor_ref1 float;
	valor_ref2 float;
	data_analitica timestamp;

BEGIN
	-- busquem el nom i cognoms del pacient: 
	search_nom_pac := 'SELECT * FROM pacients WHERE idpacient = ' || idpacient || ';';
	FOR resultat_search IN EXECUTE(search_nom_pac) LOOP
		nom := resultat_search.nom;
		cognoms = resultat_search.cognoms;
	END LOOP;
	IF nom IS NULL THEN
		resultat_final := '1';
	ELSE
	-- Si no rebem idanalitica busquem l'última del pacient:
		IF idanalitica IS NULL THEN
			searchsql := 'SELECT * FROM analitiques WHERE idpacient = ' || idpacient || ' ORDER BY dataanalitica desc limit 1;';
			FOR dades1 IN EXECUTE(searchsql) LOOP
				IF dades1 IS NULL THEN
					resultat_final := '2';
				ELSE
					id_analitica := dades1.idanalitica;
				END IF;
			END LOOP;
			searchsql := 'SELECT * FROM resultats where idanalitica = ' || id_analitica || ';';
			-- ~ RAISE NOTICE 'select from resultats where idanalitica; %',id_analitica;   -- **** 
			FOR dades2 IN EXECUTE(searchsql) LOOP
				IF dades2 IS NULL THEN
					resultat_final := '3';
				ELSE
					id_prova_tec := dades2.idprovatecnica;
					search_proves := 'SELECT * FROM analitiques JOIN resultats ON analitiques.idanalitica = resultats.idanalitica WHERE 
					idpacient = ' || idpacient || ' AND idprovatecnica = ' || id_prova_tec || ' ORDER BY dataanalitica;';
					-- ~ RAISE NOTICE 'resultat select amb join: %',search_proves;     -- ****select informe_historial(2);
					FOR dades3 IN EXECUTE(search_proves) LOOP
						IF dades3 IS NULL THEN
							resultat_final := '3';
						ELSE
							data_resultat := dades3.dataresultat; -- ha de mostrar data analitica, no data resultat! 
							resul := dades3.resultats;
							crida_funcio := valorar_res(id_prova_tec, idpacient, resul);
							-- ~ RAISE NOTICE 'data_resul: %',data_resultat;   -- ****
							-- ~ RAISE NOTICE 'resultats: %',resul;   -- ****
							IF crida_funcio = '1' THEN
								nom_resultat = 'no patologic';
							ELSEIF crida_funcio = '2' THEN
								nom_resultat = 'patologic';
							ELSEIF crida_funcio = '3' THEN
								nom_resultat = 'panic';
							ELSE
								nom_resultat = 'error';
							END IF;
							searchsql := 'SELECT * FROM provestecnica WHERE idprovatecnica = ' || id_prova_tec || ' limit 1;';
							FOR dades4 IN EXECUTE(searchsql) LOOP
								codi_prova := dades4.idprova;
								minpat := dades4.minpat;
								maxpat := dades4.maxpat;
								minpan := dades4.minpan;
								maxpan := dades4.maxpan;
								IF crida_funcio = '1' THEN
									valor_ref1 := minpat;
									valor_ref2 := maxpat;
								ELSEIF crida_funcio = '2' THEN
									valor_ref1 := minpat;
									valor_ref2 := maxpan;
								ELSEIF crida_funcio = '3' THEN
									valor_ref1 := minpan;
									valor_ref2 := maxpan;
								ELSE
									valor_ref1 := 0;
									valor_ref2 := 0;
								END IF;
							END LOOP;
						resultat_final := resultat_final || ' - ' || data_resultat || ' - ' || codi_prova || ' - ' || resul || ' - ' || nom_resultat || ' - (' || valor_ref1 || '-' || valor_ref2 || ')' || e' \n'; 
						END IF;
					END LOOP;
				END IF;
			END LOOP;
		ELSE
			-- si rebem idanalitica busquem els resultats d'aquella analitica: 
				searchsql := 'SELECT * FROM analitiques WHERE id pacient = ' || idpacient || ' AND idanalitica = ' || idanalitica || ';';
				-- ~ FOR resultat_search IN EXECUTE(searchsql) LOOP
					-- ~ IF resultat_search IS NULL THEN
						-- ~ resultat_final := '2';
					-- ~ ELSE
						-- ~ data_analitica := resultat_search.dataanalitica;
						-- ~ searchsql := 'SELECT * FROM analitiques WHERE idpacient = ' || idpacient || ' AND dataanalitica <= ' || data_analitica || ';';
						-- ~ FOR dades1 IN EXECUTE(searchsql) LOOP
							-- ~ id_analitica := dades1.idanalitica;
				-- ~ END IF;
		END IF;
	END IF;
RETURN resultat_final;
END;
$BODY$
LANGUAGE 'plpgsql';

select informe_historial(2);
select informe_historial(3);


CREATE OR REPLACE FUNCTION InformeHistorial(idpacient bigin, idanalitica bigint default NULL)
RETURNS TEXT
AS
$BODY$
DECLARE
	searchsql text;
	dades record;
	trobat boolean := False;
	resultat_final text;
	analitica bigint;
	
BEGIN
	searchsql := 'SELECT * FROM pacients WHERE 	idpacient = ' || idpacient || ';';
	FOR dades IN EXECUTE(searchsql) LOOP
		trobat := True;
	END LOOP;
	
	IF NOT trobat THEN
		resultat_final := '4';
	END IF;
	
	trobat := False;
	
	IF idanalitica IS NULL THEN 
		searchsql := 'SELECT * FROM analitiques WHERE idpacient = ' || idpacient || ' ORDER BY dataanalitica desc limit 1;';
		
		FOR dades IN EXECUTE(searchsql) LOOP
			trobat := True;
			analitica := dades.idanalitica;
		END LOOP;
		
		IF NOT trobat THEN
			resultat_final := '5';
		END IF;
	ELSE
		searchsql := 'SELECT * FROM analitiques WHERE idpacient = ' || idpacient || ' AND idanalitica = ' || idanalitica || ';';
		
		FOR dades IN EXECUTE(searchsql) LOOP
			trobat := True;
			analitica := dades.idanalitica;
		END LOOP;
		
		IF NOT trobat THEN
			resultat_final := '6';
		END IF;
	END IF;
		
END;
$BODY$
LANGUAGE 'plpgsql';





