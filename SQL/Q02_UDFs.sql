-- =========================================
-- (UDF)
-- =========================================

USE FirmaDistributieBDR
GO


-- =========================================
-- 0) Curatare dependente (constraint-uri care refera functiile)
-- =========================================

-- 0.1 Stergere CHECK constraint care refera udf_ValidEmail
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CLIENTI_EMAIL')
        ALTER TABLE CLIENTI DROP CONSTRAINT CK_CLIENTI_EMAIL
GO


-- 0.2 Stergere DEFAULT de pe VANZARI.MetodaPlata (indiferent de nume)
DECLARE @dfName nvarchar(128)

SELECT @dfName = dc.name
FROM sys.default_constraints dc
JOIN sys.columns col
        ON col.object_id = dc.parent_object_id
        AND col.column_id = dc.parent_column_id
WHERE dc.parent_object_id = OBJECT_ID('dbo.VANZARI')
  AND col.name = 'MetodaPlata'

IF (@dfName IS NOT NULL)
BEGIN
        EXEC('ALTER TABLE dbo.VANZARI DROP CONSTRAINT [' + @dfName + ']')
END
GO


-- =========================================
-- 1) DROP functii 
-- =========================================

IF OBJECT_ID('dbo.udf_ValidEmail', 'FN') IS NOT NULL
        DROP FUNCTION dbo.udf_ValidEmail
GO

IF OBJECT_ID('dbo.udf_DefaultMetodaPlata', 'FN') IS NOT NULL
        DROP FUNCTION dbo.udf_DefaultMetodaPlata
GO

IF OBJECT_ID('dbo.udf_RaportVanzariPeCentru', 'IF') IS NOT NULL
        DROP FUNCTION dbo.udf_RaportVanzariPeCentru
GO

IF OBJECT_ID('dbo.udf_Top5ProduseValoric', 'IF') IS NOT NULL
        DROP FUNCTION dbo.udf_Top5ProduseValoric
GO


-- =========================================
-- 2) Functie scalara pentru VALIDARE (Email)
-- =========================================

CREATE FUNCTION dbo.udf_ValidEmail(@Email varchar(150))
RETURNS bit
AS
BEGIN
        DECLARE @valid bit = 1

        IF (@Email IS NULL)
                RETURN 1

        IF (CHARINDEX(' ', @Email) > 0)
                SET @valid = 0

        IF (@Email NOT LIKE '%_@_%._%')
                SET @valid = 0

        IF (LEFT(@Email, 1) IN ('@', '.') OR RIGHT(@Email, 1) IN ('@', '.'))
                SET @valid = 0

        RETURN @valid
END
GO


-- Teste functie
SELECT dbo.udf_ValidEmail(NULL) AS Test_NULL
SELECT dbo.udf_ValidEmail('ioana.popescu@gmail.com') AS Test_OK
SELECT dbo.udf_ValidEmail('ioana.popescu@gmail') AS Test_FAIL
SELECT dbo.udf_ValidEmail('ioana popescu@gmail.com') AS Test_FAIL
GO


-- Asociere UDF in constrangere CHECK pe CLIENTI.Email
-- WITH NOCHECK: nu valideaza retroactiv randurile existente 
ALTER TABLE CLIENTI WITH NOCHECK
ADD CONSTRAINT CK_CLIENTI_EMAIL
CHECK (dbo.udf_ValidEmail(Email) = 1)
GO


-- =========================================
-- 3) Functie scalara pentru DEFAULT "logic"
--    - va fi asociata ca DEFAULT pentru VANZARI.MetodaPlata
-- =========================================

CREATE FUNCTION dbo.udf_DefaultMetodaPlata()
RETURNS varchar(15)
AS
BEGIN
        DECLARE @mp varchar(15)

        -- Dupa ora 18:00 => Transfer, altfel Card
        IF (DATEPART(HOUR, GETDATE()) >= 18)
                SET @mp = 'Transfer'
        ELSE
                SET @mp = 'Card'

        RETURN @mp
END
GO


-- Test functie
SELECT dbo.udf_DefaultMetodaPlata() AS MetodaPlataImplicita
GO


-- Asociere DEFAULT bazat pe UDF (pe coloana VANZARI.MetodaPlata)
ALTER TABLE dbo.VANZARI
ADD CONSTRAINT DF_VANZARI_MetodaPlata
DEFAULT (dbo.udf_DefaultMetodaPlata()) FOR MetodaPlata
GO


-- =========================================
-- 4) Functii in-line 
-- =========================================

-- 4.1 Functie in-line: Raport vanzari pe interval + centru
CREATE FUNCTION dbo.udf_RaportVanzariPeCentru
(
        @DataStart date,
        @DataEnd   date,
        @NumeCentru varchar(120)
)
RETURNS TABLE
AS
RETURN
SELECT
        v.IdVanzare,
        CAST(v.DataVanzare AS date) AS DataVanzare,
        cd.Nume AS Centru,
        cl.Nume AS Client,
        cl.SegmentClient,
        a.Nume + ' ' + a.Prenume AS Angajat,
        p.SKU,
        p.Denumire AS Produs,
        c.Nume AS Categorie,
        lv.Cantitate,
        lv.PretUnitar,
        lv.DiscountProc,
        CAST(lv.Cantitate * lv.PretUnitar * (1 - lv.DiscountProc/100.0) AS decimal(12,2)) AS ValoareLinie
FROM VANZARI v
JOIN CENTRE_DISTRIBUTIE cd ON cd.IdCentru = v.IdCentru
JOIN CLIENTI cl ON cl.IdClient = v.IdClient
JOIN ANGAJATI a ON a.IdAngajat = v.IdAngajat
JOIN LINII_VANZARE lv ON lv.IdVanzare = v.IdVanzare
JOIN PRODUSE p ON p.IdProdus = lv.IdProdus
JOIN CATEGORII c ON c.IdCategorie = p.IdCategorie
WHERE CAST(v.DataVanzare AS date) BETWEEN @DataStart AND @DataEnd
  AND cd.Nume = @NumeCentru
  AND v.Status <> 'Anulata'
GO

-- Test functie in-line
SELECT TOP 20 *
FROM dbo.udf_RaportVanzariPeCentru('2025-01-01', '2025-04-30', 'Centru Bucuresti')
ORDER BY DataVanzare DESC, IdVanzare
GO


-- 4.2 Functie in-line: Top 5 produse (valoric) pentru an + luna
CREATE FUNCTION dbo.udf_Top5ProduseValoric
(
        @An   int,
        @Luna int
)
RETURNS TABLE
AS
RETURN
SELECT TOP 5
        p.IdProdus,
        p.SKU,
        p.Denumire AS Produs,
        c.Nume AS Categorie,
        SUM(lv.Cantitate) AS TotalBucati,
        CAST(SUM(lv.Cantitate * lv.PretUnitar * (1 - lv.DiscountProc/100.0)) AS decimal(12,2)) AS TotalValoare
FROM VANZARI v
JOIN LINII_VANZARE lv ON lv.IdVanzare = v.IdVanzare
JOIN PRODUSE p ON p.IdProdus = lv.IdProdus
JOIN CATEGORII c ON c.IdCategorie = p.IdCategorie
WHERE YEAR(v.DataVanzare) = @An
  AND MONTH(v.DataVanzare) = @Luna
  AND v.Status = 'Procesata'
GROUP BY p.IdProdus, p.SKU, p.Denumire, c.Nume
ORDER BY TotalValoare DESC
GO

-- Test functie in-line
SELECT *
FROM dbo.udf_Top5ProduseValoric(2025, 3)
GO