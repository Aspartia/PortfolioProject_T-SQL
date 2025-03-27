/*
GROUP BY, 
GROUP BY GROUPING SETS,
Group by rollup, 
Group by cube
GROUP BY GROUPING SETS (cube(), rollup())
*/



/*6. K�sz�ts�nk list�t arr�l, hogy �gyfelenk�nt (LOGIN), azon bel�l sz�ll�t�si m�donk�nt h�ny megrendel�s t�rt�nt! 
		a. A lista tartalmazza a r�sz�sszegeket �s a v�g�sszeget is! 
		b. Haszn�ljuk a ROLLUP z�rad�kot! a rollup olyan mint a groupby, csak t�bb oszlopra vonatkozik*/
	select [Login], szall_mod, count(*) as 'Megrendel�sek sz�ma' from rendeles group by rollup([Login], szall_mod);
	
	-- ------------------------------------------------------------
	SELECT GROUPING_ID([Login], SZALL_MOD) AS 'GroupingID',
	CASE WHEN GROUPING([Login]) = 1 THEN '�SSZ_�gyf�l' 
			ELSE [Login] 
		END AS '[Login]',
	CASE WHEN GROUPING(SZALL_MOD) = 1 THEN '�SSZ_Sz�ll' 
			ELSE SZALL_MOD 
		END AS 'SZALL_MOD',
		COUNT(*) AS '�gyfelenk�nt/Sz�ll�t�si m�donk�nt DB'
	FROM Rendeles
	GROUP BY rollup([Login],SZALL_MOD); 

	-- ------------------------------------------------------------
	SELECT GROUPING_ID([Login], FIZ_MOD) AS 'GroupingID',
		IIF(GROUPING([Login])=1 /*felt�tel*/,'�SSZESEN' /*ha igaz*/,
		CAST([Login] AS nvarchar(10))/*ha hamis*/) AS '�gyf�lazonos�t�',
			(
			CASE GROUPING_ID([Login], FIZ_MOD)
			WHEN 0 THEN FIZ_MOD
			WHEN 1 THEN '*�sszes Fizet�si m�d*'
			WHEN 3 THEN '�sszesen'
			END
			) as 'FIZ_MOD', 
		COUNT(*) as '�gyfelenk�nt/Sz�ll�t�si m�donk�nt DB'
		FROM Rendeles
		GROUP BY grouping sets (ROLLUP([Login], FIZ_MOD));


/*7. K�sz�ts�nk list�t a term�kek sz�m�r�l a k�vetkez� csoportos�t�si szempontok szerint: kateg�ria azonos�t�, rakt�rk�d, rakt�rk�d+mennyis�gi egys�g! 
		a. A list�t sz�rj�k azokra a csoportokra, ahol a term�kek sz�ma legal�bb 6!*/
	select KAT_ID, RAKTAR_KOD, megys, count(*) as 'DB' from termek group by grouping sets ((KAT_ID),(RAKTAR_KOD), (RAKTAR_KOD,megys)) having count(*) >= 6 order by 'DB'; 

		
/*8. K�sz�ts�nk list�t az egyes term�kkateg�ri�kban l�v� term�kek sz�m�r�l! 
		a. El�g megjelen�teni a kateg�ri�k azonos�t�it �s a darabsz�mokat! 
		b. A lista megfelel�en jel�lve tartalmazza a v�g�sszeget is! 
		c. Az oszlopokat nevezz�k el �rtelemszer�en!
		d. A list�t rendezz�k a darabsz�m szerint n�vekv� sorrendbe!*/

		select kat_id, count(kat_id) 'DBsz�m' from termek group by grouping sets (KAT_ID, ()) order by 'DBsz�m'; 
		select kat_id as 'azonos�t�', count(*) as 'db_sz�m' from Termek group by rollup(KAT_ID) order by 2; 

		
    -- -----------------------------------------------------------------
		select iif(Grouping_ID(kat_id)=1,'V�g�sszeg', 
		cast(kat_id as nvarchar(5))) as 'azonos�to', 
		count(*) as 'db_sz�m' 
		from Termek group by rollup(KAT_ID) order by 2;

    -- -----------------------------------------------------------------

		SELECT CASE WHEN GROUPING(KAT_ID) = 1 THEN 'v�g�sszeg' 
			ELSE CAST(KAT_ID as nvarchar(5))
			END AS 'KAT_ID',
			COUNT(*) AS 'db_sz�m'
		from Termek
		group by rollup(KAT_ID) order by 'db_sz�m'; 

/*9. K�sz�ts�nk list�t az �gyfelek sz�m�r�l sz�let�si �v szerint, azon bel�l nem szerinti bont�sban! 
		a. A lista megfelel�en jel�lve tartalmazza a r�sz�sszegeket �s a v�g�sszeget is! 
		b. Az oszlopoknak adjunk nevet �rtelemszer�en!	*/

		select SZULEV as 'Sz�let�si �v', NEM as 'Nem',count(*) as '�gyfelek sz�ma' from ugyfel group by grouping sets(cube(SZULEV,NEM)) order by 3;

		-- --------------------------------------------------------------------------------------------------------
		SELECT IIF(GROUPING(SZULEV)=1,'TOTAL', CAST(SZULEV AS nvarchar(5))) AS 'Sz�let�si �v',
			grouping_id(SZULEV, NEM) AS 'GroupingID',
			(
			CASE GROUPING_ID(SZULEV, NEM)
			WHEN 0 THEN NEM
			WHEN 1 THEN 'Mindk�t nem'
			when 2 then 
				CASE 
					WHEN NEM = 'F' THEN '�sszes f�rfi'
					WHEN NEM = 'N' THEN '�sszes n�'
					-- ELSE '�sszes f�rfi/n�'
				END
			WHEN 3 THEN 'Total'
			END) as 'NEM',
		COUNT(*) as '�gyfelek sz�ma'
		FROM ugyfel
		GROUP BY grouping sets (rollup(SZULEV), cube(NEM)) order by 3;


/*10. K�sz�ts�nk list�t a term�kek sz�m�r�l a felvitel h�napja, azon bel�l napja szerint csoportos�tva. 
		a. A lista csak a r�sz�sszegeket �s a v�g�sszeget tartalmazza! 
		b. Az oszlopoknak adjunk megfelel� nevet! */ 

		select month(FELVITEL) as 'H�nap', day(FELVITEL) as 'Nap', count(kat_id) as 'Term�ksz�m' 
		from Termek group by rollup(month(FELVITEL), day(FELVITEL)) having Grouping_ID(month(FELVITEL), day(FELVITEL)) not in (0);

	-- ---------------------------------------------------------------------------------------------
	SELECT CASE WHEN GROUPING(month(FELVITEL)) = 1 THEN 'V�g�sszeg' 
	ELSE CAST(month(FELVITEL) as nvarchar(10))
		END AS 'H�nap',
	CASE WHEN GROUPING(day(FELVITEL)) = 1 THEN 'R�sz�sszeg' 
			ELSE cAST(day(FELVITEL) as nvarchar(10))
		END AS 'Nap',
		COUNT(*) AS 'Term�ksz�m'
	FROM Termek
	GROUP BY rollup(month(FELVITEL), day(FELVITEL))
	having Grouping_ID(month(FELVITEL), day(FELVITEL)) not in (0); 

	-- ---------------------------------------------------------------------------------------------
	SELECT IIF(GROUPING(month(FELVITEL)) = 1, '�ssz_h�nap', CAST(month(FELVITEL) AS nvarchar(10))) AS 'H�nap',
		CASE 
			GROUPING_ID(month(FELVITEL), day(FELVITEL))
			WHEN 0 THEN CAST(day(FELVITEL) AS nvarchar(10))
			WHEN 1 THEN 
				-- DATENAME(MONTH, DATEADD(MONTH, month(FELVITEL) - 1, '2000-01-01')) + ' h�nap �sszes'
				DATENAME(MONTH, DATEFROMPARTS(2000, MONTH(FELVITEL), 1)) + ' h�nap �sszes'
			WHEN 3 THEN 'Total'
		END AS 'Nap',
		COUNT(*) AS 'Term�ksz�m'
	FROM 
		Termek
	GROUP BY 
		ROLLUP(month(FELVITEL), day(FELVITEL)) having Grouping_ID(month(FELVITEL), day(FELVITEL)) not in (0);

	
/*11. K�sz�ts�nk list�t �ves bont�sban norbert2 azonos�t�j� �gyf�l rendel�seinek �rt�k�r�l! 
		a. A lista megfelel�en jel�lve tartalmazza a v�g�sszeget is!
		b. Az oszlopokat nevezz�k el �rtelemszer�en!*/			
			
		select IIF(Grouping_ID(year(rendeles.rend_datum))=1,'v�g�sszeg', cast(year(rendeles.rend_datum) as nvarchar(5))) as '�v', 
		sum(Rendeles_tetel.EGYSEGAR*Rendeles_tetel.MENNYISEG) as 'Rendel�sek �rai' 
		from Rendeles join Rendeles_tetel on rendeles.sorszam = Rendeles_tetel.SORSZAM 
		where [Login] = 'norbert2' group by grouping sets(year(rendeles.rend_datum),());
			
				

/*12. K�sz�ts�nk list�t sz�ll�t�si d�tumonk�nt, azon bel�l sz�ll�t�si m�donk�nt az egyes rendel�sek �sszmennyis�g�r�l! 
		a. Csak azokat a term�keket vegy�k figyelembe, amelyek mennyis�gi egys�ge db! 
		b. A list�t sz�rj�k �gy, hogy az csak a r�sz�sszeg sorokat �s a v�g�sszeget tartalmazza!*/

	select Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD, SUM(Rendeles_tetel.EGYSEGAR*Rendeles_tetel.MENNYISEG) as 'Rendel�sek �sszmennyis�ge' 
	from Rendeles join Rendeles_tetel on Rendeles.SORSZAM = Rendeles_tetel.SORSZAM join Termek on termek.termekkod=Rendeles_tetel.termekkod 
	where Termek.MEGYS = 'db' group by rollup(Rendeles.SZALL_DATUM,Rendeles.SZALL_MOD) having Grouping_ID(Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD) in (1,3);																																												-- �gy �rtend� hogy az IN() az egy csom� OR()
	
-- ------------------------------------------------------------------------------------------------------------
		SELECT IIF(GROUPING(Rendeles.SZALL_DATUM)=1,'V�g�sszeg', CAST(Rendeles.SZALL_DATUM AS nvarchar(10))) AS 'Sz�ll�t�s d�tuma', 
			(
				CASE GROUPING_ID(Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD)
				WHEN 0 THEN Rendeles.SZALL_MOD
				WHEN 1 THEN 'R�sz�sszeg'
				WHEN 3 THEN 'V�g�sszeg'
				END) as 'SZALL_MOD',
			COUNT(*) as 'Rendel�sek �sszmennyis�ge'
			FROM Rendeles join Rendeles_tetel on Rendeles.SORSZAM = Rendeles_tetel.SORSZAM join Termek on termek.termekkod=Rendeles_tetel.termekkod 
			where Termek.MEGYS = 'db' group by rollup(Rendeles.SZALL_DATUM,Rendeles.SZALL_MOD) having Grouping_ID(Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD) in (1,3);	


/*13. K�sz�ts�nk list�t a term�kek �tlagos lista�rair�l! 
		a. A lista legyen csoportos�tva a k�vetkez� szempontok alapj�n: kateg�rian�v, kateg�rian�v + rakt�rn�v 
		b. A lista tartalmazzon v�g�sszeget (az �tlagos �rat minden term�kre) is! 
		c. Az �tlagos �rt�ke max. k�t tizedesjeggyel legyen megjelen�tve!*/

		select Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV, FORMAT(AVG(Termek.LISTAAR), 'N2') as '�tlag�r' 
		from Termekkategoria join termek on Termekkategoria.kat_id= Termek.KAT_ID join Raktar on Raktar.RAKTAR_KOD = Termek.RAKTAR_KOD
		group by GROUPING sets((Termekkategoria.KAT_NEV),(Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV),());

-- ------------------------------------------------------------------------------------------------------------------------

SELECT grouping_id(Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV) as 'GroupingID',
		IIF(GROUPING(Termekkategoria.KAT_NEV)=1,'V�g�sszeg', CAST(Termekkategoria.KAT_NEV AS nvarchar(20))) AS 'Term�kkateg�ria',
    (CASE GROUPING_ID(termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV)
		WHEN 0 THEN  Raktar.RAKTAR_NEV
		WHEN 1 THEN UPPER(Termekkategoria.KAT_NEV) + ' �TLAG�RA'
		WHEN 3 THEN 'V�g�sszeg'
    END ) AS 'Rakt�rn�v',
    FORMAT(AVG(Termek.LISTAAR), 'N2') AS '�tlag�r'
FROM Termekkategoria JOIN Termek ON Termekkategoria.KAT_ID = Termek.KAT_ID LEFT JOIN Raktar ON Raktar.RAKTAR_KOD = Termek.RAKTAR_KOD
GROUP BY ROLLUP(Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV);


/*14. H�ny olyan �gyf�l van, aki m�g nem rendelt semmit?
		a. Csoportos�tsuk �ket nem szerint, azon bel�l �letkor szerint! 
		b. A lista tartalmazza a r�sz�sszegeket �s a v�g�sszeget is!*/

		-- OUTER JOIN:
		select ugyfel.nem, (YEAR(GETDATE())-ugyfel.szulev) '�letkor', COUNT(ugyfel.[login]) as 'M�g nem rendelt (db)' from Ugyfel left join Rendeles on Rendeles.LOGIN = Ugyfel.LOGIN
		where rendeles.sorszam is null group by rollup(ugyfel.nem, (YEAR(GETDATE())-ugyfel.szulev));
		
		--NOT IN azonosak a kulcsnevek eset�n:
		select nem, (YEAR(GETDATE())-szulev) AS '�letkor', COUNT(*) as 'M�g nem rendelt (db)' from Ugyfel
		where [Login] not in (select [login] from rendeles) group by rollup(nem, (YEAR(GETDATE())-szulev));

		-- -----------------------------------------------------------------------------------
		SELECT 
			IIF(GROUPING(nem) = 1, 'V�g�sszeg', CAST(nem AS nvarchar(10))) AS 'Nem',
			CASE 
				WHEN GROUPING(nem) = 1 AND GROUPING(szulev) = 1 THEN 'V�g�sszeg'
				WHEN GROUPING(szulev) = 1 THEN 'R�sz�sszeg'
				ELSE CAST(YEAR(GETDATE()) - szulev AS nvarchar(10))
			END AS '�letkor',
			COUNT(*) AS 'M�g nem rendelt (db)'
		FROM Ugyfel
		WHERE [Login] NOT IN (SELECT [login] FROM rendeles)
		GROUP BY ROLLUP(nem, szulev);




