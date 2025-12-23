#  Task Manager

A production-ready task management application that automatically classifies and organizes tasks based on intelligent content analysis.

## 🚀 Live Demo

- **Backend API**: `https://your-app.onrender.com`
- **API Health Check**: `https://your-app.onrender.com/health`

## 📋 Project Overview

 Task Manager is a full-stack application that helps teams manage tasks efficiently with automatic categorization and prioritization. The system analyzes task content to:

- **Detect categories** (Scheduling, Finance, Technical, Safety, General)
- **Assign priorities** (High, Medium, Low) based on urgency indicators
- **Extract entities** (dates, people, locations, actions)
- **Suggest actions** based on task category

### Example
**User creates:** "Schedule urgent meeting with team today about budget allocation"

**System automatically:**
- Category: Scheduling (keywords: meeting, schedule)
- Priority: High (keywords: urgent, today)
- Entities: team, budget
- Actions: Block calendar, Send invite, Prepare agenda

## 🛠️ Tech Stack

### Backend
- **Framework**: Node.js with Express
- **Database**: Supabase (PostgreSQL)
- **Validation**: Joi
- **Testing**: Jest
- **Deployment**: Render.com

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod 2.4.9
- **HTTP Client**: Dio 5.4.0
- **UI**: Material Design 3
- **Connectivity**: connectivity_plus

## 📦 Features

### Core Features
✅ Create, read, update, and delete tasks  
✅ Automatic task classification and prioritization  
✅ Smart entity extraction  
✅ Action suggestions based on category  
✅ Advanced filtering (status, category, priority)  
✅ Real-time search functionality  
✅ Pull-to-refresh  
✅ Offline indicator  
✅ Dark mode support  
✅ Audit trail with task history  

### UI/UX Features
✅ Summary cards with task counts  
✅ Category filter chips  
✅ Color-coded task cards  
✅ Priority badges  
✅ Status indicators  
✅ Loading states and skeleton loaders  
✅ Error handling with user-friendly messages  
✅ Form validation  
✅ Classification preview before saving  

## 🏗️ Architecture

### Backend Architecture
```
backend/
├── server.js           # Main Express server
├── server.test.js      # Unit tests
├── package.json        # Dependencies
└── .env               # Environment variables
```

### Flutter Architecture
```
lib/
├── main.dart
├── models/
│   └── task.dart           # Task data model
├── services/
│   └── api_service.dart   # API communication layer
     └── task_classification_services.dart
├── providers/
│   └── task_providers.dart # Riverpod state management
├── screens/
│   └── task_dashboard_screen.dart
└── widgets/
    ├── summary_cards.dart
    ├── filter_chips.dart
    ├── task_list.dart
    └── task_form_bottom_sheet.dart
    └── task_filter_dialog.dart
```

## 🗄️ Database Schema

### Tasks Table
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT CHECK (category IN ('scheduling', 'finance', 'technical', 'safety', 'general')),
    priority TEXT CHECK (priority IN ('high', 'medium', 'low')),
    status TEXT CHECK (status IN ('pending', 'in_progress', 'completed')),
    assigned_to TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    extracted_entities JSONB,
    suggested_actions JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Task History Table
```sql
CREATE TABLE task_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    action TEXT CHECK (action IN ('created', 'updated', 'status_changed', 'completed')),
    old_value JSONB,
    new_value JSONB,
    changed_by TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🚀 Setup Instructions

### Prerequisites
- Node.js 16+ and npm
- Flutter SDK 3.0+
- Supabase account
- Render.com account (for deployment)

### Backend Setup

1. **Clone the repository**
```bash
git clone https://github.com/AnishTiwari5077/task-manager.git
cd smart-task-manager/backend
```

2. **Install dependencies**
```bash
npm install
```

3. **Setup Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Run the SQL schema from `schema.sql` in the SQL Editor
   - Get your project URL and anon key

4. **Configure environment variables**
```bash
cp .env.example .env
```

Edit `.env`:
```
PORT=3000
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
```

5. **Run the server**
```bash
# Development
npm run dev

# Production
npm start
```

6. **Run tests**
```bash
npm test
```

### Flutter Setup

1. **Navigate to Flutter directory**
```bash
cd ../flutter_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API endpoint**

Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-app.onrender.com';
```

4. **Run the app**
```bash
# Development
flutter run

# Build for production
flutter build apk
flutter build ios
```

## 📡 API Documentation

### Base URL
```
https://your-app.onrender.com
```

### Endpoints

#### 1. Create Task
```http
POST /api/tasks
Content-Type: application/json

{
  "title": "Schedule urgent meeting with team",
  "description": "Discuss budget allocation for Q4",
  "assigned_to": "John Doe",
  "due_date": "2025-12-25T10:00:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "title": "Schedule urgent meeting with team",
    "description": "Discuss budget allocation for Q4",
    "category": "scheduling",
    "priority": "high",
    "status": "pending",
    "assigned_to": "John Doe",
    "due_date": "2025-12-25T10:00:00Z",
    "extracted_entities": {
      "dates": ["2025-12-25"],
      "people": ["team"],
      "actions": ["schedule", "discuss"]
    },
    "suggested_actions": [
      "Block calendar",
      "Send invite",
      "Prepare agenda",
      "Set reminder"
    ],
    "created_at": "2025-12-21T08:00:00Z",
    "updated_at": "2025-12-21T08:00:00Z"
  },
  "classification": {
    "category": "scheduling",
    "priority": "high",
    "extracted_entities": {...},
    "suggested_actions": [...]
  }
}
```

#### 2. Get All Tasks
```http
GET /api/tasks?status=pending&category=scheduling&limit=50&offset=0
```

**Query Parameters:**
- `status`: pending | in_progress | completed
- `category`: scheduling | finance | technical | safety | general
- `priority`: high | medium | low
- `search`: Search term for title
- `limit`: Number of results (default: 50)
- `offset`: Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "title": "...",
      ...
    }
  ],
  "pagination": {
    "total": 100,
    "limit": 50,
    "offset": 0
  }
}
```

#### 3. Get Task by ID
```http
GET /api/tasks/{id}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "title": "...",
    "history": [
      {
        "id": "...",
        "action": "created",
        "changed_by": "John Doe",
        "changed_at": "2025-12-21T08:00:00Z"
      }
    ]
  }
}
```

#### 4. Update Task
```http
PATCH /api/tasks/{id}
Content-Type: application/json

{
  "status": "in_progress",
  "priority": "high"
}
```

#### 5. Delete Task
```http
DELETE /api/tasks/{id}
```

**Response:**
```json
{
  "success": true,
  "message": "Task deleted successfully"
}
```

#### 6. Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-12-21T08:00:00Z"
}
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
```

**Test Coverage:**
- Task classification logic
- Priority detection
- Entity extraction
- Category detection
- Edge cases

### Sample Test Output
```
 PASS  ./classification.test.js
  classifyTask
    √ should classify scheduling tasks correctly (3 ms)                                                                                                         
    √ should classify finance tasks correctly (1 ms)                                                                                                            
    √ should classify technical tasks correctly (1 ms)                                                                                                          
    √ should classify safety tasks correctly (1 ms)                                                                                                             
    √ should default to general category when no keywords match (1 ms)                                                                                          
    √ should detect high priority from urgent keywords                                                                                                          
    √ should detect medium priority from important keywords                                                                                                     
    √ should default to low priority when no priority keywords found                                                                                            
    √ should handle empty description (6 ms)                                                                                                                    
    √ should handle undefined description                                                                                                                       
  extractEntities                                                                                                                                               
    √ should extract date patterns correctly                                                                                                                    
    √ should extract people names after "with", "by", "assign to" (1 ms)                                                                                        
    √ should extract action verbs from text (2 ms)                                                                                                              
    √ should handle alternative date formats (1 ms)                                                                                                             
    √ should return empty arrays when no entities found (2 ms)                                                                                                  
    √ should be case insensitive for date extraction (1 ms)                                                                                                     
    √ should extract multiple people from complex text                                                                                                          
    √ should extract all relevant action verbs                                                                                                                  
  Integration tests                                                                                                                                             
    √ should handle complex real-world task classification (1 ms)                                                                                               
    √ should prioritize first matching category                                                                                                                 
    √ should handle mixed priority keywords                                                                                                                     
                                                                                                                                                                
Test Suites: 1 passed, 1 total
Tests:       21 passed, 21 total
Snapshots:   0 total
Time:        1.132 s
Ran all test suites.
```

## 🎨 Screenshots

### Dashboard View
![Dashboard](screenshots/dashboard.png)
- Summary cards showing task counts
- Filter chips for quick category filtering
- Task list with color-coded categories

### Task Creation
![Task Form](screenshots/task-form.png)
- Auto-classification preview
- Override options for category/priority
- Form validation

### Task Details
![Task Card](screenshots/task-card.png)
- Category and priority badges
- Status indicator
- Quick actions menu

## 🚢 Deployment

### Backend Deployment to Render

1. **Create new Web Service**
   - Connect your GitHub repository
   - Select branch: `main`
   - Build Command: `npm install`
   - Start Command: `npm start`

2. **Set Environment Variables**
   ```
   SUPABASE_URL=your_url
   SUPABASE_KEY=your_key
   ```

3. **Deploy**
   - Render will automatically deploy on push
   - Get your live URL: `https://your-app.onrender.com`

### Flutter Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🎯 Architecture Decisions

### Why Riverpod?
- **Type-safe**: Compile-time safety with better error messages
- **Testable**: Easy to mock and test providers
- **Performance**: Auto-dispose and selective rebuilds
- **Developer Experience**: Great DevTools integration

### Why Dio over http?
- **Interceptors**: Centralized error handling and logging
- **Request cancellation**: Better memory management
- **Timeout configuration**: Network resilience
- **FormData support**: File uploads ready

### Why Supabase?
- **Real-time capabilities**: Ready for future features
- **Built-in auth**: Easy to add user authentication
- **Auto-generated APIs**: RESTful and GraphQL support
- **PostgreSQL**: Robust and scalable

### Classification Logic
- **Keyword-based**: Fast and predictable
- **Extensible**: Easy to add new categories
- **No ML overhead**: Works offline, low latency
- **Clear rules**: Transparent decision making

## 🔮 What I'd Improve (Given More Time)

### Immediate Improvements
1. **Real-time updates** using Supabase subscriptions
2. **Task dependencies** and subtasks
3. **File attachments** for task documentation
4. **Comments and activity feed** for collaboration
5. **Email notifications** for due dates and assignments

### Advanced Features
1. **AI-powered classification** using GPT-4 or similar
2. **Natural language task creation** ("remind me to...")
3. **Smart suggestions** based on task history
4. **Team collaboration** with mentions and sharing
5. **Analytics dashboard** with insights and trends
6. **Calendar integration** (Google Calendar, Outlook)
7. **Recurring tasks** support
8. **Task templates** for common workflows
9. **Export to CSV/PDF** for reporting
10. **Mobile push notifications**

### Technical Improvements
1. **API rate limiting** with Redis
2. **Caching layer** for frequently accessed data
3. **Full-text search** with PostgreSQL FTS
4. **GraphQL API** as alternative to REST
5. **End-to-end tests** with Cypress/Playwright
6. **CI/CD pipeline** with GitHub Actions
7. **API documentation** with Swagger/OpenAPI
8. **Performance monitoring** with Sentry
9. **Load testing** to ensure scalability
10. **Docker containerization** for consistency

## 📝 Git Commit History

```bash
git log --oneline
```

Sample commits:
- `Initial project setup with Express and Flutter`
- `Add Supabase database schema and migrations`
- `Implement task classification logic`
- `Add API endpoints for CRUD operations`
- `Create Riverpod providers and state management`
- `Build task dashboard UI with Material Design 3`
- `Implement task form with validation`
- `Add filtering and search functionality`
- `Write unit tests for classification`
- `Add error handling and loading states`
- `Implement offline indicator`
- `Add task history and audit trail`
- `Deploy to Render and update documentation`

## 📄 License

MIT License - feel free to use this project for learning or commercial purposes.

## 👤 Author

**Your Name**
- GitHub: [@AnishTiwairi5077](https://github.com/AnishTiwair5077)
- Email: anishtiwari5077@gmail.con

## 🙏 Acknowledgments

- Navicon Infraprojects for the assessment opportunity
- Supabase team for excellent documentation
- Flutter and Riverpod communities

---

**Note**: Remember to replace placeholder values:
- `your-app.onrender.com` with actual Render URL
- Supabase credentials in `.env`
- GitHub repository URL
  

