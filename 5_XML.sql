
/*XML, JSON*/



/*3.Az feladatban szereplő xml-ből kérdezze le a megrendeléseket, amit 
a könyvesboltnak adtak le (bookstore)! A Boltok neve jelenjen meg! */

DECLARE @xml XML;
SET @xml = N'
<BookstoreOrders>
  <BookstoreCustomer custid="101">
		<bookstore>Bookstore Alpha</bookstore>
		<Order orderid="501">
			<orderdate>2015-05-01T00:00:00</orderdate>
		</Order>
		<Order orderid="502">
			<orderdate>2015-05-15T00:00:00</orderdate>
		</Order>
		<Order orderid="503">
			<orderdate>2015-06-20T00:00:00</orderdate>
		</Order>
  </BookstoreCustomer>
	  <BookstoreCustomer custid="102">
		<bookstore>Bookstore Beta</bookstore>
		<Order orderid="504">
			 <orderdate>2014-09-18T00:00:00</orderdate>
		</Order>
		<Order orderid="505">
			 <orderdate>2014-10-04T00:00:00</orderdate>
		</Order>
	  </BookstoreCustomer>
</BookstoreOrders>';

--  mindet visszaadja:
	SELECT @xml.query('/BookstoreOrders/BookstoreCustomer/bookstore')'Konyvesbolt';
-- 
	select @xml.value('(/BookstoreOrders/BookstoreCustomer/bookstore)[1]', 'varchar(20)') 'Konyvesbolt';
	select @xml.value('(/BookstoreOrders/BookstoreCustomer/bookstore)[2]', 'varchar(20)') 'Konyvesbolt';

	-- '.'
	SELECT bookstore.value('.', 'varchar(20)') as 'Konyvesbolt'
	FROM @xml.nodes('/BookstoreOrders/BookstoreCustomer/bookstore') as b(bookstore);


/*4.Az előző feladatból való xml-t felhasználva döntse el, 
hogy történt-e megrendelés az 504-es és az 506-ös azonosítóval (orderid)!
    Csak a logikai érték jelenjen meg!*/


	SELECT @xml.exist('/BookstoreOrders/BookstoreCustomer/Order[@orderid ="504"]'); 
	SELECT @xml.exist('/BookstoreOrders/BookstoreCustomer/Order[@orderid ="506"]'); 


/*5.Készítsen lekérdezést az alábbi xml típusú változó tartalmából,
amely csak a szobák tábla adatait jeleníti meg xml formátumban. */

	declare @x xml
	set @x = cast(N'
	<Szobak>
		<Szoba SZOBA_ID="21" SZOBA_SZAMA="123" FEROHELY="3">
		</Szoba>
		<Szoba SZOBA_ID="22" SZOBA_SZAMA="124" FEROHELY="2">
		</Szoba>
		<Szoba SZOBA_ID="23" SZOBA_SZAMA="125" FEROHELY="2">
		</Szoba>
		<Szoba SZOBA_ID="24" SZOBA_SZAMA="126" FEROHELY="4">
		</Szoba>
	</Szobak>' as xml);

-- lekérdezés:
select @x.query('/Szobak/Szoba') -- táblát adja vissza
select @x.value('(/Szobak/Szoba/@FEROHELY)[2]', 'int') -- 1 db értéket advissza
select @x.exist('/Szobak/Szoba/Klimas'); -- leellenőrzi hogy van-e ilyen.

-- -----------------------------------------------------------------------------------------------

/*6. SQL => XML
Készítsen lekérdezést, amely megjeleníti azon vendégek nevét és elérhetőségét, akik elmúltak 55 évesek!
A lekérdezés eredménye XML formátumban jelenjen meg ilyen elemcentrikus elrendezésben:*/

Select nev, email, szaml_cim
from vendeg where DATEDIFF(year, szul_dat, getdate()) >57
for xml auto, elements, root('Vendegek'); 


-- -----------------------------------------------------------------------------------------------
/*7. XML => SQL (openxml függvény)
Készítsen tábla formátumot a BookstoreOrder xml-ből, 
amely csak a rendelések számát és dátumát tartalmazza!*/

declare @idoc int, @doc XML 
set @doc = N'<BookstoreOrders>
		<BookstoreCustomer custid="101">
			<bookstore>Bookstore Alpha</bookstore>
			<Order orderid="501">
				<orderdate>2015-05-01T00:00:00</orderdate>
			</Order>
			<Order orderid="502">
				<orderdate>2015-05-15T00:00:00</orderdate>
			</Order>
			<Order orderid="503">
				<orderdate>2015-06-20T00:00:00</orderdate>
			</Order>
		</BookstoreCustomer>
		<BookstoreCustomer custid="102">
			<bookstore>Bookstore Beta</bookstore>
			<Order orderid="504">
				<orderdate>2014-09-18T00:00:00</orderdate>
			</Order>
			<Order orderid="505">
				<orderdate>2014-10-04T00:00:00</orderdate>
			</Order>
		</BookstoreCustomer>
	</BookstoreOrders>';

-- openXML
EXEC sp_xml_preparedocument @idoc output, @doc; 

SELECT * FROM OPENXML (@idoc, '/BookstoreOrders/BookstoreCustomer/Order',2)
WITH (orderid INT '@orderid', 
		orderdate DATETIME 'orderdate');

EXEC sp_xml_removedocument @idoc; 


/* 8 Bővítse az adatbázist legalább 1 új oszloppal (vagy egy új táblával) úgy, 
	hogy annak adattípusa  XML legyen, majd töltse fel tesztadatokkal. 
	Ezután hozzon létre 1 olyan lekérdezést, amelyben az új oszlop is szerepel. 
	Amennyiben nincs jogosultsága az új oszlop/tábla létrehozására, akkor hozzon létre 
	egy ideiglenes táblát, és azzal dolgozzon!	*/

	-- arra gondoltam adjuk hozzá hogy all-inclusive (korlátlan fogyasztás) 
	--vagy hogy félpanzió (szálláshelyen történő kétszeri étkezést jelent) 
	ALTER TABLE szallashely add Felpanzio XML;
	Select * from szallashely;


	-- xml típusú változó deklarálása: 
	declare @x xml
		set @x = N'
		<Szallashely>
		<Felpanzio="NEM"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="NEM"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="NEM"/>
		<Felpanzio="NEM"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="NEM"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="NEM"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="NEM"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		<Felpanzio="IGEN"/>
		</Szallashely>';

		declare @value nvarchar(50) = 'NINCS ADAT';
		UPDATE szallashely SET Felpanzio = @x WHERE Felpanzio IS NULL;

-- lekérdezés hozzá:
	Select * from szallashely;


-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*9. SQL => JSON 
Készítsen lekérdezést, amely megjeleníti, Hány szobája van az egyes szálláshelyeknek összesen, JSON-formátumban!*/

select Szallashely.SZALLAS_ID, sum(Szoba.FEROHELY) 'Összszobaszám' 
from Szallashely join Szoba on Szallashely.SZALLAS_ID = Szoba.SZALLAS_FK 
group by Szallashely.SZALLAS_ID for json auto;


/*10. JSON => SQL
A példában szereplő online áruház termékadatait látjuk JSON formátumban. 
Kérdezzük le egy lekérdezéssel a következő információkat:
A termék nevét, a jelenlegi árát, hány darab érhető el belőle, 
a megtekintésekből az összes Ratinget és hogy mennyi a szállítási költség */

  DECLARE @js NVARCHAR(MAX)
	SET @js = N'[{
	  "product": {
		"id": 101,
		"name": "Wireless Headphones",
		"category": "Electronics"
	  },
	  "price": {
		"current": 129.99,
		"discount": 10.5,
		"final": 116.49,
		"currency": "USD"
	  },
	  "stock": {
		"availability": "In Stock",
		"quantity": 250,
		"warehouse": "New York"
	  },
	  "reviews": [
		{
		  "id": 501,
		  "user": "JohnDoe",
		  "rating": 5,
		  "comment": "Excellent sound quality!",
		  "date": "2024-02-07T14:30:00"
		},
		{
		  "id": 502,
		  "user": "JaneSmith",
		  "rating": 4,
		  "comment": "Comfortable but a bit pricey.",
		  "date": "2024-02-06T10:15:00"
		}
	  ],
	  "delivery": {
		"shipping_cost": 5.99,
		"estimated_days": 3,
		"express_available": true
	  },
	  "supplier": {
		"id": 3001,
		"name": "TechSupplies Inc.",
		"location": "California, USA"
	  },
	  "last_updated": 1707302400
	}]';


   -- lekérdezés
   select json_value(@js, '$[0].product.name') AS ProductName,
		  json_value(@js, '$[0].price.current') AS CurrentPrice,
		  json_value(@js, '$[0].stock.quantity') AS AvailableQuantity,
		  json_value(@js, '$[0].reviews[0].rating') AS AvgRating1,
		  json_value(@js, '$[0].reviews[1].rating') AS AvgRating2,
	      json_value(@js, '$[0].delivery.shipping_cost') AS ShippingCost;


/*11.Az OPENJSON() függvény segítségével alakítsuk táblává az előbbi JSON dokumentumot!*/

DECLARE @js NVARCHAR(MAX)
	SET @js = N'[{
	  "product": {
		"id": 101,
		"name": "Wireless Headphones",
		"category": "Electronics"
	  },
	  "price": {
		"current": 129.99,
		"discount": 10.5,
		"final": 116.49,
		"currency": "USD"
	  },
	  "stock": {
		"availability": "In Stock",
		"quantity": 250,
		"warehouse": "New York"
	  },
	  "reviews": [
		{
		  "id": 501,
		  "user": "JohnDoe",
		  "rating": 5,
		  "comment": "Excellent sound quality!",
		  "date": "2024-02-07T14:30:00"
		},
		{
		  "id": 502,
		  "user": "JaneSmith",
		  "rating": 4,
		  "comment": "Comfortable but a bit pricey.",
		  "date": "2024-02-06T10:15:00"
		}
	  ],
	  "delivery": {
		"shipping_cost": 5.99,
		"estimated_days": 3,
		"express_available": true
	  },
	  "supplier": {
		"id": 3001,
		"name": "TechSupplies Inc.",
		"location": "California, USA"
	  },
	  "last_updated": 1707302400
	}]';

	SELECT * FROM OPENJSON (@js ,'$[0].reviews')
	  WITH (id INT '$.id',
			[user] VARCHAR(20) '$.user',
			rating INT '$.rating',
			comment VARCHAR(50) '$.comment',
			[date] DATETIME '$.date'); 


/*12.Alakítsa tábla formára a következő JSON kifejezést:*/

	DECLARE @json nvarchar(MAX)  
	SET @json = N'[
		{"name": "Alice", "email": "alice.wonderland@example.com"},
		{"name": "Charlie", "email": "charlie.brown@example.com"},
		{"name": "David", "email": "david.smith@example.com"}]';

	SELECT * FROM OPENJSON ( @json )
		WITH (
				[Name] VARCHAR(20) '$.name', 
				Email VARCHAR(50) '$.email');

 