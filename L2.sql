-- L2 product 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L2.L2_product AS
SELECT 
product_id
,product_name
,product_type
,product_category
FROM fair-ceiling-455612-s4.L1.L1_product
WHERE product_category = "product" or product_category = "rent" -- klient chce jen tyto kategorie 
--WHERE product_category IN ('product', 'rent')
;

-- L2 branch 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L2.L2_branch AS
SELECT
branch_id
,branch_name
FROM fair-ceiling-455612-s4.L1.L1_branch
WHERE branch_name != "unknown" -- jen známé kategorie 
;


-- L2 invoice
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L2.L2_invoice AS
SELECT
i.invoice_id
,i.invoice_previous_id
,i.contract_id --FK
,i.date_issue
,i.due_date
,i.paid_date
,i.start_date
,i.end_date
,i.amount_w_vat
,i.return_w_vat
,CASE
  WHEN i.amount_w_vat <= 0 THEN 0
  WHEN i.amount_w_vat > 0 THEN amount_w_vat / 1.2
END AS amount_wo_vat_usd -- cena bez dph (20%)
,i.insert_date
,i.update_date
,ROW_NUMBER() OVER (PARTITION BY i.contract_id order by i.date_issue asc) AS invoice_order -- kolikátá je to faktura na contract 
FROM fair-ceiling-455612-s4.L1.L1_invoice i
INNER JOIN fair-ceiling-455612-s4.L1.L1_contract c
ON i.contract_id = c.contract_id
WHERE i.invoice_type = 'invoice' AND flag_invoice_issued = true -- stanoveno zákazníkem 
ORDER BY contract_id, date_issue
;

--L2 contract 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L2.L2_contract AS
SELECT
contract_id
,branch_id
,contract_valid_from
,contract_valid_to
,registration_date
,signed_date
,activation_process_date
,prolongation_date
,registration_end_reason
,flag_prolongation --if contract  was prolonged
,flag_send_email -- If the invoice is sent as email. True - yes, false - other methods
,contract_status
FROM fair-ceiling-455612-s4.L1.L1_contract
WHERE registration_date is not null -- chci jen uzavřené kontrakty
;

--L2 product purchase 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L2.L2_product_purchase AS
SELECT
product_purchase_id  --PK
,contract_id  --FK
,product_id  --FK
,create_date
,product_valid_from
,product_valid_to
,price_wo_vat
,IF(price_wo_vat <= 0, 0, price_wo_vat*1.2) AS price_w_vat --počítáme cenu s daní (20%)
,date_update
,product_status
,product_name
,product_type
,product_category
,measure_unit
,IF(product_valid_from = '2035-12-31', TRUE, FALSE) AS flag_unlimited_product
FROM fair-ceiling-455612-s4.L1.L1_product_purchase
WHERE product_status IS NOT NULL 
AND product_status NOT IN ("canceled", "canceled registration", "disconnected") --ne prázdný nebo zrušený status 
AND product_category IN ("product","rent") --opět jen tyto kategorie
;


