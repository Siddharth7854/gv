# Government Grievance Management System - API Server Setup

## Prerequisites

1. **SQL Server** (2017 or higher)
2. **Node.js** (v16 or higher)
3. **npm** or **yarn**

## Database Setup

### 1. Create Database

```sql
-- Run the SQL script in SQL Server Management Studio (SSMS)
-- File location: f:\gv\sql\grievance_database_setup.sql
```

### 2. Configure SQL Server

- Enable TCP/IP protocol
- Set SQL Server Authentication mode to Mixed
- Create a strong password for 'sa' account
- Ensure SQL Server is running on port 1433

## API Server Setup

### 1. Install Dependencies

```bash
cd f:\gv\api-server
npm install
```

### 2. Configure Environment

Edit `.env` file with your SQL Server credentials:

```env
DB_SERVER=localhost
DB_DATABASE=GrievanceManagementDB
DB_USER=sa
DB_PASSWORD=YourStrongPassword123!
DB_PORT=1433

JWT_SECRET=your_super_secret_jwt_key_here_make_it_long_and_secure
JWT_EXPIRES_IN=24h

PORT=5000
NODE_ENV=development
```

### 3. Test Database Connection

```bash
npm run dev
```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new citizen
- `POST /api/auth/login` - Login citizen
- `POST /api/auth/verify` - Verify JWT token

### Grievances

- `POST /api/grievances` - Submit new grievance
- `GET /api/grievances/citizen/:citizen_id` - Get citizen's grievances
- `GET /api/grievances/:grievance_id` - Get grievance details
- `PATCH /api/grievances/:grievance_id/status` - Update status (admin)

### Categories

- `GET /api/categories` - Get all categories
- `GET /api/categories/:category_id` - Get category details

### File Upload

- `POST /api/upload/single` - Upload single file
- `POST /api/upload/multiple` - Upload multiple files
- `DELETE /api/upload/:attachment_id` - Delete file

### Dashboard

- `GET /api/dashboard/stats/:citizen_id` - Get citizen statistics
- `GET /api/dashboard/admin/stats` - Get system statistics

## Flutter App Configuration

### 1. Update Dependencies

```bash
cd f:\gv
flutter pub get
```

### 2. Update API Base URL

In `lib/services/sql_server_api_service.dart`:

```dart
static const String _baseUrl = 'http://localhost:5000/api';
```

### 3. Update Models

- Use `lib/models/grievance_new.dart` instead of old model
- Update providers to use new API service

## Testing

### 1. Test API Server

```bash
# Health check
curl http://localhost:5000/api/health

# Test categories
curl http://localhost:5000/api/categories
```

### 2. Test Registration

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test Citizen",
    "phone": "9876543210",
    "aadhar_number": "123456789012",
    "district": "Test District",
    "block": "Test Block",
    "ward": "Test Ward",
    "address": "Test Address",
    "pincode": "123456",
    "password": "password123"
  }'
```

### 3. Test Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "9876543210",
    "password": "password123"
  }'
```

## Production Deployment

### 1. Update Environment

```env
NODE_ENV=production
DB_SERVER=your-production-server
# Update other production values
```

### 2. SSL Configuration

- Enable SSL in SQL Server
- Use HTTPS for API server
- Update Flutter app to use HTTPS

### 3. Security

- Use strong passwords
- Enable firewall rules
- Regular security updates
- Monitor logs

## Troubleshooting

### Common Issues

1. **Database Connection Failed**

   - Check SQL Server is running
   - Verify credentials in .env
   - Check network connectivity

2. **Authentication Errors**

   - Verify JWT_SECRET is set
   - Check token expiration

3. **File Upload Issues**
   - Check upload directory permissions
   - Verify file size limits

### Debug Mode

```bash
npm run dev
```

This will show detailed logs for debugging.

## Demo Data Removal

All demo/hardcoded data has been removed. The system now uses:

- Real SQL Server database
- Dynamic categories from database
- User authentication with JWT
- Proper data validation
- File upload functionality

## Support

For issues and support:

1. Check error logs in terminal
2. Verify database connectivity
3. Test API endpoints individually
4. Check network configuration
