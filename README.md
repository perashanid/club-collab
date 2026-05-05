# 🎓 Club Collaboration Platform

A comprehensive club management system with **Resource Booking**, **Volunteer Tracking**, **Badge Gamification**, and **Advanced Analytics**.

> **✨ Clean & Organized Structure:** All SQL files in `database/` folder, all documentation in `docs/` folder!

---

## 🚀 Quick Start (3 Steps!)

### Step 1: Make sure MySQL and PHP are installed
```bash
mysql --version
php --version
```

### Step 2: Run the setup script

**On Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

**On Windows:**
```bash
setup.bat
```

The script will:
- ✅ Create the database
- ✅ Load all tables, triggers, views, and procedures
- ✅ Insert sample data (20 badges, 7 students, etc.)
- ✅ Start the PHP server

### Step 3: Open your browser
```
http://localhost:8000/index.html
```

**Login with:**
- Student: `student@example.edu` / `student123`
- Admin: `admin@example.edu` / `admin123`

---

## 📋 Manual Setup (Alternative)

If you prefer manual setup:

### Option A: One-File Setup (Easiest!)
```bash
# Import everything in one go!
mysql -u root -p < database/complete_setup.sql
```

### Option B: Step-by-Step Setup
```bash
# 1. Create database
mysql -u root -p < database/tables.sql
mysql -u root -p < database/database_triggers.sql
mysql -u root -p < database/database_views.sql
mysql -u root -p < database/database_analytics.sql
mysql -u root -p < database/seed.sql

# 2. Enable event scheduler
mysql -u root -p -e "SET GLOBAL event_scheduler = ON;"

# 3. Start server
php -S localhost:8000
```

See **docs/QUICK_START.md** for detailed instructions.

---

## ✨ Features

### 🎯 Resource Booking System
- Book equipment with specific time slots
- Automatic double-booking prevention
- Auto-cancel bookings when equipment damaged
- Real-time status updates
- Booking history and conflict detection

### 👥 Volunteer Tracking
- Log volunteer hours with role tracking
- Executive verification system
- Cross-club volunteering support
- Build verified portfolios
- Prevent logging hours for future events

### 🏆 Badge System (Gamification)
- **5 Tiers:** Bronze → Silver → Gold → Platinum → Diamond
- **20 Badges:** 15 standard + 5 special
- Automatic badge awarding
- Leaderboard with medals (🥇🥈🥉)
- Progress tracking to next badge

### 📊 Analytics & Reports
- Top cross-club volunteer analysis
- Equipment utilization with ROI ratings
- Club collaboration networks
- Event success metrics
- Student engagement rankings
- Booking pattern analysis

### 🔍 Search & Filters
- Search equipment, volunteers, events, students, badges
- Multiple filter options
- Pagination support
- Full-text search

---

## 📁 Project Structure

```
├── backend/
│   ├── analytics.php          # Analytics API (17 endpoints)
│   ├── badges_api.php          # Badge management (10 endpoints)
│   ├── bookings_api.php        # Booking management (11 endpoints)
│   ├── volunteers_api.php      # Volunteer tracking (13 endpoints)
│   ├── search_api.php          # Search functionality (6 endpoints)
│   └── db_connect.php          # Database connection
├── database/
│   ├── tables.sql              # Database schema
│   ├── database_triggers.sql   # 8 triggers + 1 scheduled event
│   ├── database_views.sql      # 11 pre-built views
│   ├── database_analytics.sql  # 6 stored procedures
│   └── seed.sql                # Sample data
├── docs/
│   ├── START_HERE.md           # Complete setup guide
│   ├── QUICK_START.md          # Detailed instructions
│   ├── API_DOCUMENTATION.md    # Complete API reference
│   ├── FEATURES_SUMMARY.md     # All features explained
│   └── INSTALLATION_GUIDE.md   # Step-by-step installation
├── css/                        # Stylesheets
├── js/                         # JavaScript files
├── setup.sh                    # Linux/Mac setup script
├── setup.bat                   # Windows setup script
├── README.md                   # This file
├── RUN_ME_FIRST.txt            # Quick start guide
├── index.html                  # Main page
├── login.html                  # Login page
└── signup.html                 # Signup page
```

---

## 🎮 Test the Features

### Test 1: Create a Booking
```bash
curl -X POST http://localhost:8000/backend/bookings_api.php?action=create_booking \
  -H "Content-Type: application/json" \
  -d '{
    "equip_id": 5001,
    "event_id": 2001,
    "borrow_time": "2025-06-15 08:00:00",
    "return_time": "2025-06-15 20:00:00"
  }'
```

### Test 2: Log Volunteer Hours (Auto-Awards Badges!)
```bash
curl -X POST http://localhost:8000/backend/volunteers_api.php?action=create_volunteer_log \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": 106,
    "event_id": 2001,
    "role": "Registration",
    "hours_worked": 5.5
  }'
```

### Test 3: View Leaderboard
```bash
curl http://localhost:8000/backend/badges_api.php?action=get_leaderboard&limit=10
```

### Test 4: Check Badge Progress
```bash
curl http://localhost:8000/backend/badges_api.php?action=get_badge_progress&student_id=106
```

### Test 5: View Analytics
```bash
curl http://localhost:8000/backend/analytics.php?action=equipment_utilization
```

---

## 📊 Database Overview

- **15 Tables:** Club, Student, Equipment, Event, Booking, Volunteer, Badge, etc.
- **8 Triggers:** Auto-validation, badge awarding, conflict prevention
- **11 Views:** Pre-built reports and dashboards
- **6 Stored Procedures:** Complex analytics queries
- **1 Scheduled Event:** Auto-update equipment status every minute

---

## 🔧 API Endpoints

### Analytics API (17 endpoints)
- Top cross-club volunteer
- Equipment utilization
- Club collaboration
- Event success metrics
- Student engagement
- Booking patterns
- And more...

### Badges API (10 endpoints)
- Get all badges
- Get student badges
- Badge progress
- Leaderboard
- Badge statistics
- Create/update/delete badges

### Bookings API (11 endpoints)
- Create/update/cancel bookings
- Check availability
- Get next available time
- Booking history
- Conflict detection

### Volunteers API (13 endpoints)
- Create/update volunteer logs
- Verify hours
- Student summaries
- Event volunteers
- Cross-club volunteers
- Volunteer portfolio

### Search API (6 endpoints)
- Search equipment
- Search volunteers
- Search events
- Search students
- Search badges
- Search bookings

**Total: 57 API endpoints**

---

## 🏅 Badge Tiers

### Bronze (1-10 hours)
- Newcomer (1h)
- Helper (5h)
- Contributor (10h)

### Silver (10-50 hours)
- Dedicated (15h)
- Committed (25h)
- Reliable (40h)

### Gold (50-100 hours)
- Champion (50h)
- Legend (75h)
- All-Star (90h)

### Platinum (100-200 hours)
- Hero (100h)
- Elite (150h)
- Visionary (180h)

### Diamond (200+ hours)
- Master (200h)
- Icon (300h)
- Immortal (500h)

### Special Badges
- Cross-Club Volunteer
- Event Organizer
- Tech Support Pro
- Media Maven
- Setup Specialist

---

## 🤖 Automatic Features

- ✅ Badges awarded automatically when hours are logged
- ✅ Equipment status updates automatically based on time
- ✅ Bookings cancelled automatically when equipment damaged
- ✅ Double-booking prevented automatically
- ✅ Future event validation automatic
- ✅ Executive membership validation

---

## 📚 Documentation

- **docs/START_HERE.md** - Complete setup guide
- **docs/QUICK_START.md** - Get started in 5 minutes
- **docs/API_DOCUMENTATION.md** - Complete API reference with examples
- **docs/FEATURES_SUMMARY.md** - All features explained in detail
- **docs/INSTALLATION_GUIDE.md** - Detailed setup and troubleshooting

---

## 🐛 Troubleshooting

### MySQL connection failed?
- Check if MySQL is running: `sudo systemctl status mysql`
- Verify credentials in `backend/db_connect.php`

### Tables don't exist?
- Run all SQL files in order: tables → triggers → views → analytics → seed

### Triggers not working?
- Check: `SHOW TRIGGERS FROM club_collab;`
- Reload: `mysql -u root -p < database_triggers.sql`

### Event scheduler not running?
- Enable: `SET GLOBAL event_scheduler = ON;`

### Port 8000 already in use?
- Use different port: `php -S localhost:8080`

See **QUICK_START.md** for more solutions.

---

## 🎯 Sample Data Included

- 3 Clubs (Media Society, Tech Innovators, Sports Alliance)
- 7 Students (including demo accounts)
- 5 Equipment items (Camera, Projector, Microphone, Laptop, Speaker)
- 3 Events (Spring Media Expo, Hackathon Weekend, Championship Match)
- 20 Badges across 5 tiers
- Sample bookings and volunteer logs

---

## 🔐 Security Features

- ✅ Prepared statements (SQL injection prevention)
- ✅ CORS headers configured
- ✅ Input validation
- ✅ Password hashing ready
- ✅ Foreign key constraints
- ✅ Check constraints
- ✅ Unique constraints

---

## 📈 Performance Features

- ✅ Indexed foreign keys
- ✅ Optimized views
- ✅ Efficient stored procedures
- ✅ Pagination support
- ✅ Scheduled events for automation

---

## 🎨 Customization

You can easily customize:
- Badge requirements and tiers
- Volunteer roles
- Equipment types
- Event categories
- Analytics metrics
- Search filters

---

## 📞 Support

For issues or questions:
1. Check **QUICK_START.md** for setup help
2. Review **API_DOCUMENTATION.md** for API usage
3. See **FEATURES_SUMMARY.md** for feature details
4. Check **INSTALLATION_GUIDE.md** for troubleshooting

---

## 📄 License

This project is provided as-is for educational and organizational use.

---

## 🎉 You're Ready!

Run the setup script and start managing your clubs with:
- ⚡ Automated resource booking
- 👥 Comprehensive volunteer tracking
- 🏆 Engaging badge system
- 📊 Powerful analytics

**Happy coding!** 🚀
