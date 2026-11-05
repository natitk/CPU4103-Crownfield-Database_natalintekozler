-- =====================================================
-- 01a_alter_table.sql  (INDIVIDUAL - Part B, ALTER TABLE)
-- Run AFTER 01_schema.sql and BEFORE 01b_group_data.sql.
-- Run it ONCE on a fresh database (MySQL has no IF NOT EXISTS for constraints;
-- to start again, drop the database and run the files in order).
--
-- Group rules implemented here as ALTER TABLE statements:
--   1. Indexes for date-range queries (overdue follow-ups, daily lists).
--   2. A clinician cannot have two appointments at the same date and time.
--   3. A patient cannot have two appointments at the same date and time.
--   4. Appointments are only booked inside clinic hours (08:00-18:00).
-- =====================================================

USE CrownfieldHospital;

-- 1. Secondary indexes
ALTER TABLE Appointments  ADD INDEX idx_appointment_date (AppointmentDate);
ALTER TABLE FollowUpPlans ADD INDEX idx_followup_due (DueDate);

-- 2 and 3. No double booking (UNIQUE on the time slot)
ALTER TABLE Appointments
    ADD CONSTRAINT uq_clinician_slot UNIQUE (ClinicianID, AppointmentDate, AppointmentTime);

ALTER TABLE Appointments
    ADD CONSTRAINT uq_patient_slot UNIQUE (PatientID, AppointmentDate, AppointmentTime);

-- 4. Clinic hours (CHECK, enforced from MySQL 8.0.16)
ALTER TABLE Appointments
    ADD CONSTRAINT chk_clinic_hours CHECK (AppointmentTime BETWEEN '08:00:00' AND '18:00:00');
