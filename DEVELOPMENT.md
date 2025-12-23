
# Development Guide

## Project Structure

```
solution1/
├── src/
│   ├── task_models.pas      # ORM models (TTask entity)
│   ├── task_services.pas    # Service interfaces (empty for now)
│   └── task_manager.pas     # Main server program
├── static/
│   └── index.html           # Web client interface
├── data/
│   └── tasks.db3            # SQLite database (created at runtime)
├── bin/
│   ├── task_manager         # Compiled executable
│   └── units/               # Compiled units
├── compile.sh               # Build script
├── run.sh                   # Run script
├── README.md                # Project overview
├── ARCHITECTURE.md          # Architecture documentation
├── API.md                   # API documentation
└── DEVELOPMENT.md           # This file
```

## Prerequisites

### Required Software

1. **Free Pascal Compiler (FPC)** version 3.2.2 or later
   ```bash
   fpc -version
   ```

2. **mORMot2 Framework**
   - Located in `../mORMot2/` (relative to solution1 folder)
   - Static libraries in `../mORMot2/static/x86_64-linux/`

3. **Git** (for version control)

### System Libraries

- SQLite3 development libraries (optional, static version included)
- Standard C library

## Building the Project

### Using the Build Script

```bash
cd solution1
./compile.sh
```

### Manual Compilation

```bash
fpc src/task_manager.pas \
    -obin/task_manager \
    -FUbin/units \
    -FlmORMot2/static/x86_64-linux \
    -O1 -Mobjfpc \
    -Fi../mORMot2/src \
    -Fusrc \
    -Fu../mORMot2/src/core \
    -Fu../mORMot2/src/lib \
    -Fu../mORMot2/src/crypt \
    -Fu../mORMot2/src/orm \
    -Fu../mORMot2/src/rest \
    -Fu../mORMot2/src/db \
    -Fu../mORMot2/src/net \
    -Fu../mORMot2/src/soa \
    -Fu../mORMot2/src/app
```

### Compiler Flags Explained

- `-o`: Output file path
- `-FU`: Unit output directory
- `-Fl`: Library path (for static libraries)
- `-O1`: Optimization level 1
- `-Mobjfpc`: Object Pascal mode
- `-Fi`: Include file path
- `-Fu`: Unit path

## Running the Server

### Using the Run Script

```bash
./run.sh
```

### Manual Execution

```bash
./bin/task_manager
```

The server will:
1. Create the database if it doesn't exist
2. Create tables if needed
3. Insert sample data if the database is empty
4. Start HTTP server on port 8080
5. Wait for Enter key to shutdown

## Development Workflow

### 1. Modify Source Code

Edit the Pascal source files in the `src/` directory:

- `task_models.pas`: Add or modify ORM entities
- `task_services.pas`: Add service interfaces and implementations
- `task_manager.pas`: Modify server configuration

### 2. Compile

```bash
./compile.sh
```

### 3. Test

```bash
./run.sh
```

### 4. Access Web Interface

Open `static/index.html` in your browser, or navigate to:
```
http://localhost:8080/static/index.html
```

### 5. Test API

Use curl or any HTTP client:

```bash
# List tasks
curl http://localhost:8080/taskmanager/Task

# Create task
curl -X POST http://localhost:8080/taskmanager/Task \
  -H "Content-Type: application/json" \
  -d '{"Title":"Test Task","Priority":2,"Status":"pending"}'
```

## Adding Features

### Adding a New ORM Entity

1. Define the class in `task_models.pas`:

```pascal
type
  TCategory = class(TOrm)
  private
    fName: RawUtf8;
  published
    property Name: RawUtf8 read fName write fName;
  end;
```

2. Register it in the model (`task_manager.pas`):

```pascal
Model := TOrmModel.Create([TTask, TCategory], 'taskmanager');
```

### Adding a Service

1. Define interface in `task_services.pas`:

```pascal
type
  ITaskService = interface(IInvokable)
    ['{GENERATE-NEW-GUID}']
    function GetTasksByPriority(Priority: integer): TVariantDynArray;
  end;
```

2. Implement the interface:

```pascal
type
  TTaskService = class(TInterfacedObject, ITaskService)
  public
    function GetTasksByPriority(Priority: integer): TVariantDynArray;
  end;
```

3. Register the service (`task_manager.pas`):

```pascal
Server.ServiceDefine(TTaskService, [ITaskService], sicShared);
```

## Debugging

### Enable Logging

Add to `task_manager.pas`:

```pascal
uses
  mormot.core.log;

// In initialization
with TSynLog.Family do
begin
  Level := LOG_VERBOSE;
  EchoToConsole := LOG_VERBOSE;
end;
```

### Database Inspection

Use SQLite tools to inspect the database:

```bash
sqlite3 data/tasks.db3
.tables
SELECT * FROM Task;
```

### Check Compilation Warnings

Review compiler output for warnings and notes.

## Testing

### Manual Testing

1. Start the server
2. Use the web interface to create, update, and delete tasks
3. Verify data persistence by restarting the server

### API Testing with curl

See `API.md` for curl examples.

### Browser Developer Tools

Use browser console to check:
- Network requests
- JavaScript errors
- Response data

## Common Issues

### Compilation Errors

**Issue**: Cannot find mORMot2 units
**Solution**: Ensure mORMot2 is in the correct location (`../mORMot2/`)

**Issue**: Static library not found
**Solution**: Check that `mORMot2/static/x86_64-linux/` contains the .o and .a files

### Runtime Errors

**Issue**: Port 8080 already in use
**Solution**: Change the port in `task_manager.pas` or stop the conflicting service

**Issue**: Database locked
**Solution**: Ensure only one instance of the server is running

### CORS Errors

**Issue**: Browser blocks requests
**Solution**: The server enables CORS with `*`. Ensure you're accessing from `http://` not `file://`

## Code Style Guidelines

1. **Pascal Conventions**:
   - Use PascalCase for types and classes
   - Use camelCase for local variables
   - Prefix fields with `f` (e.g., `fTitle`)
   - Prefix parameters with `a` (e.g., `aTitle`)

2. **Comments**:
   - Document all public interfaces
   - Explain complex logic
   - Use `///` for documentation comments

3. **Error Handling**:
   - Always use try/finally for resource management
   - Use meaningful exception messages
   - Log errors appropriately

## Performance Tips

1. Use `sicShared` for stateless services
2. Enable database WAL mode for better concurrency
3. Use connection pooling for external databases
4. Profile with mORMot2's built-in performance monitoring

## Next Steps

- Add authentication and user management
- Implement SOA services for complex operations
- Add WebSocket support for real-time updates
- Create MVC views for server-side rendering
- Add unit tests
- Deploy to production server

## Resources

- [mORMot2 Documentation](https://synopse.info)
- [mORMot2 GitHub](https://github.com/synopse/mORMot2)
- [Free Pascal Documentation](https://www.freepascal.org/docs.html)
