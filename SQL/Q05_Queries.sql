-- =========================================
-- Queries
-- =========================================

USE FirmaDistributieBDR
GO


-- ============================================================
-- Q1 (AGREGARE, >=3 tabele):
-- Care este valoarea totală a vânzărilor pe centru și lună pentru vânzările procesate?
-- Tabele: VANZARI + LINII_VANZARE + CENTRE_DISTRIBUTIE
-- ============================================================
SELECT
        cd.Nume AS Centru,
        YEAR(v.DataVanzare) AS An,
        MONTH(v.DataVanzare) AS Luna,
        COUNT(DISTINCT v.IdVanzare) AS NrVanzari,
        CAST(SUM(lv.Cantitate * lv.PretUnitar * (1 - lv.DiscountProc/100.0)) AS decimal(12,2)) AS TotalValoare
FROM VANZARI v
JOIN CENTRE_DISTRIBUTIE cd ON cd.IdCentru = v.IdCentru
JOIN LINII_VANZARE lv ON lv.IdVanzare = v.IdVanzare
WHERE v.Status = 'Procesata'
GROUP BY cd.Nume, YEAR(v.DataVanzare), MONTH(v.DataVanzare)
ORDER BY An, Luna, Centru
GO


-- ============================================================
-- Q2 (AGREGARE, >=3 tabele):
-- Care sunt primii clienți după valoarea totală cumpărată și câte vânzări au realizat?
-- Tabele: CLIENTI + VANZARI + LINII_VANZARE
-- ============================================================
SELECT TOP 5
        cl.Nume AS Client,
        cl.SegmentClient,
        COUNT(DISTINCT v.IdVanzare) AS NrVanzari,
        CAST(SUM(lv.Cantitate * lv.PretUnitar * (1 - lv.DiscountProc/100.0)) AS decimal(12,2)) AS TotalCheltuit
FROM CLIENTI cl
JOIN VANZARI v ON v.IdClient = cl.IdClient
JOIN LINII_VANZARE lv ON lv.IdVanzare = v.IdVanzare
WHERE v.Status = 'Procesata'
GROUP BY cl.Nume, cl.SegmentClient
ORDER BY TotalCheltuit DESC
GO


-- ============================================================
-- Q3 (AGREGARE, >=3 tabele):
-- Cum se distribuie vânzările pe categorii de produse, în termeni de cantitate și valoare?
-- Tabele: CATEGORII + PRODUSE + LINII_VANZARE + VANZARI
-- ============================================================
SELECT
        c.Nume AS Categorie,
        SUM(lv.Cantitate) AS TotalBucati,
        CAST(SUM(lv.Cantitate * lv.PretUnitar * (1 - lv.DiscountProc/100.0)) AS decimal(12,2)) AS TotalValoare
FROM CATEGORII c
JOIN PRODUSE p ON p.IdCategorie = c.IdCategorie
JOIN LINII_VANZARE lv ON lv.IdProdus = p.IdProdus
JOIN VANZARI v ON v.IdVanzare = lv.IdVanzare
WHERE v.Status = 'Procesata'
GROUP BY c.Nume
ORDER BY TotalValoare DESC
GO


-- ============================================================
-- Q4 (AGREGARE, >=3 tabele):
-- Care este performanța angajaților în funcție de numărul de vânzări și valoarea acestora?
-- Tabele: ANGAJATI + VANZARI + LINII_VANZARE
-- ============================================================
SELECT
        a.Nume + ' ' + a.Prenume AS Angajat,
        a.Functie,
        COUNT(DISTINCT v.IdVanzare) AS NrVanzari,
        CAST(SUM(lv.Cantitate * lv.PretUnitar * (1 - lv.DiscountProc/100.0)) AS decimal(12,2)) AS TotalValoare
FROM ANGAJATI a
JOIN VANZARI v ON v.IdAngajat = a.IdAngajat
JOIN LINII_VANZARE lv ON lv.IdVanzare = v.IdVanzare
WHERE v.Status = 'Procesata'
GROUP BY a.Nume, a.Prenume, a.Functie
ORDER BY TotalValoare DESC
GO


-- ============================================================
-- Q5 (VIEW):
-- Ce detalii complete există pentru liniile de vânzare, incluzând centru, client, angajat, produs și categorie?
-- ============================================================
SELECT TOP 20
        IdVanzare, DataVanzare, Status,
        Centru, Client, SegmentClient,
        Produs, Categorie,
        Cantitate, PretUnitar, DiscountProc, ValoareNetaLinie
FROM dbo.VW_DETALII_VANZARI
ORDER BY DataVanzare DESC, IdVanzare DESC
GO


-- ============================================================
-- Q6 (VIEW):
-- Care sunt produsele aflate sub pragul minim de stoc în fiecare centru?
-- ============================================================
SELECT
        Centru, OrasCentru,
        SKU, Produs, Categorie,
        CantitateDisponibila, PragMinim
FROM dbo.VW_STOCURI_CENTRE
WHERE SubPrag = 1
ORDER BY Centru, Categorie, Produs
GO


-- ============================================================
-- Q7 (INLINE UDF):
-- Cum arată raportul vânzărilor pentru un interval de timp și un centru selectat?
-- ============================================================
SELECT TOP 30 *
FROM dbo.udf_RaportVanzariPeCentru('2025-01-01', '2025-04-30', 'Centru Bucuresti')
ORDER BY DataVanzare DESC, IdVanzare
GO


-- ============================================================
-- Q8 (INLINE UDF):
-- Care sunt cele mai valoroase produse vândute într-o lună/an dată?
-- ============================================================
SELECT *
FROM dbo.udf_Top5ProduseValoric(2025, 3)
GO
