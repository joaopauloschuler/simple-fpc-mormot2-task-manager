
# Project Structure

## Overview

This document describes the modular structure of the mORMot2 Task Manager application.

## Directory Structure

```
solution1/
├── src/                          # Source code files
│   ├── task_models.pas          # Task ORM entity definition
│   ├── task_services.pas        # Task service interface
│   ├── task_services_impl.pas   # Task service implementation
│   ├── tag_models.pas           # Tag ORM entities (TTag, TTaskTag)
│   ├── tag_services.pas         # Tag service interface
│   ├── tag_services_impl.pas    # Tag service implementation
│   └── task_manager.pas         # Main server program
├── static/                       # Web client files
│   └── index.html               # Web-based task manager UI
├── data/                         # Database files
│   └── tasks.db3                # SQLite database (created at runtime)
├── bin/                          # Compiled binaries and units
│   ├── task_manager             # Executable
│   └── units/                   # Compiled Pascal units (.o, .ppu)
├── compile.sh                    # Compilation script
├── run.sh                        # Run script
└── *.md                          # Documentation files
```

## Source Code Modules

### Core ORM Models

#### task_models.pas (88 lines)
Defines the `TTask` entity representing tasks in the system.

**Key Components:**
- `TTask` class with properties: Title, Description, Priority, DueDate, Status, IsCompleted, CreatedAt, UpdatedAt
- Helper functions: `GetPriorityName`, `IsValidStatus`, `GetDefaultStatus`

#### tag_models.pas (75 lines)
Defines tagging system entities.

**Key Components:**
- `TTag` class for tag definitions (Name, Color, CreatedAt)
- `TTaskTag` class for many-to-many task-tag relationships
- Helper functions: `IsValidColor`, `GetDefaultColor`

### Service Layer (SOA)

#### task_services.pas (39 lines)
Interface definition for task management services.

**Exports:**
- `ITaskService` interface with methods for CRUD operations, filtering, searching

#### task_services_impl.pas (379 lines)
Implementation of task service business logic.

**Key Features:**
- Task creation, retrieval, update, deletion
- Status management and completion tracking
- Task filtering and searching
- Data validation
- Self-testing capabilities

#### tag_services.pas (57 lines)
Interface definition for tag management services.

**Exports:**
- `ITagService` interface with methods for tag CRUD and task-tag associations

#### tag_services_impl.pas (346 lines)
Implementation of tag service business logic.

**Key Features:**
- Tag creation with duplicate prevention
- Tag-task association management
- Tag searching and filtering
- Automatic cleanup on tag deletion
- Self-testing capabilities

### Main Application

#### task_manager.pas (261 lines)
Main server program that coordinates all components.

**Responsibilities:**
- ORM model creation (registers TTask, TTag, TTaskTag)
- Database initialization
- Service registration (ITaskService, ITagService)
- HTTP server setup on port 8080
- Sample data creation
- Self-test execution

## Module Dependencies

```
task_manager.pas
    ├── task_models.pas
    ├── task_services.pas
    ├── task_services_impl.pas
    │       ├── task_models.pas
    │       └── task_services.pas
    ├── tag_models.pas
    ├── tag_services.pas
    └── tag_services_impl.pas
            ├── tag_models.pas
            └── tag_services.pas
```

## Modular Design Principles

### Separation of Concerns
- **Models**: Pure data entities (ORM classes)
- **Service Interfaces**: Contract definitions
- **Service Implementations**: Business logic
- **Main Program**: Composition and initialization

### Independence
- Each module can be understood independently
- Clear interfaces between modules
- Minimal coupling between components

### Testability
- Each service has self-test methods
- Models are simple and testable
- Business logic isolated in service implementations

### Maintainability
- Files kept under 500 lines each
- Clear naming conventions
- Comprehensive inline documentation
- Modular structure allows easy updates

## Compilation Order

The Free Pascal compiler automatically handles dependencies, but the logical compilation order is:

1. **Models** (task_models.pas, tag_models.pas)
2. **Service Interfaces** (task_services.pas, tag_services.pas)
3. **Service Implementations** (task_services_impl.pas, tag_services_impl.pas)
4. **Main Program** (task_manager.pas)

## Adding New Features

To add a new feature to the system:

1. **Define ORM Model** (if needed)
   - Create new unit in `src/` directory
   - Define `TOrm` descendant class
   - Add to model registration in `task_manager.pas`

2. **Define Service Interface**
   - Create interface inheriting from `IInvokable`
   - Add unique GUID
   - Define service methods

3. **Implement Service**
   - Create implementation class
   - Implement all interface methods
   - Add self-test method

4. **Register Service**
   - Register interface with `TInterfaceFactory`
   - Register service with `Server.ServiceDefine`

5. **Update Documentation**
   - Add API documentation
   - Update relevant .md files

## File Naming Conventions

- **Models**: `*_models.pas`
- **Service Interfaces**: `*_services.pas`
- **Service Implementations**: `*_services_impl.pas`
- **Main Programs**: `*.pas` (e.g., `task_manager.pas`)
- **Documentation**: `*.md` (uppercase)
- **Scripts**: `*.sh`

## Code Style Guidelines

- All Pascal reserved words in lowercase
- Use `RawUtf8` for strings
- Use dynamic arrays (never fixed-size)
- Always free objects in try/finally blocks
- Declare variables in declaration section (not in begin/end)
- Include self-test methods in service implementations
- Comment complex logic
- Keep files modular and focused
