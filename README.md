# Club-Collab

A comprehensive university club management system with resource booking, volunteer tracking, badge gamification, equipment bidding, and advanced analytics.

## Features

- Resource booking system with conflict detection
- Volunteer tracking with verification
- Badge gamification system (20 badges across 5 tiers)
- Equipment bidding with club currency
- Analytics and reporting
- Club leaderboards
- Modern black and white UI

## Quick Start

### Prerequisites

- PHP 7.4 or higher
- MySQL 5.7 or higher
- Web server (Apache/Nginx) or PHP built-in server

### Installation

1. Clone the repository
```bash
git clone https://github.com/perashanid/club-collab.git
cd club-collab
```

2. Import the database
```bash
mysql -u root -p < database/complete_setup.sql
```

3. Configure database connection
Edit `backend/db_connect.php` with your MySQL credentials.

4. Start the server
```bash
php -S localhost:8000
```

5. Open your browser
```
http://localhost:8000/index.html
```

### Default Login Credentials

- Student: `student@example.edu` / `student123`
- Admin: `admin@example.edu` / `admin123`

## Project Structure

```
club-collab/
├── backend/              # PHP backend APIs
│   ├── analytics.php
│   ├── badges_api.php
│   ├── bidding_api.php
│   ├── bookings_api.php
│   ├── volunteers_api.php
│   └── db_connect.php
├── database/             # SQL files
│   ├── complete_setup.sql
│   ├── tables.sql
│   ├── database_triggers.sql
│   ├── database_views.sql
│   └── seed.sql
├── css/                  # Stylesheets
├── js/                   # JavaScript files
├── docs/                 # Documentation
├── index.html            # Main dashboard
├── login.html            # Login page
└── signup.html           # Signup page
```

## Core Features

### Resource Booking
- Book equipment with specific time slots
- Automatic conflict detection
- Real-time availability checking
- Booking history tracking

### Volunteer Tracking
- Log volunteer hours with role tracking
- Executive verification system
- Cross-club volunteering support
- Automatic badge awarding

### Badge System
- 5 tiers: Bronze, Silver, Gold, Platinum, Diamond
- 20 badges total (15 standard + 5 special)
- Automatic awarding based on hours
- Leaderboard with rankings

### Equipment Bidding
- Clubs earn currency through volunteer work
- Bid on equipment from other clubs
- Real-time auction system
- Currency leaderboard

### Analytics
- Equipment utilization reports
- Club collaboration analysis
- Event success metrics
- Student engagement tracking
- Booking pattern analysis

## Database Schema

- 15 tables with proper relationships
- 8 triggers for automation
- 11 views for reporting
- 6 stored procedures for analytics
- 1 scheduled event for status updates

## API Endpoints

### Analytics API
- Equipment utilization
- Club collaboration
- Event success metrics
- Student engagement
- Booking patterns

### Badges API
- Get all badges
- Student badge progress
- Leaderboard
- Badge statistics

### Bidding API
- Active auctions
- Place bids
- Create auctions
- Currency leaderboard

### Bookings API
- Create/update/cancel bookings
- Check availability
- Conflict detection
- Booking history

### Volunteers API
- Log volunteer hours
- Verify hours
- Student summaries
- Volunteer portfolio

## Technology Stack

- Frontend: HTML, CSS, JavaScript
- Backend: PHP
- Database: MySQL/MariaDB
- UI: Modern black and white theme

## Security Features

- Prepared statements for SQL injection prevention
- Input validation
- Password hashing
- Foreign key constraints
- Check constraints

## Sample Data

The database includes sample data:
- 3 clubs
- 7 students
- 5 equipment items
- 3 events
- 20 badges
- Sample bookings and volunteer logs

## Troubleshooting

### MySQL connection failed
- Verify MySQL is running
- Check credentials in `backend/db_connect.php`

### Tables don't exist
- Run `database/complete_setup.sql`

### Event scheduler not running
```sql
SET GLOBAL event_scheduler = ON;
```

### Port already in use
```bash
php -S localhost:8080
```

## Documentation

See the `docs/` folder for detailed documentation:
- Database schema diagrams
- API documentation
- Feature guides

## License

This project is provided as-is for educational and organizational use.
