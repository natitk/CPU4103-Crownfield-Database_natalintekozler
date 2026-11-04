-- =====================================================
-- CROWNFIELD EYE HOSPITAL
-- 01_schema.sql : creates the database and the 11 tables
-- (structure only - data is loaded by 02_data.sql)
-- =====================================================

CREATE DATABASE IF NOT EXISTS CrownfieldHospital;
USE CrownfieldHospital;


-- =====================================================
-- 1. PATIENTS
-- Each patient is stored once
-- =====================================================

CREATE TABLE IF NOT EXISTS Patients (
    PatientID VARCHAR(10) PRIMARY KEY,
    PatientName VARCHAR(100) NOT NULL,
    Postcode VARCHAR(10) NOT NULL
);


-- =====================================================
-- 2. SPECIALTIES
-- =====================================================

CREATE TABLE IF NOT EXISTS Specialties (
    SpecialtyID VARCHAR(10) PRIMARY KEY,
    SpecialtyName VARCHAR(100) NOT NULL UNIQUE
);


-- =====================================================
-- 3. CLINICIANS
-- Each clinician may have one primary specialty
-- =====================================================

CREATE TABLE IF NOT EXISTS Clinicians (
    ClinicianID VARCHAR(10) PRIMARY KEY,
    ClinicianName VARCHAR(100) NOT NULL,
    SpecialtyID VARCHAR(10),

    FOREIGN KEY (SpecialtyID)
        REFERENCES Specialties(SpecialtyID)
);


-- =====================================================
-- 4. CLINICS
-- =====================================================

CREATE TABLE IF NOT EXISTS Clinics (
    ClinicID VARCHAR(10) PRIMARY KEY,
    ClinicName VARCHAR(100) NOT NULL UNIQUE
);


-- =====================================================
-- 5. APPOINTMENTS
-- Each appointment requires a patient, clinician and clinic
-- =====================================================

CREATE TABLE IF NOT EXISTS Appointments (
    AppointmentID VARCHAR(10) PRIMARY KEY,
    PatientID VARCHAR(10) NOT NULL,
    ClinicianID VARCHAR(10) NOT NULL,
    ClinicID VARCHAR(10) NOT NULL,
    AppointmentDate DATE NOT NULL,
    AppointmentTime TIME NOT NULL,

    FOREIGN KEY (PatientID)
        REFERENCES Patients(PatientID),

    FOREIGN KEY (ClinicianID)
        REFERENCES Clinicians(ClinicianID),

    FOREIGN KEY (ClinicID)
        REFERENCES Clinics(ClinicID)
);


-- =====================================================
-- 6. DIAGNOSES
-- A catalogue of diagnoses
-- =====================================================

CREATE TABLE IF NOT EXISTS Diagnoses (
    DiagnosisID VARCHAR(10) PRIMARY KEY,
    DiagnosisName VARCHAR(150) NOT NULL UNIQUE
);


-- =====================================================
-- 7. APPOINTMENT DIAGNOSES
-- An appointment can have several diagnoses
-- The same diagnosis can appear in several appointments
-- =====================================================

CREATE TABLE IF NOT EXISTS AppointmentDiagnoses (
    AppointmentID VARCHAR(10) NOT NULL,
    DiagnosisID VARCHAR(10) NOT NULL,

    PRIMARY KEY (AppointmentID, DiagnosisID),

    FOREIGN KEY (AppointmentID)
        REFERENCES Appointments(AppointmentID),

    FOREIGN KEY (DiagnosisID)
        REFERENCES Diagnoses(DiagnosisID)
);


-- =====================================================
-- 8. MEDICINES
-- =====================================================

CREATE TABLE IF NOT EXISTS Medicines (
    MedicineID VARCHAR(10) PRIMARY KEY,
    MedicineName VARCHAR(100) NOT NULL UNIQUE
);


-- =====================================================
-- 9. PRESCRIPTIONS
-- Each prescription belongs to an appointment
-- =====================================================

CREATE TABLE IF NOT EXISTS Prescriptions (
    PrescriptionID VARCHAR(10) PRIMARY KEY,
    AppointmentID VARCHAR(10) NOT NULL,

    FOREIGN KEY (AppointmentID)
        REFERENCES Appointments(AppointmentID)
);


-- =====================================================
-- 10. PRESCRIPTION ITEMS
-- Each medicine is stored as a separate prescription item
-- NULL means the source did not supply the dosing details
-- =====================================================

CREATE TABLE IF NOT EXISTS PrescriptionItems (
    PrescriptionID VARCHAR(10) NOT NULL,
    ItemNumber INT NOT NULL,
    MedicineID VARCHAR(10) NOT NULL,
    Dose VARCHAR(100),
    Route VARCHAR(50),
    Frequency VARCHAR(100),
    Duration VARCHAR(100),

    PRIMARY KEY (PrescriptionID, ItemNumber),

    CHECK (ItemNumber > 0),

    FOREIGN KEY (PrescriptionID)
        REFERENCES Prescriptions(PrescriptionID),

    FOREIGN KEY (MedicineID)
        REFERENCES Medicines(MedicineID)
);


-- =====================================================
-- 11. FOLLOW-UP PLANS
-- Assumption: at most one follow-up plan per appointment
-- 'Not recorded' preserves the missing source status
-- =====================================================

CREATE TABLE IF NOT EXISTS FollowUpPlans (
    FollowUpID VARCHAR(10) PRIMARY KEY,
    AppointmentID VARCHAR(10) NOT NULL UNIQUE,
    DueDate DATE NOT NULL,
    Priority VARCHAR(10) NOT NULL,
    FollowUpStatus VARCHAR(20) NOT NULL
        DEFAULT 'Not recorded',
    Notes VARCHAR(255),

    CHECK (Priority IN ('Routine', 'High', 'Urgent')),

    CHECK (
        FollowUpStatus IN (
            'Not recorded',
            'Pending',
            'Scheduled',
            'Completed',
            'Cancelled'
        )
    ),

    FOREIGN KEY (AppointmentID)
        REFERENCES Appointments(AppointmentID)
);
