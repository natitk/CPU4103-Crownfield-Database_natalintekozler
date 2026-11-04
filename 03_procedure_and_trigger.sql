-- =====================================================
-- 03_procedure_and_trigger.sql  (INDIVIDUAL)
-- Run AFTER 01_schema.sql, 01b_group_data.sql and 01c_my_extra_data.sql
-- =====================================================

USE CrownfieldHospital;

-- =====================================================
-- Q5: STORED PROCEDURE WITH AN INPUT PARAMETER
-- Question: What is the schedule of a given clinician, with patient,
--           clinic and follow-up due date (if any)?
-- =====================================================

DROP PROCEDURE IF EXISTS GetClinicianSchedule;

DELIMITER $$

CREATE PROCEDURE GetClinicianSchedule(IN p_clinician_id VARCHAR(10))
BEGIN
    -- Input validation: reject an unknown clinician with a clear error
    IF NOT EXISTS (SELECT 1 FROM Clinicians WHERE ClinicianID = p_clinician_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Unknown ClinicianID';
    END IF;

    SELECT a.AppointmentID,
           a.AppointmentDate,
           a.AppointmentTime,
           p.PatientName,
           cl.ClinicName,
           f.DueDate AS FollowUpDue,
           f.Priority
    FROM Appointments AS a
    INNER JOIN Patients AS p ON p.PatientID = a.PatientID
    INNER JOIN Clinics AS cl ON cl.ClinicID = a.ClinicID
    LEFT JOIN FollowUpPlans AS f ON f.AppointmentID = a.AppointmentID
    WHERE a.ClinicianID = p_clinician_id
    ORDER BY a.AppointmentDate, a.AppointmentTime;
END$$

DELIMITER ;

-- Test calls
CALL GetClinicianSchedule('C001');
-- CALL GetClinicianSchedule('C999');   -- uncomment to show the error handling


-- =====================================================
-- Q6: TRIGGERS THAT ENFORCE A BUSINESS RULE
-- Rule: a follow-up due date must not be earlier than the appointment date.
-- Why a trigger: a CHECK constraint cannot read another table, but the
-- appointment date lives in Appointments, not in FollowUpPlans.
-- Two triggers are needed because MySQL has no single INSERT-or-UPDATE trigger.
-- =====================================================

DROP TRIGGER IF EXISTS trg_followup_before_insert;
DROP TRIGGER IF EXISTS trg_followup_before_update;

DELIMITER $$

CREATE TRIGGER trg_followup_before_insert
BEFORE INSERT ON FollowUpPlans
FOR EACH ROW
BEGIN
    DECLARE v_appt_date DATE;

    SELECT AppointmentDate INTO v_appt_date
    FROM Appointments
    WHERE AppointmentID = NEW.AppointmentID;

    IF NEW.DueDate < v_appt_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Follow-up due date cannot be before the appointment date';
    END IF;
END$$

CREATE TRIGGER trg_followup_before_update
BEFORE UPDATE ON FollowUpPlans
FOR EACH ROW
BEGIN
    DECLARE v_appt_date DATE;

    SELECT AppointmentDate INTO v_appt_date
    FROM Appointments
    WHERE AppointmentID = NEW.AppointmentID;

    IF NEW.DueDate < v_appt_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Follow-up due date cannot be before the appointment date';
    END IF;
END$$

DELIMITER ;

-- ---------------- TRIGGER TESTS (run one at a time) ----------------
-- Test 1 - must FAIL (A001 is on 2026-10-05, due date is earlier):
-- UPDATE FollowUpPlans SET DueDate = '2026-01-01' WHERE FollowUpID = 'F001';
--
-- Test 2 - must SUCCEED (valid date, then restore the original):
-- UPDATE FollowUpPlans SET DueDate = '2026-11-20' WHERE FollowUpID = 'F001';
-- UPDATE FollowUpPlans SET DueDate = '2026-11-16' WHERE FollowUpID = 'F001';
--
-- Check the data is unchanged after the failed update:
-- SELECT FollowUpID, AppointmentID, DueDate FROM FollowUpPlans WHERE FollowUpID = 'F001';
