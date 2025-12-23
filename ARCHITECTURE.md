
# Task Manager Architecture

## Overview

This document describes the architecture of the mORMot2 Task Manager application.

## Architecture Layers

### 1. Model Layer (ORM)

**File**: `src/task_models.pas`

The model layer defines the data entities that are persisted to the database.

#### TTask Class

```pascal
TTask = class(TOrm)
  - ID: TID (automatic, primary key)
  - Title: RawUtf8
  - Description: RawUtf8
  - Priority: Integer (1=Low, 2=Medium, 3=High)
  - DueDate: TDateTime
  - Status: RawUtf8 (pending, in_progress, completed)
  - IsCompleted: Boolean
  - CreatedAt: TDateTime
  - UpdatedAt: TDateTime
```

**Design Decisions**:
- Use `RawUtf8` for all string fields (mORMot2 optimized UTF-8)
- Use `TDateTime` for dates (Pascal standard)
- Simple integer priority system (1-3)
- Status field for workflow tracking
- Separate `IsCompleted` boolean for quick filtering
- Automatic timestamps for audit trail

### 2. Service Layer (SOA)

**File**: `src/task_services.pas`

The service layer implements business logic through interface-based services.

#### ITaskService Interface

```pascal
ITaskService = interface(IInvokable)
  function CreateTask(const Title, Description: RawUtf8; 
                      Priority: Integer; DueDate: TDateTime): TID;
  function GetTask(TaskID: TID): Variant;
  function UpdateTask(TaskID: TID; const Title, Description: RawUtf8; 
                      Priority: Integer; DueDate: TDateTime): Boolean;
  function DeleteTask(TaskID: TID): Boolean;
  function ListTasks(const Status: RawUtf8): TVariantDynArray;
  function MarkComplete(TaskID: TID; IsComplete: Boolean): Boolean;
  function SearchTasks(const SearchTerm: RawUtf8): TVariantDynArray;
end;
```

#### TTaskService Implementation

Business logic includes:
- Input validation
- Status management
- Timestamp updates
- Error handling
- Data transformation (ORM ↔ Variant)

**Design Decisions**:
- Use `Variant` for flexible JSON responses
- Return `TVariantDynArray` for lists
- Simple boolean returns for success/failure
- Stateless service (sicShared) for scalability

### 3. Server Layer

**File**: `src/task_manager.pas`

The main server program orchestrates all components.

#### Components

1. **ORM Model** (`TOrmModel`)
   - Registers TTask class
   - Defines database schema

2. **REST Server** (`TRestServerDB`)
   - SQLite3 backend
   - Automatic table creation
   - ORM operations

3. **HTTP Server** (`TRestHttpServer`)
   - Async I/O for performance
   - CORS support for web clients
   - Static file serving
   - Port 8080

#### Initialization Flow

```
1. Create ORM Model
2. Create REST Server with SQLite
3. Create database tables
4. Register SOA services
5. Start HTTP server
6. Serve requests
```

### 4. Client Layer (Web)

**File**: `static/index.html`

Single-page web application consuming REST APIs.

#### Features

- Task creation form
- Task list display
- Task editing
- Task deletion
- Task completion toggle
- Search and filter
- Responsive design

#### API Communication

```javascript
// Example: Create task
fetch('http://localhost:8080/TaskService/CreateTask', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(['Task Title', 'Description', 2, '2024-12-31'])
});
```

## Data Flow

### Creating a Task

```
Browser → HTTP POST → HTTP Server → REST Server → 
Service Layer → ORM → SQLite → Response → JSON → Browser
```

### Reading Tasks

```
Browser → HTTP GET → HTTP Server → REST Server → 
ORM → SQLite → Response → JSON → Browser
```

## Database Schema

### Task Table

| Column      | Type     | Description                |
|-------------|----------|----------------------------|
| ID          | INTEGER  | Primary key (auto)         |
| Title       | TEXT     | Task title (required)      |
| Description | TEXT     | Task description           |
| Priority    | INTEGER  | 1=Low, 2=Medium, 3=High    |
| DueDate     | REAL     | Due date (TDateTime)       |
| Status      | TEXT     | pending/in_progress/done   |
| IsCompleted | BOOLEAN  | Completion flag            |
| CreatedAt   | REAL     | Creation timestamp         |
| UpdatedAt   | REAL     | Last update timestamp      |

## Security Considerations

**Current Implementation** (v1.0):
- No authentication (development version)
- CORS enabled for all origins
- Local network access only

**Future Enhancements**:
- User authentication
- Session management
- Role-based access control
- HTTPS support
- Input sanitization

## Performance Optimizations

1. **Async HTTP Server** (`useHttpAsync`)
   - Non-blocking I/O
   - High concurrency

2. **SQLite WAL Mode**
   - Better concurrent read/write
   - Improved performance

3. **Stateless Services** (`sicShared`)
   - Single instance
   - No per-request overhead

4. **UTF-8 Strings** (`RawUtf8`)
   - Zero-copy operations
   - Memory efficient

## Testing Strategy

1. **Unit Tests** - Self-test methods in each unit
2. **Integration Tests** - Service layer tests
3. **Manual Tests** - Web interface testing

## Extensibility Points

Future features can be added by:

1. **New ORM Models** - Categories, Tags, Users
2. **New Services** - Analytics, Reporting, Export
3. **Enhanced UI** - Drag-and-drop, Calendar view
4. **Additional Features** - Attachments, Comments, Notifications

## Dependencies

- **mORMot2** - Core framework
  - `mormot.core.base` - Base types
  - `mormot.core.data` - Data structures
  - `mormot.core.json` - JSON support
  - `mormot.orm.core` - ORM functionality
  - `mormot.rest.core` - REST framework
  - `mormot.rest.server` - Server components
  - `mormot.rest.sqlite3` - SQLite support
  - `mormot.rest.http.server` - HTTP server
  - `mormot.net.server` - Network layer

## Conclusion

This architecture provides a solid foundation for a scalable, maintainable task management system using modern Free Pascal and mORMot2 technologies.
