
# Task Manager API Documentation

## Overview

This document describes the REST API provided by the mORMot2 Task Manager server.

**Base URL**: `http://localhost:8080/taskmanager`

**Content-Type**: All requests and responses use `application/json`

## Endpoints

### ORM REST Endpoints

mORMot2 automatically provides RESTful CRUD endpoints for the Task entity.

#### List All Tasks

```
GET /taskmanager/Task
```

**Response**: Array of Task objects

```json
[
  {
    "ID": 1,
    "Title": "Welcome to Task Manager",
    "Description": "This is a sample task",
    "Priority": 2,
    "DueDate": "2024-12-30T00:00:00",
    "Status": "pending",
    "IsCompleted": false,
    "CreatedAt": "2024-12-23T10:00:00",
    "UpdatedAt": "2024-12-23T10:00:00"
  }
]
```

#### Get Task by ID

```
GET /taskmanager/Task/{id}
```

**Parameters**:
- `id` (integer): Task ID

**Response**: Single Task object

```json
{
  "ID": 1,
  "Title": "Welcome to Task Manager",
  "Description": "This is a sample task",
  "Priority": 2,
  "DueDate": "2024-12-30T00:00:00",
  "Status": "pending",
  "IsCompleted": false,
  "CreatedAt": "2024-12-23T10:00:00",
  "UpdatedAt": "2024-12-23T10:00:00"
}
```

#### Create Task

```
POST /taskmanager/Task
```

**Request Body**:

```json
{
  "Title": "New Task",
  "Description": "Task description",
  "Priority": 2,
  "DueDate": "2024-12-30T00:00:00",
  "Status": "pending",
  "IsCompleted": false,
  "CreatedAt": "2024-12-23T10:00:00",
  "UpdatedAt": "2024-12-23T10:00:00"
}
```

**Response**: Task ID

```json
1
```

#### Update Task

```
PUT /taskmanager/Task
```

**Request Body**: Complete Task object with updated fields

```json
{
  "ID": 1,
  "Title": "Updated Task",
  "Description": "Updated description",
  "Priority": 3,
  "DueDate": "2024-12-31T00:00:00",
  "Status": "in_progress",
  "IsCompleted": false,
  "CreatedAt": "2024-12-23T10:00:00",
  "UpdatedAt": "2024-12-23T11:00:00"
}
```

**Response**: HTTP 200 OK

#### Delete Task

```
DELETE /taskmanager/Task/{id}
```

**Parameters**:
- `id` (integer): Task ID

**Response**: HTTP 200 OK

### Query Parameters

You can filter tasks using query parameters:

```
GET /taskmanager/Task?where=Status='pending'
GET /taskmanager/Task?where=Priority=3
GET /taskmanager/Task?where=IsCompleted=false
```

## Data Model

### Task Object

| Field | Type | Description |
|-------|------|-------------|
| ID | integer | Unique task identifier (auto-generated) |
| Title | string | Task title (required) |
| Description | string | Task description (optional) |
| Priority | integer | Priority level: 1 (Low), 2 (Medium), 3 (High) |
| DueDate | datetime | Due date (ISO 8601 format) |
| Status | string | Task status: 'pending', 'in_progress', 'completed' |
| IsCompleted | boolean | Completion flag |
| CreatedAt | datetime | Creation timestamp |
| UpdatedAt | datetime | Last update timestamp |

## Status Codes

- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Examples

### JavaScript/Fetch API

```javascript
// Get all tasks
const tasks = await fetch('http://localhost:8080/taskmanager/Task')
  .then(res => res.json());

// Get task by ID
const task = await fetch('http://localhost:8080/taskmanager/Task/1')
  .then(res => res.json());

// Create task
const newTask = await fetch('http://localhost:8080/taskmanager/Task', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    Title: 'New Task',
    Description: 'Description',
    Priority: 2,
    DueDate: '2024-12-30T00:00:00',
    Status: 'pending',
    IsCompleted: false,
    CreatedAt: new Date().toISOString(),
    UpdatedAt: new Date().toISOString()
  })
}).then(res => res.json());

// Update task
await fetch('http://localhost:8080/taskmanager/Task', {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(taskObject)
});

// Delete task
await fetch('http://localhost:8080/taskmanager/Task/1', {
  method: 'DELETE'
});
```

### cURL

```bash
# Get all tasks
curl http://localhost:8080/taskmanager/Task

# Get task by ID
curl http://localhost:8080/taskmanager/Task/1

# Create task
curl -X POST http://localhost:8080/taskmanager/Task \
  -H "Content-Type: application/json" \
  -d '{"Title":"New Task","Description":"Test","Priority":2,"Status":"pending","IsCompleted":false}'

# Update task
curl -X PUT http://localhost:8080/taskmanager/Task \
  -H "Content-Type: application/json" \
  -d '{"ID":1,"Title":"Updated","Description":"Test","Priority":3,"Status":"completed","IsCompleted":true}'

# Delete task
curl -X DELETE http://localhost:8080/taskmanager/Task/1
```

## CORS

The server is configured with CORS enabled (`Access-Control-Allow-Origin: *`) to allow web clients from any origin.

## Notes

- All datetime fields use ISO 8601 format
- The server automatically creates database tables on first run
- Sample data is created if the database is empty
- The database file is stored in `solution1/data/tasks.db3`
