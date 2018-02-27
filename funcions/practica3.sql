-- Pràctica 3.

--2. Escriure una funció per determinar si un resultat és normal, no-normal(patològic) o pànic. 
--La funció no tindrà en compte el sexe i l'edat del pacient (de moment). La funció rebrà el codi
--de la prova, el codi del pacient i el resultat i retornarà un 1(normal), un 2(patològic) o un 3(pànic).

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
	
BEGIN
	searchsql_pacient := 'SELECT idpacient FROM pacients WHERE idpacient = ' || idpacient || ';'; 
	EXECUTE(searchsql_pacient) INTO resultat_search;
	-- No existeix el pacient:
	IF resultat_search IS NULL THEN
		resultat_final := '4';
	ELSE
		searchsql_pacient := 'SELECT * FROM provestecnica WHERE idprovatecnica = ' || idprovatecnica || ';';
		FOR dades_prova IN EXECUTE(searchsql_pacient) LOOP

			min_pat := dades_prova.minpat;
			max_pat := dades_prova.maxpat;
			min_panic := dades_prova.minpan;
			max_panic := dades_prova.maxpan;
			resultat_con := resultats;
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
			-- ~ END IF;
		END LOOP;				
	END IF;
RETURN resultat_final;
END;
$BODY$
LANGUAGE 'plpgsql';


-------------------------------------------------------------------------------------------------------

select valorar_res(1,1,'99'); -- normal
select valorar_res(2,1,'101'); -- patologic
select valorar_res(2,1,'115'); -- panic
select valorar_res(3,1000,'88'); -- no existeix el pacient


-- ~ 3. Escriure una altra funció que rebi un id_resultat de la taula resultats i cridi a la funció anterior per determinar 
-- ~ la patologia del resultat i retornar un 1(normal), un 2(patològic) o un 3(pànic).
		-- ~ 3.1 Buscar provatecnica
		-- ~ 3.2 Buscar pacient (buscar idanalitica, anar a la taula analitiques i mirar si existeix)
		-- ~ 3.3 Buscar resultats
		-- ~ 3.4 Cridar la funció valorar_res. 
		
CREATE OR REPLACE FUNCTION valorar_idresultat(idresultat bigint)
RETURNS TEXT
AS
$BODY$

DECLARE
	searchsql text;
	resultat_search record;
	dades_resultat record;
	dades_analitica record;
	id_analitica bigint;
	id_provatecnica bigint;
	id_pacient bigint;
	resultat varchar;
	crida_funcio varchar;
	resultat_final varchar;
	
BEGIN
	searchsql := 'SELECT * FROM resultats WHERE idresultat = ' || idresultat || ';';
	EXECUTE(searchsql) INTO resultat_search;
	-- No existeix el idresultat:
	IF resultat_search IS NULL THEN
		resultat_final := '4';
	ELSE
	-- ~ FOR dades_resultat IN resultat_search LOOP
		id_provatecnica := resultat_search.idprovatecnica;
		id_analitica := resultat_search.idanalitica;
		resultat := resultat_search.resultats;

		searchsql := 'SELECT * FROM analitiques WHERE idanalitica = ' || id_analitica || ';';
		EXECUTE(searchsql) INTO resultat_search;
		-- No existeix el idanalitica: 
		IF resultat_search IS NULL THEN
			resultat_final := '4';
		ELSE
			-- ~ FOR dades_analitica IN resultat_search LOOP
			id_pacient := resultat_search.idpacient;
			-- ~ END LOOP;	
			resultat_final := valorar_res(id_provatecnica, id_pacient, resultat);
		END IF;
		-- ~ END LOOP;
	END IF;
RETURN resultat_final;

END;
$BODY$
LANGUAGE 'plpgsql';

select valorar_idresultat(1);
select valorar_idresultat(2);

-- ~ 4. Escriure una funció que examini tots els resultats d'una analítica d'un pacient, rebrà
 -- ~ l’id del pacient i el codi d’analítica (si no rep el codi d’analítica s'agafarà l'última
  -- ~ analítica que s'hagi fet el pacient) i retorni una cadena amb :
  -- ~ pacient#data#codi_prova#nom_prova#resultat#valoració|
  -- ~ pacient#data#codi_prova#nom_prova#resultat#valoració|
  -- ~ pacient#data#codi_prova#nom_prova#resultat#valoració|

CREATE OR REPLACE FUNCTION resultats_analitiques_pacient(idpacient bigint, idanalitica bigint)
RETURNS TEXT
AS
$BODY$

DECLARE
	search_analitiques text;
	resultat_search record;
	search_nom_pac text;
	search_resultat text;
	search_cataleg text;
	search_prova text;
	dades_analitica record;
	data_analitica timestamp;
	dades record;
	dades_prova record;
	dades_cataleg record;
	codi_prova bigint;
	nomprova text;
	resultat text;
	id_resultat bigint;
	id_prova bigint;
	resultat_final text;
	nom text;
	cognoms text;
	valoracio text;
BEGIN
	-- busquem el nom i cognoms del pacien
	search_nom_pac := 'SELECT nom,cognoms FROM pacients WHERE idpacient = ' || idpacient || ';';
	EXECUTE(search_nom_pac) INTO resultat_search;
	nom := resultat_search.nom;
	cognoms := resultat_search.cognoms;
	-- ~ RAISE NOTICE 'nom : %',nom;
	-- ~ RAISE NOTICE 'cognom : %',cognoms;
	-- Si no troba el nom, finalitzem:
	IF nom IS NULL THEN
		resultat_final := '1';
	ELSE
	-- Si no rebem idanalitica busquem l'última del pacient:
		IF idanalitica IS NULL THEN
			search_analitiques := 'SELECT * FROM analitiques WHERE idpacient = ' || idpacient || ' ORDER BY dataanalitica DESC LIMIT 1;';
			EXECUTE(search_analitiques) INTO resultat_search;
			data_analitica := resultat_search.dataanalitica;
			-- ~ RAISE NOTICE 'data: %',data_analitica;
		ELSE
			search_analitiques := 'SELECT * FROM analitiques WHERE idpacient = ' || idpacient || ' AND idanalitica = ' || idanalitica || ';';
			FOR dades_analitica IN EXECUTE(search_analitiques) LOOP
				data_analitica := dades_analitica.dataanalitica;
				-- ~ RAISE NOTICE 'data: %',data_analitica;
			END LOOP;
			search_resultat := 'SELECT * FROM resultats WHERE idanalitica = ' || idanalitica || ';';
			FOR dades IN EXECUTE(search_resultat) LOOP
				codi_prova := dades.idprovatecnica;
				resultat := dades.resultats;
				id_resultat := dades.idresultat;
				-- ~ RAISE NOTICE 'codi : %',codi_prova;
				-- ~ RAISE NOTICE 'resultat : %',resultat;
				-- ~ RAISE NOTICE 'id_resultat : %',id_resultat;
				search_prova := 'SELECT * FROM provestecnica WHERE idprovatecnica = ' || codi_prova || ';';
				FOR dades_prova IN EXECUTE(search_prova) LOOP
					id_prova := dades_prova.idprova;
					-- ~ RAISE NOTICE 'id_prova: %', id_prova;
				END LOOP;
				search_cataleg := 'SELECT * FROM catalegproves WHERE idprova = ' || id_prova || ';';
				FOR dades_cataleg IN EXECUTE(search_cataleg) LOOP
					nomprova := dades_cataleg.nom_prova;
					-- ~ RAISE NOTICE 'nom prova: %',nomprova;
				END LOOP;
				valoracio := valorar_idresultat(id_resultat);
				-- ~ RAISE NOTICE 'valoracio: %',valoracio;
				resultat_final := nom || ' ' || cognoms || ' # ' || data_analitica || ' # ' || id_prova || ' # ' || nomprova || ' # ' || resultat || ' # ' || valoracio || e' \n';
			--	resultat_final := resultat_final || '' || nom || ' ' || cognoms || '#' || data_analitica || '#' || id_prova || '#' || nomprova || '#' || resultat || '#' || valoracio || e'\n';
				-- ~ RAISE NOTICE 'resultat final: %',resultat_final;
			END LOOP;
		END IF;
	END IF;
RETURN resultat_final;
EXCEPTION WHEN others THEN
	RETURN '2';
END;
$BODY$
LANGUAGE 'plpgsql';

select resultats_analitiques_pacient(1,2);
select resultats_analitiques_pacient(4,6);

-- ~ 5. Escriure una script per ser executada des del cron per omplir la taula ResultatsAnalitiques 
-- ~ cada cop que arribin noves dades al directori /tmp/resultats.
 -- ~ Les dades que arribin seran registres amb idanalítica, idprovatecnica i resultat.
-- ~ Aquesta script guardarà els resultats en fitxers de log. Per cada execució de l’script es guardarà 
-- ~ el resultat en un fitxer de log. El resultat per el log serà :

-- ~ data – hora – execució correcta
-- ~ data – hora – error amb idanalítica-idprovatectnica-resultat, idanalítica-idprovatectnica-resultat, ...
-- ~ data – hora – execució correcta
-- ~ data – hora – error amb idanalítica-idprovatectnica-resultat
-- ~ data – hora – error amb idanalítica-idprovatectnica-resultat, idanalítica-idprovatectnica-resultat, ...
-- ~ ...

CREATE OR REPLACE FUNCTION insert_resultats(idanalitica bigint, idprovatecnica bigint, resultats varchar)
RETURNS TEXT
AS
$BODY$

DECLARE
	sentencia text;
	searchsql text;
	dades_analitica text;
	dades_resultat record;
	resultat_final int := 0;
	data_resultat timestamp;
	select_curr_time text;
	resultat_inicial text;
BEGIN
	searchsql := 'SELECT * FROM analitiques WHERE idanalitica = ' || idanalitica || ';';
	-- ~ RAISE NOTICE 'search: %',searchsql;
	EXECUTE(searchsql) INTO dades_analitica;
	-- ~ RAISE NOTICE 'execute: %',dades_analitica;
	IF dades_analitica IS NULL THEN
		resultat_final := 1;
	ELSE
		searchsql := 'SELECT * FROM resultats WHERE idanalitica = ' || idanalitica || ' and idprovatecnica = ' || idprovatecnica || ';';
		FOR dades_resultat IN EXECUTE(searchsql) LOOP
			resultat_inicial := dades_resultat.resultats;
		END LOOP;

		select_curr_time := 'SELECT localtimestamp;';
		EXECUTE(select_curr_time) INTO data_resultat;
		IF dades_resultat IS NULL THEN
			sentencia := 'INSERT INTO resultats (idanalitica, idprovatecnica, resultats, dataresultat) VALUES (' || idanalitica || ',' || idprovatecnica || ',''' 
			|| resultats || ''',''' || data_resultat || ''')';
			-- ~ RAISE NOTICE 'Sentencia: %',sentencia;
			EXECUTE(sentencia);
		ELSE
			IF resultat_inicial != resultats THEN
				sentencia := 'UPDATE resultats SET resultats = ''' || resultats || ''', dataresultat = ''' || data_resultat || ''' WHERE idanalitica = ' || idanalitica || ' AND idprovatecnica = ' || idprovatecnica || ';';
			-- ~ RAISE NOTICE 'Sentencia: %',sentencia;
				EXECUTE(sentencia);
			ELSE
				resultat_final := 2;
			END IF;
		END IF;
	END IF;
RETURN resultat_final;
EXCEPTION
	WHEN unique_violation THEN RETURN 5; --'ERROR, UNIQUE VIOLATION';
	WHEN not_null_violation THEN RETURN 6; --'ERROR, NOT NULL VIOLATION';
	WHEN foreign_key_violation THEN RETURN 7; --'FOREIGN KEY VIOLATION';
	WHEN check_violation THEN RETURN 8; --'ERROR, CHECK VIOLATION';
	WHEN others THEN RETURN 15; --'ANOTHER ERROR';

END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE;

select insert_resultats(3,2,'1');
select insert_resultats(3,2,'0');

