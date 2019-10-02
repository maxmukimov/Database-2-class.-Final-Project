USE MyGuitarShop

--add GO where needed

--1--


IF OBJECT_ID('ProductsView') is not null
	DROP View ProductsView
GO
CREATE VIEW ProductsView AS
SELECT  ProductName , Description, ListPrice,  (ListPrice -(ListPrice * (DiscountPercent / 100))) as DiscountPrice 
FROM Products


GO
select *
from ProductsView

--2--
IF OBJECT_ID('createCustomerRole') is not null
	DROP PROC createCustomerRole
GO
IF OBJECT_ID('CustomerRole') is not null
	DROP role CustomerRole
GO
CREATE PROC createCustomerRole 
AS 
CREATE ROLE CustomerRole 

GRANT SELECT 
ON ProductsView 
TO  CustomerRole

--3--
IF OBJECT_ID('insertFromTXT') is not null
	DROP PROC insertFromTXT
GO
IF OBJECT_ID('Logins') is not null
	DROP TABLE Logins
GO
CREATE TABLE Logins(Email VARCHAR(40), LastName VARCHAR(40), FirstName VARCHAR(40))
GO
CREATE PROC insertFromTXT
 @location varchar(256)
AS
	DECLARE @DynamicSQL varchar(256)
	SET  @DynamicSQL =  ' BULKINSERT Logins  FROM ''' + @location + '''
	WITH(	FIELDTERMINATOR = '','', 	
		ROWTERMINATOR = ''\n''
	  ) '
	print @DynamicSQL
	exec(@DynamicSQL)
GO

EXEC insertFromTXT @location = 'C:\Users\Maxx\Desktop\names.txt'


--4--
GO
IF OBJECT_ID('insertFromXML') is not null
	DROP PROC insertFromXML
GO

CREATE PROC insertFromXML
 @xmlData varchar(4000)
AS
BEGIN

DECLARE @DataHandle int

EXEC sp_Xml_PrepareDocument 
	@DataHandle OUTPUT, @xmlData

IF OBJECT_ID('Logins') is not null
	DROP TABLE Logins
SELECT * INTO Logins
FROM OPENXML (@DataHandle, '/customerdata/customer') 
WITH (
    Email  varchar(40) 'email', 
    LastName VARCHAR(40) 'name/first', 
    FirstName VARCHAR(40) 'name/last' );

EXEC sp_Xml_RemoveDocument @DataHandle
END
go

--Procedure call
DECLARE @data VARCHAR(4000)
SET @data = ( SELECT BulkColumn
     FROM OPENROWSET (BULK 'C:\Users\Maxx\Desktop\names_xml.xml', SINGLE_CLOB) MyFile)

EXEC insertFromXML @xmlData = @data

--5--  I wasn't able to debug and fix questions 5 and 6. 
go
IF OBJECT_ID('createLogins') is not null
	DROP PROC createLogins
go
CREATE PROC createLogins
AS

DECLARE Logins_Cursor CURSOR
DYNAMIC 
FOR
    SELECT LastName , Email  FROM Logins 

   DECLARE @Last varchar(50), @Email varchar(50);	
  DECLARE @createLog varchar(4000);
	OPEN Logins_Cursor
FETCH NEXT FROM Logins_Cursor

WHILE @@FETCH_STATUS = 0
  BEGIN

 
SET @createLog = ' CREATE LOGIN    ((select LEFT ( ' + @Email + ', CHARINDEX(''@'', ' + @Email + ')-1) FROM Logins))  WITH PASSWORD = ' + @Last + '_17' + ' 
CHECK_POLICY = OFF, DEFAULT_DATABASE = MyGuitarShop; 
CREATE USER ((select LEFT ( ' + @Email + ', CHARINDEX(''@'', ' + @Email + ')-1) FROM Logins))   
 ALTER ROLE CustomerRole ADD MEMBER  ((select LEFT ( ' + @Email + ', CHARINDEX(''@'', ' + @Email + ')-1) FROM Logins))  '
    EXEC(@createLog)
    FETCH NEXT FROM Logins_Cursor;
	PRINT @createLog
   END
CLOSE Logins_Cursor;
DEALLOCATE Logins_Cursor;

go 
exec  createLogins

--6--
IF OBJECT_ID('dropLogins') is not null
	DROP PROC dropLogins

go
CREATE PROC dropLogins
    AS
Declare @Roles Table(DbRole varchar(20), MemberName varchar(50), MemberSID varchar(50));
INSERT INTO @Roles
EXEC sp_HelpRoleMember CustomerRole
go

DECLARE Member_Cursor CURSOR
DYNAMIC
FOR
SELECT  MemberName

FROM @Roles
EXEC sp_HelpRoleMember CustomerRole
    OPEN Member_Cursor
	DECLARE @theRole varchar (2000)

	FETCH NEXT FROM Member_Cursor into @Roles
INSERT INTO @Roles  values (@theRole)
    WHILE @@FETCH_STATUS = 0
        ALTER ROLE CustomerRole DROP MEMBER MemberName
    FETCH NEXT FROM Member_Cursor
    INTO @Roles 
CLOSE Member_Cursor
DEALLOCATE Member_Cursor


--7--
DECLARE @data xml
SET @data = (SELECT BulkColumn
     FROM OPENROWSET (BULK 'C:\Users\Maxx\Desktop\update_email.xml', SINGLE_BLOB) MyFile)

	 SELECT @data.value('/customerdata[1]/customer[/@name/first[1]]/email[1]','varchar(50)');
	  sELECT @data.value('/customerdata[1]/customer[name/last="Valentino"][1]/email[1]','varchar(50)');



DECLARE @data2 xml
SET @data2 = (SELECT BulkColumn
     FROM OPENROWSET (BULK 'C:\Users\Maxx\Desktop\update_email.xml', SINGLE_BLOB) MyFile)

	 
UPDATE Customers
SET EmailAddress = (Select @data2.value('/customerdata[1]/customer[1]/email[1]', 'varchar(50)'))
where FirstName = (Select @data2.value('/customerdata[1]/customer[1]/name[1]/first[1]', 'varchar(50)'))

	 
UPDATE Customers
SET EmailAddress = (Select @data2.value('/customerdata[1]/customer[2]/email[1]', 'varchar(50)'))
where FirstName = (Select @data2.value('/customerdata[1]/customer[2]/name[1]/first[1]', 'varchar(50)'))

UPDATE Customers
SET EmailAddress = (Select @data2.value('/customerdata[1]/customer[3]/email[1]', 'varchar(50)'))
where FirstName = (Select @data2.value('/customerdata[1]/customer[3]/name[1]/first[1]', 'varchar(50)'))


------------------------------------TEST CODE----------------------------------------------
--Remove any procedure test code you have added above.

--Use the following code to test your procedures. Do not edit anything here except file path. 
--When you click execute, this file should run successfully without any errors showing you the 
--ProductsView table, Logins table, CustomerRole Member table

--GO
--USE MyGuitarShop

--Select * from ProductsView

----reading XML data into Logins table
/*
DECLARE @data xml
--change the path of the file location for your server
SET @data = (SELECT BulkColumn
		     FROM OPENROWSET (BULK 'C:\Users\Maxx\Desktop\names_xml.xml', SINGLE_BLOB) MyFile)
EXEC insertFromXML @xmlData = @data
Select * from Logins
*/

----reading a text file data into Logins table
/*
--change the path of the file location for your server
EXEC insertFromTXT @fileLocation = 'C:\Users\MSSQL$DAY\Desktop\names.txt'
Select * from Logins
*/

----create CustomerRole and the Logins and test
--EXEC createCustomerRole
--EXEC createLogins
--EXEC sp_HelpRoleMember CustomerRole ------should show all Customers added to the role

----drop all the logins & users when you want and test
--EXEC dropLogins
--EXEC sp_HelpRoleMember CustomerRole ------should show an empty table after dropLogins is executed

----drop the role
--DROP ROLE CustomerRole







