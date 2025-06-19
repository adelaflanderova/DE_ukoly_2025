-- Googlesheet 
-- L1 status 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L1.L1_status AS
SELECT 
  CAST(id_status AS INT) AS product_status_id --PK
  ,LOWER(status_name) AS product_status_name -- vše na malá písmena 
 --zbytečný ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS product_status_update_date -- vše v jednom čas.pásmu 
FROM fair-ceiling-455612-s4.L0_google_sheet.status
WHERE id_status IS NOT NULL -- nechci null hodnoty
  AND status_name IS NOT NULL 
QUALIFY ROW_NUMBER() OVER(PARTITION BY product_status_id) = 1 -- unikátní id 
;


--L1 branch
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L1.L1_branch AS
SELECT 
  CAST(id_branch AS INT) AS branch_id --PK
  ,branch_name
--  ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS product_branch_update_date --zbytečný, nemusí tu vůbec být
FROM fair-ceiling-455612-s4.L0_google_sheet.branch
WHERE id_branch != "NULL"
;

--L1 product
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L1.L1_product AS
SELECT
  CAST(id_product AS INT) AS product_id --PK
  ,LOWER(name) AS product_name
  ,LOWER(type) AS product_type
  ,LOWER(category) AS product_category
  --,CAST(is_vat_applicable AS BOOL) AS is_vat_applicable
 -- ,DATE(TIMESTAMP(date_update), 'Europe/Prague') AS product_update_date
FROM fair-ceiling-455612-s4.L0_google_sheet.product
where id_product IS NOT NULL AND name IS NOT NULL
QUALIFY ROW_NUMBER() OVER(PARTITION BY id_product) = 1
;


-- Accounting system:
-- L1 invoice 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L1.L1_invoice AS
SELECT 
  id_invoice AS invoice_id --PK
  ,id_invoice_old AS invoice_previous_id
  ,invoice_id_contract AS contract_id -- FK 
  ,status AS invoice_status_id 
  ,id_branch AS branch_id
  ,IF(status < 100, TRUE, FALSE) AS flag_invoice_issued -- Invoce status. Invoice status < 100  have been issued. >= 100 - not issued
  ,DATE(TIMESTAMP(date),'Europe/Prague') AS date_issue
  ,DATE(TIMESTAMP(scadent),'Europe/Prague') AS due_date
  ,DATE(TIMESTAMP(date_paid),'Europe/Prague') AS paid_date
  ,DATE(TIMESTAMP(start_date),'Europe/Prague') AS start_date
  ,DATE(TIMESTAMP(end_date),'Europe/Prague') AS end_date
  ,DATE(TIMESTAMP(date_insert),'Europe/Prague') AS insert_date
  ,DATE(TIMESTAMP(date_update),'Europe/Prague') AS update_date
  ,value AS amount_w_vat
  ,payed AS amount_payed
--  ,flag_paid_currier 
  ,invoice_type AS invoice_type_id -- Invoice_type: 1 - invoice, 3 -  credit_note, 2 - return, 4 - other
  ,CASE
    WHEN invoice_type = 1 THEN "invoice"
    WHEN invoice_type = 2 THEN "return"
    WHEN invoice_type = 3 THEN "credit_note"
    WHEN invoice_type = 4 THEN "other"
  END AS invoice_type
  ,number AS invoice_number
  ,value_storno AS return_w_vat
  FROM fair-ceiling-455612-s4.L0_accounting_system.invoices
  ; 

  --L1 invoice load 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L1.L1_invoice_load AS 
SELECT
  id_load AS invoice_load_id --PK
  ,id_contract AS contract_id --FK
  ,CAST(id_package AS INT) AS package_id --FK
  ,id_invoice AS invoice_id --FK
  ,id_package_template AS product_id --FK
  ,notlei AS price_wo_vat_usd
 -- ,currency
  ,tva AS vat_rate
  ,value AS price_w_vat_usd
  ,payed AS paid_w_vat_usd
  ,CASE
    WHEN um IN ('mesia','m?síce','m?si?1ce','měsice','mesiace','měsíce','mesice') THEN 'month'
    WHEN um = "kus" THEN "item"
    WHEN um = "den" THEN "day"
    WHEN um = "min" THEN "minutes"
    WHEN um = '0' then null 
  ELSE um
  END AS unit -- sjednocení dat pro grupování + eng
  ,quantity
  ,DATE(start_date, "Europe/Prague") AS start_date
  ,DATE(end_date, "Europe/Prague") AS end_date
  ,DATE(date_insert, "Europe/Prague") AS date_insert
  ,DATE(date_update, "Europe/Prague") AS date_update
  ,DATE(TIMESTAMP(load_date), "Europe/Prague") AS load_date
FROM fair-ceiling-455612-s4.L0_accounting_system.invoices_load
;

--CRM
-- contract L1
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L1.L1_contract AS
SELECT
  id_contract AS contract_id --PK
  ,id_branch AS branch_id -- FK
  ,DATE(date_contract_valid_from, "Europe/Prague") AS contract_valid_from
  ,DATE(TIMESTAMP(date_contract_valid_to), "Europe/Prague") AS contract_valid_to
  ,DATE(date_registered, "Europe/Prague") as registration_date
  ,DATE(date_signed, "Europe/Prague") as signed_date
  ,DATE(activation_process_date, "Europe/Prague") as activation_process_date
  ,DATE(prolongation_date, "Europe/Prague") as prolongation_date
  ,registration_end_reason
  ,flag_prolongation --if contract  was prolonged
  ,flag_send_inv_email AS flag_send_email -- If the invoice is sent as email. True - yes, false - other methods
  ,contract_status
  ,DATE(TIMESTAMP(load_date), "Europe/Prague") as load_date
FROM fair-ceiling-455612-s4.L0_crm.contract
;

-- L1 product purchase 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L1.L1_product_purchase AS
SELECT
pac.id_package AS product_purchase_id  --PK
,pac.id_contract AS contract_id  --FK
,pac.id_package_template AS product_id  --FK
,DATE(pac.date_insert, "Europe/Prague") AS create_date
,DATE(TIMESTAMP(pac.start_date), "Europe/Prague") AS product_valid_from
,DATE(TIMESTAMP(pac.end_date), "Europe/Prague") AS product_valid_to
,pac.fee AS price_wo_vat
,DATE(pac.date_update, "Europe/Prague") AS date_update
,pac.package_status AS product_status_id  -- FK
,st.product_status_name as product_status
,pro.product_name
,pro.product_type
,pro.product_category
,CASE
  WHEN pac.measure_unit IN ('mesia','m?síce','m?si?1ce','měsice','mesiace','měsíce','mesice') then  'month'
  WHEN pac.measure_unit = "kus" THEN "item"
  WHEN pac.measure_unit = "den" THEN "day"
  WHEN pac.measure_unit = "min" THEN "minutes"
  ELSE pac.measure_unit
END AS measure_unit
,pac.id_branch as branch_id --FK
,pac.load_date
FROM fair-ceiling-455612-s4.L0_crm.package_purchases pac
LEFT JOIN fair-ceiling-455612-s4.L1.L1_product pro
ON pro.product_id = pac.id_package_template
LEFT JOIN fair-ceiling-455612-s4.L1.L1_status st
ON st.product_status_id = pac.package_status
;
