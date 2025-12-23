
# Task Comments Feature

## Overview

The Task Comments feature allows users to add timestamped notes and discussions to tasks. This feature enhances collaboration by providing a conversation thread for each task where team members can share updates, ask questions, and provide feedback.

## Architecture

The comments system follows the same mORMot2 ORM/SOA pattern as the rest of the application:

### 1. Data Model (ORM Layer)

**File:** `src/comment_models.pas`

The `TComment` class represents a comment in the database:

```pascal
TComment = class(TOrm)
  property TaskID: TID;        // Foreign key to the task
  property Content: RawUtf8;   // Comment text content
  property Author: RawUtf8;    // Name/identifier of the author
  property CreatedAt: TDateTime; // When the comment was created
  property UpdatedAt: TDateTime; // When the comment was last edited
  property IsEdited: boolean;  // Whether the comment has been edited
end;
```

**Validation Functions:**
- `IsValidCommentContent(Content: RawUtf8): boolean` - Validates content length (1-10000 characters)
- `GetMaxCommentLength: integer` - Returns the maximum allowed comment length (10000)

### 2. Service Interface (SOA Layer)

**File:** `src/comment_services.pas`

The `ICommentService` interface defines the business operations:

```pascal
ICommentService = interface(IInvokable)
  ['{B8F3A2C1-9D4E-4F2A-8C7B-1E6D5A9F3B2C}']
  
  function CreateComment(TaskID: TID; const Content, Author: RawUtf8): TID;
  function GetComment(CommentID: TID): Variant;
  function UpdateComment(CommentID: TID; const Content: RawUtf8): boolean;
  function DeleteComment(CommentID: TID): boolean;
  function GetTaskComments(TaskID: TID): TVariantDynArray;
  function GetCommentCount(TaskID: TID): integer;
  function DeleteTaskComments(TaskID: TID): integer;
end;
```

### 3. Service Implementation

**File:** `src/comment_services_impl.pas`

The `TCommentService` class implements the business logic with:
- **Validation:** Ensures tasks exist before allowing comments
- **Content validation:** Checks comment length constraints
- **Author validation:** Requires an author name for each comment
- **Automatic timestamps:** Sets CreatedAt and UpdatedAt automatically
- **Edit tracking:** Marks comments as edited when content changes
- **Logging:** Internal logging of all operations for debugging

## API Endpoints

### REST ORM Endpoints

- `GET /taskmanager/Comment/:id` - Retrieve a comment by ID
- `POST /taskmanager/Comment` - Create a new comment (JSON body)
- `PUT /taskmanager/Comment` - Update a comment (JSON body)
- `DELETE /taskmanager/Comment/:id` - Delete a comment

### SOA Service Endpoints

All service methods are available at `/taskmanager/CommentService/`:

#### CreateComment
Creates a new comment on a task.

**Endpoint:** `POST /taskmanager/CommentService/CreateComment`

**Parameters:** `[taskId, content, author]`

**Example:**
```javascript
POST /taskmanager/CommentService/CreateComment
Body: [1, "Great progress on this task!", "John Doe"]
Response: 42  // The new comment ID
```

#### GetComment
Retrieves a specific comment by ID.

**Endpoint:** `POST /taskmanager/CommentService/GetComment`

**Parameters:** `[commentId]`

**Response:**
```json
{
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
Updates the content of an existing comment.

**Endpoint:** `POST /taskmanager/CommentService/UpdateComment`

**Parameters:** `[commentId, newContent]`

**Returns:** `true` if successful, `false` otherwise

**Note:** Automatically sets `isEdited` to true and updates the `updatedAt` timestamp.

#### DeleteComment
Deletes a specific comment.

**Endpoint:** `POST /taskmanager/CommentService/DeleteComment`

**Parameters:** `[commentId]`

**Returns:** `true` if successful, `false` otherwise

#### GetTaskComments
Retrieves all comments for a specific task, ordered by creation date (oldest first).

**Endpoint:** `POST /taskmanager/CommentService/GetTaskComments`

**Parameters:** `[taskId]`

**Response:**
```json
[
  {
    "id": 42,
    "taskId": 1,
    "content": "First comment",
    "author": "Alice",
    "createdAt": "2024-12-23T10:30:00",
    "updatedAt": "2024-12-23T10:30:00",
    "isEdited": false
  },
  {
    "id": 43,
    "taskId": 1,
    "content": "Second comment",
    "author": "Bob",
    "createdAt": "2024-12-23T11:15:00",
    "updatedAt": "2024-12-23T11:15:00",
    "isEdited": false
  }
]
```

#### GetCommentCount
Returns the number of comments on a task.

**Endpoint:** `POST /taskmanager/CommentService/GetCommentCount`

**Parameters:** `[taskId]`

**Returns:** Integer count of comments

#### DeleteTaskComments
Deletes all comments associated with a task.

**Endpoint:** `POST /taskmanager/CommentService/DeleteTaskComments`

**Parameters:** `[taskId]`

**Returns:** Integer count of deleted comments

## Database Schema

The `Comment` table is automatically created by mORMot2 with the following structure:

| Column | Type | Description |
|--------|------|-------------|
| ID | INTEGER PRIMARY KEY | Auto-increment comment ID |
| TaskID | INTEGER | Foreign key to Task table |
| Content | TEXT | Comment content (UTF-8) |
| Author | TEXT | Author name (UTF-8) |
| CreatedAt | DATETIME | Creation timestamp (UTC) |
| UpdatedAt | DATETIME | Last update timestamp (UTC) |
| IsEdited | BOOLEAN | Edit flag |

## Usage Examples

### JavaScript/Web Client

```javascript
const API_BASE = 'http://localhost:8080/taskmanager';

// Helper function to call SOA services
async function callService(serviceName, methodName, params = []) {
  const url = `${API_BASE}/${serviceName}/${methodName}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(params)
  });
  return await response.json();
}

// Create a comment
const commentId = await callService('CommentService', 'CreateComment', 
  [taskId, 'This is my comment', 'John Doe']);

// Get all comments for a task
const comments = await callService('CommentService', 'GetTaskComments', [taskId]);

// Update a comment
await callService('CommentService', 'UpdateComment', 
  [commentId, 'Updated comment text']);

// Delete a comment
await callService('CommentService', 'DeleteComment', [commentId]);

// Get comment count
const count = await callService('CommentService', 'GetCommentCount', [taskId]);
```

## Business Rules

1. **Task Validation:** Comments can only be created for existing tasks
2. **Content Length:** Comment content must be between 1 and 10,000 characters
3. **Author Required:** Every comment must have an author name
4. **Timestamps:** CreatedAt and UpdatedAt are automatically managed
5. **Edit Tracking:** When a comment is updated, IsEdited is automatically set to true
6. **Cascade Delete:** When deleting a task, consider deleting associated comments using DeleteTaskComments

## Error Handling

The service logs warnings for common error conditions:
- Task not found when creating a comment
- Invalid content length
- Missing author name
- Comment not found when retrieving/updating/deleting

All errors are logged to the mORMot2 internal log with appropriate severity levels.

## Future Enhancements

Potential improvements to the comment system:
- Rich text support (Markdown)
- File attachments to comments
- @mentions to notify users
- Comment reactions (likes, emoji)
- Comment threading (replies to comments)
- Comment moderation and flagging
- Comment edit history
- Real-time notifications via WebSockets

## Implementation Notes

- Comments use UTC timestamps for consistency across timezones
- The author field is currently a simple string; in a multi-user system, this could be linked to a User table
- Comments are ordered chronologically (oldest first) to maintain conversation flow
- The IsEdited flag helps users understand which comments have been modified after posting
