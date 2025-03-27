
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

kiv�telkezel�s

*/


-- VIEW ------------------------------------------------------------------------------------------------------------------------------------------------

/*1 K�sz�ts�nk n�zett�bl�t, amely mutatja a 2017. 05.05.-i foglal�sokat*/

CREATE VIEW AktivFoglalasok AS 
SELECT vendeg.nev, foglalas.mettol, foglalas.szoba_fk
FROM foglalas
JOIN vendeg ON foglalas.ugyfel_fk = vendeg.usernev
WHERE foglalas.mettol = '2016-05-01';

Select * from AktivFoglalasok; 


-- TEMPORARY TABLE ------------------------------------------------------------------------------------------------------------------------------------------------
/*2 K�sz�ts�nk ideiglenes t�bl�t, amely mutatja, hogy egy adott id�szakban mennyire voltak kihaszn�lva az egyes sz�ll�sok*/
CREATE TEMPORARY TABLE Kihasznaltsag AS 
SELECT szallas_id, SUM(felnott_szam + gyermek_szam) AS vendegszam
FROM szoba join Szallashely on SZALLAS_ID = SZALLAS_FK join Foglalas on SZOBA_ID = SZOBA_FK
WHERE mettol BETWEEN '2016-01-01' AND '2016-12-31'
GROUP BY szallas_id order by SZALLAS_ID;


SELECT * FROM Kihasznaltsag; 



-- Procedure, Function ------------------------------------------------------------------------------------------------------------------------------------------------

/* H�ny vend�g van , aki adott sz�let�s� �v� (pl.:1990) 
K�sz�ts�k el a procedure �s a function verzi�t is!*/

create procedure SP_VendegszamEv
	@szulev int
	AS BEGIN
		select count(usernev)'Vend�gsz�m' from Vendeg where year(SZUL_DAT)= @szulev 
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

/* Mely vend�gek foglaltak sz�ll�st bizonyos alkalomn�l (pl.: 5-n�l) t�bbsz�r. 
K�sz�ts�k el a procedure �s a function verzi�t is!*/

create procedure SP_VendegHanyszorTobb
	@hanyszor int

	as begin
			select vendeg.nev , count(*) as 'Foglal�sok_sz�ma' from Vendeg join Foglalas on vendeg.USERNEV= Foglalas.UGYFEL_FK 
			group by vendeg.nev having count(*) >  @hanyszor 
			order by  'Foglal�sok_sz�ma'
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

/*14.K�sz�ts�nk t�bla �rt�k� f�ggv�nyt UDF_Rangsor n�ven, amely rangsorolja a sz�ll�shelyeket 
a foglal�sok sz�ma alapj�n (a legt�bb foglal�s legyen a rangsorban az els�). 
A felhaszn�l� a rangsor sz�ma alapj�n k�v�ncsi a helyezettekre!
a. A list�ban a sz�ll�s azonos�t�ja, neve �s a rangsor szerinti helyez�s jelenjen meg 
- holtverseny eset�n ugr�ssal (ne s�r�n)!*/

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

SELECT * FROM dbo.UDF_Rangsor(1); -- Megn�zi az els� helyezett sz�ll�sokat
SELECT * FROM dbo.UDF_Rangsor(2); -- Megn�zi az 2. helyezetteket



-- Trigger ------------------------------------------------------------------------------------------------------------------------------------------------

/*Korl�tozzuk le triggerrel a foglal�sok sz�m�t! 
Ha egy vend�gnek 10-n�l t�bb foglal�sa volt, akkor t�bbet nem foglalhat!*/

create trigger tgKorlatozas
on foglalas 
instead of insert
 as begin
		begin transaction
	begin try
		--declare
		declare @fpk int --foglalas
		declare @nev nvarchar(30) --�gyf�l
		declare @szoba int  --szoba_fk
		declare @mettol date -- mett�l
		declare @meddig date -- meddig
		declare @f int  -- feln�tt_szam
		declare @gy int -- gyermek_szam
		declare @db int

		--�rt�kad�s
		select 
			@fpk = foglalas_PK,
			@nev = ugyfel_fk,
			@szoba = szoba_fk,
			@mettol =mettol,
			@meddig = meddig,
			@f =felnott_szam,
			@gy = gyermek_szam from inserted

		-- lek�rdez�s helye
		select  distinct @nev = ugyfel_fk, @db =count(FOGLALAS_PK) 
		from foglalas 
		group by ugyfel_fk having count(FOGLALAS_PK) > 10 -- @mennyivel

		--felt�tel
		IF @db > 10
        BEGIN -- Ha teljes�l a felt�tel hiba�zenetet dobunk �s megszak�tjuk a tranzakci�t
            RAISERROR ('Hiba: Egy �gyf�l legfeljebb 10 foglal�st hozhat l�tre!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Ha a felt�tel nem teljes�l, enged�lyezz�k a besz�r�st
        INSERT INTO Foglalas SELECT * FROM INSERTED;

		-- Ha minden sikeres, v�gleges�tj�k a tranzakci�t
	COMMIT TRANSACTION;
		PRINT 'Foglal�s sikeresen r�gz�tve!';

	END TRY
	BEGIN CATCH -- Ha hiba t�rt�nik, vissza�ll�tjuk az adatb�zist
		ROLLBACK TRANSACTION;
		PRINT 'Hiba t�rt�nt a foglal�s r�gz�t�se sor�n!';
		PRINT ERROR_MESSAGE();
	END CATCH
END;


INSERT INTO Foglalas  VALUES(101,'adam4', '2025-06-01', '2025-06-07', 2, 1);
INSERT INTO Foglalas VALUES(200,'peter4', '2020-08-08', '2020-08-17', 2, 1);
insert into Foglalas values (1586, 'zoltan4',1,'2019.02.01','2019.03.05', 2,1)



