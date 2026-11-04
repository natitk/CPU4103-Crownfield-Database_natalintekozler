-- =====================================================
-- 04_security.sql  (INDIVIDUAL - Part D)
-- Run AFTER 01_schema.sql, 01b_group_data.sql, 01c_my_extra_data.sql
-- and 03_procedure_and_trigger.sql
--
-- D1  Roles and privileges (least privilege) for 4 user types
-- D2  Data protection: salted SHA-256 hashing of patient passwords
-- Extra credit: SQL injection demo and the secure alternative
--
-- NOTE: all passwords below are DEMO values for this teaching scenario.
-- Never reuse them anywhere real.
-- =====================================================

USE CrownfieldHospital;


-- =====================================================
-- PART 1: PATIENT ACCOUNTS TABLE
-- Stores a login for a patient. The password is never stored in plain
-- text: only a random salt and the SHA-256 hash of (salt + password).
-- PatientID is a foreign key, so the table is not orphaned.
-- =====================================================

CREATE TABLE IF NOT EXISTS PatientAccounts (
    PatientID    VARCHAR(10) PRIMARY KEY,
    Username     VARCHAR(30) NOT NULL UNIQUE,
    PasswordSalt CHAR(32)    NOT NULL,
    PasswordHash CHAR(64)    NOT NULL,

    FOREIGN KEY (PatientID)
        REFERENCES Patients(PatientID)
);


-- =====================================================
-- PART 2: ROLES (D1)
-- =====================================================

CREATE ROLE IF NOT EXISTS 'role_admin';
CREATE ROLE IF NOT EXISTS 'role_doctor';
CREATE ROLE IF NOT EXISTS 'role_receptionist';
CREATE ROLE IF NOT EXISTS 'role_patient';


-- ---------- Administrator: full control of this database ----------
GRANT ALL PRIVILEGES ON CrownfieldHospital.* TO 'role_admin';


-- ---------- Doctor: reads everything clinical, writes clinical data,
--            never deletes, cannot see password hashes ----------
GRANT SELECT ON CrownfieldHospital.Patients              TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.Specialties           TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.Clinicians            TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.Clinics               TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.Appointments          TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.Diagnoses             TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.AppointmentDiagnoses  TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.Medicines             TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.Prescriptions         TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.PrescriptionItems     TO 'role_doctor';
GRANT SELECT ON CrownfieldHospital.FollowUpPlans         TO 'role_doctor';

GRANT INSERT, UPDATE ON CrownfieldHospital.AppointmentDiagnoses TO 'role_doctor';
GRANT INSERT, UPDATE ON CrownfieldHospital.Prescriptions        TO 'role_doctor';
GRANT INSERT, UPDATE ON CrownfieldHospital.PrescriptionItems    TO 'role_doctor';
GRANT INSERT, UPDATE ON CrownfieldHospital.FollowUpPlans        TO 'role_doctor';

GRANT EXECUTE ON PROCEDURE CrownfieldHospital.GetClinicianSchedule TO 'role_doctor';


-- ---------- Receptionist: manages patients and bookings only.
--            No access to diagnoses or prescriptions (clinical data) ----------
GRANT SELECT, INSERT, UPDATE ON CrownfieldHospital.Patients      TO 'role_receptionist';
GRANT SELECT, INSERT, UPDATE ON CrownfieldHospital.Appointments  TO 'role_receptionist';
GRANT SELECT ON CrownfieldHospital.Clinicians    TO 'role_receptionist';
GRANT SELECT ON CrownfieldHospital.Clinics       TO 'role_receptionist';
GRANT SELECT ON CrownfieldHospital.Specialties   TO 'role_receptionist';
GRANT SELECT ON CrownfieldHospital.FollowUpPlans TO 'role_receptionist';

GRANT EXECUTE ON PROCEDURE CrownfieldHospital.GetClinicianSchedule TO 'role_receptionist';


-- ---------- Patient: can see ONLY their own appointments, through a view.
--            MySQL has no row-level security, so the view filters rows
--            by the database user name that is logged in. ----------
CREATE OR REPLACE VIEW v_my_appointments AS
SELECT a.AppointmentID,
       a.AppointmentDate,
       a.AppointmentTime,
       c.ClinicianName,
       cl.ClinicName
FROM PatientAccounts AS pa
INNER JOIN Appointments AS a  ON a.PatientID   = pa.PatientID
INNER JOIN Clinicians   AS c  ON c.ClinicianID = a.ClinicianID
INNER JOIN Clinics      AS cl ON cl.ClinicID   = a.ClinicID
WHERE pa.Username = SUBSTRING_INDEX(USER(), '@', 1);

GRANT SELECT ON CrownfieldHospital.v_my_appointments TO 'role_patient';


-- =====================================================
-- PART 3: DEMO USERS (one per role) AND ROLE ASSIGNMENT
-- =====================================================

CREATE USER IF NOT EXISTS 'crown_admin'@'localhost' IDENTIFIED BY 'Demo#Admin1';
CREATE USER IF NOT EXISTS 'dr_shah'@'localhost'     IDENTIFIED BY 'Demo#Doctor1';
CREATE USER IF NOT EXISTS 'recep_amy'@'localhost'   IDENTIFIED BY 'Demo#Recep1';
CREATE USER IF NOT EXISTS 'amina'@'localhost'       IDENTIFIED BY 'Demo#Amina1';

GRANT 'role_admin'        TO 'crown_admin'@'localhost';
GRANT 'role_doctor'       TO 'dr_shah'@'localhost';
GRANT 'role_receptionist' TO 'recep_amy'@'localhost';
GRANT 'role_patient'      TO 'amina'@'localhost';

-- Make the role active automatically when the user logs in
SET DEFAULT ROLE 'role_admin'        TO 'crown_admin'@'localhost';
SET DEFAULT ROLE 'role_doctor'       TO 'dr_shah'@'localhost';
SET DEFAULT ROLE 'role_receptionist' TO 'recep_amy'@'localhost';
SET DEFAULT ROLE 'role_patient'      TO 'amina'@'localhost';


-- =====================================================
-- PART 4: DATA PROTECTION - SALTED HASHING (D2)
-- A fresh random salt is generated for every patient, so two patients
-- with the same password get different hashes.
-- INSERT IGNORE keeps the script safe to run twice.
-- =====================================================

INSERT IGNORE INTO PatientAccounts (PatientID, Username, PasswordSalt, PasswordHash)
SELECT 'OP001', 'amina', s.salt, SHA2(CONCAT(s.salt, 'Demo#Amina1'), 256)
FROM (SELECT HEX(RANDOM_BYTES(16)) AS salt) AS s;

INSERT IGNORE INTO PatientAccounts (PatientID, Username, PasswordSalt, PasswordHash)
SELECT 'OP002', 'daniel', s.salt, SHA2(CONCAT(s.salt, 'Demo#Daniel1'), 256)
FROM (SELECT HEX(RANDOM_BYTES(16)) AS salt) AS s;


-- =====================================================
-- CHECKS (run these one at a time with Ctrl+Enter)
-- =====================================================

-- Check 1: the table holds only salts and hashes, no plain-text password
-- SELECT PatientID, Username, PasswordSalt, PasswordHash FROM PatientAccounts;

-- Check 2: login test with the CORRECT password -> 1 row
-- SELECT COUNT(*) AS LoginOK
-- FROM PatientAccounts
-- WHERE Username = 'amina'
--   AND PasswordHash = SHA2(CONCAT(PasswordSalt, 'Demo#Amina1'), 256);

-- Check 3: login test with a WRONG password -> 0 rows
-- SELECT COUNT(*) AS LoginOK
-- FROM PatientAccounts
-- WHERE Username = 'amina'
--   AND PasswordHash = SHA2(CONCAT(PasswordSalt, 'wrong-password'), 256);

-- Check 4: access matrix evidence
-- SHOW GRANTS FOR 'role_doctor';
-- SHOW GRANTS FOR 'role_receptionist';
-- SHOW GRANTS FOR 'role_patient';
-- SHOW GRANTS FOR 'role_admin';


-- =====================================================
-- EXTRA CREDIT: SQL INJECTION - VULNERABLE vs SECURE
-- (run each block separately, they are separate demonstrations)
-- =====================================================

-- Attacker input: closes the quote and adds a condition that is always true
-- SET @username = "x' OR '1'='1";

-- VULNERABLE: the input is glued into the SQL text -> returns EVERY account
-- SET @sql = CONCAT("SELECT PatientID, Username FROM PatientAccounts WHERE Username = '", @username, "'");
-- PREPARE unsafe_stmt FROM @sql;
-- EXECUTE unsafe_stmt;
-- DEALLOCATE PREPARE unsafe_stmt;

-- SECURE: a parameter placeholder (?) keeps the input as plain data -> 0 rows
-- PREPARE safe_stmt FROM 'SELECT PatientID, Username FROM PatientAccounts WHERE Username = ?';
-- EXECUTE safe_stmt USING @username;
-- DEALLOCATE PREPARE safe_stmt;
