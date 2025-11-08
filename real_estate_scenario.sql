-- Real Estate Business Scenario Implementation
-- This script creates the schema, sample data, and reporting queries described in README.md.

/*
    The script targets Microsoft SQL Server (T-SQL).
    It creates a dedicated database so that it can be executed in one batch.
*/

IF DB_ID('RealEstate') IS NULL
BEGIN
    EXEC('CREATE DATABASE RealEstate');
END;
GO

USE RealEstate;
GO

-- Drop existing objects to allow re-running the script without errors.
IF OBJECT_ID('dbo.Listing', 'U') IS NOT NULL DROP TABLE dbo.Listing;
IF OBJECT_ID('dbo.HouseType', 'U') IS NOT NULL DROP TABLE dbo.HouseType;
IF OBJECT_ID('dbo.Town', 'U') IS NOT NULL DROP TABLE dbo.Town;
GO

CREATE TABLE dbo.Town
(
    TownId      INT             IDENTITY(1, 1) PRIMARY KEY,
    TownName    NVARCHAR(100)   NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.HouseType
(
    HouseTypeId TINYINT         IDENTITY(1, 1) PRIMARY KEY,
    TypeName    NVARCHAR(50)    NOT NULL UNIQUE,
    CONSTRAINT CK_HouseType_AllowedValues CHECK (
        TypeName IN ('Bi-Level', 'Colonial', 'Ranch', 'Split-Level', 'Duplex', 'Townhouse', 'Vacant Land', 'Apartment')
    )
);
GO

CREATE TABLE dbo.Listing
(
    ListingId               INT             IDENTITY(1, 1) PRIMARY KEY,
    StreetAddress           NVARCHAR(200)   NOT NULL UNIQUE,
    HouseNumber             INT             NOT NULL,
    TownId                  INT             NOT NULL REFERENCES dbo.Town(TownId),
    HouseTypeId             TINYINT         NOT NULL REFERENCES dbo.HouseType(HouseTypeId),
    Bedrooms                TINYINT         NOT NULL CHECK (Bedrooms >= 0),
    Bathrooms               DECIMAL(4, 1)   NOT NULL CHECK (Bathrooms >= 0),
    HouseSquareFeet         DECIMAL(10, 1)  NOT NULL CHECK (HouseSquareFeet > 0),
    LotSquareFeet           DECIMAL(12, 1)  NOT NULL CHECK (LotSquareFeet > 0),
    OwnerName               NVARCHAR(200)   NOT NULL,
    OwnerContactName        NVARCHAR(200)   NULL,
    ClientName              NVARCHAR(200)   NOT NULL,
    RealtorName             NVARCHAR(200)   NOT NULL,
    OnMarketDate            DATE            NOT NULL,
    AskingPrice             DECIMAL(12, 2)  NOT NULL CHECK (AskingPrice BETWEEN 100000 AND 9900000),
    IsSold                  BIT             NOT NULL DEFAULT (0),
    SoldDate                DATE            NULL,
    SoldPrice               DECIMAL(12, 2)  NULL,
    BuyerName               NVARCHAR(200)   NULL,
    IsInContract            BIT             NOT NULL DEFAULT (0),
    ContractBuyerName       NVARCHAR(200)   NULL,
    ContractPrice           DECIMAL(12, 2)  NULL,
    CONSTRAINT CK_Listing_SoldData CHECK (
        (IsSold = 0 AND SoldDate IS NULL AND SoldPrice IS NULL) OR
        (IsSold = 1 AND SoldDate IS NOT NULL AND SoldPrice IS NOT NULL)
    ),
    CONSTRAINT CK_Listing_BuyerForSold CHECK (
        (IsSold = 0 AND BuyerName IS NULL) OR
        (IsSold = 1 AND BuyerName IS NOT NULL)
    ),
    CONSTRAINT CK_Listing_ContractData CHECK (
        (IsInContract = 0 AND ContractBuyerName IS NULL AND ContractPrice IS NULL) OR
        (IsInContract = 1 AND ContractBuyerName IS NOT NULL AND ContractPrice IS NOT NULL)
    ),
    CONSTRAINT CK_Listing_SoldDateOnOrAfterMarket CHECK (
        SoldDate IS NULL OR SoldDate >= OnMarketDate
    ),
    CONSTRAINT CK_Listing_SoldPriceGTEAsking CHECK (
        SoldPrice IS NULL OR SoldPrice >= AskingPrice
    ),
    CONSTRAINT CK_Listing_PriceBounds CHECK (
        (SoldPrice IS NULL OR (SoldPrice BETWEEN 100000 AND 9900000)) AND
        (ContractPrice IS NULL OR (ContractPrice BETWEEN 100000 AND 9900000))
    ),
    CONSTRAINT CK_Listing_NotSoldAndContract CHECK (
        NOT (IsSold = 1 AND IsInContract = 1)
    )
);
GO

-- Seed lookup data.
INSERT INTO dbo.Town (TownName)
VALUES
    ('Lakewood'),
    ('Jackson'),
    ('Toms River'),
    ('Howell'),
    ('Brick'),
    ('Manchester');
GO

INSERT INTO dbo.HouseType (TypeName)
VALUES
    ('Bi-Level'),
    ('Colonial'),
    ('Ranch'),
    ('Split-Level'),
    ('Duplex'),
    ('Townhouse'),
    ('Vacant Land'),
    ('Apartment');
GO

-- Insert sample listings.
INSERT INTO dbo.Listing
(
    StreetAddress, HouseNumber, TownId, HouseTypeId, Bedrooms, Bathrooms,
    HouseSquareFeet, LotSquareFeet, OwnerName, OwnerContactName, ClientName,
    RealtorName, OnMarketDate, AskingPrice, IsSold, SoldDate, SoldPrice,
    BuyerName, IsInContract, ContractBuyerName, ContractPrice
)
VALUES
    ('5 Lynn Drive', 5, (SELECT TownId FROM dbo.Town WHERE TownName = 'Toms River'),
        (SELECT HouseTypeId FROM dbo.HouseType WHERE TypeName = 'Colonial'),
        4, 2.5, 3000.0, 42000.0, 'Lynn Drive, LLC', 'Lynn Drive, LLC', 'Yaakov Fishman',
        'Rivka Harnik', '2021-01-12', 450000.00, 1, '2021-02-22', 475000.00,
        'Rachel Gestetner', 0, NULL, NULL),
    ('8 London Drive', 8, (SELECT TownId FROM dbo.Town WHERE TownName = 'Lakewood'),
        (SELECT HouseTypeId FROM dbo.HouseType WHERE TypeName = 'Ranch'),
        3, 2.0, 2000.0, 4089.0, 'Shaindy Braun', 'Shaindy Braun', 'Shaindy Braun',
        'Raizy Berger', '2009-04-05', 200000.00, 1, '2010-07-10', 200000.00,
        'Elazar and Faigy Adler', 0, NULL, NULL),
    ('423 2nd Street', 423, (SELECT TownId FROM dbo.Town WHERE TownName = 'Lakewood'),
        (SELECT HouseTypeId FROM dbo.HouseType WHERE TypeName = 'Colonial'),
        9, 5.5, 3500.0, 4200.0, 'L3C Jackson, LLC', 'Mark Farkas', 'Mark Farkas',
        'Rivka Harnik', '2015-01-06', 360000.00, 1, '2015-06-09', 370000.00,
        'Yossi Handler and Rivky Handler', 0, NULL, NULL),
    ('176 Hadassah Lane', 176, (SELECT TownId FROM dbo.Town WHERE TownName = 'Lakewood'),
        (SELECT HouseTypeId FROM dbo.HouseType WHERE TypeName = 'Duplex'),
        5, 2.5, 2550.0, 3049.2, 'Greenview Equities, LLC', 'Shlomo Press', 'Shlomo Press',
        'Moshe Celnik', '2021-05-03', 549000.00, 0, NULL, NULL,
        NULL, 1, 'Shea Speigel', 600000.00),
    ('1141 Central Avenue', 1141, (SELECT TownId FROM dbo.Town WHERE TownName = 'Lakewood'),
        (SELECT HouseTypeId FROM dbo.HouseType WHERE TypeName = 'Ranch'),
        3, 1.0, 855.0, 5000.0, 'Sorah Hager', 'Yitzchok Tendler', 'Yitzchok Tendler',
        'Moshe Celnik', '2022-01-02', 300000.00, 0, NULL, NULL,
        NULL, 0, NULL, NULL);
GO

/*
    REPORTS
*/

-- 1) Report of all houses sorted by block (house number) and then by town/city.
SELECT
    l.HouseNumber AS Block,
    l.StreetAddress,
    t.TownName,
    ht.TypeName AS HouseType,
    l.Bedrooms,
    l.Bathrooms,
    l.HouseSquareFeet,
    l.LotSquareFeet,
    l.OnMarketDate,
    l.IsSold,
    l.IsInContract
FROM dbo.Listing AS l
INNER JOIN dbo.Town AS t ON l.TownId = t.TownId
INNER JOIN dbo.HouseType AS ht ON l.HouseTypeId = ht.HouseTypeId
ORDER BY l.HouseNumber, t.TownName, l.StreetAddress;
GO

-- 2) Report of all houses sorted by realtor.
SELECT
    l.RealtorName,
    l.StreetAddress,
    t.TownName,
    ht.TypeName AS HouseType,
    l.ClientName,
    l.OnMarketDate,
    l.IsSold,
    l.IsInContract
FROM dbo.Listing AS l
INNER JOIN dbo.Town AS t ON l.TownId = t.TownId
INNER JOIN dbo.HouseType AS ht ON l.HouseTypeId = ht.HouseTypeId
ORDER BY l.RealtorName, l.OnMarketDate, l.StreetAddress;
GO

-- 3) Report of how long it took for each house to sell.
SELECT
    l.StreetAddress,
    t.TownName,
    l.OnMarketDate,
    l.SoldDate,
    CASE WHEN l.IsSold = 1 THEN DATEDIFF(DAY, l.OnMarketDate, l.SoldDate) END AS DaysOnMarket
FROM dbo.Listing AS l
INNER JOIN dbo.Town AS t ON l.TownId = t.TownId
ORDER BY l.OnMarketDate;
GO

-- 4) Report of the price difference from the asking price to the sold price.
SELECT
    l.StreetAddress,
    t.TownName,
    l.AskingPrice,
    l.SoldPrice,
    CASE WHEN l.IsSold = 1 THEN l.SoldPrice - l.AskingPrice END AS PriceDifference
FROM dbo.Listing AS l
INNER JOIN dbo.Town AS t ON l.TownId = t.TownId
WHERE l.IsSold = 1
ORDER BY PriceDifference DESC;
GO
