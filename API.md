
# Task Manager API Documentation

## Overview

This document describes the REST API provided by the mORMot2 Task Manager server.

**Base URL**: `http://localhost:8080/taskmanager`

**Content-Type**: All requests and responses use `application/json`

## Endpoints

### ORM REST Endpoints

mORMot2 automatically provides RESTful CRUD endpoints for the Task entity.

#### List All Task IDs

```
GET /taskmanager/Task
```

**Response**: Array of Task IDs only (mORMot2 default behavior for security/performance)

```json
[{"ID":1},{"ID":2},{"ID":3}]
```

#### List All Tasks with Full Details

```
GET /taskmanager/Task?select=*
```

**Response**: Array of Task objects with all fields

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

### Tag ORM Endpoints

mORMot2 also provides RESTful CRUD endpoints for the Tag entity.

#### List All Tags

```
GET /taskmanager/Tag
```

**Response**: Array of Tag objects

```json
[
  {
    "ID": 1,
    "Name": "urgent",
    "Color": "#FF3333",
    "CreatedAt": "2024-12-23T10:00:00"
  }
]
```

#### Get Tag by ID

```
GET /taskmanager/Tag/{id}
```

**Parameters**:
- `id` (integer): Tag ID

**Response**: Single Tag object

```json
{
  "ID": 1,
  "Name": "urgent",
  "Color": "#FF3333",
  "CreatedAt": "2024-12-23T10:00:00"
}
```

#### Create Tag

```
POST /taskmanager/Tag
```

**Request Body**:

```json
{
  "Name": "work",
  "Color": "#3498DB"
}
```

**Response**: Tag ID

```json
1
```

#### Update Tag

```
PUT /taskmanager/Tag
```

**Request Body**: Complete Tag object with updated fields

```json
{
  "ID": 1,
  "Name": "urgent",
  "Color": "#FF0000"
}
```

**Response**: HTTP 200 OK

#### Delete Tag

```
DELETE /taskmanager/Tag/{id}
```

**Parameters**:
- `id` (integer): Tag ID

**Response**: HTTP 200 OK

### Comment ORM Endpoints

mORMot2 also provides RESTful CRUD endpoints for the Comment entity.

#### Get Comment by ID

```
GET /taskmanager/Comment/{id}
```

**Parameters**:
- `id` (integer): Comment ID

**Response**: Single Comment object

```json
{
  "ID": 1,
  "TaskID": 1,
  "Content": "Great progress on this task!",
  "Author": "John Doe",
  "CreatedAt": "2024-12-23T10:30:00",
  "UpdatedAt": "2024-12-23T10:30:00",
  "IsEdited": false
}
```

#### Create Comment

```
POST /taskmanager/Comment
```

**Request Body**:

```json
{
  "TaskID": 1,
  "Content": "This is a comment",
  "Author": "John Doe"
}
```

**Response**: Comment ID

```json
1
```

#### Update Comment

```
PUT /taskmanager/Comment
```

**Request Body**: Complete Comment object with updated fields

```json
{
  "ID": 1,
  "TaskID": 1,
  "Content": "Updated comment text",
  "Author": "John Doe",
  "IsEdited": true
}
```

**Response**: HTTP 200 OK

#### Delete Comment

```
DELETE /taskmanager/Comment/{id}
```

**Parameters**:
- `id` (integer): Comment ID

**Response**: HTTP 200 OK

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

### Tag Object

| Field | Type | Description |
|-------|------|-------------|
| ID | integer | Unique tag identifier (auto-generated) |
| Name | string | Tag name (unique, lowercase) |
| Color | string | Color code (#RRGGBB format or named color) |
| CreatedAt | datetime | Creation timestamp |

### TaskTag Object (Junction Table)

| Field | Type | Description |
|-------|------|-------------|
| ID | integer | Unique identifier (auto-generated) |
| TaskID | integer | Foreign key to Task |
| TagID | integer | Foreign key to Tag |
| CreatedAt | datetime | Association timestamp |

### Comment Object

| Field | Type | Description |
|-------|------|-------------|
| ID | integer | Unique comment identifier (auto-generated) |
| TaskID | integer | Foreign key to Task |
| Content | string | Comment text content (1-10000 characters) |
| Author | string | Author name/identifier |
| CreatedAt | datetime | Creation timestamp (UTC) |
| UpdatedAt | datetime | Last update timestamp (UTC) |
| IsEdited | boolean | Whether the comment has been edited |

## SOA Service Endpoints

In addition to ORM endpoints, the Task Manager provides SOA (Service-Oriented Architecture) service endpoints for more complex business logic operations.

### TagService

All TagService endpoints use POST with JSON body parameters:

#### CreateTag

Creates a new tag with the specified name and color.

```
POST /taskmanager/TagService/CreateTag
Body: ["urgent", "#FF0000"]
Response: 123  // tag ID
```

#### GetTag

Retrieves tag information by ID.

```
POST /taskmanager/TagService/GetTag
Body: [1]
Response: {"id": 1, "name": "urgent", "color": "#FF0000", "createdAt": "..."}
```

#### UpdateTag

Updates an existing tag's name and/or color.

```
POST /taskmanager/TagService/UpdateTag
Body: [1, "new-name", "#00FF00"]
Response: true
```

#### DeleteTag

Deletes a tag and all its task associations.

```
POST /taskmanager/TagService/DeleteTag
Body: [1]
Response: true
```

#### ListTags

Returns all tags in the system.

```
POST /taskmanager/TagService/ListTags
Body: []
Response: [{"id": 1, "name": "urgent", "color": "#FF0000", ...}, ...]
```

#### SearchTags

Searches tags by name (case-insensitive partial match).

```
POST /taskmanager/TagService/SearchTags
Body: ["urg"]
Response: [{"id": 1, "name": "urgent", ...}]
```

#### AddTagToTask

Associates a tag with a task.

```
POST /taskmanager/TagService/AddTagToTask
Body: [1, 2]  // [taskID, tagID]
Response: true
```

#### RemoveTagFromTask

Removes a tag from a task.

```
POST /taskmanager/TagService/RemoveTagFromTask
Body: [1, 2]  // [taskID, tagID]
Response: true
```

#### GetTaskTags

Returns all tags associated with a specific task.

```
POST /taskmanager/TagService/GetTaskTags
Body: [1]  // taskID
Response: [{"id": 2, "name": "urgent", ...}, ...]
```

#### GetTasksByTag

Returns all tasks that have a specific tag.

```
POST /taskmanager/TagService/GetTasksByTag
Body: [1]  // tagID
Response: [{"id": 1, "title": "Task 1", ...}, ...]
```

### CommentService

All CommentService endpoints use POST with JSON body parameters:

#### CreateComment

Creates a new comment on a task.

```
POST /taskmanager/CommentService/CreateComment
Body: [1, "Great progress on this task!", "John Doe"]  // [taskId, content, author]
Response: 42  // The new comment ID
```

#### GetComment

Retrieves a specific comment by ID.

```
POST /taskmanager/CommentService/GetComment
Body: [42]  // commentId
Response: {
  "id": 42,
  "taskId": 1,
  "content": "Great progress on this task!",
  "author": "John Doe",
  "createdAt": "2024-12-23T10:30:00",
  "updatedAt": "2024-12-23T10:30:00",
  "isEdited": false
}
```

#### UpdateComment

Updates the content of an existing comment. Automatically sets `isEdited` to true.

```
POST /taskmanager/CommentService/UpdateComment
Body: [42, "Updated comment text"]  // [commentId, newContent]
Response: true
```

#### DeleteComment

Deletes a specific comment.

```
POST /taskmanager/CommentService/DeleteComment
Body: [42]  // commentId
Response: true
```

#### GetTaskComments

Retrieves all comments for a specific task, ordered by creation date (oldest first).

```
POST /taskmanager/CommentService/GetTaskComments
Body: [1]  // taskId
Response: [
  {
    "id": 42,
    "taskId": 1,
    "content": "First comment",
    "author": "Alice",
    "createdAt": "2024-12-23T10:30:00",
    "updatedAt": "2024-12-23T10:30:00",
    "isEdited": false
  },
  ...
]
```

#### GetCommentCount

Returns the number of comments on a task.

```
POST /taskmanager/CommentService/GetCommentCount
Body: [1]  // taskId
Response: 5
```

#### DeleteTaskComments

Deletes all comments associated with a task.

```
POST /taskmanager/CommentService/DeleteTaskComments
Body: [1]  // taskId
Response: 3  // number of deleted comments
```

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
