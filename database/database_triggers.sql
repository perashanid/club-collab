USE club_collab;

DELIMITER //

-- ============================================
-- RESOURCE BOOKING TRIGGERS
-- ============================================

-- 1. Prevent double-booking conflicts (INSERT)
DROP TRIGGER IF EXISTS prevent_double_booking//
CREATE TRIGGER prevent_double_booking
BEFORE INSERT ON Resource_Booking
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT;
    DECLARE equip_status VARCHAR(20);
    
    -- Check equipment availability
    SELECT Status INTO equip_status FROM Equipment WHERE Equip_ID = NEW.Equip_ID;
    
    IF equip_status IN ('Damaged', 'Maintenance') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot book equipment that is Damaged or under Maintenance.';
    END IF;
    
    -- Check for overlapping bookings
    SELECT COUNT(*) INTO conflict_count
    FROM Resource_Booking
    WHERE Equip_ID = NEW.Equip_ID
      AND Status = 'Confirmed'
      AND (NEW.Borrow_Time < Return_Time AND NEW.Return_Time > Borrow_Time);
      
    IF conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Double-booking conflict detected. Equipment is already booked for this time slot.';
    END IF;
END//

-- 2. Prevent double-booking conflicts (UPDATE)
DROP TRIGGER IF EXISTS prevent_double_booking_update//
CREATE TRIGGER prevent_double_booking_update
BEFORE UPDATE ON Resource_Booking
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT;
    DECLARE equip_status VARCHAR(20);
    
    IF NEW.Status = 'Confirmed' THEN
        -- Check equipment availability
        SELECT Status INTO equip_status FROM Equipment WHERE Equip_ID = NEW.Equip_ID;
        
        IF equip_status IN ('Damaged', 'Maintenance') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot confirm booking for equipment that is Damaged or under Maintenance.';
        END IF;
        
        -- Check for overlapping bookings
        SELECT COUNT(*) INTO conflict_count
        FROM Resource_Booking
        WHERE Equip_ID = NEW.Equip_ID
          AND Booking_ID != NEW.Booking_ID
          AND Status = 'Confirmed'
          AND (NEW.Borrow_Time < Return_Time AND NEW.Return_Time > Borrow_Time);
          
        IF conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Double-booking conflict detected. Equipment is already booked for this time slot.';
        END IF;
    END IF;
END//

-- 3. Automatic cancellation when equipment is damaged
DROP TRIGGER IF EXISTS cancel_bookings_on_damage//
CREATE TRIGGER cancel_bookings_on_damage
AFTER UPDATE ON Equipment
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Damaged' AND OLD.Status != 'Damaged' THEN
        UPDATE Resource_Booking
        SET Status = 'Cancelled'
        WHERE Equip_ID = NEW.Equip_ID
          AND Status = 'Confirmed'
          AND Return_Time > NOW();
    END IF;
END//

-- ============================================
-- VOLUNTEER LOG TRIGGERS
-- ============================================

-- 4. Prevent logging hours for future events
DROP TRIGGER IF EXISTS validate_volunteer_event_date//
CREATE TRIGGER validate_volunteer_event_date
BEFORE INSERT ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE event_date DATE;
    SELECT Date INTO event_date FROM Event WHERE Event_ID = NEW.Event_ID;
    
    IF event_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot log volunteer hours for future events.';
    END IF;
END//

-- 5. Validate volunteer hours on update
DROP TRIGGER IF EXISTS validate_volunteer_event_date_update//
CREATE TRIGGER validate_volunteer_event_date_update
BEFORE UPDATE ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE event_date DATE;
    SELECT Date INTO event_date FROM Event WHERE Event_ID = NEW.Event_ID;
    
    IF event_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot log volunteer hours for future events.';
    END IF;
END//

-- ============================================
-- BADGE AWARDING TRIGGERS
-- ============================================

-- 6. Auto-award badges when volunteer hours are logged (INSERT)
DROP TRIGGER IF EXISTS auto_award_badges_insert//
CREATE TRIGGER auto_award_badges_insert
AFTER INSERT ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE total_hours DECIMAL(6,2);
    
    -- Calculate total volunteer hours for the student
    SELECT COALESCE(SUM(Hours_Worked), 0) INTO total_hours
    FROM Volunteer_Log
    WHERE Student_ID = NEW.Student_ID;
    
    -- Award eligible badges that haven't been earned yet
    INSERT IGNORE INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
    SELECT NEW.Student_ID, Badge_ID, CURDATE(), total_hours
    FROM Badge
    WHERE Hours_Required <= total_hours
      AND Badge_ID NOT IN (
          SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = NEW.Student_ID
      );
END//

-- 7. Auto-award badges when volunteer hours are updated
DROP TRIGGER IF EXISTS auto_award_badges_update//
CREATE TRIGGER auto_award_badges_update
AFTER UPDATE ON Volunteer_Log
FOR EACH ROW
BEGIN
    DECLARE total_hours DECIMAL(6,2);
    
    -- Calculate total volunteer hours for the student
    SELECT COALESCE(SUM(Hours_Worked), 0) INTO total_hours
    FROM Volunteer_Log
    WHERE Student_ID = NEW.Student_ID;
    
    -- Award eligible badges that haven't been earned yet
    INSERT IGNORE INTO Volunteer_Badge (Student_ID, Badge_ID, Earned_Date, Total_Hours_At_Earning)
    SELECT NEW.Student_ID, Badge_ID, CURDATE(), total_hours
    FROM Badge
    WHERE Hours_Required <= total_hours
      AND Badge_ID NOT IN (
          SELECT Badge_ID FROM Volunteer_Badge WHERE Student_ID = NEW.Student_ID
      );
END//

-- ============================================
-- EXECUTIVE MEMBERSHIP VALIDATION
-- ============================================

-- 8. Ensure executives have membership records
DROP TRIGGER IF EXISTS validate_executive_membership//
CREATE TRIGGER validate_executive_membership
BEFORE INSERT ON Club_Executive
FOR EACH ROW
BEGIN
    DECLARE membership_count INT;
    
    SELECT COUNT(*) INTO membership_count
    FROM Membership
    WHERE Student_ID = NEW.Student_ID AND Role = 'Executive';
    
    IF membership_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student must have an Executive membership record before being added as Club Executive.';
    END IF;
END//

DELIMITER ;

-- ============================================
-- SCHEDULED EVENTS
-- ============================================

-- 9. Automatic status updates (Available <-> In-Use) based on booking times
-- Make sure to enable the Event Scheduler in MySQL: SET GLOBAL event_scheduler = ON;
DROP EVENT IF EXISTS update_equipment_status;
CREATE EVENT update_equipment_status
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    -- Set to In-Use if currently within a confirmed booking time
    UPDATE Equipment e
    SET Status = 'In-Use'
    WHERE Status = 'Available'
      AND EXISTS (
          SELECT 1 FROM Resource_Booking rb
          WHERE rb.Equip_ID = e.Equip_ID
            AND rb.Status = 'Confirmed'
            AND NOW() BETWEEN rb.Borrow_Time AND rb.Return_Time
      );

    -- Set booking to Completed if the time has passed
    UPDATE Resource_Booking
    SET Status = 'Completed'
    WHERE Status = 'Confirmed'
      AND NOW() > Return_Time;

    -- Set to Available if the booking has passed
    UPDATE Equipment e
    SET Status = 'Available'
    WHERE Status = 'In-Use'
      AND NOT EXISTS (
          SELECT 1 FROM Resource_Booking rb
          WHERE rb.Equip_ID = e.Equip_ID
            AND rb.Status = 'Confirmed'
            AND NOW() BETWEEN rb.Borrow_Time AND rb.Return_Time
      );
END;