/*
GROUP BY, 
GROUP BY GROUPING SETS,
Group by rollup, 
Group by cube
GROUP BY GROUPING SETS (cube(), rollup())
*/



/*6. Készítsünk listát arról, hogy ügyfelenként (LOGIN), azon belül szállítási módonként hány megrendelés történt! 
		a. A lista tartalmazza a részösszegeket és a végösszeget is! 
		b. Használjuk a ROLLUP záradékot! a rollup olyan mint a groupby, csak több oszlopra vonatkozik*/
	select [Login], szall_mod, count(*) as 'Megrendelések száma' from rendeles group by rollup([Login], szall_mod);
	
	-- ------------------------------------------------------------
	SELECT GROUPING_ID([Login], SZALL_MOD) AS 'GroupingID',
	CASE WHEN GROUPING([Login]) = 1 THEN 'ÖSSZ_Ügyfél' 
			ELSE [Login] 
		END AS '[Login]',
	CASE WHEN GROUPING(SZALL_MOD) = 1 THEN 'ÖSSZ_Száll' 
			ELSE SZALL_MOD 
		END AS 'SZALL_MOD',
		COUNT(*) AS 'ügyfelenként/Szállítási módonként DB'
	FROM Rendeles
	GROUP BY rollup([Login],SZALL_MOD); 

	-- ------------------------------------------------------------
	SELECT GROUPING_ID([Login], FIZ_MOD) AS 'GroupingID',
		IIF(GROUPING([Login])=1 /*feltétel*/,'ÖSSZESEN' /*ha igaz*/,
		CAST([Login] AS nvarchar(10))/*ha hamis*/) AS 'Ügyfélazonosító',
			(
			CASE GROUPING_ID([Login], FIZ_MOD)
			WHEN 0 THEN FIZ_MOD
			WHEN 1 THEN '*Összes Fizetési mód*'
			WHEN 3 THEN 'Összesen'
			END
			) as 'FIZ_MOD', 
		COUNT(*) as 'ügyfelenként/Szállítási módonként DB'
		FROM Rendeles
		GROUP BY grouping sets (ROLLUP([Login], FIZ_MOD));


/*7. Készítsünk listát a termékek számáról a következõ csoportosítási szempontok szerint: kategória azonosító, raktárkód, raktárkód+mennyiségi egység! 
		a. A listát szûrjük azokra a csoportokra, ahol a termékek száma legalább 6!*/
	select KAT_ID, RAKTAR_KOD, megys, count(*) as 'DB' from termek group by grouping sets ((KAT_ID),(RAKTAR_KOD), (RAKTAR_KOD,megys)) having count(*) >= 6 order by 'DB'; 

		
/*8. Készítsünk listát az egyes termékkategóriákban lévõ termékek számáról! 
		a. Elég megjeleníteni a kategóriák azonosítóit és a darabszámokat! 
		b. A lista megfelelõen jelölve tartalmazza a végösszeget is! 
		c. Az oszlopokat nevezzük el értelemszerûen!
		d. A listát rendezzük a darabszám szerint növekvõ sorrendbe!*/

		select kat_id, count(kat_id) 'DBszám' from termek group by grouping sets (KAT_ID, ()) order by 'DBszám'; 
		select kat_id as 'azonosító', count(*) as 'db_szám' from Termek group by rollup(KAT_ID) order by 2; 

		
    -- -----------------------------------------------------------------
		select iif(Grouping_ID(kat_id)=1,'Végösszeg', 
		cast(kat_id as nvarchar(5))) as 'azonosíto', 
		count(*) as 'db_szám' 
		from Termek group by rollup(KAT_ID) order by 2;

    -- -----------------------------------------------------------------

		SELECT CASE WHEN GROUPING(KAT_ID) = 1 THEN 'végösszeg' 
			ELSE CAST(KAT_ID as nvarchar(5))
			END AS 'KAT_ID',
			COUNT(*) AS 'db_szám'
		from Termek
		group by rollup(KAT_ID) order by 'db_szám'; 

/*9. Készítsünk listát az ügyfelek számáról születési év szerint, azon belül nem szerinti bontásban! 
		a. A lista megfelelõen jelölve tartalmazza a részösszegeket és a végösszeget is! 
		b. Az oszlopoknak adjunk nevet értelemszerûen!	*/

		select SZULEV as 'Születési Év', NEM as 'Nem',count(*) as 'Ügyfelek száma' from ugyfel group by grouping sets(cube(SZULEV,NEM)) order by 3;

		-- --------------------------------------------------------------------------------------------------------
		SELECT IIF(GROUPING(SZULEV)=1,'TOTAL', CAST(SZULEV AS nvarchar(5))) AS 'Születési Év',
			grouping_id(SZULEV, NEM) AS 'GroupingID',
			(
			CASE GROUPING_ID(SZULEV, NEM)
			WHEN 0 THEN NEM
			WHEN 1 THEN 'Mindkét nem'
			when 2 then 
				CASE 
					WHEN NEM = 'F' THEN 'Összes férfi'
					WHEN NEM = 'N' THEN 'Összes nõ'
					-- ELSE 'Összes férfi/nõ'
				END
			WHEN 3 THEN 'Total'
			END) as 'NEM',
		COUNT(*) as 'Ügyfelek száma'
		FROM ugyfel
		GROUP BY grouping sets (rollup(SZULEV), cube(NEM)) order by 3;


/*10. Készítsünk listát a termékek számáról a felvitel hónapja, azon belül napja szerint csoportosítva. 
		a. A lista csak a részösszegeket és a végösszeget tartalmazza! 
		b. Az oszlopoknak adjunk megfelelõ nevet! */ 

		select month(FELVITEL) as 'Hónap', day(FELVITEL) as 'Nap', count(kat_id) as 'Termékszám' 
		from Termek group by rollup(month(FELVITEL), day(FELVITEL)) having Grouping_ID(month(FELVITEL), day(FELVITEL)) not in (0);

	-- ---------------------------------------------------------------------------------------------
	SELECT CASE WHEN GROUPING(month(FELVITEL)) = 1 THEN 'Végösszeg' 
	ELSE CAST(month(FELVITEL) as nvarchar(10))
		END AS 'Hónap',
	CASE WHEN GROUPING(day(FELVITEL)) = 1 THEN 'Részösszeg' 
			ELSE cAST(day(FELVITEL) as nvarchar(10))
		END AS 'Nap',
		COUNT(*) AS 'Termékszám'
	FROM Termek
	GROUP BY rollup(month(FELVITEL), day(FELVITEL))
	having Grouping_ID(month(FELVITEL), day(FELVITEL)) not in (0); 

	-- ---------------------------------------------------------------------------------------------
	SELECT IIF(GROUPING(month(FELVITEL)) = 1, 'Össz_hónap', CAST(month(FELVITEL) AS nvarchar(10))) AS 'Hónap',
		CASE 
			GROUPING_ID(month(FELVITEL), day(FELVITEL))
			WHEN 0 THEN CAST(day(FELVITEL) AS nvarchar(10))
			WHEN 1 THEN 
				-- DATENAME(MONTH, DATEADD(MONTH, month(FELVITEL) - 1, '2000-01-01')) + ' hónap összes'
				DATENAME(MONTH, DATEFROMPARTS(2000, MONTH(FELVITEL), 1)) + ' hónap összes'
			WHEN 3 THEN 'Total'
		END AS 'Nap',
		COUNT(*) AS 'Termékszám'
	FROM 
		Termek
	GROUP BY 
		ROLLUP(month(FELVITEL), day(FELVITEL)) having Grouping_ID(month(FELVITEL), day(FELVITEL)) not in (0);

	
/*11. Készítsünk listát éves bontásban norbert2 azonosítójú ügyfél rendeléseinek értékérõl! 
		a. A lista megfelelõen jelölve tartalmazza a végösszeget is!
		b. Az oszlopokat nevezzük el értelemszerûen!*/			
			
		select IIF(Grouping_ID(year(rendeles.rend_datum))=1,'végösszeg', cast(year(rendeles.rend_datum) as nvarchar(5))) as 'Év', 
		sum(Rendeles_tetel.EGYSEGAR*Rendeles_tetel.MENNYISEG) as 'Rendelések árai' 
		from Rendeles join Rendeles_tetel on rendeles.sorszam = Rendeles_tetel.SORSZAM 
		where [Login] = 'norbert2' group by grouping sets(year(rendeles.rend_datum),());
			
				

/*12. Készítsünk listát szállítási dátumonként, azon belül szállítási módonként az egyes rendelések összmennyiségérõl! 
		a. Csak azokat a termékeket vegyük figyelembe, amelyek mennyiségi egysége db! 
		b. A listát szûrjük úgy, hogy az csak a részösszeg sorokat és a végösszeget tartalmazza!*/

	select Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD, SUM(Rendeles_tetel.EGYSEGAR*Rendeles_tetel.MENNYISEG) as 'Rendelések összmennyisége' 
	from Rendeles join Rendeles_tetel on Rendeles.SORSZAM = Rendeles_tetel.SORSZAM join Termek on termek.termekkod=Rendeles_tetel.termekkod 
	where Termek.MEGYS = 'db' group by rollup(Rendeles.SZALL_DATUM,Rendeles.SZALL_MOD) having Grouping_ID(Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD) in (1,3);																																												-- így értendõ hogy az IN() az egy csomó OR()
	
-- ------------------------------------------------------------------------------------------------------------
		SELECT IIF(GROUPING(Rendeles.SZALL_DATUM)=1,'Végösszeg', CAST(Rendeles.SZALL_DATUM AS nvarchar(10))) AS 'Szállítás dátuma', 
			(
				CASE GROUPING_ID(Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD)
				WHEN 0 THEN Rendeles.SZALL_MOD
				WHEN 1 THEN 'Részösszeg'
				WHEN 3 THEN 'Végösszeg'
				END) as 'SZALL_MOD',
			COUNT(*) as 'Rendelések összmennyisége'
			FROM Rendeles join Rendeles_tetel on Rendeles.SORSZAM = Rendeles_tetel.SORSZAM join Termek on termek.termekkod=Rendeles_tetel.termekkod 
			where Termek.MEGYS = 'db' group by rollup(Rendeles.SZALL_DATUM,Rendeles.SZALL_MOD) having Grouping_ID(Rendeles.SZALL_DATUM, Rendeles.SZALL_MOD) in (1,3);	


/*13. Készítsünk listát a termékek átlagos listaárairól! 
		a. A lista legyen csoportosítva a következõ szempontok alapján: kategórianév, kategórianév + raktárnév 
		b. A lista tartalmazzon végösszeget (az átlagos árat minden termékre) is! 
		c. Az átlagos értéke max. két tizedesjeggyel legyen megjelenítve!*/

		select Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV, FORMAT(AVG(Termek.LISTAAR), 'N2') as 'ÁtlagÁr' 
		from Termekkategoria join termek on Termekkategoria.kat_id= Termek.KAT_ID join Raktar on Raktar.RAKTAR_KOD = Termek.RAKTAR_KOD
		group by GROUPING sets((Termekkategoria.KAT_NEV),(Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV),());

-- ------------------------------------------------------------------------------------------------------------------------

SELECT grouping_id(Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV) as 'GroupingID',
		IIF(GROUPING(Termekkategoria.KAT_NEV)=1,'Végösszeg', CAST(Termekkategoria.KAT_NEV AS nvarchar(20))) AS 'Termékkategória',
    (CASE GROUPING_ID(termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV)
		WHEN 0 THEN  Raktar.RAKTAR_NEV
		WHEN 1 THEN UPPER(Termekkategoria.KAT_NEV) + ' ÁTLAGÁRA'
		WHEN 3 THEN 'Végösszeg'
    END ) AS 'Raktárnév',
    FORMAT(AVG(Termek.LISTAAR), 'N2') AS 'ÁtlagÁr'
FROM Termekkategoria JOIN Termek ON Termekkategoria.KAT_ID = Termek.KAT_ID LEFT JOIN Raktar ON Raktar.RAKTAR_KOD = Termek.RAKTAR_KOD
GROUP BY ROLLUP(Termekkategoria.KAT_NEV, Raktar.RAKTAR_NEV);


/*14. Hány olyan ügyfél van, aki még nem rendelt semmit?
		a. Csoportosítsuk õket nem szerint, azon belül életkor szerint! 
		b. A lista tartalmazza a részösszegeket és a végösszeget is!*/

		-- OUTER JOIN:
		select ugyfel.nem, (YEAR(GETDATE())-ugyfel.szulev) 'életkor', COUNT(ugyfel.[login]) as 'Még nem rendelt (db)' from Ugyfel left join Rendeles on Rendeles.LOGIN = Ugyfel.LOGIN
		where rendeles.sorszam is null group by rollup(ugyfel.nem, (YEAR(GETDATE())-ugyfel.szulev));
		
		--NOT IN azonosak a kulcsnevek esetén:
		select nem, (YEAR(GETDATE())-szulev) AS 'Életkor', COUNT(*) as 'Még nem rendelt (db)' from Ugyfel
		where [Login] not in (select [login] from rendeles) group by rollup(nem, (YEAR(GETDATE())-szulev));

		-- -----------------------------------------------------------------------------------
		SELECT 
			IIF(GROUPING(nem) = 1, 'Végösszeg', CAST(nem AS nvarchar(10))) AS 'Nem',
			CASE 
				WHEN GROUPING(nem) = 1 AND GROUPING(szulev) = 1 THEN 'Végösszeg'
				WHEN GROUPING(szulev) = 1 THEN 'Részösszeg'
				ELSE CAST(YEAR(GETDATE()) - szulev AS nvarchar(10))
			END AS 'Életkor',
			COUNT(*) AS 'Még nem rendelt (db)'
		FROM Ugyfel
		WHERE [Login] NOT IN (SELECT [login] FROM rendeles)
		GROUP BY ROLLUP(nem, szulev);




