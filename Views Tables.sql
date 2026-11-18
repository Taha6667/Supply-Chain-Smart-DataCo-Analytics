-- dbo.vw_FactOrderItem

CREATE OR ALTER VIEW dbo.vw_FactOrderItem AS
SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    o.customer_id,
    o.destination_id,
    o.shipping_mode_id,
    o.order_status_id,
    o.delivery_status_id,
    o.order_type_id,
    o.order_date,
    o.shipping_date,
    oi.order_item_quantity,
    oi.unit_price_at_sale,
    oi.discount_amount,
    oi.discount_rate,
    oi.sales,
    oi.item_total,
    oi.profit_ratio,
    oi.profit_amount,
    o.days_for_shipping_real,
    o.days_for_shipment_scheduled,

    /* ---------- جديد: علامة جودة الفترة ---------- */
    CAST( CASE WHEN o.order_date < '2017-10-01' THEN 1 ELSE 0 END AS bit )
        AS is_complete_period,

    CASE WHEN o.order_date < '2017-10-01'
         THEN 'Complete months'
         ELSE 'Partial tail'
    END AS period_quality

FROM dbo.order_item AS oi
INNER JOIN dbo.orders AS o
    ON oi.order_id = o.order_id;
GO

--------------------------------------------------------------------------------
--dbo.vw_DimCustomer
CREATE OR ALTER VIEW dbo.vw_DimCustomer AS
SELECT
    c.customer_id,
    c.customer_fname,
    c.customer_lname,
    c.customer_email,
    cs.customer_segment_name,
    a.customer_address_id,
    a.street,
    a.city,
    a.state,
    a.zipcode,
    a.country,
    a.latitude,
    a.longitude
FROM dbo.customer AS c
LEFT JOIN dbo.customer_segment AS cs
    ON c.customer_segment_id = cs.customer_segment_id
LEFT JOIN dbo.customer_address AS a
    ON c.customer_address_id = a.customer_address_id;
GO
----------------------------------------------------------------------------------
-- dbo.vw_DimProduct
CREATE OR ALTER VIEW dbo.vw_DimProduct AS
WITH cat_size AS (
    SELECT category_id, COUNT(*) AS sku_count
    FROM   dbo.product
    GROUP  BY category_id
),
base AS (
    SELECT
        p.product_id,
        p.product_name,
        p.product_price,
        p.product_status,
        cat.category_name,
        d.department_name,
        ISNULL( cs.sku_count, 0 ) AS sku_count,


        CASE
            WHEN p.product_name LIKE 'Nike%'            THEN 'Nike'
            WHEN p.product_name LIKE 'Field & Stream%'  THEN 'Field & Stream'
            WHEN p.product_name LIKE 'Perfect Fitness%' THEN 'Perfect Fitness'
            WHEN p.product_name LIKE 'Diamondback%'     THEN 'Diamondback'
            WHEN p.product_name LIKE 'Pelican%'         THEN 'Pelican'
            WHEN p.product_name LIKE 'O''Brien%'        THEN 'O''Brien'
            WHEN p.product_name LIKE 'Under Armour%'    THEN 'Under Armour'
            WHEN p.product_name LIKE 'Titleist%'        THEN 'Titleist'
            WHEN p.product_name LIKE 'adidas%'          THEN 'adidas'
            WHEN p.product_name LIKE 'Team Golf%'       THEN 'Team Golf'
            WHEN p.product_name LIKE 'LIJA%'            THEN 'LIJA'
            WHEN p.product_name LIKE 'Glove It%'        THEN 'Glove It'
            WHEN p.product_name LIKE 'Merrell%'         THEN 'Merrell'
            WHEN p.product_name LIKE 'Clicgear%'        THEN 'Clicgear'
            WHEN p.product_name LIKE 'TaylorMade%'      THEN 'TaylorMade'
            WHEN p.product_name LIKE 'Columbia%'        THEN 'Columbia'
            WHEN p.product_name LIKE 'Elevation%'       THEN 'Elevation'
            WHEN p.product_name LIKE 'SOLE%'            THEN 'SOLE'
            WHEN p.product_name LIKE 'GoPro%'           THEN 'GoPro'
            WHEN p.product_name LIKE 'Yakima%'          THEN 'Yakima'
            WHEN p.product_name LIKE 'Stiga%'           THEN 'Stiga'
            WHEN p.product_name LIKE 'Bowflex%'         THEN 'Bowflex'
            WHEN p.product_name LIKE 'Garmin%'          THEN 'Garmin'
            WHEN p.product_name LIKE 'Polar%'           THEN 'Polar'
            WHEN p.product_name LIKE 'Bag Boy%'         THEN 'Bag Boy'
            WHEN p.product_name LIKE 'Bridgestone%'     THEN 'Bridgestone'
            WHEN p.product_name LIKE 'Cleveland Golf%'  THEN 'Cleveland Golf'
            WHEN p.product_name LIKE 'Hirzl%'           THEN 'Hirzl'
            WHEN p.product_name LIKE 'Brooks%'          THEN 'Brooks'
            WHEN p.product_name LIKE 'Fitbit%'          THEN 'Fitbit'
            WHEN p.product_name LIKE 'The North Face%'  THEN 'The North Face'
            WHEN p.product_name LIKE 'TYR%'             THEN 'TYR'
            WHEN p.product_name LIKE 'Ogio%'            THEN 'Ogio'
            WHEN p.product_name LIKE 'Bushnell%'        THEN 'Bushnell'
            WHEN p.product_name LIKE 'ENO%'             THEN 'ENO'
            WHEN p.product_name LIKE 'GolfBuddy%'       THEN 'GolfBuddy'
            WHEN p.product_name LIKE 'Top Flite%'       THEN 'Top Flite'
            WHEN p.product_name LIKE 'MDGolf%'          THEN 'MDGolf'
            WHEN p.product_name LIKE 'insta-bed%'       THEN 'insta-bed'
            WHEN p.product_name LIKE 'Mio %'            THEN 'Mio'
            WHEN p.product_name LIKE 'Total Gym%'       THEN 'Total Gym'
            WHEN p.product_name LIKE 'Dell %'           THEN 'Dell'
            ELSE 'Unbranded / Generic'
        END AS brand_name

    FROM       dbo.product     AS p
    LEFT JOIN  dbo.category    AS cat ON p.category_id     = cat.category_id
    LEFT JOIN  dbo.department  AS d   ON cat.department_id = d.department_id
    LEFT JOIN  cat_size        AS cs  ON p.category_id     = cs.category_id
)
SELECT
    b.product_id,
    b.product_name,
    b.product_price,
    b.product_status,

    b.department_name,
    b.brand_name,

    CASE
        WHEN b.product_price <  25  THEN 'Under $25'
        WHEN b.product_price <  50  THEN '$25 - $50'
        WHEN b.product_price < 100  THEN '$50 - $100'
        WHEN b.product_price < 200  THEN '$100 - $200'
        WHEN b.product_price < 400  THEN '$200 - $400'
        ELSE                             '$400+'
    END AS price_band,

    CASE
        WHEN b.product_price <  25  THEN 1
        WHEN b.product_price <  50  THEN 2
        WHEN b.product_price < 100  THEN 3
        WHEN b.product_price < 200  THEN 4
        WHEN b.product_price < 400  THEN 5
        ELSE                             6
    END AS price_band_sort,

    CASE WHEN b.brand_name = 'Unbranded / Generic'
         THEN 'Generic catalogue item'
         ELSE 'Branded catalogue item'
    END                     AS sku_type,

    b.category_name         AS category_name_raw,
    b.sku_count             AS category_sku_count,
    CASE WHEN b.sku_count = 1
         THEN 'Single-SKU'
         ELSE 'Multi-SKU'
    END                     AS category_reliability

FROM base AS b;
GO
-----------------------------------------------------------------------------------------
--rpt.vw_DimGeography
CREATE OR ALTER VIEW dbo.vw_DimGeography AS
SELECT
sd.destination_id,
sd.order_city,
sd.order_state,
sd.order_zipcode,
r.region_name,
m.market_name,
oc.order_country_name
FROM dbo.shipping_destination AS sd
LEFT JOIN dbo.region AS r
ON sd.region_id = r.region_id
LEFT JOIN dbo.order_country AS oc
ON sd.order_country_id = oc.order_country_id
LEFT JOIN dbo.market AS m
ON r.market_id = m.market_id;
GO
----------------------------------------------------------------------------------------
-- rpt.vw_DimShippingMode
CREATE OR ALTER VIEW dbo.vw_DimShippingMode AS
SELECT
shipping_mode_id,
shipping_mode_name
FROM dbo.shipping_mode;
GO
-------------------------------------------------------------------------------------
--rpt.vw_DimOrderStatus
CREATE OR ALTER VIEW dbo.vw_DimOrderStatus AS
SELECT
os.order_status_id * 100 + ds.delivery_status_id AS OrderStatusKey,
os.order_status_name,
ds.delivery_status_name
FROM dbo.order_status AS os
CROSS JOIN dbo.delivery_status AS ds;
GO
-------------------------------------------------------------------------------------
--rpt.vw_DimOrderType
CREATE OR ALTER VIEW dbo.vw_DimOrderType AS
SELECT
order_type_id,
order_type_name
FROM dbo.order_type;
GO
-----------------------------------------------------------------------------
-- Confirm every reporting view exists and returns rows before connecting Power BI  التحقق من ڤيوهات التقارير
SELECT 'dbo.vw_FactOrderItem' AS view_name, COUNT(*) AS row_count FROM dbo.vw_FactOrderItem
UNION ALL SELECT 'dbo.vw_DimCustomer', COUNT(*) FROM dbo. vw_DimCustomer
UNION ALL SELECT 'dbo.vw_DimProduct', COUNT(*) FROM dbo.vw_DimProduct
UNION ALL SELECT 'dbo.vw_DimGeography', COUNT(*) FROM dbo.vw_DimGeography
UNION ALL SELECT 'dbo.vw_DimShippingMode', COUNT(*) FROM dbo.vw_DimShippingMode
UNION ALL SELECT 'dbo.vw_DimOrderStatus', COUNT(*) FROM dbo. vw_DimOrderStatus
UNION ALL SELECT 'dbo.vw_DimOrderType', COUNT(*) FROM dbo.vw_DimOrderType;

SELECT @@SERVERNAME
---------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.country_iso;
GO

CREATE TABLE dbo.country_iso (
    order_country_id  INT           NOT NULL PRIMARY KEY,
    country_name_es   NVARCHAR(80)  NOT NULL,   
    country_name_en   NVARCHAR(80)  NOT NULL,   
    iso2              VARCHAR(2)    NOT NULL,   
    iso3              VARCHAR(3)    NOT NULL,  
    continent         NVARCHAR(20)  NOT NULL,
    map_status        NVARCHAR(30)  NOT NULL,  
    CONSTRAINT ck_iso2_len CHECK ( LEN(iso2) = 2 ),
    CONSTRAINT ck_iso3_len CHECK ( LEN(iso3) = 3 )
);
GO

INSERT INTO dbo.country_iso
    (order_country_id, country_name_es, country_name_en, iso2, iso3, continent, map_status)
VALUES
    (   1, N'Afganistán', N'Afghanistan', 'AF', 'AFG', N'Asia', N'OK'),
    (   2, N'Albania', N'Albania', 'AL', 'ALB', N'Europe', N'OK'),
    (   3, N'Alemania', N'Germany', 'DE', 'DEU', N'Europe', N'OK'),
    (   4, N'Angola', N'Angola', 'AO', 'AGO', N'Africa', N'OK'),
    (   5, N'Arabia Saudí', N'Saudi Arabia', 'SA', 'SAU', N'Asia', N'OK'),
    (   6, N'Argelia', N'Algeria', 'DZ', 'DZA', N'Africa', N'OK'),
    (   7, N'Argentina', N'Argentina', 'AR', 'ARG', N'South America', N'OK'),
    (   8, N'Armenia', N'Armenia', 'AM', 'ARM', N'Asia', N'OK'),
    (   9, N'Australia', N'Australia', 'AU', 'AUS', N'Oceania', N'OK'),
    (  10, N'Austria', N'Austria', 'AT', 'AUT', N'Europe', N'OK'),
    (  11, N'Azerbaiyán', N'Azerbaijan', 'AZ', 'AZE', N'Asia', N'OK'),
    (  12, N'Bangladés', N'Bangladesh', 'BD', 'BGD', N'Asia', N'OK'),
    (  13, N'Barbados', N'Barbados', 'BB', 'BRB', N'North America', N'OK'),
    (  14, N'Baréin', N'Bahrain', 'BH', 'BHR', N'Asia', N'OK'),
    (  15, N'Belice', N'Belize', 'BZ', 'BLZ', N'North America', N'OK'),
    (  16, N'Benín', N'Benin', 'BJ', 'BEN', N'Africa', N'OK'),
    (  17, N'Bielorrusia', N'Belarus', 'BY', 'BLR', N'Europe', N'OK'),
    (  18, N'Bolivia', N'Bolivia', 'BO', 'BOL', N'South America', N'OK'),
    (  19, N'Bosnia y Herzegovina', N'Bosnia and Herzegovina', 'BA', 'BIH', N'Europe', N'OK'),
    (  20, N'Botsuana', N'Botswana', 'BW', 'BWA', N'Africa', N'OK'),
    (  21, N'Brasil', N'Brazil', 'BR', 'BRA', N'South America', N'OK'),
    (  22, N'Bulgaria', N'Bulgaria', 'BG', 'BGR', N'Europe', N'OK'),
    (  23, N'Burkina Faso', N'Burkina Faso', 'BF', 'BFA', N'Africa', N'OK'),
    (  24, N'Burundi', N'Burundi', 'BI', 'BDI', N'Africa', N'OK'),
    (  25, N'Bután', N'Bhutan', 'BT', 'BTN', N'Asia', N'OK'),
    (  26, N'Bélgica', N'Belgium', 'BE', 'BEL', N'Europe', N'OK'),
    (  27, N'Camboya', N'Cambodia', 'KH', 'KHM', N'Asia', N'OK'),
    (  28, N'Camerún', N'Cameroon', 'CM', 'CMR', N'Africa', N'OK'),
    (  29, N'Canada', N'Canada', 'CA', 'CAN', N'North America', N'OK'),
    (  30, N'Chad', N'Chad', 'TD', 'TCD', N'Africa', N'OK'),
    (  31, N'Chile', N'Chile', 'CL', 'CHL', N'South America', N'OK'),
    (  32, N'China', N'China', 'CN', 'CHN', N'Asia', N'OK'),
    (  33, N'Chipre', N'Cyprus', 'CY', 'CYP', N'Europe', N'OK'),
    (  34, N'Colombia', N'Colombia', 'CO', 'COL', N'South America', N'OK'),
    (  35, N'Corea del Sur', N'South Korea', 'KR', 'KOR', N'Asia', N'OK'),
    (  36, N'Costa Rica', N'Costa Rica', 'CR', 'CRI', N'North America', N'OK'),
    (  37, N'Costa de Marfil', N'Côte d''Ivoire', 'CI', 'CIV', N'Africa', N'OK'),
    (  38, N'Croacia', N'Croatia', 'HR', 'HRV', N'Europe', N'OK'),
    (  39, N'Cuba', N'Cuba', 'CU', 'CUB', N'North America', N'OK'),
    (  40, N'Dinamarca', N'Denmark', 'DK', 'DNK', N'Europe', N'OK'),
    (  41, N'Ecuador', N'Ecuador', 'EC', 'ECU', N'South America', N'OK'),
    (  42, N'Egipto', N'Egypt', 'EG', 'EGY', N'Africa', N'OK'),
    (  43, N'El Salvador', N'El Salvador', 'SV', 'SLV', N'North America', N'OK'),
    (  44, N'Emiratos Árabes Unidos', N'United Arab Emirates', 'AE', 'ARE', N'Asia', N'OK'),
    (  45, N'Eritrea', N'Eritrea', 'ER', 'ERI', N'Africa', N'OK'),
    (  46, N'Eslovaquia', N'Slovakia', 'SK', 'SVK', N'Europe', N'OK'),
    (  47, N'Eslovenia', N'Slovenia', 'SI', 'SVN', N'Europe', N'OK'),
    (  48, N'España', N'Spain', 'ES', 'ESP', N'Europe', N'OK'),
    (  49, N'Estados Unidos', N'United States', 'US', 'USA', N'North America', N'OK'),
    (  50, N'Estonia', N'Estonia', 'EE', 'EST', N'Europe', N'OK'),
    (  51, N'Etiopía', N'Ethiopia', 'ET', 'ETH', N'Africa', N'OK'),
    (  52, N'Filipinas', N'Philippines', 'PH', 'PHL', N'Asia', N'OK'),
    (  53, N'Finlandia', N'Finland', 'FI', 'FIN', N'Europe', N'OK'),
    (  54, N'Francia', N'France', 'FR', 'FRA', N'Europe', N'OK'),
    (  55, N'Gabón', N'Gabon', 'GA', 'GAB', N'Africa', N'OK'),
    (  56, N'Georgia', N'Georgia', 'GE', 'GEO', N'Asia', N'Ambiguous with US state'),
    (  57, N'Ghana', N'Ghana', 'GH', 'GHA', N'Africa', N'OK'),
    (  58, N'Grecia', N'Greece', 'GR', 'GRC', N'Europe', N'OK'),
    (  59, N'Guadalupe', N'Guadeloupe', 'GP', 'GLP', N'North America', N'FR overseas dept'),
    (  60, N'Guatemala', N'Guatemala', 'GT', 'GTM', N'North America', N'OK'),
    (  61, N'Guayana Francesa', N'French Guiana', 'GF', 'GUF', N'South America', N'FR overseas dept'),
    (  62, N'Guinea', N'Guinea', 'GN', 'GIN', N'Africa', N'OK'),
    (  63, N'Guinea Ecuatorial', N'Equatorial Guinea', 'GQ', 'GNQ', N'Africa', N'OK'),
    (  64, N'Guinea-Bissau', N'Guinea-Bissau', 'GW', 'GNB', N'Africa', N'OK'),
    (  65, N'Guyana', N'Guyana', 'GY', 'GUY', N'South America', N'OK'),
    (  66, N'Haití', N'Haiti', 'HT', 'HTI', N'North America', N'OK'),
    (  67, N'Honduras', N'Honduras', 'HN', 'HND', N'North America', N'OK'),
    (  68, N'Hong Kong', N'Hong Kong SAR', 'HK', 'HKG', N'Asia', N'Non-sovereign SAR'),
    (  69, N'Hungría', N'Hungary', 'HU', 'HUN', N'Europe', N'OK'),
    (  70, N'India', N'India', 'IN', 'IND', N'Asia', N'OK'),
    (  71, N'Indonesia', N'Indonesia', 'ID', 'IDN', N'Asia', N'OK'),
    (  72, N'Irak', N'Iraq', 'IQ', 'IRQ', N'Asia', N'OK'),
    (  73, N'Irlanda', N'Ireland', 'IE', 'IRL', N'Europe', N'OK'),
    (  74, N'Irán', N'Iran', 'IR', 'IRN', N'Asia', N'OK'),
    (  75, N'Israel', N'Israel', 'IL', 'ISR', N'Asia', N'OK'),
    (  76, N'Italia', N'Italy', 'IT', 'ITA', N'Europe', N'OK'),
    (  77, N'Jamaica', N'Jamaica', 'JM', 'JAM', N'North America', N'OK'),
    (  78, N'Japón', N'Japan', 'JP', 'JPN', N'Asia', N'OK'),
    (  79, N'Jordania', N'Jordan', 'JO', 'JOR', N'Asia', N'OK'),
    (  80, N'Kazajistán', N'Kazakhstan', 'KZ', 'KAZ', N'Asia', N'OK'),
    (  81, N'Kenia', N'Kenya', 'KE', 'KEN', N'Africa', N'OK'),
    (  82, N'Kirguistán', N'Kyrgyzstan', 'KG', 'KGZ', N'Asia', N'OK'),
    (  83, N'Kuwait', N'Kuwait', 'KW', 'KWT', N'Asia', N'OK'),
    (  84, N'Laos', N'Laos', 'LA', 'LAO', N'Asia', N'OK'),
    (  85, N'Lesoto', N'Lesotho', 'LS', 'LSO', N'Africa', N'OK'),
    (  86, N'Liberia', N'Liberia', 'LR', 'LBR', N'Africa', N'OK'),
    (  87, N'Libia', N'Libya', 'LY', 'LBY', N'Africa', N'OK'),
    (  88, N'Lituania', N'Lithuania', 'LT', 'LTU', N'Europe', N'OK'),
    (  89, N'Luxemburgo', N'Luxembourg', 'LU', 'LUX', N'Europe', N'OK'),
    (  90, N'Líbano', N'Lebanon', 'LB', 'LBN', N'Asia', N'OK'),
    (  91, N'Macedonia', N'North Macedonia', 'MK', 'MKD', N'Europe', N'OK'),
    (  92, N'Madagascar', N'Madagascar', 'MG', 'MDG', N'Africa', N'OK'),
    (  93, N'Malasia', N'Malaysia', 'MY', 'MYS', N'Asia', N'OK'),
    (  94, N'Mali', N'Mali', 'ML', 'MLI', N'Africa', N'OK'),
    (  95, N'Marruecos', N'Morocco', 'MA', 'MAR', N'Africa', N'OK'),
    (  96, N'Martinica', N'Martinique', 'MQ', 'MTQ', N'North America', N'FR overseas dept'),
    (  97, N'Mauritania', N'Mauritania', 'MR', 'MRT', N'Africa', N'OK'),
    (  98, N'Moldavia', N'Moldova', 'MD', 'MDA', N'Europe', N'OK'),
    (  99, N'Mongolia', N'Mongolia', 'MN', 'MNG', N'Asia', N'OK'),
    ( 100, N'Montenegro', N'Montenegro', 'ME', 'MNE', N'Europe', N'OK'),
    ( 101, N'Mozambique', N'Mozambique', 'MZ', 'MOZ', N'Africa', N'OK'),
    ( 102, N'Myanmar (Birmania)', N'Myanmar', 'MM', 'MMR', N'Asia', N'OK'),
    ( 103, N'México', N'Mexico', 'MX', 'MEX', N'North America', N'OK'),
    ( 104, N'Namibia', N'Namibia', 'NA', 'NAM', N'Africa', N'OK'),
    ( 105, N'Nepal', N'Nepal', 'NP', 'NPL', N'Asia', N'OK'),
    ( 106, N'Nicaragua', N'Nicaragua', 'NI', 'NIC', N'North America', N'OK'),
    ( 107, N'Nigeria', N'Nigeria', 'NG', 'NGA', N'Africa', N'OK'),
    ( 108, N'Noruega', N'Norway', 'NO', 'NOR', N'Europe', N'OK'),
    ( 109, N'Nueva Zelanda', N'New Zealand', 'NZ', 'NZL', N'Oceania', N'OK'),
    ( 110, N'Níger', N'Niger', 'NE', 'NER', N'Africa', N'OK'),
    ( 111, N'Omán', N'Oman', 'OM', 'OMN', N'Asia', N'OK'),
    ( 112, N'Pakistán', N'Pakistan', 'PK', 'PAK', N'Asia', N'OK'),
    ( 113, N'Panamá', N'Panama', 'PA', 'PAN', N'North America', N'OK'),
    ( 114, N'Papúa Nueva Guinea', N'Papua New Guinea', 'PG', 'PNG', N'Oceania', N'OK'),
    ( 115, N'Paraguay', N'Paraguay', 'PY', 'PRY', N'South America', N'OK'),
    ( 116, N'Países Bajos', N'Netherlands', 'NL', 'NLD', N'Europe', N'OK'),
    ( 117, N'Perú', N'Peru', 'PE', 'PER', N'South America', N'OK'),
    ( 118, N'Polonia', N'Poland', 'PL', 'POL', N'Europe', N'OK'),
    ( 119, N'Portugal', N'Portugal', 'PT', 'PRT', N'Europe', N'OK'),
    ( 120, N'Qatar', N'Qatar', 'QA', 'QAT', N'Asia', N'OK'),
    ( 121, N'Reino Unido', N'United Kingdom', 'GB', 'GBR', N'Europe', N'OK'),
    ( 122, N'República Centroafricana', N'Central African Republic', 'CF', 'CAF', N'Africa', N'OK'),
    ( 123, N'República Checa', N'Czechia', 'CZ', 'CZE', N'Europe', N'OK'),
    ( 124, N'República Democrática del Congo', N'Democratic Republic of the Congo', 'CD', 'COD', N'Africa', N'OK'),
    ( 125, N'República Dominicana', N'Dominican Republic', 'DO', 'DOM', N'North America', N'OK'),
    ( 126, N'República de Gambia', N'Gambia', 'GM', 'GMB', N'Africa', N'OK'),
    ( 127, N'República del Congo', N'Republic of the Congo', 'CG', 'COG', N'Africa', N'OK'),
    ( 128, N'Ruanda', N'Rwanda', 'RW', 'RWA', N'Africa', N'OK'),
    ( 129, N'Rumania', N'Romania', 'RO', 'ROU', N'Europe', N'OK'),
    ( 130, N'Rusia', N'Russia', 'RU', 'RUS', N'Europe', N'OK'),
    ( 131, N'Senegal', N'Senegal', 'SN', 'SEN', N'Africa', N'OK'),
    ( 132, N'Serbia', N'Serbia', 'RS', 'SRB', N'Europe', N'OK'),
    ( 133, N'Sierra Leona', N'Sierra Leone', 'SL', 'SLE', N'Africa', N'OK'),
    ( 134, N'Singapur', N'Singapore', 'SG', 'SGP', N'Asia', N'OK'),
    ( 135, N'Siria', N'Syria', 'SY', 'SYR', N'Asia', N'OK'),
    ( 136, N'Somalia', N'Somalia', 'SO', 'SOM', N'Africa', N'OK'),
    ( 137, N'Sri Lanka', N'Sri Lanka', 'LK', 'LKA', N'Asia', N'OK'),
    ( 138, N'Suazilandia', N'Eswatini', 'SZ', 'SWZ', N'Africa', N'OK'),
    ( 139, N'SudAfrica', N'South Africa', 'ZA', 'ZAF', N'Africa', N'OK'),
    ( 140, N'Sudán', N'Sudan', 'SD', 'SDN', N'Africa', N'OK'),
    ( 141, N'Sudán del Sur', N'South Sudan', 'SS', 'SSD', N'Africa', N'OK'),
    ( 142, N'Suecia', N'Sweden', 'SE', 'SWE', N'Europe', N'OK'),
    ( 143, N'Suiza', N'Switzerland', 'CH', 'CHE', N'Europe', N'OK'),
    ( 144, N'Surinam', N'Suriname', 'SR', 'SUR', N'South America', N'OK'),
    ( 145, N'Sáhara Occidental', N'Western Sahara', 'EH', 'ESH', N'Africa', N'Disputed territory'),
    ( 146, N'Tailandia', N'Thailand', 'TH', 'THA', N'Asia', N'OK'),
    ( 147, N'Taiwán', N'Taiwan', 'TW', 'TWN', N'Asia', N'Disputed status'),
    ( 148, N'Tanzania', N'Tanzania', 'TZ', 'TZA', N'Africa', N'OK'),
    ( 149, N'Tayikistán', N'Tajikistan', 'TJ', 'TJK', N'Asia', N'OK'),
    ( 150, N'Togo', N'Togo', 'TG', 'TGO', N'Africa', N'OK'),
    ( 151, N'Trinidad y Tobago', N'Trinidad and Tobago', 'TT', 'TTO', N'North America', N'OK'),
    ( 152, N'Turkmenistán', N'Turkmenistan', 'TM', 'TKM', N'Asia', N'OK'),
    ( 153, N'Turquía', N'Türkiye', 'TR', 'TUR', N'Asia', N'OK'),
    ( 154, N'Túnez', N'Tunisia', 'TN', 'TUN', N'Africa', N'OK'),
    ( 155, N'Ucrania', N'Ukraine', 'UA', 'UKR', N'Europe', N'OK'),
    ( 156, N'Uganda', N'Uganda', 'UG', 'UGA', N'Africa', N'OK'),
    ( 157, N'Uruguay', N'Uruguay', 'UY', 'URY', N'South America', N'OK'),
    ( 158, N'Uzbekistán', N'Uzbekistan', 'UZ', 'UZB', N'Asia', N'OK'),
    ( 159, N'Venezuela', N'Venezuela', 'VE', 'VEN', N'South America', N'OK'),
    ( 160, N'Vietnam', N'Vietnam', 'VN', 'VNM', N'Asia', N'OK'),
    ( 161, N'Yemen', N'Yemen', 'YE', 'YEM', N'Asia', N'OK'),
    ( 162, N'Yibuti', N'Djibouti', 'DJ', 'DJI', N'Africa', N'OK'),
    ( 163, N'Zambia', N'Zambia', 'ZM', 'ZMB', N'Africa', N'OK'),
    ( 164, N'Zimbabue', N'Zimbabwe', 'ZW', 'ZWE', N'Africa', N'OK');
GO
------------------------------------------------------------------------------------------------------------

CREATE OR ALTER VIEW dbo.vw_DimGeography AS
SELECT
    sd.destination_id,
    sd.order_city,
    sd.order_state,
    sd.order_zipcode,
    r.region_name,
    m.market_name,
    oc.order_country_name,             

    /* ---------- جديد ---------- */
    ci.country_name_en  AS country_name,   
    ci.iso2             AS country_iso2,
    ci.iso3             AS country_iso3,     
    ci.continent        AS continent,
    ci.map_status       AS country_map_status

FROM       dbo.shipping_destination AS sd
LEFT JOIN  dbo.region               AS r  ON sd.region_id        = r.region_id
LEFT JOIN  dbo.order_country        AS oc ON sd.order_country_id = oc.order_country_id
LEFT JOIN  dbo.market               AS m  ON r.market_id         = m.market_id
LEFT JOIN  dbo.country_iso          AS ci ON sd.order_country_id = ci.order_country_id;
GO
---------------------------------------------------------------------------------------------------------------------

