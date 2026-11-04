-- =====================================================
-- 01c_my_extra_data.sql  (INDIVIDUAL - my own test data)
-- Run AFTER 01_schema.sql and 01b_group_data.sql
-- Purpose: two newly registered patients with no appointment yet,
--          so the LEFT JOIN query (Q3) has missing data to reveal.
-- All records are fictional synthetic data.
-- INSERT IGNORE makes the script safe to run twice.
-- =====================================================

USE CrownfieldHospital;

INSERT IGNORE INTO Patients (PatientID, PatientName, Postcode) VALUES
('OP201', 'Hannah Clarke', 'HA1 2AB'),
('OP202', 'Omar Hassan',   'HA2 3CD');
