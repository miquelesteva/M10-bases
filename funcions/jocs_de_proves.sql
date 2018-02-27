-- ~ JOC DE PROVES: 

-- ~ VALORAR RESULTAT: 

-- ~ select valorar_res(1,1,'99'); -- normal
-- ~ select valorar_res(2,1,'101'); -- patologic
-- ~ select valorar_res(2,1,'115'); -- panic
-- ~ select valorar_res(8,4,'Negatiu'); -- No patologic
-- ~ select valorar_res(8,4,'Positiu'); -- Patologic
-- ~ select valorar_res(3,1000,'88'); -- no existeix el pacient

-- ~ VALORAR AMB ID RESULTAT

-- ~ select valorar_idresultat(1);
-- ~ select valorar_idresultat(2);

-- ~ RESULTAT ANALITIQUES

-- ~ select resultats_analitiques_pacient(1,2);
-- ~ select resultats_analitiques_pacient(4,6);

-- ~ INSERT RESULTATS

-- ~ select insert_resultats(3,2,'1');
-- ~ select insert_resultats(3,2,'0');

-- ~ VALORAR RESULTAT AMB SEXE I DATA NAIXEMENT

select valorar_res(10600, 2, '80'); -- No patologic
select valorar_res(10600, 4, '86'); -- Patologic
select valorar_res(10600, 4, '40'); -- Panic
select valorar_res(10600, 80, '40'); -- No existeix pacient
select valorar_res(11600, 2, '40'); -- No existeix provatecnica

-- ~ TRIGGER REVISIÓ DE RESULTATS PATOLOGICS O PANIC

select revisio_resultats(1, 1, 10500, '99');
select revisio_resultats(2, 1, 10600, '101');
select revisio_resultats(3, 2, 10600, '155');
