
/*
VIEW Table
Temporary Table

TRIGGER:
	create trigger
	before/after/instead of  insert/delete/update

PROCEDURE
FUNCTION

COMMIT
ROLLBACK
LOCK

kivételkezelés

*/


-- VIEW ------------------------------------------------------------------------------------------------------------------------------------------------

/*1 Készítsünk nézettáblát, amely mutatja a 2017. 05.05.-i foglalásokat*/

CREATE VIEW AktivFoglalasok AS 
SELECT vendeg.nev, foglalas.mettol, foglalas.szoba_fk
FROM foglalas
JOIN vendeg ON foglalas.ugyfel_fk = vendeg.usernev
WHERE foglalas.mettol = '2016-05-01';

Select * from AktivFoglalasok; 


-- TEMPORARY TABLE ------------------------------------------------------------------------------------------------------------------------------------------------
/*2 Készítsünk ideiglenes táblát, amely mutatja, hogy egy adott idõszakban mennyire voltak kihasználva az egyes szállások*/
CREATE TEMPORARY TABLE Kihasznaltsag AS 
SELECT szallas_id, SUM(felnott_szam + gyermek_szam) AS vendegszam
FROM szoba join Szallashely on SZALLAS_ID = SZALLAS_FK join Foglalas on SZOBA_ID = SZOBA_FK
WHERE mettol BETWEEN '2016-01-01' AND '2016-12-31'
GROUP BY szallas_id order by SZALLAS_ID;


SELECT * FROM Kihasznaltsag; 



-- Procedure, Function ------------------------------------------------------------------------------------------------------------------------------------------------

/* Hány vendég van , aki adott születésû évû (pl.:1990) 
Készítsük el a procedure és a function verziót is!*/

create procedure SP_VendegszamEv
	@szulev int
	AS BEGIN
		select count(usernev)'Vendégszám' from Vendeg where year(SZUL_DAT)= @szulev 
		END;

	EXEC SP_VendegszamEv 1990;

-- 
create function UDF_VendegszamEv
	(@szulev int) 
		returns int --

	as begin
		declare @db int --
			select @db =count(usernev) 
			from Vendeg 
			where year(SZUL_DAT)= @szulev
		return @db
		end;

	SELECT dbo.UDF_VendegszamEv(1990);

/* Mely vendégek foglaltak szállást bizonyos alkalomnál (pl.: 5-nél) többször. 
Készítsük el a procedure és a function verziót is!*/

create procedure SP_VendegHanyszorTobb
	@hanyszor int

	as begin
			select vendeg.nev , count(*) as 'Foglalások_száma' from Vendeg join Foglalas on vendeg.USERNEV= Foglalas.UGYFEL_FK 
			group by vendeg.nev having count(*) >  @hanyszor 
			order by  'Foglalások_száma'
		end;

	exec SP_VendegHanyszorTobb 5;

-- 
		CREATE FUNCTION UDF_VendegHanyszorTobb4(@hanyszor INT)
		RETURNS TABLE
		AS
		RETURN 
		(
			SELECT vendeg.nev, COUNT(*) AS foglalasok_szama
			FROM Vendeg 
			JOIN Foglalas ON vendeg.USERNEV = Foglalas.UGYFEL_FK 
			GROUP BY vendeg.nev 
			HAVING COUNT(*) > @hanyszor
		);


	select *from dbo.UDF_VendegHanyszorTobb4(5);

/*14.Készítsünk tábla értékû függvényt UDF_Rangsor néven, amely rangsorolja a szálláshelyeket 
a foglalások száma alapján (a legtöbb foglalás legyen a rangsorban az elsõ). 
A felhasználó a rangsor száma alapján kíváncsi a helyezettekre!
a. A listában a szállás azonosítója, neve és a rangsor szerinti helyezés jelenjen meg 
- holtverseny esetén ugrással (ne sûrûn)!*/

CREATE FUNCTION UDF_Rangsor(@rangsorszam INT)
RETURNS TABLE
AS
RETURN 
(
    WITH RangSor AS (
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
    SELECT szallas_id, szallas_nev, rangsor
    FROM RangSor
    WHERE rangsor = @rangsorszam
);

SELECT * FROM dbo.UDF_Rangsor(1); -- Megnézi az elsõ helyezett szállásokat
SELECT * FROM dbo.UDF_Rangsor(2); -- Megnézi az 2. helyezetteket



-- Trigger ------------------------------------------------------------------------------------------------------------------------------------------------

/*Korlátozzuk le triggerrel a foglalások számát! 
Ha egy vendégnek 10-nél több foglalása volt, akkor többet nem foglalhat!*/

create trigger tgKorlatozas
on foglalas 
instead of insert
 as begin
		begin transaction
	begin try
		--declare
		declare @fpk int --foglalas
		declare @nev nvarchar(30) --ügyfél
		declare @szoba int  --szoba_fk
		declare @mettol date -- mettõl
		declare @meddig date -- meddig
		declare @f int  -- felnõtt_szam
		declare @gy int -- gyermek_szam
		declare @db int

		--értékadás
		select 
			@fpk = foglalas_PK,
			@nev = ugyfel_fk,
			@szoba = szoba_fk,
			@mettol =mettol,
			@meddig = meddig,
			@f =felnott_szam,
			@gy = gyermek_szam from inserted

		-- lekérdezés helye
		select  distinct @nev = ugyfel_fk, @db =count(FOGLALAS_PK) 
		from foglalas 
		group by ugyfel_fk having count(FOGLALAS_PK) > 10 -- @mennyivel

		--feltétel
		IF @db > 10
        BEGIN -- Ha teljesül a feltétel hibaüzenetet dobunk és megszakítjuk a tranzakciót
            RAISERROR ('Hiba: Egy ügyfél legfeljebb 10 foglalást hozhat létre!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Ha a feltétel nem teljesül, engedélyezzük a beszúrást
        INSERT INTO Foglalas SELECT * FROM INSERTED;

		-- Ha minden sikeres, véglegesítjük a tranzakciót
	COMMIT TRANSACTION;
		PRINT 'Foglalás sikeresen rögzítve!';

	END TRY
	BEGIN CATCH -- Ha hiba történik, visszaállítjuk az adatbázist
		ROLLBACK TRANSACTION;
		PRINT 'Hiba történt a foglalás rögzítése során!';
		PRINT ERROR_MESSAGE();
	END CATCH
END;


INSERT INTO Foglalas  VALUES(101,'adam4', '2025-06-01', '2025-06-07', 2, 1);
INSERT INTO Foglalas VALUES(200,'peter4', '2020-08-08', '2020-08-17', 2, 1);
insert into Foglalas values (1586, 'zoltan4',1,'2019.02.01','2019.03.05', 2,1)



