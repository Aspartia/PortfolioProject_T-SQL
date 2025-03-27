
/*Part�ci�k, ablakok 
� be�gyazott Select
� be�gyazott lek�rdez�s, mint t�bla
� OVER(PARTITION BY ...) 
 	OVER(PARTITION BY kifejez�s* ORDER BY kifejez�s*
	ROWS | RANGE BETWEEN kezd�pont AND v�gpont)  --group by altern�tiv form�ja

ANALITIKUS F�GGV�NYEK:
� ROW_NUMBER(), RANK(), DENSE_RANK()
� LAG() �s LEAD()
� FIRST_VALUE(), LAST_VALUE()
� NTILE()

*/


/*2.�tlagosan h�ny term�k van k�szleten kateg�ri�nk�nt (KAT_ID), rakt�rank�nt (RAKTAR_KOD), illetve mennyis�gi egys�genk�nt? 
(szempontonk�nt k�l�n-k�l�n) 
a. Az �tlagot kerek�ts�k eg�szre! 
b. A feladatot egy lek�rdez�ssel oldja meg! */ 

	select kat_id, raktar_kod, megys, round(avg(keszlet),0)'�tlag k�szlet' from termek group by grouping sets((kat_id), (raktar_kod), (megys)); 

	-- ----------------------------------------------------------------------------------------------------------------------------------------------
	SELECT 
		CASE WHEN GROUPING(kat_id) = 1 THEN '-' ELSE CAST(kat_id AS NVARCHAR(10)) END AS 'Kateg�ria ID',
		CASE WHEN GROUPING(raktar_kod) = 1 THEN '-' ELSE CAST(raktar_kod AS NVARCHAR(10)) END AS 'Rakt�r k�d',
		CASE WHEN GROUPING(megys) = 1 THEN '-' ELSE megys END AS 'Mennyis�gi egys�g',
    ROUND(AVG(keszlet), 0) AS '�tlag k�szlet'
	FROM termek GROUP BY GROUPING SETS ((kat_id), (raktar_kod), (megys));


/*3.K�sz�ts�nk list�t a megrendelt term�kek legkisebb �s legnagyobb egys�g�r�r�l sz�ll�t�si d�tum, azon bel�l sz�ll�t�si m�d szerinti bont�sban! 
a. A lista csak a 2015 m�jusi sz�ll�t�sokat tartalmazza!
b. Jelen�ts�k meg a r�sz�sszegeket �s a v�g�sszeget is! */

	select rendeles.szall_datum, rendeles.szall_mod, min(rendeles_tetel.egysegar) 'Legkisebb egys�g�r', max(rendeles_tetel.egysegar) 'Legnagyobb egys�g�r'
	from termek join rendeles_tetel on termek.termekkod = rendeles_tetel.termekkod join rendeles on rendeles_tetel.sorszam= rendeles.sorszam
	where rendeles.rend_datum between '2015-05-01' and '2015-05-31' 
	group by rollup(szall_datum, szall_mod);

	-- ----------------------------------------------------------------------------------------------------------------------------------------------
	SELECT CASE WHEN GROUPING(rendeles.szall_datum) = 1 THEN '***LEGNAGYOBB***' 
        ELSE CAST(rendeles.szall_datum AS NVARCHAR(10))
    END AS 'Sz�ll�t�si d�tum',
    CASE WHEN GROUPING(rendeles.szall_mod) = 1 THEN '**Legnagyobb �r**' 
        ELSE CAST(rendeles.szall_mod AS NVARCHAR(10))
    END AS 'Sz�ll�t�si m�d',
    MIN(rendeles_tetel.egysegar) AS 'Legkisebb egys�g�r', 
    MAX(rendeles_tetel.egysegar) AS 'Legnagyobb egys�g�r'
	FROM termek JOIN rendeles_tetel ON termek.termekkod = rendeles_tetel.termekkod JOIN rendeles ON rendeles_tetel.sorszam = rendeles.sorszam
	WHERE rendeles.rend_datum BETWEEN '2015-05-01' AND '2015-05-31' 
	GROUP BY ROLLUP (rendeles.szall_datum, rendeles.szall_mod);


/*4.K�sz�ts�nk csoportot a term�kek lista�ra alapj�n a k�vetkez�k szerint: 
Az "olcs�" term�kek legyenek azok, amelyek lista�ra 3000 alatt van. A "dr�ga" term�kek legyenek az 5000 felettiek, a t�bbi legyen "k�zepes". 
a. List�zzuk az egyes csoportokat, �s a csoportokba tartoz� term�kek darabsz�m�t! 
b. A lista jelen�tse meg a v�g�sszeget is!*/

SELECT 
		CASE WHEN GROUPING(Kategoria) = 1 THEN 'V�g�sszeg'
		ELSE Kategoria
		END AS 'Kateg�ria',
		COUNT(*) AS 'Darabsz�m'
FROM ( SELECT 
        CASE WHEN listaar < 3000 THEN 'Olcs�'  
            WHEN listaar > 5000 THEN 'Dr�ga' 
            ELSE 'K�zepes'                   
        END AS Kategoria
    FROM termek) AS subquery
GROUP BY ROLLUP(Kategoria);

-- CTE + NTILE()
WITH PriceCategories AS (SELECT listaar, NTILE(3) OVER(ORDER BY listaar) AS '�rkateg�ria' FROM termek)
SELECT 
    CASE WHEN GROUPING(�rkateg�ria) = 1 THEN 'V�g�sszeg'
        ELSE CAST(�rkateg�ria AS NVARCHAR(10)) 
		END AS '�rkateg�ri�k (1,2,3)', 
    COUNT(*) AS 'Darabsz�m'
FROM PriceCategories 
GROUP BY ROLLUP(�rkateg�ria);


/*5.List�zzuk a rendel�si t�telek sz�m�t rakt�rank�nt �ves bont�sban! 
a. A list�ban a rakt�r neve, az �v �s a darabsz�m jelenjen meg! 
b. A lista jelen�tse meg a r�sz�sszegeket �s a v�g�sszeget is!
c. A v�g�sszeget megfelel�en jel�lj�k! 
d. Az oszlopokat nevezz�k el �rtelemszer�en!*/

select raktar.RAKTAR_NEV, year(rendeles.rend_datum) as '�v', count(*) as 'dbszam' from raktar join termek on raktar.raktar_kod = termek.raktar_kod 
			join rendeles_tetel on termek.termekkod = rendeles_tetel.termekkod
			join rendeles on rendeles_tetel.sorszam=rendeles.sorszam
			group by rollup(raktar.raktar_nev, year(rendeles.rend_datum));
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------
	SELECT
	CASE WHEN GROUPING(raktar.raktar_nev) = 1 THEN 'V�g�sszeg' 
        ELSE CAST(raktar.raktar_nev AS NVARCHAR(10))
		END AS 'Rakt�rn�v',
    CASE WHEN GROUPING(year(rendeles.rend_datum)) = 1 THEN 'R�sz�sszeg' 
        ELSE CAST(year(rendeles.rend_datum) AS NVARCHAR(10))
		END AS '�v',
	count(rendeles_tetel.sorszam) as 'RendT�telSz�ma'
	from raktar join termek on raktar.raktar_kod = termek.raktar_kod join rendeles_tetel on termek.termekkod = rendeles_tetel.termekkod join rendeles on rendeles_tetel.sorszam=rendeles.sorszam 
	group by rollup(raktar.raktar_nev, year(rendeles.rend_datum)); 


/*6.K�sz�ts�nk list�t az �gyfelek adatair�l n�v szerinti sorrendben. 
a. Minden sorban jelenjen meg a sorrend szerint el�z�, illetve k�vetkez� �gyf�l neve is.
b. Ha nincs el�z� vagy k�vetkez� �gyf�l, akkor a 'Nincs' jelenjen meg!*/

Select *, (LAG(nev,1,'Nincs') over(order by nev)) as 'El�z� �gyf�l neve', 
			Lead(nev,1,'Nincs') over(order by nev) as 'K�vetkez� �gyf�l neve' from ugyfel;

--
SELECT nev AS '�gyf�l neve', 
    COALESCE(LAG(nev,1) OVER (ORDER BY nev), 'Nincs') AS 'El�z� �gyf�l',
    COALESCE(LEAD(nev,1) OVER (ORDER BY nev), 'Nincs') AS 'K�vetkez� �gyf�l'
FROM ugyfel ORDER BY nev;


 /*9.List�zzuk a term�kek k�dj�t, megnevez�s�t, kateg�ri�j�nak nev�t, �s lista�r�t. 
a. A list�t eg�sz�ts�k ki k�t �j oszloppal, amelyek a kateg�ria legolcs�bb, illetve legdr�g�bb term�k�nek �r�t tartalmazz�k. 
b. A k�t �j oszlop l�trehoz�s�n�l part�ci�kkal dolgozzunk!*/
	
	
	SELECT KAT_ID, MIN(LISTAAR) AS 'Legolcs�bb', MAX(LISTAAR) AS 'Legdr�g�bb' FROM termek GROUP BY KAT_ID;

	-- partitionnel:
	select TERMEKKOD, MEGNEVEZES, KAT_ID, LISTAAR, 
	first_value(LISTAAR) over(partition by KAT_ID order by LISTAAR) 'Legolcs�bb', 
	first_value(LISTAAR) over(partition by KAT_ID order by LISTAAR DESC) 'Legdr�g�bb'
	from Termek ;


	select TERMEKKOD, MEGNEVEZES, KAT_ID, LISTAAR, 
	min(LISTAAR) over(partition by KAT_ID order by LISTAAR) 'Legolcs�bb', 
	max(LISTAAR) over(partition by KAT_ID order by LISTAAR DESC) 'Legdr�g�bb'
	from Termek ;


/*10.K�sz�ts�nk list�t a rendel�sekr�l. 
A lista legyen rendezve �gyfelenk�nt (LOGIN), azon bel�l a rendel�s d�tuma szerint.
 A list�hoz k�sz�ts�nk sorsz�moz�st is.  
	a. A sz�moz�s login-onk�nt, azon bel�l rendel�si �venk�nt kezd�dj�n �jra.
	b. A sorsz�m oszlop neve legyen Azonos�t�.
	A sorsz�m a k�vetkez� form�ban jelenjen meg: sorsz�m_�v_login. Pl: 1_2015_adam1*/

	select concat(dense_rank() over(partition by [Login] order by year(rend_datum)),'_' , year(rend_datum), '_', [Login]) as 'Azonos�t�', * from rendeles;



/*11. K�sz�ts�nk list�t a term�kek adatair�l lista�r szerint n�vekv� sorrendben!
A lista jelen�tse meg k�t �j oszlopban a sorrend szerint el�z�, illetve k�vetkez� term�k lista�r�t is a term�k saj�t kateg�ri�j�ban �s rakt�r�ban! 
	a. Ahol nincs el�z� vagy k�vetkez� �rt�k, ott 0 jelenjen meg! 
	b. Az oszlopokat nevezz�k el �rtelemszer�en!*/

	select KAT_ID,RAKTAR_KOD, LISTAAR, megnevezes, 
			LAG(listaar,1,0) over(partition by kat_id,raktar_kod order by listaar) as 'El�z� �rt�k', 
			Lead(listaar,1,0) over( partition by kat_id,raktar_kod order by listaar) as 'K�vetkez� �rt�k'  
			from termek;


/*12.List�zzuk a term�kek k�dj�t, nev�t �s lista�r�t lista�r szerinti sorrendben!
	 a. Vegy�nk fel egy �j oszlopot Mozg��tlag n�ven, amely minden esetben az aktu�lis term�k az el�z�, �s a k�vetkez� term�k �tlag�r�t tartalmazza!
	 b. A mozg��tlagot kerek�ts�k k�t tizedesre!*/

	 select termekkod, megnevezes, listaar, round(avg(listaar) over(order by listaar ROWS BETWEEN 1 PRECEDING AND 1 following), 2) 'mozg��tlag'
	 from termek;

	 	 
/*13.K�sz�ts�nk list�t, amely a rendel�sek sorsz�m�t �s a rendel�s �rt�k�t tartalmazza.
A list�t eg�sz�ts�k ki egy �j oszloppal, amely minden rendel�s eset�n addigi rendel�sek �rt�k�nek �sszeg�t tartalmazza (az aktu�lisat is bele�rtve)! 
	a. A list�t rendezz�k sorsz�m szerint n�vekv� sorrendbe. 
	b. A lista ne tartalmazzon duplik�lt sorokat!
	c. Nevezz�k el az oszlopokat �rtelemszer�en!*/

	SELECT sorszam, 
    SUM(egysegar * mennyiseg) AS 'Rendel�sek �rt�ke', 
    SUM(SUM(egysegar * mennyiseg)) OVER (ORDER BY sorszam ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Eddigi rendel�sek �sszege'
	FROM rendeles_tetel GROUP BY sorszam ORDER BY sorszam;



/*14.K�sz�ts�nk list�t a rendel�si t�telekr�l, amely minden sor eset�n g�ngy�l�tve tartalmazza az �gyf�l 
adott rendel�si t�telig megl�v� rendel�si t�teleinek �ssz�rt�k�t! 
	a. Az �j oszlop neve legyen Eddigi rendel�si t�telek �ssz�rt�ke! 
	b. Az �gyf�l neve is jelenjen meg!*/

	-- az �sszes �gyfel�t �sszeg�ngy�l�ti
	SELECT rendeles.[login], (rendeles_tetel.egysegar*rendeles_tetel.mennyiseg) as 'Rendel�sek �rt�ke', 
	sum(rendeles_tetel.egysegar*rendeles_tetel.mennyiseg) OVER (PARTITION BY rendeles.[login] ORDER BY rendeles.sorszam 
     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Eddigi rendel�si t�telek �ssz�rt�ke'
    from rendeles_tetel join rendeles on rendeles_tetel.sorszam = rendeles.sorszam  ORDER BY rendeles.[login], rendeles.sorszam;


	-- �j �gyf�ln�l �jraindul a g�ngy�l�t�s
	SELECT rendeles.[login], rendeles.sorszam, (rendeles_tetel.egysegar * rendeles_tetel.mennyiseg) AS 'Rendel�sek �rt�ke', 
    SUM(rendeles_tetel.egysegar * rendeles_tetel.mennyiseg) OVER (PARTITION BY rendeles.[login] ORDER BY rendeles.sorszam, rendeles_tetel.sorszam 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Eddigi rendel�si t�telek �ssz�rt�ke'
	FROM rendeles_tetel JOIN rendeles ON rendeles_tetel.sorszam = rendeles.sorszam  ORDER BY rendeles.[login], rendeles.sorszam, rendeles_tetel.sorszam;


/*15.K�sz�ts�nk list�t a term�kek k�dj�r�l, nev�r�l, kateg�ria azonos�t�j�r�l, rakt�r azonos�t�j�r�l �s lista�r�r�l,
valamint a term�k adott szempontok szerinti rangsorokban elfoglalt helyez�seir�l. (Szempontonk�nt k�l�n oszlopban, a helyez�sekn�l n�vekv� sorrendet felt�telezve).
A szempontok a k�vetkez�k legyenek: lista�r, kateg�ria szerinti lista�r, �s rakt�rk�d szerinti lista�r. 
	a. Az oszlopokat nevezz�k el �rtelemszer�en. 
	b. A helyez�sek egyenl�s�g eset�n "s�r�n" k�vess�k egym�st.
	c. A lista legyen rendezett kateg�ria azonos�t�, azon bel�l lista�r szerint!*/

	select termekkod, megnevezes, kat_id, raktar_kod, listaar, 
		dense_rank() over (order by listaar) as 'Rangsor_Listaar'	,
		dense_rank() over (partition by kat_id order by listaar) as 'Rangsor_KAt_Listaar'	,
		dense_rank() over (partition by raktar_kod order by listaar) as 'Rangsor_RAktar_listaar'	
	from termek order by kat_id, listaar;



