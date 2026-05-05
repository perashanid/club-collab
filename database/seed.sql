USE club_collab;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE Volunteer_Badge;
TRUNCATE TABLE Badge;
TRUNCATE TABLE Phone_Numbers;
TRUNCATE TABLE Contact_Emails;
TRUNCATE TABLE Volunteer_Log;
TRUNCATE TABLE Collaboration;
TRUNCATE TABLE Resource_Booking;
TRUNCATE TABLE Maintenance_Log;
TRUNCATE TABLE Equipment;
TRUNCATE TABLE Event;
TRUNCATE TABLE Membership;
TRUNCATE TABLE Club_Executive;
TRUNCATE TABLE General_Student;
TRUNCATE TABLE Student;
TRUNCATE TABLE Club;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO Club (Club_ID, Name, Department, Office_Room, Founded_Date) VALUES
(1, 'Media Society', 'Arts & Media', 'A201', '2018-09-01'),
(2, 'Tech Innovators', 'Computer Science', 'C305', '2017-05-15'),
(3, 'Sports Alliance', 'Physical Education', 'B108', '2016-02-10');

INSERT INTO Student (Student_ID, Name, Email, Password, Street, City, Zip, Contact_No) VALUES
(101, 'Maya Patel', 'maya.patel@example.edu', 'password123', '12 Elm St', 'Springfield', '12345', '555-0101'),
(102, 'Noah Kim', 'noah.kim@example.edu', 'securePass!', '89 Pine St', 'Springfield', '12345', '555-0102'),
(103, 'Aisha Ahmed', 'aisha.ahmed@example.edu', 'helloWorld', '47 Oak Ave', 'Springfield', '12345', '555-0103'),
(104, 'Liam Torres', 'liam.torres@example.edu', 'pass2026', '73 Maple Rd', 'Springfield', '12345', '555-0104'),
(105, 'Zoe Carter', 'zoe.carter@example.edu', 'clubLeader!', '28 Birch Blvd', 'Springfield', '12345', '555-0105'),
(106, 'Demo Student', 'student@example.edu', 'student123', '123 Demo St', 'Springfield', '12345', '555-0199'),
(107, 'Demo Admin', 'admin@example.edu', 'admin123', '456 Admin Ave', 'Springfield', '12345', '555-0198');

INSERT INTO General_Student (Student_ID, Year_of_Study, Major) VALUES
(101, 2, 'Media Studies'),
(102, 3, 'Computer Science'),
(103, 1, 'Journalism'),
(104, 4, 'Sports Management'),
(105, 2, 'Information Systems'),
(106, 2, 'Computer Science');

INSERT INTO Club_Executive (Student_ID, Position, Term_Start, Term_End) VALUES
(101, 'President', '2024-08-01', '2025-05-31'),
(102, 'Vice President', '2024-08-01', '2025-05-31'),
(107, 'System Administrator', '2024-01-01', '2025-12-31');

INSERT INTO Contact_Emails (Club_ID, Email) VALUES
(1, 'media@college.edu'),
(2, 'tech@college.edu'),
(3, 'sports@college.edu');

INSERT INTO Phone_Numbers (Student_ID, Phone_Number) VALUES
(101, '555-010-1001'),
(102, '555-010-1002'),
(103, '555-010-1003'),
(106, '555-019-9001'),
(107, '555-019-9002');

INSERT INTO Membership (Member_ID, Student_ID, Club_ID, Role, Join_Date) VALUES
(1001, 101, 1, 'Executive', '2023-09-05'),
(1002, 102, 2, 'Executive', '2023-09-05'),
(1003, 103, 1, 'Member', '2024-01-20'),
(1004, 104, 3, 'Volunteer', '2024-02-15'),
(1005, 105, 2, 'Member', '2024-03-10'),
(1006, 106, 2, 'Member', '2024-09-01'),
(1007, 107, 1, 'Executive', '2024-01-01');

INSERT INTO Equipment (Equip_ID, Name, Type, Status, Owner_Club_ID, Purchase_Date) VALUES
(5001, 'Sony Camera ZX10', 'Camera', 'Available', 1, '2023-03-22'),
(5002, 'Epson Projector P90', 'Projector', 'In-Use', 2, '2022-10-12'),
(5003, 'Rode Microphone XLR', 'Microphone', 'Damaged', 1, '2023-07-05'),
(5004, 'Dell Laptop Latitude', 'Laptop', 'Available', 2, '2023-11-02'),
(5005, 'Bose Wireless Speaker', 'Speaker', 'Maintenance', 3, '2024-01-18');

INSERT INTO Maintenance_Log (Equip_ID, Log_ID, Date, Description, Cost) VALUES
(5003, 1, '2024-03-10', 'Replacement of XLR cable and audio test', 45.00),
(5005, 1, '2024-04-05', 'Speaker calibration and firmware update', 60.00);

INSERT INTO Event (Event_ID, Title, Date, Venue, Primary_Club_ID, Description) VALUES
(2001, 'Spring Media Expo', '2025-05-10', 'Auditorium A', 1, 'A showcase of media projects and club collaboration.'),
(2002, 'Hackathon Weekend', '2025-06-08', 'Lab C', 2, '24-hour innovation and prototyping competition.'),
(2003, 'Championship Match', '2025-05-22', 'Gymnasium', 3, 'Inter-college sports final with guest volunteers.');

INSERT INTO Collaboration (Event_ID, Partner_Club_ID, Contribution_Type) VALUES
(2001, 2, 'Tech support'),
(2002, 1, 'Media coverage'),
(2003, 2, 'Audio/visual equipment');

INSERT INTO Resource_Booking (Booking_ID, Equip_ID, Event_ID, Borrow_Time, Return_Time, Status) VALUES
(3001, 5001, 2001, '2025-05-09 08:00:00', '2025-05-10 20:00:00', 'Confirmed'),
(3002, 5002, 2002, '2025-06-07 09:00:00', '2025-06-08 21:00:00', 'Confirmed');

INSERT INTO Volunteer_Log (Log_ID, Student_ID, Event_ID, Role, Hours_Worked, Verified_By, Verification_Date) VALUES
(4001, 104, 2003, 'Event Coordinator', 6.50, 102, '2025-05-23'),
(4002, 103, 2001, 'Media Assistant', 4.00, 101, '2025-05-11');

-- Badge System: 5 Tiers with Multiple Badges
INSERT INTO Badge (Badge_ID, Name, Description, Icon, Color, Hours_Required, Tier) VALUES
-- Bronze Tier (1-10 hours)
(6001, 'Newcomer', 'Welcome to volunteering! First steps into community service.', 'star', '#CD7F32', 1.00, 'Bronze'),
(6002, 'Helper', 'Lending a hand and making a difference.', 'hands-helping', '#CD7F32', 5.00, 'Bronze'),
(6003, 'Contributor', 'Consistent support for club events.', 'user-check', '#CD7F32', 10.00, 'Bronze'),

-- Silver Tier (10-50 hours)
(6004, 'Dedicated', 'Showing true commitment to the community.', 'award', '#C0C0C0', 15.00, 'Silver'),
(6005, 'Committed', 'Going above and beyond for club success.', 'medal', '#C0C0C0', 25.00, 'Silver'),
(6006, 'Reliable', 'A trusted volunteer for any event.', 'shield-check', '#C0C0C0', 40.00, 'Silver'),

-- Gold Tier (50-100 hours)
(6007, 'Champion', 'Leading by example with exceptional service.', 'trophy', '#FFD700', 50.00, 'Gold'),
(6008, 'Legend', 'Inspiring others through dedication and impact.', 'crown', '#FFD700', 75.00, 'Gold'),
(6009, 'All-Star', 'Outstanding contributions across multiple events.', 'star-half-alt', '#FFD700', 90.00, 'Gold'),

-- Platinum Tier (100-200 hours)
(6010, 'Hero', 'Extraordinary commitment to community excellence.', 'user-shield', '#E5E4E2', 100.00, 'Platinum'),
(6011, 'Elite', 'Among the top volunteers in the community.', 'gem', '#E5E4E2', 150.00, 'Platinum'),
(6012, 'Visionary', 'Shaping the future of club collaboration.', 'lightbulb', '#E5E4E2', 180.00, 'Platinum'),

-- Diamond Tier (200+ hours)
(6013, 'Master', 'The pinnacle of volunteer achievement.', 'diamond', '#B9F2FF', 200.00, 'Diamond'),
(6014, 'Icon', 'A legendary figure in club history.', 'fire', '#B9F2FF', 300.00, 'Diamond'),
(6015, 'Immortal', 'Unmatched dedication and lifetime impact.', 'infinity', '#B9F2FF', 500.00, 'Diamond'),

-- Special Badges
(6016, 'Cross-Club Volunteer', 'Helped 3 or more different clubs.', 'handshake', '#9370DB', 10.00, 'Silver'),
(6017, 'Event Organizer', 'Led event coordination and logistics.', 'calendar-check', '#FF6347', 20.00, 'Gold'),
(6018, 'Tech Support Pro', 'Expert in technical assistance roles.', 'laptop-code', '#4169E1', 15.00, 'Silver'),
(6019, 'Media Maven', 'Excellence in media and documentation.', 'camera', '#FF1493', 15.00, 'Silver'),
(6020, 'Setup Specialist', 'Master of event setup and preparation.', 'tools', '#32CD32', 15.00, 'Silver');

-- Sample badge awards (will be auto-awarded by triggers in real usage)
INSERT INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning) VALUES
(103, 6001, '2025-05-11', 4.00),
(104, 6001, '2025-05-23', 6.50),
(104, 6002, '2025-05-23', 6.50);
