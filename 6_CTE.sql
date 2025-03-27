
/*
CTE
Pivoting
Cursors
*/



/*5. Feladat: H�ny vend�g tart�zkodott egy adott id�szakban?
Feladat: Sz�moljuk ki, hogy mennyivel t�bb vend�g volt 2016-ban, mint 2017-ben! */

	WITH ev_vendeg_szam_CTE AS (
		SELECT year(mettol) AS ev, SUM(felnott_szam + gyermek_szam) AS osszes_vendeg FROM foglalas
		WHERE year(mettol) IN (2016, 2017) GROUP BY year(mettol)
		)
	SELECT 
		MAX(CASE WHEN ev = 2016 THEN osszes_vendeg END) AS vendeg_2016,
		MAX(CASE WHEN ev = 2017 THEN osszes_vendeg END) AS vendeg_2017,
		MAX(CASE WHEN ev = 2016 THEN osszes_vendeg END) - MAX(CASE WHEN ev = 2017 THEN osszes_vendeg END) AS kulonbseg
	FROM ev_vendeg_szam_CTE;


/*6. Hierarchikus CTE seg�ts�g�vel kategoriz�ljuk a szob�kat aszerint, hogy kl�m�sak vagy sem!
Az al�bbi hierarchia szerint lit�zzuk ki a szob�kat:
- p�t�gyas+ kl�m�s
- kl�m�s 
- p�t�gyas 
- egyik sem */

WITH cte_szoba_klima AS (
    SELECT szoba_id, klimas, 
           CASE
               WHEN klimas = 'i' AND potagy > 0 THEN 1  -- P�t�gyas �s kl�m�s
               WHEN klimas = 'i' THEN 2  -- Csak kl�m�s
               WHEN potagy > 0 THEN 3  -- Csak p�t�gyas
               ELSE 4  -- Egyik sem
           END AS szint
    FROM szoba
						)
						SELECT szoba_id, klimas,
							   CASE
								   WHEN szint = 1 THEN 'P�t�gyas + Kl�m�s'
								   WHEN szint = 2 THEN 'Kl�m�s'
								   WHEN szint = 3 THEN 'P�t�gyas'
								   ELSE 'Egyik sem'
							   END AS kategoria
						FROM cte_szoba_klima ORDER BY szoba_id,szint;

WITH cte_szoba_kat AS (
    -- 1. Szob�k kategoriz�l�sa kezd� �llapotban
    SELECT 
        szoba_id, 
        szoba_szama, 
        klimas, 
        potagy, 
        CASE 
            WHEN potagy > 0 AND klimas = 'i' THEN 'P�t�gyas + Kl�m�s'
            WHEN klimas = 'i' THEN 'Kl�m�s'
            WHEN potagy > 0 THEN 'P�t�gyas'
            ELSE 'Egyik sem'
        END AS kategoria
    FROM szoba
)
-- 2. Eredm�ny list�z�sa
SELECT szoba_id, szoba_szama, kategoria
FROM cte_szoba_kat
ORDER BY 
    CASE 
        WHEN kategoria = 'P�t�gyas + Kl�m�s' THEN 1
        WHEN kategoria = 'Kl�m�s' THEN 2
        WHEN kategoria = 'P�t�gyas' THEN 3
        ELSE 4
    END, szoba_szama;


/*7. List�zzuk ki azon vend�gek nev�t sz�ll�st�pusonk�nt, akik a legkevesebb ideig maradtak az egyes sz�ll�sokon!
A lek�rdez�sben csak a legkisebb �rt�k szerepeljen. */

WITH MinFoglalas AS (
    SELECT 
        Szallashely.TIPUS,
        vendeg.nev AS VendegNev,
        Szallas_NEV AS SzallasNeve,
        DATEDIFF(DAY, foglalas.mettol, foglalas.meddig) AS TartozkodasNap
    FROM Szallashely
    JOIN Szoba ON Szallashely.szallas_id = Szoba.szallas_fk 
    JOIN Foglalas ON Szoba.szoba_id = Foglalas.SZOBA_FK
    JOIN Vendeg ON Foglalas.ugyfel_fk = Vendeg.usernev
)
SELECT 
    mf.TIPUS,
    mf.SzallasNeve,
    mf.VendegNev,
    mf.TartozkodasNap
FROM MinFoglalas mf
WHERE mf.TartozkodasNap = (
    SELECT MIN(DATEDIFF(DAY, f.mettol, f.meddig))
    FROM Szallashely sh
    JOIN Szoba sz ON sh.szallas_id = sz.szallas_fk
    JOIN Foglalas f ON sz.szoba_id = f.SZOBA_FK
    WHERE sh.TIPUS = mf.TIPUS
)
ORDER BY mf.TIPUS, mf.TartozkodasNap;


/*9.K�sz�ts�nk CTE-t RangSor_CTE n�ven, amely rangsorolja a sz�ll�shelyeket a foglal�sok sz�ma alapj�n
(a legt�bb foglal�s legyen a rangsorban az els�). 
A list�ban a sz�ll�s neve �s a rangsor szerinti helyez�s �s a foglal�sok sz�ma.*/


    WITH RangSor_CTE AS (
        SELECT 
            szh.szallas_id,
            szh.szallas_nev,
            COUNT(*) AS foglalasok_szama,
            DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rangsor
        FROM foglalas f
        JOIN szoba sz ON szoba_fk = sz.szoba_id
        JOIN szallashely szh ON sz.szallas_fk = szh.szallas_id
        GROUP BY szh.szallas_id, szh.szallas_nev
    )
    SELECT szallas_nev, rangsor, foglalasok_szama
    FROM RangSor_CTE;
   



/*10. CTE seg�ts�g�vel list�zzuk ki azokat a foglal�sokat, amelyek hosszabbak az �tlagos tart�zkod�si id�n�l.*/

	with cte_atlag(atlag) as
		(SELECT AVG(DATEDIFF(day, METTOL, MEDDIG))	FROM Foglalas) 
	SELECT FOGLALAS_PK, METTOL,MEDDIG fROM Foglalas	WHERE DATEDIFF(day, METTOL, MEDDIG) > (select atlag from cte_atlag);


/*11. List�zzuk ki azon vend�gek nev�t akik a legkevesebb ideig maradtak az egyes sz�ll�shelyeken!
A lek�rdez�sben szerepeljen a sz�ll�s neve, t�pusa, Tart�zkod�s ideje.*/


	WITH MinFoglalas AS (
		SELECT 
			Szallashely.TIPUS,
			vendeg.nev AS VendegNev,
			Szallashely.SZALLAS_NEV AS SzallasNeve,
			DATEDIFF(DAY, foglalas.mettol, foglalas.meddig) AS TartozkodasNap
		FROM Szallashely
		JOIN Szoba ON Szallashely.szallas_id = Szoba.szallas_fk 
		JOIN Foglalas ON Szoba.szoba_id = Foglalas.SZOBA_FK
		JOIN Vendeg ON Foglalas.ugyfel_fk = Vendeg.usernev
	)
	SELECT 
		mf.TIPUS,
		mf.SzallasNeve,
		mf.VendegNev,
		mf.TartozkodasNap
	FROM MinFoglalas mf
	WHERE mf.TartozkodasNap = (
		SELECT MIN(DATEDIFF(DAY, f.mettol, f.meddig))
		FROM Szallashely sh
		JOIN Szoba sz ON sh.szallas_id = sz.szallas_fk
		JOIN Foglalas f ON sz.szoba_id = f.SZOBA_FK
		WHERE sh.TIPUS = mf.TIPUS
	)
	ORDER BY mf.TIPUS, mf.TartozkodasNap;



/*12. Rekurz�v CTE seg�ts�g�vel mondjuk meg a term�kkateg�ri�k szintjeit!
Azok a kateg�ri�k, amelyeknek nincs sz�l�j�k, jelents�k az 1. szintet!*/

WITH cte_kat (id, nev, parent, szint) AS 
(
    -- 1. A legfels� szint� kateg�ri�k (1. szint)
    SELECT kat_id, kat_nev, szulo_kat, 1 
    FROM Termekkategoria 
    WHERE szulo_kat IS NULL
    UNION ALL
    -- 2. Rekurz�van hozz�rendelj�k a szinteket
    SELECT tk.kat_id, tk.kat_nev, tk.szulo_kat, ck.szint + 1 
    FROM Termekkategoria tk
    JOIN cte_kat ck ON tk.szulo_kat = ck.id
)
-- 3. Kateg�ri�k list�z�sa szint szerint rendezve
SELECT id, nev, parent, szint
FROM cte_kat
ORDER BY szint, nev;



/*13.K�sz�tsen pivot t�bl�t, amely megmutatja, hogy az adott csillagsz�m� sz�ll�shelyb�l h�ny db van!
    Az eredm�ny az al�bbi form�ban jelenjen meg:
db sz�m csillagonk�nt	1	2	3	4	5
db	 f�r�helysz�m       0	0	8	3	0*/


	select 'db' as 'Sz�ll�shelyek sz�ma csillagonk�nt', [1], [2], [3], [4], [5] 
	from( SELECT szallas_ID, csillagok_szama from szallashely ) as Sz�ll�shely 
	pivot( 
		count(szallas_ID) -- sz�ll�shely
		for csillagok_szama in ([1], [2], [3], [4], [5]) 
		) as pivottabla;


/*14.K�sz�tsen pivot t�bl�t, amely megjelen�ti, hogy apartmanb�l �s di�ksz�ll�b�l h�ny db van az egyes helyeken!*/
-- #1
	select * from( SELECT hely, tipus  from szallashely where tipus in ('Apartman','di�ksz�ll�') ) as tipus
	pivot( 
		count(tipus) for tipus in ([Apartman], [di�ksz�ll�]) 
				) as pivottabla ;

--#2
	select * from( SELECT hely, tipus  from szallashely where tipus in ('Apartman','di�ksz�ll�') ) as tipus
	pivot( 
		count(hely) for hely in ([Balaton-D�l], [Budapest], [D�l-Somogy], [Hajd�-Bihar megye]) 
				) as pivottabla ;


/*15.List�zza a Szallashelyek azonos�t�j�t �s nev�t kurzor seg�ts�g�vel!*/

	declare @id int
	declare @nev nvarchar(50)

	declare c cursor for 
		select szallas_id, szallas_nev from szallashely; 
	open c 
	fetch next from c into @id, @nev  
	while @@fetch_status =0
		begin
			select @id, @nev
			fetch next from c into @id, @nev
		end
	close c
	deallocate c; 


/*14.List�zzuk a vend�gek nev�t �s email c�m�t a k�vetkez�k�ppen:
    Kurzort haszn�ljunk, Csak minden m�sodik vend�g jelenjen meg!*/

	declare @email nvarchar(50)
	declare @nev nvarchar(50)

	declare c2 cursor for 
		select nev, email from vendeg; 
	open c2 
	fetch next from c2 into @nev, @email 
	while @@fetch_status =0
		begin
			select @nev + ' - ' + @email;  
			FETCH NEXT FROM c2 INTO @nev, @email;  --l�ptet
			FETCH NEXT FROM c2 INTO @nev, @email;  --�tugor  
		end
	close c2
	deallocate c2; 


