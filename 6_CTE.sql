
/*
CTE
Pivoting
Cursors
*/



/*5. Feladat: Hány vendég tartózkodott egy adott idõszakban?
Feladat: Számoljuk ki, hogy mennyivel több vendég volt 2016-ban, mint 2017-ben! */

	WITH ev_vendeg_szam_CTE AS (
		SELECT year(mettol) AS ev, SUM(felnott_szam + gyermek_szam) AS osszes_vendeg FROM foglalas
		WHERE year(mettol) IN (2016, 2017) GROUP BY year(mettol)
		)
	SELECT 
		MAX(CASE WHEN ev = 2016 THEN osszes_vendeg END) AS vendeg_2016,
		MAX(CASE WHEN ev = 2017 THEN osszes_vendeg END) AS vendeg_2017,
		MAX(CASE WHEN ev = 2016 THEN osszes_vendeg END) - MAX(CASE WHEN ev = 2017 THEN osszes_vendeg END) AS kulonbseg
	FROM ev_vendeg_szam_CTE;


/*6. Hierarchikus CTE segítségével kategorizáljuk a szobákat aszerint, hogy klímásak vagy sem!
Az alábbi hierarchia szerint litázzuk ki a szobákat:
- pótágyas+ klímás
- klímás 
- pótágyas 
- egyik sem */

WITH cte_szoba_klima AS (
    SELECT szoba_id, klimas, 
           CASE
               WHEN klimas = 'i' AND potagy > 0 THEN 1  -- Pótágyas és klímás
               WHEN klimas = 'i' THEN 2  -- Csak klímás
               WHEN potagy > 0 THEN 3  -- Csak pótágyas
               ELSE 4  -- Egyik sem
           END AS szint
    FROM szoba
						)
						SELECT szoba_id, klimas,
							   CASE
								   WHEN szint = 1 THEN 'Pótágyas + Klímás'
								   WHEN szint = 2 THEN 'Klímás'
								   WHEN szint = 3 THEN 'Pótágyas'
								   ELSE 'Egyik sem'
							   END AS kategoria
						FROM cte_szoba_klima ORDER BY szoba_id,szint;

WITH cte_szoba_kat AS (
    -- 1. Szobák kategorizálása kezdõ állapotban
    SELECT 
        szoba_id, 
        szoba_szama, 
        klimas, 
        potagy, 
        CASE 
            WHEN potagy > 0 AND klimas = 'i' THEN 'Pótágyas + Klímás'
            WHEN klimas = 'i' THEN 'Klímás'
            WHEN potagy > 0 THEN 'Pótágyas'
            ELSE 'Egyik sem'
        END AS kategoria
    FROM szoba
)
-- 2. Eredmény listázása
SELECT szoba_id, szoba_szama, kategoria
FROM cte_szoba_kat
ORDER BY 
    CASE 
        WHEN kategoria = 'Pótágyas + Klímás' THEN 1
        WHEN kategoria = 'Klímás' THEN 2
        WHEN kategoria = 'Pótágyas' THEN 3
        ELSE 4
    END, szoba_szama;


/*7. Listázzuk ki azon vendégek nevét szállástípusonként, akik a legkevesebb ideig maradtak az egyes szállásokon!
A lekérdezésben csak a legkisebb érték szerepeljen. */

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


/*9.Készítsünk CTE-t RangSor_CTE néven, amely rangsorolja a szálláshelyeket a foglalások száma alapján
(a legtöbb foglalás legyen a rangsorban az elsõ). 
A listában a szállás neve és a rangsor szerinti helyezés és a foglalások száma.*/


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
   



/*10. CTE segítségével listázzuk ki azokat a foglalásokat, amelyek hosszabbak az átlagos tartózkodási idõnél.*/

	with cte_atlag(atlag) as
		(SELECT AVG(DATEDIFF(day, METTOL, MEDDIG))	FROM Foglalas) 
	SELECT FOGLALAS_PK, METTOL,MEDDIG fROM Foglalas	WHERE DATEDIFF(day, METTOL, MEDDIG) > (select atlag from cte_atlag);


/*11. Listázzuk ki azon vendégek nevét akik a legkevesebb ideig maradtak az egyes szálláshelyeken!
A lekérdezésben szerepeljen a szállás neve, típusa, Tartózkodás ideje.*/


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



/*12. Rekurzív CTE segítségével mondjuk meg a termékkategóriák szintjeit!
Azok a kategóriák, amelyeknek nincs szülõjük, jelentsék az 1. szintet!*/

WITH cte_kat (id, nev, parent, szint) AS 
(
    -- 1. A legfelsõ szintû kategóriák (1. szint)
    SELECT kat_id, kat_nev, szulo_kat, 1 
    FROM Termekkategoria 
    WHERE szulo_kat IS NULL
    UNION ALL
    -- 2. Rekurzívan hozzárendeljük a szinteket
    SELECT tk.kat_id, tk.kat_nev, tk.szulo_kat, ck.szint + 1 
    FROM Termekkategoria tk
    JOIN cte_kat ck ON tk.szulo_kat = ck.id
)
-- 3. Kategóriák listázása szint szerint rendezve
SELECT id, nev, parent, szint
FROM cte_kat
ORDER BY szint, nev;



/*13.Készítsen pivot táblát, amely megmutatja, hogy az adott csillagszámú szálláshelybõl hány db van!
    Az eredmény az alábbi formában jelenjen meg:
db szám csillagonként	1	2	3	4	5
db	 férõhelyszám       0	0	8	3	0*/


	select 'db' as 'Szálláshelyek száma csillagonként', [1], [2], [3], [4], [5] 
	from( SELECT szallas_ID, csillagok_szama from szallashely ) as Szálláshely 
	pivot( 
		count(szallas_ID) -- szálláshely
		for csillagok_szama in ([1], [2], [3], [4], [5]) 
		) as pivottabla;


/*14.Készítsen pivot táblát, amely megjeleníti, hogy apartmanból és diákszállóból hány db van az egyes helyeken!*/
-- #1
	select * from( SELECT hely, tipus  from szallashely where tipus in ('Apartman','diákszálló') ) as tipus
	pivot( 
		count(tipus) for tipus in ([Apartman], [diákszálló]) 
				) as pivottabla ;

--#2
	select * from( SELECT hely, tipus  from szallashely where tipus in ('Apartman','diákszálló') ) as tipus
	pivot( 
		count(hely) for hely in ([Balaton-Dél], [Budapest], [Dél-Somogy], [Hajdú-Bihar megye]) 
				) as pivottabla ;


/*15.Listázza a Szallashelyek azonosítóját és nevét kurzor segítségével!*/

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


/*14.Listázzuk a vendégek nevét és email címét a következõképpen:
    Kurzort használjunk, Csak minden második vendég jelenjen meg!*/

	declare @email nvarchar(50)
	declare @nev nvarchar(50)

	declare c2 cursor for 
		select nev, email from vendeg; 
	open c2 
	fetch next from c2 into @nev, @email 
	while @@fetch_status =0
		begin
			select @nev + ' - ' + @email;  
			FETCH NEXT FROM c2 INTO @nev, @email;  --léptet
			FETCH NEXT FROM c2 INTO @nev, @email;  --átugor  
		end
	close c2
	deallocate c2; 


