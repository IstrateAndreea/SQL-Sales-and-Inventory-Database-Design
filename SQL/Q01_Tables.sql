-- =========================================
-- Tema: Firma distributie bauturi alcoolice
-- =========================================

-- Creare baza de date
CREATE DATABASE FirmaDistributieBDR
GO

-- Selectie baza de date de lucru
USE FirmaDistributieBDR
GO


-- Tabela Categorii
CREATE TABLE CATEGORII (
        IdCategorie             int                     PRIMARY KEY IDENTITY,
        Nume                    varchar(100)            NOT NULL UNIQUE,
        Descriere               varchar(255)            NULL,
        VarstaMinima            tinyint                 NOT NULL
                DEFAULT 18
                CHECK (VarstaMinima BETWEEN 0 AND 21)
)
GO


-- Tabela Produse
CREATE TABLE PRODUSE (
        IdProdus                int                     PRIMARY KEY IDENTITY,
        IdCategorie             int                     NOT NULL,
        Denumire                varchar(150)            NOT NULL,
        Brand                   varchar(100)            NULL,
        SKU                     varchar(30)             NOT NULL UNIQUE,
        Volum                   int                     NOT NULL
                CHECK (Volum > 0),
        ProcentAlcool           decimal(5,2)            NOT NULL
                CHECK (ProcentAlcool BETWEEN 0 AND 100),
        PretCatalog             decimal(10,2)           NOT NULL
                CHECK (PretCatalog >= 0)
)
GO


-- Tabela Clienti
CREATE TABLE CLIENTI (
        IdClient                int                     PRIMARY KEY IDENTITY,
        TipClient               varchar(10)             NOT NULL
                CHECK (TipClient IN ('PF', 'PJ')),
        Nume                    varchar(150)            NOT NULL,
        Telefon                 varchar(20)             NULL,
        Email                   varchar(150)            NULL,
        Oras                    varchar(80)             NOT NULL,
        Adresa                  varchar(200)            NOT NULL,
        SegmentClient           varchar(20)             NOT NULL
                DEFAULT 'Retail'
                CHECK (SegmentClient IN ('Retail', 'HoReCa', 'Online')),
        DiscountStandardProc    decimal(5,2)            NOT NULL
                DEFAULT 0
                CHECK (DiscountStandardProc BETWEEN 0 AND 100)
)
GO


-- Tabela Angajati
CREATE TABLE ANGAJATI (
        IdAngajat               int                     PRIMARY KEY IDENTITY,
        Nume                    varchar(80)             NOT NULL,
        Prenume                 varchar(80)             NOT NULL,
        Functie                 varchar(80)             NOT NULL,
        Telefon                 varchar(20)             NULL,
        Email                   varchar(150)            NULL UNIQUE,
        DataAngajare            date                    NOT NULL
                DEFAULT CAST(GETDATE() AS date)
)
GO


-- Tabela CentreDistributie
CREATE TABLE CENTRE_DISTRIBUTIE (
        IdCentru                int                     PRIMARY KEY IDENTITY,
        Nume                    varchar(120)            NOT NULL UNIQUE,
        Oras                    varchar(80)             NOT NULL,
        Adresa                  varchar(200)            NOT NULL,
        Telefon                 varchar(20)             NULL
)
GO


-- Tabela Vanzari
CREATE TABLE VANZARI (
        IdVanzare               int                     PRIMARY KEY IDENTITY,
        IdClient                int                     NOT NULL,
        IdAngajat               int                     NOT NULL,
        IdCentru                int                     NOT NULL,
        DataVanzare             datetime2               NOT NULL
                DEFAULT GETDATE(),
        Status                  varchar(15)             NOT NULL
                DEFAULT 'Noua'
                CHECK (Status IN ('Noua', 'Procesata', 'Anulata')),
        MetodaPlata             varchar(15)             NOT NULL
                DEFAULT 'Card'
                CHECK (MetodaPlata IN ('Card', 'Cash', 'Transfer'))
)
GO


-- Tabela LiniiVanzare (asociere M:N intre Vanzari si Produse)
CREATE TABLE LINII_VANZARE (
        IdVanzare               int                     NOT NULL,
        IdProdus                int                     NOT NULL,
        Cantitate               int                     NOT NULL
                CHECK (Cantitate > 0),
        PretUnitar              decimal(10,2)           NOT NULL
                CHECK (PretUnitar >= 0),
        DiscountProc            decimal(5,2)            NOT NULL
                DEFAULT 0
                CHECK (DiscountProc BETWEEN 0 AND 100),

        CONSTRAINT PK_LINII_VANZARE PRIMARY KEY (IdVanzare, IdProdus)
)
GO


-- Tabela Stocuri (asociere M:N intre CentreDistributie si Produse)
CREATE TABLE STOCURI (
        IdCentru                int                     NOT NULL,
        IdProdus                int                     NOT NULL,
        CantitateDisponibila    int                     NOT NULL
                DEFAULT 0
                CHECK (CantitateDisponibila >= 0),
        PragMinim               int                     NOT NULL
                DEFAULT 0
                CHECK (PragMinim >= 0),

        CONSTRAINT PK_STOCURI PRIMARY KEY (IdCentru, IdProdus)
)
GO


-- =========================================
-- Chei straine (FK)
-- =========================================

-- FK Produse -> Categorii
ALTER TABLE PRODUSE
ADD CONSTRAINT FK_PRODUSE_CATEGORII
FOREIGN KEY (IdCategorie) REFERENCES CATEGORII (IdCategorie)
GO

-- FK Vanzari -> Clienti
ALTER TABLE VANZARI
ADD CONSTRAINT FK_VANZARI_CLIENTI
FOREIGN KEY (IdClient) REFERENCES CLIENTI (IdClient)
GO

-- FK Vanzari -> Angajati
ALTER TABLE VANZARI
ADD CONSTRAINT FK_VANZARI_ANGAJATI
FOREIGN KEY (IdAngajat) REFERENCES ANGAJATI (IdAngajat)
GO

-- FK Vanzari -> CentreDistributie
ALTER TABLE VANZARI
ADD CONSTRAINT FK_VANZARI_CENTRE
FOREIGN KEY (IdCentru) REFERENCES CENTRE_DISTRIBUTIE (IdCentru)
GO

-- FK LiniiVanzare -> Vanzari
ALTER TABLE LINII_VANZARE
ADD CONSTRAINT FK_LINII_VANZARE_VANZARI
FOREIGN KEY (IdVanzare) REFERENCES VANZARI (IdVanzare)
GO

-- FK LiniiVanzare -> Produse
ALTER TABLE LINII_VANZARE
ADD CONSTRAINT FK_LINII_VANZARE_PRODUSE
FOREIGN KEY (IdProdus) REFERENCES PRODUSE (IdProdus)
GO

-- FK Stocuri -> CentreDistributie
ALTER TABLE STOCURI
ADD CONSTRAINT FK_STOCURI_CENTRE
FOREIGN KEY (IdCentru) REFERENCES CENTRE_DISTRIBUTIE (IdCentru)
GO

-- FK Stocuri -> Produse
ALTER TABLE STOCURI
ADD CONSTRAINT FK_STOCURI_PRODUSE
FOREIGN KEY (IdProdus) REFERENCES PRODUSE (IdProdus)
GO


USE FirmaDistributieBDR
GO


-- =========================================
-- Populare tabela CATEGORII
-- =========================================
INSERT INTO CATEGORII (Nume, Descriere, VarstaMinima) VALUES ('Vin',        'Vinuri linistite (rosu/alb/rose)', 18)
INSERT INTO CATEGORII (Nume, Descriere, VarstaMinima) VALUES ('Bere',       'Bere lager/IPA/nefiltrata',        18)
INSERT INTO CATEGORII (Nume, Descriere, VarstaMinima) VALUES ('Spirtoase',  'Whisky, vodka, gin, rom etc.',     18)
INSERT INTO CATEGORII (Nume, Descriere, VarstaMinima) VALUES ('Lichior',    'Lichioruri si aperitive',          18)
INSERT INTO CATEGORII (Nume, Descriere, VarstaMinima) VALUES ('Cidru',      'Cidru de mere/pere',                18)
INSERT INTO CATEGORII (Nume, Descriere, VarstaMinima) VALUES ('Spumante',   'Vinuri spumante',                   18)
GO


-- =========================================
-- Populare tabela CENTRE_DISTRIBUTIE
-- =========================================
INSERT INTO CENTRE_DISTRIBUTIE (Nume, Oras, Adresa, Telefon)
        VALUES ('Centru Bucuresti', 'Bucuresti', 'Str. Industriilor 10', '021-555-0100')
INSERT INTO CENTRE_DISTRIBUTIE (Nume, Oras, Adresa, Telefon)
        VALUES ('Centru Cluj', 'Cluj-Napoca', 'Bd. Muncii 25', '0264-555-0200')
INSERT INTO CENTRE_DISTRIBUTIE (Nume, Oras, Adresa, Telefon)
        VALUES ('Centru Iasi', 'Iasi', 'Str. Fabricii 7', '0232-555-0300')
GO


-- =========================================
-- Populare tabela ANGAJATI
-- =========================================
INSERT INTO ANGAJATI (Nume, Prenume, Functie, Telefon, Email, DataAngajare)
        VALUES ('Ionescu', 'Mihai', 'Manager Vanzari', '0722-100-101', 'mihai.ionescu@firma.ro', '2022-02-01')
INSERT INTO ANGAJATI (Nume, Prenume, Functie, Telefon, Email, DataAngajare)
        VALUES ('Popa', 'Ioana', 'Agent Vanzari', '0722-200-201', 'ioana.popa@firma.ro', '2023-03-15')
INSERT INTO ANGAJATI (Nume, Prenume, Functie, Telefon, Email, DataAngajare)
        VALUES ('Rusu', 'Andrei', 'Agent Vanzari', '0722-300-301', 'andrei.rusu@firma.ro', '2023-05-10')
INSERT INTO ANGAJATI (Nume, Prenume, Functie, Telefon, Email, DataAngajare)
        VALUES ('Dumitrescu', 'Elena', 'Agent Vanzari', '0722-400-401', 'elena.dumitrescu@firma.ro', '2024-01-05')
INSERT INTO ANGAJATI (Nume, Prenume, Functie, Telefon, Email, DataAngajare)
        VALUES ('Toma', 'Cristian', 'Gestionar', '0722-500-501', 'cristian.toma@firma.ro', '2022-09-20')
INSERT INTO ANGAJATI (Nume, Prenume, Functie, Telefon, Email, DataAngajare)
        VALUES ('Marinescu', 'Ana', 'Contabil', '0722-600-601', 'ana.marinescu@firma.ro', '2021-11-11')
GO


-- =========================================
-- Populare tabela CLIENTI
-- =========================================
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PJ', 'Bar Central', '0730-111-111', 'contact@barcentral.ro', 'Bucuresti', 'Calea Victoriei 100', 'HoReCa', 10)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PJ', 'Restaurant Riviera', '0730-222-222', 'rezervari@rivieracluj.ro', 'Cluj-Napoca', 'Str. Republicii 12', 'HoReCa', 12)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PJ', 'Magazin Vinoteca Nord', '0730-333-333', 'office@vinotecanord.ro', 'Iasi', 'Str. Stefan cel Mare 55', 'Retail', 8)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PJ', 'Market La Doi Pasi', '0730-444-444', 'manager@ladoipasi.ro', 'Cluj-Napoca', 'Str. Fabricii 3', 'Retail', 5)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PJ', 'E-Shop Bauturi Online', '0730-555-555', 'support@eshopbauturi.ro', 'Bucuresti', 'Bd. Unirii 1', 'Online', 7)
GO

INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PF', 'Popescu Ioana', '0740-101-101', 'ioana.popescu@gmail.com', 'Bucuresti', 'Str. Lalelelor 10', 'Retail', 0)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PF', 'Ionescu Andrei', '0740-202-202', 'andrei.ionescu@gmail.com', 'Cluj-Napoca', 'Str. Memorandumului 7', 'Online', 0)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PF', 'Marin Elena', '0740-303-303', 'elena.marin@gmail.com', 'Iasi', 'Str. Pacurari 21', 'Retail', 0)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PF', 'Dumitru Radu', '0740-404-404', 'radu.dumitru@gmail.com', 'Timisoara', 'Str. Aradului 5', 'Retail', 0)
INSERT INTO CLIENTI (TipClient, Nume, Telefon, Email, Oras, Adresa, SegmentClient, DiscountStandardProc)
        VALUES ('PF', 'Stan Maria', '0740-505-505', 'maria.stan@gmail.com', 'Bucuresti', 'Str. Bujorului 2', 'Online', 0)
GO


-- =========================================
-- Populare tabela PRODUSE
-- =========================================
INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Vin'),
                'Vin rosu Cabernet Sauvignon 0.75L', 'Crama Valea Mare', 'VIN-CAB-0750', 750, 13.50, 45.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Vin'),
                'Vin alb Sauvignon Blanc 0.75L', 'Crama Dealul Alb', 'VIN-SAU-0750', 750, 12.50, 42.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Vin'),
                'Vin rose 0.75L', 'Crama Rose', 'VIN-ROS-0750', 750, 12.00, 39.00)
GO

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spumante'),
                'Prosecco Spumant 0.75L', 'Valdo', 'SPU-PRO-0750', 750, 11.00, 55.00)
GO

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Bere'),
                'Bere Lager 0.5L', 'BrewHouse', 'BER-LAG-0500', 500, 5.00, 7.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Bere'),
                'Bere IPA 0.5L', 'BrewHouse', 'BER-IPA-0500', 500, 6.20, 9.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Bere'),
                'Bere Nefiltrata 0.5L', 'HopCraft', 'BER-NEF-0500', 500, 5.50, 8.00)
GO

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spirtoase'),
                'Whisky Jameson 0.7L', 'Jameson', 'SPI-JAM-0700', 700, 40.00, 110.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spirtoase'),
                'Whisky Glenfiddich 12Y 0.7L', 'Glenfiddich', 'SPI-GLF-0700', 700, 40.00, 220.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spirtoase'),
                'Vodka Absolut 0.7L', 'Absolut', 'SPI-ABS-0700', 700, 40.00, 95.00)
GO

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spirtoase'),
                'Gin Bombay Sapphire 0.7L', 'Bombay', 'SPI-BOM-0700', 700, 40.00, 120.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spirtoase'),
                'Rom Havana Club 0.7L', 'Havana Club', 'SPI-HAV-0700', 700, 40.00, 105.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spirtoase'),
                'Tequila Olmeca 0.7L', 'Olmeca', 'SPI-OLM-0700', 700, 38.00, 130.00)
GO

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Lichior'),
                'Lichior Baileys 0.7L', 'Baileys', 'LIC-BAI-0700', 700, 17.00, 85.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Lichior'),
                'Jagermeister 0.7L', 'Jagermeister', 'LIC-JAG-0700', 700, 35.00, 90.00)

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Lichior'),
                'Aperitiv Aperol 0.7L', 'Aperol', 'LIC-APE-0700', 700, 11.00, 95.00)
GO

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Cidru'),
                'Cidru de mere 0.5L', 'ApplePress', 'CID-MER-0500', 500, 4.50, 8.00)
GO

INSERT INTO PRODUSE (IdCategorie, Denumire, Brand, SKU, Volum, ProcentAlcool, PretCatalog)
        VALUES ((SELECT IdCategorie FROM CATEGORII WHERE Nume='Spirtoase'),
                'Cognac Hennessy 0.7L', 'Hennessy', 'SPI-HEN-0700', 700, 40.00, 350.00)
GO


-- =========================================
-- Populare tabela STOCURI
-- Stocuri pe fiecare centru + stoc scazut 
-- =========================================

-- Stocuri - Centru Bucuresti
INSERT INTO STOCURI (IdCentru, IdProdus, CantitateDisponibila, PragMinim)
        VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-CAB-0750'), 80, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-SAU-0750'), 70, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-ROS-0750'), 60, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPU-PRO-0750'), 50, 15)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-LAG-0500'), 500, 100)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-IPA-0500'), 200, 50)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-NEF-0500'), 150, 40)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-JAM-0700'), 40, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-GLF-0700'), 5, 10)     -- stoc scazut
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-ABS-0700'), 60, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-BOM-0700'), 50, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HAV-0700'), 45, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-OLM-0700'), 25, 10)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-BAI-0700'), 30, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-JAG-0700'), 35, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-APE-0700'), 55, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='CID-MER-0500'), 180, 50)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HEN-0700'), 3, 5)      -- stoc scazut
GO


-- Stocuri - Centru Cluj
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-CAB-0750'), 90, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-SAU-0750'), 80, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-ROS-0750'), 50, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPU-PRO-0750'), 40, 15)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-LAG-0500'), 400, 100)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-IPA-0500'), 180, 50)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-NEF-0500'), 120, 40)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-JAM-0700'), 8, 10)     -- stoc scazut
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-GLF-0700'), 12, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-ABS-0700'), 40, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-BOM-0700'), 30, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HAV-0700'), 25, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-OLM-0700'), 20, 10)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-BAI-0700'), 15, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-JAG-0700'), 22, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-APE-0700'), 35, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='CID-MER-0500'), 140, 50)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HEN-0700'), 6, 5)
GO


-- Stocuri - Centru Iasi
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-CAB-0750'), 60, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-SAU-0750'), 55, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-ROS-0750'), 40, 20)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPU-PRO-0750'), 5, 15)     -- stoc scazut
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-LAG-0500'), 250, 100)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-IPA-0500'), 120, 50)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-NEF-0500'), 90, 40)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-JAM-0700'), 20, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-GLF-0700'), 6, 10)     -- stoc scazut
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-ABS-0700'), 30, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-BOM-0700'), 20, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HAV-0700'), 18, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-OLM-0700'), 10, 10)
GO
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-BAI-0700'), 12, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-JAG-0700'), 15, 10)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-APE-0700'), 18, 15)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='CID-MER-0500'), 100, 50)
INSERT INTO STOCURI VALUES ((SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HEN-0700'), 2, 5)      -- stoc scazut
GO


-- =========================================
-- Populare tabela VANZARI + LINII_VANZARE
-- =========================================

-- Vanzare 1 - Bar Central (HoReCa) - Centru Bucuresti - Agent Ioana
DECLARE @V1 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Bar Central'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='ioana.popa@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                '2025-01-10', 'Procesata', 'Transfer')
SET @V1 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE (IdVanzare, IdProdus, Cantitate, PretUnitar, DiscountProc)
        VALUES (@V1, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-JAM-0700'), 6, 110.00, 10)
INSERT INTO LINII_VANZARE VALUES (@V1, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-ABS-0700'), 12, 95.00, 10)
INSERT INTO LINII_VANZARE VALUES (@V1, (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-LAG-0500'), 48, 7.00, 10)
GO


-- Vanzare 2 - Popescu Ioana (PF) - Centru Bucuresti - Agent Andrei
DECLARE @V2 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Popescu Ioana'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='andrei.rusu@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                '2025-01-12', 'Procesata', 'Card')
SET @V2 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V2, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPU-PRO-0750'), 2, 55.00, 0)
INSERT INTO LINII_VANZARE VALUES (@V2, (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-BAI-0700'), 1, 85.00, 0)
GO


-- Vanzare 3 - Restaurant Riviera (HoReCa) - Centru Cluj - Agent Elena
DECLARE @V3 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Restaurant Riviera'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='elena.dumitrescu@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                '2025-02-03', 'Procesata', 'Transfer')
SET @V3 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V3, (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-APE-0700'), 10, 95.00, 12)
INSERT INTO LINII_VANZARE VALUES (@V3, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPU-PRO-0750'), 12, 55.00, 12)
INSERT INTO LINII_VANZARE VALUES (@V3, (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-LAG-0500'), 60, 7.00, 12)
GO


-- Vanzare 4 - Magazin Vinoteca Nord (Retail) - Centru Iasi - Agent Ioana (Status Noua)
DECLARE @V4 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Magazin Vinoteca Nord'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='ioana.popa@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                '2025-02-15', 'Noua', 'Transfer')
SET @V4 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V4, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-GLF-0700'), 2, 220.00, 8)
INSERT INTO LINII_VANZARE VALUES (@V4, (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-CAB-0750'), 24, 45.00, 8)
INSERT INTO LINII_VANZARE VALUES (@V4, (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-SAU-0750'), 24, 42.00, 8)
GO


-- Vanzare 5 - E-Shop Bauturi Online (Online) - Centru Bucuresti - Agent Andrei
DECLARE @V5 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='E-Shop Bauturi Online'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='andrei.rusu@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                '2025-03-01', 'Procesata', 'Card')
SET @V5 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V5, (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-IPA-0500'), 24, 9.00, 7)
INSERT INTO LINII_VANZARE VALUES (@V5, (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-JAG-0700'), 6, 90.00, 7)
INSERT INTO LINII_VANZARE VALUES (@V5, (SELECT IdProdus FROM PRODUSE WHERE SKU='CID-MER-0500'), 24, 8.00, 7)
GO


-- Vanzare 6 - Market La Doi Pasi (Retail) - Centru Cluj - Agent Elena
DECLARE @V6 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Market La Doi Pasi'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='elena.dumitrescu@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                '2025-03-04', 'Procesata', 'Cash')
SET @V6 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V6, (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-LAG-0500'), 120, 7.00, 5)
INSERT INTO LINII_VANZARE VALUES (@V6, (SELECT IdProdus FROM PRODUSE WHERE SKU='CID-MER-0500'), 60, 8.00, 5)
GO


-- Vanzare 7 - Ionescu Andrei (PF, Online) - Centru Cluj - Agent Andrei (Status Anulata)
DECLARE @V7 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Ionescu Andrei'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='andrei.rusu@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                '2025-03-06', 'Anulata', 'Card')
SET @V7 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V7, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-OLM-0700'), 1, 130.00, 0)
INSERT INTO LINII_VANZARE VALUES (@V7, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-BOM-0700'), 1, 120.00, 0)
GO


-- Vanzare 8 - Marin Elena (PF) - Centru Iasi - Agent Ioana
DECLARE @V8 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Marin Elena'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='ioana.popa@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                '2025-03-10', 'Procesata', 'Card')
SET @V8 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V8, (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-ROS-0750'), 6, 39.00, 0)
INSERT INTO LINII_VANZARE VALUES (@V8, (SELECT IdProdus FROM PRODUSE WHERE SKU='CID-MER-0500'), 12, 8.00, 0)
GO


-- Vanzare 9 - Bar Central (HoReCa) - Centru Bucuresti - Agent Ioana
DECLARE @V9 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Bar Central'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='ioana.popa@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                '2025-04-02', 'Procesata', 'Transfer')
SET @V9 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V9, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HAV-0700'), 12, 105.00, 10)
INSERT INTO LINII_VANZARE VALUES (@V9, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-BOM-0700'), 12, 120.00, 10)
INSERT INTO LINII_VANZARE VALUES (@V9, (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-LAG-0500'), 96, 7.00, 10)
GO


-- Vanzare 10 - Restaurant Riviera (HoReCa) - Centru Cluj - Agent Elena
DECLARE @V10 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Restaurant Riviera'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='elena.dumitrescu@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Cluj'),
                '2025-04-05', 'Procesata', 'Transfer')
SET @V10 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V10, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-JAM-0700'), 3, 110.00, 12)
INSERT INTO LINII_VANZARE VALUES (@V10, (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-JAG-0700'), 12, 90.00, 12)
INSERT INTO LINII_VANZARE VALUES (@V10, (SELECT IdProdus FROM PRODUSE WHERE SKU='BER-IPA-0500'), 48, 9.00, 12)
GO


-- Vanzare 11 - Dumitru Radu (PF) - Centru Bucuresti - Agent Andrei (Status Noua)
DECLARE @V11 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Dumitru Radu'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='andrei.rusu@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Bucuresti'),
                '2025-04-10', 'Noua', 'Card')
SET @V11 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V11, (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-SAU-0750'), 3, 42.00, 0)
INSERT INTO LINII_VANZARE VALUES (@V11, (SELECT IdProdus FROM PRODUSE WHERE SKU='LIC-BAI-0700'), 1, 85.00, 0)
GO


-- Vanzare 12 - Magazin Vinoteca Nord (Retail) - Centru Iasi - Agent Ioana (data mai veche)
DECLARE @V12 int
INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
        VALUES ((SELECT IdClient FROM CLIENTI WHERE Nume='Magazin Vinoteca Nord'),
                (SELECT IdAngajat FROM ANGAJATI WHERE Email='ioana.popa@firma.ro'),
                (SELECT IdCentru FROM CENTRE_DISTRIBUTIE WHERE Nume='Centru Iasi'),
                '2024-12-20', 'Procesata', 'Transfer')
SET @V12 = SCOPE_IDENTITY()

INSERT INTO LINII_VANZARE VALUES (@V12, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPI-HEN-0700'), 1, 350.00, 8)
INSERT INTO LINII_VANZARE VALUES (@V12, (SELECT IdProdus FROM PRODUSE WHERE SKU='VIN-CAB-0750'), 12, 45.00, 8)
INSERT INTO LINII_VANZARE VALUES (@V12, (SELECT IdProdus FROM PRODUSE WHERE SKU='SPU-PRO-0750'), 6, 55.00, 8)
GO