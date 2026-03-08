-- =========================================
-- Proceduri stocate (SPs)
-- =========================================

USE FirmaDistributieBDR
GO


-- ============================================================
-- Procedura 1: Insert VANZARE + 1 LINIE_VANZARE + Update STOC
-- Identificare pe descrieri:
--   - Client: Nume
--   - Angajat: Email
--   - Centru: Nume
--   - Produs: SKU
-- Return codes:
--   0   = OK
--  -1   = Client inexistent
--  -2   = Angajat inexistent
--  -3   = Centru inexistent
--  -4   = Produs inexistent
--  -5   = Status invalid
--  -6   = MetodaPlata invalida
--  -7   = Date invalide (cantitate/pret/discount/data)
--  -8   = Stoc insuficient / stoc inexistent
--  -99  = Eroare neasteptata (catch)
-- ============================================================

DROP PROCEDURE IF EXISTS dbo.usp_Insert_Vanzare_Descrieri
GO

CREATE OR ALTER PROCEDURE dbo.usp_Insert_Vanzare_Descrieri
(
        @NumeClient      varchar(150),
        @EmailAngajat    varchar(150),
        @NumeCentru      varchar(120),

        @SKU             varchar(30),
        @Cantitate       int,
        @PretUnitar      decimal(10,2) = NULL,
        @DiscountProc    decimal(5,2)  = 0,

        @DataVanzare     datetime2     = NULL,
        @Status          varchar(15)   = 'Noua',
        @MetodaPlata     varchar(15)   = NULL,

        @IdVanzareOut    int           OUTPUT
)
AS
SET QUOTED_IDENTIFIER OFF
SET NOCOUNT ON

DECLARE
        @IdClient   int,
        @IdAngajat  int,
        @IdCentru   int,
        @IdProdus   int,
        @Stoc       int

BEGIN TRY
        -- Validari simple
        IF (@Status NOT IN ('Noua','Procesata','Anulata'))
        BEGIN
                RAISERROR('Status invalid.', 11, 1)
                RETURN -5
        END

        IF (@MetodaPlata IS NOT NULL AND @MetodaPlata NOT IN ('Card','Cash','Transfer'))
        BEGIN
                RAISERROR('MetodaPlata invalida.', 11, 1)
                RETURN -6
        END

        IF (@Cantitate IS NULL OR @Cantitate <= 0)
        BEGIN
                RAISERROR('Cantitate invalida.', 11, 1)
                RETURN -7
        END

        IF (@DiscountProc IS NULL OR @DiscountProc < 0 OR @DiscountProc > 100)
        BEGIN
                RAISERROR('DiscountProc invalid.', 11, 1)
                RETURN -7
        END

        IF (@DataVanzare IS NULL)
                SET @DataVanzare = GETDATE()

        IF (@DataVanzare > DATEADD(day, 1, GETDATE()))
        BEGIN
                RAISERROR('DataVanzare nu poate fi in viitor.', 11, 1)
                RETURN -7
        END

        -- Cautare ID-uri pe baza de descrieri (NU ID-uri de la utilizator)
        SELECT @IdClient = IdClient
        FROM CLIENTI
        WHERE Nume = @NumeClient

        IF (@IdClient IS NULL)
        BEGIN
                RAISERROR('Client inexistent.', 11, 1)
                RETURN -1
        END

        SELECT @IdAngajat = IdAngajat
        FROM ANGAJATI
        WHERE Email = @EmailAngajat

        IF (@IdAngajat IS NULL)
        BEGIN
                RAISERROR('Angajat inexistent.', 11, 1)
                RETURN -2
        END

        SELECT @IdCentru = IdCentru
        FROM CENTRE_DISTRIBUTIE
        WHERE Nume = @NumeCentru

        IF (@IdCentru IS NULL)
        BEGIN
                RAISERROR('Centru distributie inexistent.', 11, 1)
                RETURN -3
        END

        SELECT @IdProdus = IdProdus
        FROM PRODUSE
        WHERE SKU = @SKU

        IF (@IdProdus IS NULL)
        BEGIN
                RAISERROR('Produs inexistent (SKU).', 11, 1)
                RETURN -4
        END

        -- PretUnitar: daca nu e dat, luam PretCatalog
        IF (@PretUnitar IS NULL)
        BEGIN
                SELECT @PretUnitar = PretCatalog
                FROM PRODUSE
                WHERE IdProdus = @IdProdus
        END

        IF (@PretUnitar IS NULL OR @PretUnitar < 0)
        BEGIN
                RAISERROR('PretUnitar invalid.', 11, 1)
                RETURN -7
        END

        -- MetodaPlata: daca nu e data, folosim UDF de default
        IF (@MetodaPlata IS NULL)
                SET @MetodaPlata = dbo.udf_DefaultMetodaPlata()

        BEGIN TRAN

                -- Verificare stoc (cu lock pentru consistenta in tranzactie)
                SELECT @Stoc = CantitateDisponibila
                FROM STOCURI WITH (UPDLOCK, HOLDLOCK)
                WHERE IdCentru = @IdCentru AND IdProdus = @IdProdus

                IF (@Stoc IS NULL)
                BEGIN
                        RAISERROR('Nu exista stoc pentru produs in centrul dat.', 11, 1)
                        ROLLBACK TRAN
                        RETURN -8
                END

                IF (@Stoc < @Cantitate)
                BEGIN
                        RAISERROR('Stoc insuficient.', 11, 1)
                        ROLLBACK TRAN
                        RETURN -8
                END

                -- Inserare VANZARE
                INSERT INTO VANZARI (IdClient, IdAngajat, IdCentru, DataVanzare, Status, MetodaPlata)
                VALUES (@IdClient, @IdAngajat, @IdCentru, @DataVanzare, @Status, @MetodaPlata)

                SET @IdVanzareOut = SCOPE_IDENTITY()

                -- Inserare LINIE (o singura linie per apel)
                INSERT INTO LINII_VANZARE (IdVanzare, IdProdus, Cantitate, PretUnitar, DiscountProc)
                VALUES (@IdVanzareOut, @IdProdus, @Cantitate, @PretUnitar, @DiscountProc)

                -- Update STOC
                UPDATE STOCURI
                SET CantitateDisponibila = CantitateDisponibila - @Cantitate
                WHERE IdCentru = @IdCentru AND IdProdus = @IdProdus

        COMMIT TRAN

        RETURN 0
END TRY
BEGIN CATCH
        IF (@@TRANCOUNT > 0)
                ROLLBACK TRAN

        DECLARE @ErrorMessage NVARCHAR(1000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -99
END CATCH
GO


-- ============================================================
-- Procedura 2: Update VANZARE (identificare pe descrieri)
-- + update/insert o linie pentru un produs (SKU) + ajustare stoc
-- Return codes:
-- same +: 
--  -9   = Vanzare neidentificata
-- ============================================================

DROP PROCEDURE IF EXISTS dbo.usp_Update_Vanzare_Descrieri
GO

CREATE OR ALTER PROCEDURE dbo.usp_Update_Vanzare_Descrieri
(
        -- Identificare vanzare (descrieri)
        @NumeClient          varchar(150),
        @NumeCentru          varchar(120),
        @DataVanzare         date,
        @EmailAngajat        varchar(150) = NULL,   -- identificare mai precisa

        -- Campuri de actualizat in VANZARI
        @StatusNou           varchar(15)  = NULL,
        @MetodaPlataNou      varchar(15)  = NULL,
        @DataVanzareNoua     datetime2    = NULL,
        @EmailAngajatNou     varchar(150) = NULL,   -- schimba vanzatorul pe baza emailului

        -- Actualizare/insert o linie (SKU) + ajustare stoc
        @SKU                 varchar(30)  = NULL,
        @CantitateNoua       int          = NULL,
        @PretUnitarNou       decimal(10,2)= NULL,
        @DiscountProcNou     decimal(5,2) = NULL
)
AS
SET QUOTED_IDENTIFIER OFF
SET NOCOUNT ON

DECLARE
        @IdClient   int,
        @IdCentru   int,
        @IdAngajat  int,
        @IdAngajatNou int,
        @IdVanzare  int,
        @IdProdus   int,
        @CantitateVeche int,
        @Delta int,
        @Stoc int

BEGIN TRY
        -- Validari (doar daca se modifica)
        IF (@StatusNou IS NOT NULL AND @StatusNou NOT IN ('Noua','Procesata','Anulata'))
        BEGIN
                RAISERROR('StatusNou invalid.', 11, 1)
                RETURN -5
        END

        IF (@MetodaPlataNou IS NOT NULL AND @MetodaPlataNou NOT IN ('Card','Cash','Transfer'))
        BEGIN
                RAISERROR('MetodaPlataNou invalida.', 11, 1)
                RETURN -6
        END

        IF (@DataVanzareNoua IS NOT NULL AND @DataVanzareNoua > DATEADD(day, 1, GETDATE()))
        BEGIN
                RAISERROR('DataVanzareNoua nu poate fi in viitor.', 11, 1)
                RETURN -7
        END

        -- ID-uri pe descrieri
        SELECT @IdClient = IdClient
        FROM CLIENTI
        WHERE Nume = @NumeClient

        IF (@IdClient IS NULL)
        BEGIN
            RAISERROR('Client inexistent.', 11, 1)
            RETURN -1
        END

        SELECT @IdCentru = IdCentru
        FROM CENTRE_DISTRIBUTIE
        WHERE Nume = @NumeCentru

        IF (@IdCentru IS NULL)
        BEGIN
            RAISERROR('Centru distributie inexistent.', 11, 1)
            RETURN -3
        END

        IF (@EmailAngajat IS NOT NULL)
        BEGIN
                SELECT @IdAngajat = IdAngajat
                FROM ANGAJATI
                WHERE Email = @EmailAngajat

                IF (@IdAngajat IS NULL)
                BEGIN
                        RAISERROR('Angajat (pentru identificare) inexistent.', 11, 1)
                        RETURN -2
                END
        END

        -- Gasim vanzarea dupa descrieri (fara ID)
        SELECT TOP 1
                @IdVanzare = v.IdVanzare
        FROM VANZARI v
        WHERE v.IdClient = @IdClient
          AND v.IdCentru = @IdCentru
          AND CAST(v.DataVanzare AS date) = @DataVanzare
          AND (@IdAngajat IS NULL OR v.IdAngajat = @IdAngajat)
        ORDER BY v.IdVanzare DESC

        IF (@IdVanzare IS NULL)
        BEGIN
                RAISERROR('Vanzare neidentificata.', 11, 1)
                RETURN -9
        END

        -- Angajat nou 
        IF (@EmailAngajatNou IS NOT NULL)
        BEGIN
                SELECT @IdAngajatNou = IdAngajat
                FROM ANGAJATI
                WHERE Email = @EmailAngajatNou

                IF (@IdAngajatNou IS NULL)
                BEGIN
                        RAISERROR('AngajatNou inexistent.', 11, 1)
                        RETURN -2
                END
        END

        -- Daca vrem update pe linie, validam parametrii liniei
        IF (@SKU IS NOT NULL)
        BEGIN
                SELECT @IdProdus = IdProdus
                FROM PRODUSE
                WHERE SKU = @SKU

                IF (@IdProdus IS NULL)
                BEGIN
                        RAISERROR('Produs inexistent (SKU).', 11, 1)
                        RETURN -4
                END

                IF (@CantitateNoua IS NOT NULL AND @CantitateNoua <= 0)
                BEGIN
                        RAISERROR('CantitateNoua invalida.', 11, 1)
                        RETURN -7
                END

                IF (@DiscountProcNou IS NOT NULL AND (@DiscountProcNou < 0 OR @DiscountProcNou > 100))
                BEGIN
                        RAISERROR('DiscountProcNou invalid.', 11, 1)
                        RETURN -7
                END

                IF (@PretUnitarNou IS NOT NULL AND @PretUnitarNou < 0)
                BEGIN
                        RAISERROR('PretUnitarNou invalid.', 11, 1)
                        RETURN -7
                END
        END

        BEGIN TRAN

                -- Update antet VANZARE
                UPDATE VANZARI
                SET
                        Status = COALESCE(@StatusNou, Status),
                        MetodaPlata = COALESCE(@MetodaPlataNou, MetodaPlata),
                        DataVanzare = COALESCE(@DataVanzareNoua, DataVanzare),
                        IdAngajat = COALESCE(@IdAngajatNou, IdAngajat)
                WHERE IdVanzare = @IdVanzare

                --  update/insert linie + ajustare stoc
                IF (@SKU IS NOT NULL)
                BEGIN
                        SELECT @CantitateVeche = Cantitate
                        FROM LINII_VANZARE
                        WHERE IdVanzare = @IdVanzare AND IdProdus = @IdProdus

                        -- Daca nu s-a dat CantitateNoua:
                        -- - daca linia exista => pastram vechea cantitate
                        -- - daca linia nu exista => trebuie sa fie data (altfel nu stim ce inseram)
                        IF (@CantitateNoua IS NULL)
                        BEGIN
                                IF (@CantitateVeche IS NULL)
                                BEGIN
                                        RAISERROR('Pentru produs nou pe vanzare, CantitateNoua este obligatorie.', 11, 1)
                                        ROLLBACK TRAN
                                        RETURN -7
                                END
                                ELSE
                                        SET @CantitateNoua = @CantitateVeche
                        END

                        -- Pret/Discount: daca nu sunt date, pastram vechiul; daca nu exista linia, luam pret catalog / 0
                        IF (@PretUnitarNou IS NULL)
                        BEGIN
                                IF EXISTS (SELECT 1 FROM LINII_VANZARE WHERE IdVanzare=@IdVanzare AND IdProdus=@IdProdus)
                                        SELECT @PretUnitarNou = PretUnitar
                                        FROM LINII_VANZARE
                                        WHERE IdVanzare=@IdVanzare AND IdProdus=@IdProdus
                                ELSE
                                        SELECT @PretUnitarNou = PretCatalog
                                        FROM PRODUSE WHERE IdProdus=@IdProdus
                        END

                        IF (@DiscountProcNou IS NULL)
                        BEGIN
                                IF EXISTS (SELECT 1 FROM LINII_VANZARE WHERE IdVanzare=@IdVanzare AND IdProdus=@IdProdus)
                                        SELECT @DiscountProcNou = DiscountProc
                                        FROM LINII_VANZARE
                                        WHERE IdVanzare=@IdVanzare AND IdProdus=@IdProdus
                                ELSE
                                        SET @DiscountProcNou = 0
                        END

                        SET @Delta = @CantitateNoua - ISNULL(@CantitateVeche, 0)

                        -- Daca delta > 0 => mai scadem stoc (verificam)
                        -- Daca delta < 0 => returnam stoc (adaugam inapoi)
                        IF (@Delta > 0)
                        BEGIN
                                SELECT @Stoc = CantitateDisponibila
                                FROM STOCURI WITH (UPDLOCK, HOLDLOCK)
                                WHERE IdCentru = @IdCentru AND IdProdus = @IdProdus

                                IF (@Stoc IS NULL)
                                BEGIN
                                        RAISERROR('Nu exista stoc pentru produs in centrul dat.', 11, 1)
                                        ROLLBACK TRAN
                                        RETURN -8
                                END

                                IF (@Stoc < @Delta)
                                BEGIN
                                        RAISERROR('Stoc insuficient pentru actualizare linie.', 11, 1)
                                        ROLLBACK TRAN
                                        RETURN -8
                                END

                                UPDATE STOCURI
                                SET CantitateDisponibila = CantitateDisponibila - @Delta
                                WHERE IdCentru = @IdCentru AND IdProdus = @IdProdus
                        END
                        ELSE IF (@Delta < 0)
                        BEGIN
                                UPDATE STOCURI
                                SET CantitateDisponibila = CantitateDisponibila + ABS(@Delta)
                                WHERE IdCentru = @IdCentru AND IdProdus = @IdProdus
                        END

                        -- Update/Insert linie
                        IF EXISTS (SELECT 1 FROM LINII_VANZARE WHERE IdVanzare=@IdVanzare AND IdProdus=@IdProdus)
                        BEGIN
                                UPDATE LINII_VANZARE
                                SET Cantitate = @CantitateNoua,
                                    PretUnitar = @PretUnitarNou,
                                    DiscountProc = @DiscountProcNou
                                WHERE IdVanzare = @IdVanzare AND IdProdus = @IdProdus
                        END
                        ELSE
                        BEGIN
                                INSERT INTO LINII_VANZARE (IdVanzare, IdProdus, Cantitate, PretUnitar, DiscountProc)
                                VALUES (@IdVanzare, @IdProdus, @CantitateNoua, @PretUnitarNou, @DiscountProcNou)

                        END
                END

        COMMIT TRAN

        RETURN 0
END TRY
BEGIN CATCH
        IF (@@TRANCOUNT > 0)
                ROLLBACK TRAN

        DECLARE @ErrorMessage NVARCHAR(1000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -99
END CATCH
GO


-- =========================================
-- TESTE
-- =========================================

-- 1) Inserare vanzare (1 linie) pe baza de descrieri
DECLARE @NewId int, @RC int
EXEC @RC = dbo.usp_Insert_Vanzare_Descrieri
        @NumeClient = 'Bar Central',
        @EmailAngajat = 'ioana.popa@firma.ro',
        @NumeCentru = 'Centru Bucuresti',
        @SKU = 'BER-LAG-0500',
        @Cantitate = 10,
        @PretUnitar = NULL,          -- se ia PretCatalog
        @DiscountProc = 10,
        @DataVanzare = '2025-05-01',
        @Status = 'Procesata',
        @MetodaPlata = NULL,         -- se calculeaza prin UDF
        @IdVanzareOut = @NewId OUTPUT

SELECT @RC AS ReturnCode, @NewId AS IdVanzareNoua
GO


-- 2) Actualizare vanzare identificata dupa descrieri (ex: schimbare status)
DECLARE @RC2 int
EXEC @RC2 = dbo.usp_Update_Vanzare_Descrieri
        @NumeClient = 'Magazin Vinoteca Nord',
        @NumeCentru = 'Centru Iasi',
        @DataVanzare = '2025-02-15',
        @EmailAngajat = 'ioana.popa@firma.ro',
        @StatusNou = 'Procesata',
        @MetodaPlataNou = 'Transfer'
SELECT @RC2 AS ReturnCode
GO


-- 3) Actualizare vanzare + actualizare linie (SKU) + ajustare stoc
DECLARE @RC3 int
EXEC @RC3 = dbo.usp_Update_Vanzare_Descrieri
        @NumeClient = 'Bar Central',
        @NumeCentru = 'Centru Bucuresti',
        @DataVanzare = '2025-01-10',
        @EmailAngajat = 'ioana.popa@firma.ro',
        @SKU = 'SPI-JAM-0700',
        @CantitateNoua = 7,          -- creste cu 1 => scade stoc cu 1
        @DiscountProcNou = 10
SELECT @RC3 AS ReturnCode
GO