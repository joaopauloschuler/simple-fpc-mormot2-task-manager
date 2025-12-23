
# SOA Services Documentation

## Overview

The Task Manager now includes a complete Service-Oriented Architecture (SOA) layer built with mORMot2. This layer provides a clean separation between business logic and data access, making the application more maintainable and testable.

## Architecture

### Service Interface: ITaskService

Located in `src/task_services.pas`, the `ITaskService` interface defines the contract for task management operations:

```pascal
ITaskService = interface(IInvokable)
  ['{12345678-ABCD-EFAB-1234-567890ABCDEF}']
  
  function CreateTask(const Title, Description: RawUtf8; 
                      Priority: integer; const DueDate: RawUtf8): TID;
  function GetTask(TaskID: TID): Variant;
  function UpdateTask(TaskID: TID; const Title, Description: RawUtf8; 
                      Priority: integer; const DueDate: RawUtf8): boolean;
  function DeleteTask(TaskID: TID): boolean;
  function ListTasks(const Status: RawUtf8): TVariantDynArray;
  function MarkComplete(TaskID: TID; IsComplete: boolean): boolean;
  function SearchTasks(const SearchTerm: RawUtf8): TVariantDynArray;
end;
```

### Service Implementation: TTaskService

Located in `src/task_services.impl.pas`, the `TTaskService` class implements the business logic:

**Key Features:**
- Inherits from `TInjectableObjectRest` for dependency injection and REST integration
- Implements `ITaskService` interface
- Provides input validation for all operations
- Handles error cases with appropriate exceptions
- Converts database entities to JSON-friendly Variant types

## Service Methods

### CreateTask

Creates a new task with validation.

**Parameters:**
- `Title`: Task title (required, non-empty)
- `Description`: Task description (optional)
- `Priority`: Priority level (1-5, where 1=Low, 5=Critical)
- `DueDate`: ISO 8601 formatted date string (optional)

**Returns:** Task ID (TID)

**Validation:**
- Title cannot be empty
- Priority must be between 1 and 5
- DueDate must be valid ISO 8601 format if provided

**Example:**
```
POST /taskmanager/TaskService.CreateTask
Body: ["Buy groceries", "Get milk and bread", 2, "2024-12-25T10:00:00"]
```

### GetTask

Retrieves a single task by ID.

**Parameters:**
- `TaskID`: The task's unique identifier

**Returns:** Variant object containing task details

**Throws:** `EServiceException` if task not found

**Example:**
```
POST /taskmanager/TaskService.GetTask
Body: [1]
```

### UpdateTask

Updates an existing task's properties.

**Parameters:**
- `TaskID`: The task's unique identifier
- `Title`: New task title
- `Description`: New description
- `Priority`: New priority (1-5)
- `DueDate`: New due date (ISO 8601)

**Returns:** Boolean indicating success

**Validation:** Same as CreateTask

**Example:**
```
POST /taskmanager/TaskService.UpdateTask
Body: [1, "Updated title", "Updated description", 3, "2024-12-30T15:00:00"]
```

### DeleteTask

Deletes a task from the system.

**Parameters:**
- `TaskID`: The task's unique identifier

**Returns:** Boolean indicating success

**Throws:** `EServiceException` if task not found

**Example:**
```
POST /taskmanager/TaskService.DeleteTask
Body: [1]
```

### ListTasks

Lists all tasks, optionally filtered by status.

**Parameters:**
- `Status`: Filter by status ('pending', 'in_progress', 'completed', or empty for all)

**Returns:** Array of Variant objects containing task details

**Example:**
```
POST /taskmanager/TaskService.ListTasks
Body: ["pending"]
```

### MarkComplete

Marks a task as complete or incomplete.

**Parameters:**
- `TaskID`: The task's unique identifier
- `IsComplete`: Boolean indicating completion status

**Returns:** Boolean indicating success

**Side Effects:**
- Sets `IsCompleted` field
- Updates `Status` to 'completed' or 'pending'
- Updates `UpdatedAt` timestamp

**Example:**
```
POST /taskmanager/TaskService.MarkComplete
Body: [1, true]
```

### SearchTasks

Searches tasks by title or description.

**Parameters:**
- `SearchTerm`: Text to search for (case-insensitive)

**Returns:** Array of Variant objects containing matching tasks

**Search Behavior:**
- Searches both title and description fields
- Uses SQL LIKE with wildcards for partial matching
- Empty search term returns all tasks

**Example:**
```
POST /taskmanager/TaskService.SearchTasks
Body: ["groceries"]
```

## Self-Testing

The `TTaskService` class includes a comprehensive self-test method that validates all service operations:

```pascal
class procedure TTaskService.SelfTest(aRestServer: TRestServer);
```

**Tests performed:**
1. Create a new task
2. Retrieve the created task
3. Update the task
4. Mark task as complete
5. List all tasks
6. Search for tasks
7. Delete the task

The self-test runs automatically when the server starts, ensuring all services are functioning correctly.

## REST API Endpoints

All service methods are automatically exposed as REST endpoints:

**Base URL:** `http://localhost:8080/taskmanager/TaskService`

**Method Pattern:** `POST /taskmanager/TaskService.<MethodName>`

**Request Format:**
- Content-Type: `application/json`
- Body: JSON array of parameters

**Response Format:**
- Content-Type: `application/json`
- Body: JSON result (value, object, or array)

## Error Handling

The service layer uses `EServiceException` for business logic errors:

- **Invalid input:** Throws exception with descriptive message
- **Entity not found:** Throws exception indicating which entity
- **Validation failures:** Throws exception with validation details

All exceptions are automatically converted to HTTP 500 responses with error details in JSON format.

## Integration with ORM

The service layer interacts with the ORM layer (`TTask` model) through the inherited `Server.Orm` property:

- **Create:** `Server.Orm.Add(Task, true)`
- **Read:** `TTask.Create(Server.Orm, TaskID)`
- **Update:** `Server.Orm.Update(Task)`
- **Delete:** `Server.Orm.Delete(TTask, TaskID)`
- **Query:** `Server.Orm.RetrieveList(TTask, whereClause, params, '')`

## Registration

The service is registered in `task_manager.pas` using:

```pascal
// Register interface factory
TInterfaceFactory.RegisterInterfaces([TypeInfo(ITaskService)]);

// Register service implementation
Server.ServiceDefine(TTaskService, [ITaskService], sicShared);
```

**Service Instance Mode:** `sicShared`
- One instance shared across all requests
- Stateless service (no per-request state)
- Thread-safe (mORMot2 handles synchronization)
- Best for scalability

## Benefits of SOA Layer

1. **Separation of Concerns:** Business logic separated from HTTP/REST handling
2. **Testability:** Services can be tested independently
3. **Reusability:** Same services can be used by different clients
4. **Type Safety:** Strongly-typed interface contract
5. **Automatic REST Exposure:** No manual endpoint coding required
6. **Validation:** Centralized input validation
7. **Error Handling:** Consistent error reporting
8. **Documentation:** Interface serves as API documentation

## Future Enhancements

Potential additions to the SOA layer:

- **Batch Operations:** Methods for bulk create/update/delete
- **Task Categories:** Group tasks by categories or projects
- **Task Assignment:** Assign tasks to users
- **Task Dependencies:** Link related tasks
- **Task History:** Track changes to tasks over time
- **Advanced Filtering:** Filter by multiple criteria
- **Sorting:** Sort tasks by various fields
- **Pagination:** Support for large result sets
- **Task Statistics:** Aggregate data and reports
- **Task Reminders:** Schedule notifications for due dates

## See Also

- [README.md](README.md) - Project overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall architecture
- [API.md](API.md) - Complete API reference
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
