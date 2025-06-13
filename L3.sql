--L3 product 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L3.L3_product AS
SELECT
p.product_id
,pp.product_valid_from
,pp.product_valid_to
,pp.measure_unit
,pp.flag_unlimited_product
,p.product_name
,p.product_type
FROM fair-ceiling-455612-s4.L2.L2_product_purchase pp
LEFT JOIN fair-ceiling-455612-s4.L2.L2_product p
ON pp.product_id = p.product_id
;

--L3 contract 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L3.L3_contract AS
SELECT 
contract_id
,branch_id
,contract_valid_from
,contract_valid_to
,prolongation_date
,registration_end_reason
,contract_status
FROM fair-ceiling-455612-s4.L2.L2_contract 
;


--L3 branch
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L3.L3_branch AS
SELECT branch_id
  , branch_name
FROM fair-ceiling-455612-s4.L2.L2_branch
;


--L3 invoice 
CREATE OR REPLACE VIEW fair-ceiling-455612-s4.L3.L3_invoice AS
SELECT
i.invoice_id
,i.contract_id
,i.paid_date
,i.amount_w_vat
,i.return_w_vat
,pp.product_id
FROM fair-ceiling-455612-s4.L2.L2_invoice i
LEFT JOIN fair-ceiling-455612-s4.L2.L2_product_purchase pp
ON pp.contract_id = i.contract_id --může být i inner join
WHERE pp.product_id IS NOT NULL
;
