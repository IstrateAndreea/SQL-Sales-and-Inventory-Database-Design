-- =========================================
-- Views
-- =========================================

USE FirmaDistributieBDR
GO

-- ============================================================
-- View 1: VW_DETALII_VANZARI
-- Pregatire date pentru rapoarte: vanzari + clienti + angajati + centre + linii + produse + categorii
-- ============================================================

IF OBJECT_ID('dbo.VW_DETALII_VANZARI', 'V') IS NOT NULL
        DROP VIEW dbo.VW_DETALII_VANZARI
GO

CREATE VIEW dbo.VW_DETALII_VANZARI
AS
SELECT
        v.IdVanzare,
        v.DataVanzare,
        v.Status,
        v.MetodaPlata,

        cl.IdClient,
        cl.Nume AS Client,
        cl.TipClient,
        cl.SegmentClient,
        cl.DiscountStandardProc,

        a.IdAngajat,
        a.Nume + ' ' + a.Prenume AS Angajat,
        a.Functie,

        cd.IdCentru,
        cd.Nume AS Centru,
        cd.Oras AS OrasCentru,

        p.IdProdus,
        p.SKU,
        p.Denumire AS Produs,
        p.Brand,
        p.Volum,
        p.ProcentAlcool,
        p.PretCatalog,

        c.IdCategorie,
        c.Nume AS Categorie,

        lv.Cantitate,
        lv.PretUnitar,
        lv.DiscountProc,

        CAST(lv.Cantitate * lv.PretUnitar AS decimal(12,2)) AS ValoareBrutaLinie,
        CAST(lv.Cantitate * lv.PretUnitar * (1 - lv.DiscountProc/100.0) AS decimal(12,2)) AS ValoareNetaLinie
FROM VANZARI v
JOIN CLIENTI cl ON cl.IdClient = v.IdClient
JOIN ANGAJATI a ON a.IdAngajat = v.IdAngajat
JOIN CENTRE_DISTRIBUTIE cd ON cd.IdCentru = v.IdCentru
JOIN LINII_VANZARE lv ON lv.IdVanzare = v.IdVanzare
JOIN PRODUSE p ON p.IdProdus = lv.IdProdus
JOIN CATEGORII c ON c.IdCategorie = p.IdCategorie
GO


-- Test View 1
SELECT TOP 20 *
FROM dbo.VW_DETALII_VANZARI
ORDER BY DataVanzare DESC, IdVanzare DESC
GO


-- ============================================================
-- View 2: VW_STOCURI_CENTRE
-- Pregatire date pentru stocuri: stocuri + centre + produse + categorii
-- ============================================================

IF OBJECT_ID('dbo.VW_STOCURI_CENTRE', 'V') IS NOT NULL
        DROP VIEW dbo.VW_STOCURI_CENTRE
GO

CREATE VIEW dbo.VW_STOCURI_CENTRE
AS
SELECT
        cd.IdCentru,
        cd.Nume AS Centru,
        cd.Oras AS OrasCentru,

        p.IdProdus,
        p.SKU,
        p.Denumire AS Produs,
        p.Brand,
        p.Volum,
        p.ProcentAlcool,
        p.PretCatalog,

        c.IdCategorie,
        c.Nume AS Categorie,

        s.CantitateDisponibila,
        s.PragMinim,
        CASE
                WHEN s.CantitateDisponibila < s.PragMinim THEN 1
                ELSE 0
        END AS SubPrag
FROM STOCURI s
JOIN CENTRE_DISTRIBUTIE cd ON cd.IdCentru = s.IdCentru
JOIN PRODUSE p ON p.IdProdus = s.IdProdus
JOIN CATEGORII c ON c.IdCategorie = p.IdCategorie
GO


-- Test View 2
SELECT TOP 30 *
FROM dbo.VW_STOCURI_CENTRE
ORDER BY SubPrag DESC, Centru, Categorie, Produs
GO


-- Test: doar produsele sub prag
SELECT *
FROM dbo.VW_STOCURI_CENTRE
WHERE SubPrag = 1
ORDER BY Centru, Produs
GO