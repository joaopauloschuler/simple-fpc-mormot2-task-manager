
# Task Tags Feature Documentation

## Overview

The Task Manager now supports a comprehensive tagging system that allows you to categorize and organize tasks using custom labels. Tags provide a flexible way to group related tasks across different projects, priorities, or categories.

## Features

### Tag Management
- **Create Tags**: Define custom tags with names and colors
- **List Tags**: View all available tags
- **Update Tags**: Modify tag names and colors
- **Delete Tags**: Remove tags (automatically removes all task associations)
- **Search Tags**: Find tags by name

### Task-Tag Association
- **Add Tags to Tasks**: Associate one or more tags with any task
- **Remove Tags from Tasks**: Disassociate tags when no longer needed
- **View Task Tags**: See all tags assigned to a specific task
- **Filter by Tag**: Find all tasks with a specific tag

## Data Models

### TTag (ORM Entity)
```pascal
TTag = class(TOrm)
  property Name: RawUtf8;        // Unique tag name (lowercase)
  property Color: RawUtf8;       // Color code (#RRGGBB or named color)
  property CreatedAt: TDateTime; // Creation timestamp
end;
```

### TTaskTag (Junction Table)
```pascal
TTaskTag = class(TOrm)
  property TaskID: TID;          // Reference to task
  property TagID: TID;           // Reference to tag
  property CreatedAt: TDateTime; // Association timestamp
end;
```

## Service Interface (ITagService)

### Tag CRUD Operations

#### CreateTag
```pascal
function CreateTag(const Name, Color: RawUtf8): TID;
```
Creates a new tag with the specified name and color.
- **Name**: Tag identifier (automatically converted to lowercase)
- **Color**: Hex color code (e.g., "#FF0000") or empty for default
- **Returns**: ID of the created tag
- **Throws**: Exception if tag name already exists

#### GetTag
```pascal
function GetTag(TagID: TID): Variant;
```
Retrieves tag information by ID.
- **Returns**: JSON variant with tag details (id, name, color, createdAt)

#### UpdateTag
```pascal
function UpdateTag(TagID: TID; const Name, Color: RawUtf8): boolean;
```
Updates an existing tag.
- **Returns**: true if successful

#### DeleteTag
```pascal
function DeleteTag(TagID: TID): boolean;
```
Deletes a tag and all its task associations.
- **Returns**: true if successful

#### ListTags
```pascal
function ListTags: TVariantDynArray;
```
Returns all tags in the system.

#### SearchTags
```pascal
function SearchTags(const SearchTerm: RawUtf8): TVariantDynArray;
```
Searches tags by name (case-insensitive partial match).

### Task-Tag Association Operations

#### AddTagToTask
```pascal
function AddTagToTask(TaskID: TID; TagID: TID): boolean;
```
Associates a tag with a task.
- **Returns**: true if successful (idempotent - returns true if already associated)

#### RemoveTagFromTask
```pascal
function RemoveTagFromTask(TaskID: TID; TagID: TID): boolean;
```
Removes a tag from a task.

#### GetTaskTags
```pascal
function GetTaskTags(TaskID: TID): TVariantDynArray;
```
Returns all tags associated with a specific task.

#### GetTasksByTag
```pascal
function GetTasksByTag(TagID: TID): TVariantDynArray;
```
Returns all tasks that have a specific tag.

## REST API Endpoints

### ORM Endpoints
- `GET /taskmanager/Tag` - List all tags
- `GET /taskmanager/Tag/123` - Get tag by ID
- `POST /taskmanager/Tag` - Create new tag
- `PUT /taskmanager/Tag` - Update tag
- `DELETE /taskmanager/Tag/123` - Delete tag

### SOA Service Endpoints
All endpoints use POST with JSON body:

```javascript
// Create a tag
POST /taskmanager/TagService.CreateTag
Body: ["urgent", "#FF0000"]
Returns: 123 (tag ID)

// List all tags
POST /taskmanager/TagService.ListTags
Body: []
Returns: [{id: 1, name: "urgent", color: "#FF0000", ...}, ...]

// Add tag to task
POST /taskmanager/TagService.AddTagToTask
Body: [1, 2]  // [taskID, tagID]
Returns: true

// Get task tags
POST /taskmanager/TagService.GetTaskTags
Body: [1]  // taskID
Returns: [{id: 2, name: "urgent", ...}, ...]
```

## Usage Examples

### Creating Tags
```pascal
var
  Service: ITagService;
  TagID: TID;
begin
  if Server.Services.Resolve(ITagService, Service) then
  begin
    TagID := Service.CreateTag('urgent', '#FF3333');
    TagID := Service.CreateTag('work', '#3498DB');
    TagID := Service.CreateTag('personal', '#2ECC71');
  end;
end;
```

### Tagging Tasks
```pascal
// Add multiple tags to a task
Service.AddTagToTask(TaskID, UrgentTagID);
Service.AddTagToTask(TaskID, WorkTagID);

// View task tags
var Tags := Service.GetTaskTags(TaskID);
```

### Finding Tagged Tasks
```pascal
// Find all urgent tasks
var Tasks := Service.GetTasksByTag(UrgentTagID);
```

## Sample Data

The server automatically creates these sample tags on first run:
- **urgent** (#FF3333) - Red color for high-priority items
- **work** (#3498DB) - Blue color for work-related tasks
- **personal** (#2ECC71) - Green color for personal tasks

## Implementation Notes

### Tag Name Normalization
- All tag names are automatically converted to lowercase
- Leading/trailing whitespace is trimmed
- Duplicate names are prevented (case-insensitive)

### Color Handling
- Accepts hex colors (#RRGGBB format)
- Accepts named colors
- If invalid or empty, uses default color (#3498db)

### Data Integrity
- Deleting a tag automatically removes all task-tag associations
- Task-tag associations are unique (can't add same tag to task twice)

### Performance Considerations
- Tag queries are optimized with proper indexing
- Many-to-many relationships handled efficiently through junction table

## Future Enhancements

Potential improvements for the tagging system:
- Tag hierarchies (parent/child tags)
- Tag suggestions based on task content
- Tag usage statistics
- Predefined tag templates
- Bulk tag operations
- Tag-based task filtering in web UI
- Tag color themes

## Testing

The tag service includes a `SelfTest` method that validates:
- Tag creation
- Tag listing
- Tag searching
- Task-tag associations
- Tag retrieval

Run the server to execute self-tests automatically on startup.
