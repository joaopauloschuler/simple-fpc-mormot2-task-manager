# mORMot2 Task Manager - AI Coding Agent Instructions

## Architecture Overview

This is a **Free Pascal (FPC) + mORMot2** REST API server using a 3-layer architecture:

1. **ORM Layer** (`*_models.pas`): TOrm descendants define database entities
2. **SOA Layer** (`*_services.pas` + `*_services_impl.pas`): Interface-based business logic
3. **Server** (`task_manager.pas`): Orchestrates HTTP server, database, and service registration

**Core Pattern**: Each feature follows the same structure:
- `TTask`, `TTag`, `TComment` (models) → `ITaskService`, `ITagService`, `ICommentService` (interfaces) → `TTaskService`, `TTagService`, `TCommentService` (implementations)

## Critical mORMot2 Conventions

### String Types
- **Always use `RawUtf8`** for string properties in ORM models and service interfaces (not `string`)
- mORMot2 uses UTF-8 internally; `RawUtf8` avoids conversion overhead

### ORM Entity Pattern
```pascal
TMyEntity = class(TOrm)
private
  fMyField: RawUtf8;
published
  property MyField: RawUtf8 read fMyField write fMyField;
end;
```
- Properties must be in `published` section for ORM mapping
- ID field is inherited from TOrm (don't redeclare)

### Service Implementation Pattern
```pascal
TMyService = class(TInjectableObjectRest, IMyService)
public
  function DoSomething(Param: RawUtf8): TID;
end;
```
- Inherit from `TInjectableObjectRest` (provides `Server` property for ORM access)
- Access database via `Server.Orm.Add()`, `Server.Orm.Update()`, etc.
- Use `NowUtc` for timestamps (not `Now`)
- Raise `EServiceException` for business logic errors

### Service Registration (in task_manager.pas)
1. Register interfaces before use: `TInterfaceFactory.RegisterInterfaces([TypeInfo(IMyService)])`
2. Define services: `Server.ServiceDefine(TMyService, [IMyService], sicShared)`
3. `sicShared` = stateless, one instance for all requests (default for REST services)

## Build & Run Workflow

**Compile**: `./compile.sh` (uses FPC with mORMot2 paths in `../mORMot2/`)
**Run**: `./run.sh` or `./bin/task_manager`
**Test**: Open `static/index.html` or curl `http://localhost:8080/taskmanager/Task`

### Key Compiler Flags (in compile.sh)
- `-Fl../mORMot2/static/x86_64-linux`: Link static SQLite3 library
- `-Fu../mORMot2/src/{core,orm,rest,soa,...}`: mORMot2 unit paths
- `-FUbin/units`: Output compiled units here
- `-Mobjfpc`: Object Pascal mode (required)

**Database**: `data/tasks.db3` (SQLite3, auto-created on first run)

## Code Patterns & Conventions

### Adding a New Feature
1. Create `feature_models.pas` with TOrm entities
2. Create `feature_services.pas` with IFeatureService interface (include GUID)
3. Create `feature_services_impl.pas` with TFeatureService implementation
4. Register in `task_manager.pas`:
   - Add to `uses` clause
   - Add to `Model := TOrmModel.Create([TTask, ..., TNewEntity])`
   - Add to `TInterfaceFactory.RegisterInterfaces([..., TypeInfo(IFeatureService)])`
   - Add `Server.ServiceDefine(TFeatureService, [IFeatureService], sicShared)`

### ORM Operations
```pascal
// Create
Entity := TMyEntity.Create;
Entity.Field := Value;
ID := Server.Orm.Add(Entity, true);  // true = force ID generation

// Read
Entity := TMyEntity.Create(Server.Orm, ID);
if Entity.ID = 0 then raise EServiceException.Create('Not found');

// Update
Entity.Field := NewValue;
Success := Server.Orm.Update(Entity);

// Delete
Success := Server.Orm.Delete(TMyEntity, ID);
```

### Validation Pattern
```pascal
if Title = '' then
  raise EServiceException.Create('Title cannot be empty');
if not IsValidFormat(Value) then
  raise EServiceException.CreateUtf8('Invalid format: %', [Value]);
```

### Date Handling
- Use `Iso8601ToDateTime()` to parse ISO 8601 strings
- Use `DateTimeToIso8601(DateTime, true)` to format (true = with milliseconds)
- Store as TDateTime in database (Unix epoch stored internally)

### Variant Conversion (for JSON responses)
```pascal
TDocVariantData(Result).InitObject([
  'id', Entity.ID,
  'field', Entity.Field,
  'createdAt', DateTimeToIso8601(Entity.CreatedAt, true)
]);
```

## Project-Specific Quirks

- **Priority values**: 1=Low, 2=Medium, 3=High (hardcoded in task_models.pas)
- **Status values**: 'pending', 'in_progress', 'completed' (validated by `IsValidStatus()`)
- **CORS enabled**: `HttpServer.AccessControlAllowOrigin := '*'` for web client access
- **Sample data**: Auto-created on first run if tables are empty (see `CreateSampleData()`)
- **Self-tests**: Each service has a `SelfTest` class method called during initialization

## API Structure

- **ORM Endpoints**: `/taskmanager/{Entity}/{ID}` (CRUD via GET/POST/PUT/DELETE)
- **SOA Endpoints**: `/taskmanager/{ServiceName}/{MethodName}` (POST JSON array of params)
- **Static files**: `/static/` mapped to `static/` directory

Example SOA call:
```bash
curl -X POST http://localhost:8080/taskmanager/TaskService/CreateTask \
  -H "Content-Type: application/json" \
  -d '["Buy milk", "From the store", 2, "2024-12-30T10:00:00"]'
```

## When Modifying Code

- **Never use `string` type** in models or services (use `RawUtf8`)
- **Always update timestamps** when modifying entities (set `UpdatedAt := NowUtc`)
- **Add validation** for all user inputs in service implementations
- **Free objects** in try-finally blocks (Pascal requires manual memory management)
- **Test compilation** after changes: `./compile.sh` shows line-specific errors
- **Check logs** if service fails: mORMot2 logs to console during development
