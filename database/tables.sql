CREATE DATABASE IF NOT EXISTS club_collab;
USE club_collab;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Volunteer_Badge;
DROP TABLE IF EXISTS Badge;
DROP TABLE IF EXISTS Phone_Numbers;
DROP TABLE IF EXISTS Contact_Emails;
DROP TABLE IF EXISTS Volunteer_Log;
DROP TABLE IF EXISTS Collaboration;
DROP TABLE IF EXISTS Resource_Booking;
DROP TABLE IF EXISTS Maintenance_Log;
DROP TABLE IF EXISTS Equipment;
DROP TABLE IF EXISTS Event;
DROP TABLE IF EXISTS Membership;
DROP TABLE IF EXISTS Club_Executive;
DROP TABLE IF EXISTS General_Student;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Club;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Club (
    Club_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Department VARCHAR(100) NOT NULL,
    Office_Room VARCHAR(50),
    Founded_Date DATE,
    CONSTRAINT chk_club_name CHECK (LENGTH(Name) > 0)
);

CREATE TABLE Student (
    Student_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Street VARCHAR(200),
    City VARCHAR(50),
    Zip VARCHAR(10),
    Contact_No VARCHAR(20),
    CONSTRAINT chk_email CHECK (Email LIKE '%@%'),
    CONSTRAINT chk_student_name CHECK (LENGTH(Name) > 0)
);

CREATE TABLE General_Student (
    Student_ID INT PRIMARY KEY,
    Year_of_Study INT NOT NULL,
    Major VARCHAR(100) NOT NULL,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    CONSTRAINT chk_year CHECK (Year_of_Study BETWEEN 1 AND 4)
);

CREATE TABLE Club_Executive (
    Student_ID INT PRIMARY KEY,
    Position VARCHAR(50) NOT NULL,
    Term_Start DATE NOT NULL,
    Term_End DATE,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    CONSTRAINT chk_term CHECK (Term_End IS NULL OR Term_End > Term_Start)
);

CREATE TABLE Contact_Emails (
    Club_ID INT NOT NULL,
    Email VARCHAR(100) NOT NULL,
    PRIMARY KEY (Club_ID, Email),
    FOREIGN KEY (Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE,
    CONSTRAINT chk_contact_email CHECK (Email LIKE '%@%')
);

CREATE TABLE Phone_Numbers (
    Student_ID INT NOT NULL,
    Phone_Number VARCHAR(20) NOT NULL,
    PRIMARY KEY (Student_ID, Phone_Number),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    CONSTRAINT chk_phone CHECK (LENGTH(Phone_Number) >= 10)
);

CREATE TABLE Membership (
    Member_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT NOT NULL,
    Club_ID INT NOT NULL,
    Role VARCHAR(50) NOT NULL,
    Join_Date DATE NOT NULL,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE,
    CONSTRAINT chk_role CHECK (Role IN ('Member', 'Volunteer', 'Executive', 'Advisor')),
    UNIQUE (Student_ID, Club_ID)
);

CREATE TABLE Equipment (
    Equip_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Type VARCHAR(50) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Available',
    Owner_Club_ID INT NOT NULL,
    Purchase_Date DATE,
    FOREIGN KEY (Owner_Club_ID) REFERENCES Club(Club_ID) ON DELETE RESTRICT,
    CONSTRAINT chk_status CHECK (Status IN ('Available', 'In-Use', 'Damaged', 'Maintenance')),
    CONSTRAINT chk_equip_type CHECK (Type IN ('Camera', 'Projector', 'Microphone', 'Laptop', 'Speaker', 'Other'))
);

CREATE TABLE Maintenance_Log (
    Equip_ID INT NOT NULL,
    Log_ID INT NOT NULL,
    Date DATE NOT NULL,
    Description TEXT NOT NULL,
    Cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (Equip_ID, Log_ID),
    FOREIGN KEY (Equip_ID) REFERENCES Equipment(Equip_ID) ON DELETE CASCADE,
    CONSTRAINT chk_cost CHECK (Cost >= 0)
);

CREATE TABLE Event (
    Event_ID INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(200) NOT NULL,
    Date DATE NOT NULL,
    Venue VARCHAR(200) NOT NULL,
    Primary_Club_ID INT NOT NULL,
    Description TEXT,
    FOREIGN KEY (Primary_Club_ID) REFERENCES Club(Club_ID) ON DELETE RESTRICT,
    CONSTRAINT chk_title CHECK (LENGTH(Title) > 0)
);

CREATE TABLE Collaboration (
    Event_ID INT NOT NULL,
    Partner_Club_ID INT NOT NULL,
    Contribution_Type VARCHAR(100),
    PRIMARY KEY (Event_ID, Partner_Club_ID),
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    FOREIGN KEY (Partner_Club_ID) REFERENCES Club(Club_ID) ON DELETE CASCADE
);

CREATE TABLE Resource_Booking (
    Booking_ID INT PRIMARY KEY AUTO_INCREMENT,
    Equip_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    Borrow_Time DATETIME NOT NULL,
    Return_Time DATETIME NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Confirmed',
    FOREIGN KEY (Equip_ID) REFERENCES Equipment(Equip_ID) ON DELETE RESTRICT,
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    CONSTRAINT chk_booking_time CHECK (Return_Time > Borrow_Time),
    CONSTRAINT chk_booking_status CHECK (Status IN ('Confirmed', 'Completed', 'Cancelled'))
);

CREATE TABLE Volunteer_Log (
    Log_ID INT PRIMARY KEY AUTO_INCREMENT,
    Student_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    Role VARCHAR(100) NOT NULL,
    Hours_Worked DECIMAL(5, 2) NOT NULL,
    Verified_By INT,
    Verification_Date DATE,
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    FOREIGN KEY (Verified_By) REFERENCES Club_Executive(Student_ID) ON DELETE SET NULL,
    CONSTRAINT chk_hours CHECK (Hours_Worked > 0 AND Hours_Worked <= 24),
    CONSTRAINT chk_role_length CHECK (LENGTH(Role) > 0)
);

CREATE TABLE Badge (
    Badge_ID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT NOT NULL,
    Icon VARCHAR(50) NOT NULL,
    Color VARCHAR(20) NOT NULL,
    Hours_Required DECIMAL(5, 2) NOT NULL,
    Tier VARCHAR(20) NOT NULL,
    CONSTRAINT chk_tier CHECK (Tier IN ('Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond')),
    CONSTRAINT chk_hours_required CHECK (Hours_Required >= 0)
);

CREATE TABLE Volunteer_Badge (
    Student_ID INT NOT NULL,
    Badge_ID INT NOT NULL,
    Earned_Date DATE NOT NULL,
    Total_Hours_At_Earning DECIMAL(6, 2) NOT NULL,
    PRIMARY KEY (Student_ID, Badge_ID),
    FOREIGN KEY (Student_ID) REFERENCES Student(Student_ID) ON DELETE CASCADE,
    FOREIGN KEY (Badge_ID) REFERENCES Badge(Badge_ID) ON DELETE CASCADE,
    CONSTRAINT chk_total_hours CHECK (Total_Hours_At_Earning >= 0)
);
