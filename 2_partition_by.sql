
/*Partíciók, ablakok 
• beágyazott Select
• beágyazott lekérdezés, mint tábla
• OVER(PARTITION BY ...) 
 	OVER(PARTITION BY kifejezés* ORDER BY kifejezés*
	ROWS | RANGE BETWEEN kezdõpont AND végpont)  --group by alternítiv formája

ANALITIKUS FÜGGVÉNYEK:
• ROW_NUMBER(), RANK(), DENSE_RANK()
• LAG() és LEAD()
• FIRST_VALUE(), LAST_VALUE()
• NTILE()

*/


/*2.Átlagosan hány termék van készleten kategóriánként (KAT_ID), raktáranként (RAKTAR_KOD), illetve mennyiségi egységenként? 
(szempontonként külön-külön) 
a. Az átlagot kerekítsük egészre! 
b. A feladatot egy lekérdezéssel oldja meg! */ 

	select kat_id, raktar_kod, megys, round(avg(keszlet),0)'Átlag készlet' from termek group by grouping sets((kat_id), (raktar_kod), (megys)); 

	-- ----------------------------------------------------------------------------------------------------------------------------------------------
	SELECT 
		CASE WHEN GROUPING(kat_id) = 1 THEN '-' ELSE CAST(kat_id AS NVARCHAR(10)) END AS 'Kategória ID',
		CASE WHEN GROUPING(raktar_kod) = 1 THEN '-' ELSE CAST(raktar_kod AS NVARCHAR(10)) END AS 'Raktár kód',
		CASE WHEN GROUPING(megys) = 1 THEN '-' ELSE megys END AS 'Mennyiségi egység',
    ROUND(AVG(keszlet), 0) AS 'Átlag készlet'
	FROM termek GROUP BY GROUPING SETS ((kat_id), (raktar_kod), (megys));


/*3.Készítsünk listát a megrendelt termékek legkisebb és legnagyobb egységáráról szállítási dátum, azon belül szállítási mód szerinti bontásban! 
a. A lista csak a 2015 májusi szállításokat tartalmazza!
b. Jelenítsük meg a részösszegeket és a végösszeget is! */

	select rendeles.szall_datum, rendeles.szall_mod, min(rendeles_tetel.egysegar) 'Legkisebb egységár', max(rendeles_tetel.egysegar) 'Legnagyobb egységár'
	from termek join rendeles_tetel on termek.termekkod = rendeles_tetel.termekkod join rendeles on rendeles_tetel.sorszam= rendeles.sorszam
	where rendeles.rend_datum between '2015-05-01' and '2015-05-31' 
	group by rollup(szall_datum, szall_mod);

	-- ----------------------------------------------------------------------------------------------------------------------------------------------
	SELECT CASE WHEN GROUPING(rendeles.szall_datum) = 1 THEN '***LEGNAGYOBB***' 
        ELSE CAST(rendeles.szall_datum AS NVARCHAR(10))
    END AS 'Szállítási dátum',
    CASE WHEN GROUPING(rendeles.szall_mod) = 1 THEN '**Legnagyobb Ár**' 
        ELSE CAST(rendeles.szall_mod AS NVARCHAR(10))
    END AS 'Szállítási mód',
    MIN(rendeles_tetel.egysegar) AS 'Legkisebb egységár', 
    MAX(rendeles_tetel.egysegar) AS 'Legnagyobb egységár'
	FROM termek JOIN rendeles_tetel ON termek.termekkod = rendeles_tetel.termekkod JOIN rendeles ON rendeles_tetel.sorszam = rendeles.sorszam
	WHERE rendeles.rend_datum BETWEEN '2015-05-01' AND '2015-05-31' 
	GROUP BY ROLLUP (rendeles.szall_datum, rendeles.szall_mod);


/*4.Készítsünk csoportot a termékek listaára alapján a következõk szerint: 
Az "olcsó" termékek legyenek azok, amelyek listaára 3000 alatt van. A "drága" termékek legyenek az 5000 felettiek, a többi legyen "közepes". 
a. Listázzuk az egyes csoportokat, és a csoportokba tartozó termékek darabszámát! 
b. A lista jelenítse meg a végösszeget is!*/

SELECT 
		CASE WHEN GROUPING(Kategoria) = 1 THEN 'Végösszeg'
		ELSE Kategoria
		END AS 'Kategória',
		COUNT(*) AS 'Darabszám'
FROM ( SELECT 
        CASE WHEN listaar < 3000 THEN 'Olcsó'  
            WHEN listaar > 5000 THEN 'Drága' 
            ELSE 'Közepes'                   
        END AS Kategoria
    FROM termek) AS subquery
GROUP BY ROLLUP(Kategoria);

-- CTE + NTILE()
WITH PriceCategories AS (SELECT listaar, NTILE(3) OVER(ORDER BY listaar) AS 'Árkategória' FROM termek)
SELECT 
    CASE WHEN GROUPING(Árkategória) = 1 THEN 'Végösszeg'
        ELSE CAST(Árkategória AS NVARCHAR(10)) 
		END AS 'Árkategóriák (1,2,3)', 
    COUNT(*) AS 'Darabszám'
FROM PriceCategories 
GROUP BY ROLLUP(Árkategória);


/*5.Listázzuk a rendelési tételek számát raktáranként éves bontásban! 
a. A listában a raktár neve, az év és a darabszám jelenjen meg! 
b. A lista jelenítse meg a részösszegeket és a végösszeget is!
c. A végösszeget megfelelõen jelöljük! 
d. Az oszlopokat nevezzük el értelemszerûen!*/

select raktar.RAKTAR_NEV, year(rendeles.rend_datum) as 'Év', count(*) as 'dbszam' from raktar join termek on raktar.raktar_kod = termek.raktar_kod 
			join rendeles_tetel on termek.termekkod = rendeles_tetel.termekkod
			join rendeles on rendeles_tetel.sorszam=rendeles.sorszam
			group by rollup(raktar.raktar_nev, year(rendeles.rend_datum));
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------
	SELECT
	CASE WHEN GROUPING(raktar.raktar_nev) = 1 THEN 'Végösszeg' 
        ELSE CAST(raktar.raktar_nev AS NVARCHAR(10))
		END AS 'Raktárnév',
    CASE WHEN GROUPING(year(rendeles.rend_datum)) = 1 THEN 'Részösszeg' 
        ELSE CAST(year(rendeles.rend_datum) AS NVARCHAR(10))
		END AS 'Év',
	count(rendeles_tetel.sorszam) as 'RendTételSzáma'
	from raktar join termek on raktar.raktar_kod = termek.raktar_kod join rendeles_tetel on termek.termekkod = rendeles_tetel.termekkod join rendeles on rendeles_tetel.sorszam=rendeles.sorszam 
	group by rollup(raktar.raktar_nev, year(rendeles.rend_datum)); 


/*6.Készítsünk listát az ügyfelek adatairól név szerinti sorrendben. 
a. Minden sorban jelenjen meg a sorrend szerint elõzõ, illetve következõ ügyfél neve is.
b. Ha nincs elõzõ vagy következõ ügyfél, akkor a 'Nincs' jelenjen meg!*/

Select *, (LAG(nev,1,'Nincs') over(order by nev)) as 'Elõzõ ügyfél neve', 
			Lead(nev,1,'Nincs') over(order by nev) as 'Következõ ügyfél neve' from ugyfel;

--
SELECT nev AS 'Ügyfél neve', 
    COALESCE(LAG(nev,1) OVER (ORDER BY nev), 'Nincs') AS 'Elõzõ ügyfél',
    COALESCE(LEAD(nev,1) OVER (ORDER BY nev), 'Nincs') AS 'Következõ ügyfél'
FROM ugyfel ORDER BY nev;


 /*9.Listázzuk a termékek kódját, megnevezését, kategóriájának nevét, és listaárát. 
a. A listát egészítsük ki két új oszloppal, amelyek a kategória legolcsóbb, illetve legdrágább termékének árát tartalmazzák. 
b. A két új oszlop létrehozásánál partíciókkal dolgozzunk!*/
	
	
	SELECT KAT_ID, MIN(LISTAAR) AS 'Legolcsóbb', MAX(LISTAAR) AS 'Legdrágább' FROM termek GROUP BY KAT_ID;

	-- partitionnel:
	select TERMEKKOD, MEGNEVEZES, KAT_ID, LISTAAR, 
	first_value(LISTAAR) over(partition by KAT_ID order by LISTAAR) 'Legolcsóbb', 
	first_value(LISTAAR) over(partition by KAT_ID order by LISTAAR DESC) 'Legdrágább'
	from Termek ;


	select TERMEKKOD, MEGNEVEZES, KAT_ID, LISTAAR, 
	min(LISTAAR) over(partition by KAT_ID order by LISTAAR) 'Legolcsóbb', 
	max(LISTAAR) over(partition by KAT_ID order by LISTAAR DESC) 'Legdrágább'
	from Termek ;


/*10.Készítsünk listát a rendelésekrõl. 
A lista legyen rendezve ügyfelenként (LOGIN), azon belül a rendelés dátuma szerint.
 A listához készítsünk sorszámozást is.  
	a. A számozás login-onként, azon belül rendelési évenként kezdõdjön újra.
	b. A sorszám oszlop neve legyen Azonosító.
	A sorszám a következõ formában jelenjen meg: sorszám_év_login. Pl: 1_2015_adam1*/

	select concat(dense_rank() over(partition by [Login] order by year(rend_datum)),'_' , year(rend_datum), '_', [Login]) as 'Azonosító', * from rendeles;



/*11. Készítsünk listát a termékek adatairól listaár szerint növekvõ sorrendben!
A lista jelenítse meg két új oszlopban a sorrend szerint elõzõ, illetve következõ termék listaárát is a termék saját kategóriájában és raktárában! 
	a. Ahol nincs elõzõ vagy következõ érték, ott 0 jelenjen meg! 
	b. Az oszlopokat nevezzük el értelemszerûen!*/

	select KAT_ID,RAKTAR_KOD, LISTAAR, megnevezes, 
			LAG(listaar,1,0) over(partition by kat_id,raktar_kod order by listaar) as 'Elõzõ Érték', 
			Lead(listaar,1,0) over( partition by kat_id,raktar_kod order by listaar) as 'Következõ Érték'  
			from termek;


/*12.Listázzuk a termékek kódját, nevét és listaárát listaár szerinti sorrendben!
	 a. Vegyünk fel egy új oszlopot Mozgóátlag néven, amely minden esetben az aktuális termék az elõzõ, és a következõ termék átlagárát tartalmazza!
	 b. A mozgóátlagot kerekítsük két tizedesre!*/

	 select termekkod, megnevezes, listaar, round(avg(listaar) over(order by listaar ROWS BETWEEN 1 PRECEDING AND 1 following), 2) 'mozgóátlag'
	 from termek;

	 	 
/*13.Készítsünk listát, amely a rendelések sorszámát és a rendelés értékét tartalmazza.
A listát egészítsük ki egy új oszloppal, amely minden rendelés esetén addigi rendelések értékének összegét tartalmazza (az aktuálisat is beleértve)! 
	a. A listát rendezzük sorszám szerint növekvõ sorrendbe. 
	b. A lista ne tartalmazzon duplikált sorokat!
	c. Nevezzük el az oszlopokat értelemszerûen!*/

	SELECT sorszam, 
    SUM(egysegar * mennyiseg) AS 'Rendelések értéke', 
    SUM(SUM(egysegar * mennyiseg)) OVER (ORDER BY sorszam ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Eddigi rendelések összege'
	FROM rendeles_tetel GROUP BY sorszam ORDER BY sorszam;



/*14.Készítsünk listát a rendelési tételekrõl, amely minden sor esetén göngyölítve tartalmazza az ügyfél 
adott rendelési tételig meglévõ rendelési tételeinek összértékét! 
	a. Az új oszlop neve legyen Eddigi rendelési tételek összértéke! 
	b. Az ügyfél neve is jelenjen meg!*/

	-- az összes ügyfelét összegöngyölíti
	SELECT rendeles.[login], (rendeles_tetel.egysegar*rendeles_tetel.mennyiseg) as 'Rendelések értéke', 
	sum(rendeles_tetel.egysegar*rendeles_tetel.mennyiseg) OVER (PARTITION BY rendeles.[login] ORDER BY rendeles.sorszam 
     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Eddigi rendelési tételek összértéke'
    from rendeles_tetel join rendeles on rendeles_tetel.sorszam = rendeles.sorszam  ORDER BY rendeles.[login], rendeles.sorszam;


	-- új ügyfélnél újraindul a göngyölítés
	SELECT rendeles.[login], rendeles.sorszam, (rendeles_tetel.egysegar * rendeles_tetel.mennyiseg) AS 'Rendelések értéke', 
    SUM(rendeles_tetel.egysegar * rendeles_tetel.mennyiseg) OVER (PARTITION BY rendeles.[login] ORDER BY rendeles.sorszam, rendeles_tetel.sorszam 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Eddigi rendelési tételek összértéke'
	FROM rendeles_tetel JOIN rendeles ON rendeles_tetel.sorszam = rendeles.sorszam  ORDER BY rendeles.[login], rendeles.sorszam, rendeles_tetel.sorszam;


/*15.Készítsünk listát a termékek kódjáról, nevérõl, kategória azonosítójáról, raktár azonosítójáról és listaáráról,
valamint a termék adott szempontok szerinti rangsorokban elfoglalt helyezéseirõl. (Szempontonként külön oszlopban, a helyezéseknél növekvõ sorrendet feltételezve).
A szempontok a következõk legyenek: listaár, kategória szerinti listaár, és raktárkód szerinti listaár. 
	a. Az oszlopokat nevezzük el értelemszerûen. 
	b. A helyezések egyenlõség esetén "sûrûn" kövessék egymást.
	c. A lista legyen rendezett kategória azonosító, azon belül listaár szerint!*/

	select termekkod, megnevezes, kat_id, raktar_kod, listaar, 
		dense_rank() over (order by listaar) as 'Rangsor_Listaar'	,
		dense_rank() over (partition by kat_id order by listaar) as 'Rangsor_KAt_Listaar'	,
		dense_rank() over (partition by raktar_kod order by listaar) as 'Rangsor_RAktar_listaar'	
	from termek order by kat_id, listaar;



