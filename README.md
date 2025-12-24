
# mORMot2 Task Manager

A modern, high-performance task management system built with Free Pascal and the mORMot2 framework.

## 🌟 Features

- ✅ **Full CRUD Operations** - Create, Read, Update, Delete tasks
- ✅ **RESTful API** - Complete REST API with automatic ORM endpoints
- ✅ **Web Interface** - Modern, responsive web-based client
- ✅ **SQLite Database** - Embedded SQLite3 with ORM support
- ✅ **Task Priorities** - Low, Medium, High priority levels
- ✅ **Task Status** - Pending, In Progress, Completed states
- ✅ **Due Dates** - Track task deadlines
- ✅ **Real-time Updates** - Instant feedback on all operations
- ✅ **CORS Enabled** - Works with web clients from any origin
- ✅ **Sample Data** - Pre-populated with example tasks

## 🚀 Quick Start

### Prerequisites

- Free Pascal Compiler (FPC) 3.2.2 or later
- mORMot2 framework (automatically included)
- Modern web browser

### Installation

1. **Clone the repository** (if not already done)

2. **Install dependencies and mORMot2**
   
   Run the dependency installation script to set up FPC, mORMot2, and required tools:
   ```bash
   ./install_dependencies.sh
   ```
   
   This script will:
   - Install Free Pascal Compiler (FPC) if not already installed
   - Install git, wget, and tar utilities if needed
   - Clone the mORMot2 repository to `../mORMot2/`
   - Download and extract the mORMot2 static libraries (SQLite3)

3. **Compile the server**
   ```bash
   ./compile.sh
   ```

4. **Run the server**
   ```bash
   ./run.sh
   ```

5. **Open the web interface**
   - Open `static/index.html` in your web browser
   - Or navigate to: `http://localhost:8080/static/index.html`

## 📖 Usage

### Web Interface

The web interface provides an intuitive way to manage tasks:

1. **Create Task**: Fill in the form with task details and click "Create Task"
2. **View Tasks**: All tasks are displayed in card format
3. **Filter Tasks**: Use filter buttons to show All, Pending, In Progress, or Completed tasks
4. **Complete Task**: Click the "✓ Complete" button to mark as done
5. **Delete Task**: Click the "🗑️ Delete" button to remove a task

### API Access

The server provides a RESTful API at `http://localhost:8080/taskmanager/Task`

**Examples**:

```bash
# Get all tasks
curl http://localhost:8080/taskmanager/Task

# Get task by ID
curl http://localhost:8080/taskmanager/Task/1

# Create task
curl -X POST http://localhost:8080/taskmanager/Task \
  -H "Content-Type: application/json" \
  -d '{
    "Title": "My Task",
    "Description": "Task description",
    "Priority": 2,
    "Status": "pending",
    "IsCompleted": false
  }'

# Update task
curl -X PUT http://localhost:8080/taskmanager/Task \
  -H "Content-Type: application/json" \
  -d '{
    "ID": 1,
    "Title": "Updated Task",
    "Priority": 3,
    "Status": "completed",
    "IsCompleted": true
  }'

# Delete task
curl -X DELETE http://localhost:8080/taskmanager/Task/1
```

See [API.md](API.md) for complete API documentation.

## 📁 Project Structure

```
solution1/
├── src/
│   ├── task_models.pas      # ORM models (TTask entity)
│   ├── task_services.pas    # Service interfaces (placeholder)
│   └── task_manager.pas     # Main server program
├── static/
│   └── index.html           # Web client interface
├── data/
│   └── tasks.db3            # SQLite database (auto-created)
├── bin/
│   ├── task_manager         # Compiled executable
│   └── units/               # Compiled units
├── compile.sh               # Build script
├── run.sh                   # Run script
├── README.md                # This file
├── ARCHITECTURE.md          # Architecture documentation
├── API.md                   # API documentation
└── DEVELOPMENT.md           # Development guide
```

## 🏗️ Architecture

This application follows the mORMot2 architecture pattern:

- **ORM Layer**: SQLite3 database with automatic table generation
- **REST Layer**: Automatic RESTful endpoints for all entities
- **HTTP Server**: High-performance async HTTP server
- **Web Client**: Modern HTML5/JavaScript interface

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## 🛠️ Development

### Building from Source

```bash
./compile.sh
```

### Running Tests

Start the server and use the web interface or API to test functionality.

### Adding Features

See [DEVELOPMENT.md](DEVELOPMENT.md) for:
- How to add new entities
- Creating service interfaces
- Extending the API
- Debugging tips

## 📊 Technical Stack

**Backend**:
- Language: Free Pascal (Object Pascal)
- Framework: mORMot2
- Database: SQLite3
- ORM: mORMot2 ORM
- HTTP Server: mORMot2 HTTP Server (async)

**Frontend**:
- HTML5
- CSS3
- Vanilla JavaScript (ES6+)
- Fetch API for REST calls

## 🎯 API Endpoints

### Task Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/taskmanager/Task` | List all tasks |
| GET | `/taskmanager/Task/{id}` | Get task by ID |
| POST | `/taskmanager/Task` | Create new task |
| PUT | `/taskmanager/Task` | Update task |
| DELETE | `/taskmanager/Task/{id}` | Delete task |

### Tag Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/taskmanager/Tag` | List all tags |
| GET | `/taskmanager/Tag/{id}` | Get tag by ID |
| POST | `/taskmanager/Tag` | Create new tag |
| PUT | `/taskmanager/Tag` | Update tag |
| DELETE | `/taskmanager/Tag/{id}` | Delete tag |

### Comment Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/taskmanager/Comment/{id}` | Get comment by ID |
| POST | `/taskmanager/Comment` | Create new comment |
| PUT | `/taskmanager/Comment` | Update comment |
| DELETE | `/taskmanager/Comment/{id}` | Delete comment |

## 💾 Database Schema

### Task Table

| Column | Type | Description |
|--------|------|-------------|
| ID | INTEGER | Primary key (auto-increment) |
| Title | TEXT | Task title |
| Description | TEXT | Task description |
| Priority | INTEGER | 1=Low, 2=Medium, 3=High |
| DueDate | REAL | Due date (TDateTime) |
| Status | TEXT | pending/in_progress/completed |
| IsCompleted | BOOLEAN | Completion flag |
| CreatedAt | REAL | Creation timestamp |
| UpdatedAt | REAL | Last update timestamp |

### Tag Table

| Column | Type | Description |
|--------|------|-------------|
| ID | INTEGER | Primary key (auto-increment) |
| Name | TEXT | Unique tag name (lowercase) |
| Color | TEXT | Color code (#RRGGBB or named color) |
| CreatedAt | REAL | Creation timestamp |

### TaskTag Table (Junction)

| Column | Type | Description |
|--------|------|-------------|
| ID | INTEGER | Primary key (auto-increment) |
| TaskID | INTEGER | Foreign key to Task table |
| TagID | INTEGER | Foreign key to Tag table |
| CreatedAt | REAL | Association timestamp |

### Comment Table

| Column | Type | Description |
|--------|------|-------------|
| ID | INTEGER | Primary key (auto-increment) |
| TaskID | INTEGER | Foreign key to Task table |
| Content | TEXT | Comment content (UTF-8) |
| Author | TEXT | Author name (UTF-8) |
| CreatedAt | REAL | Creation timestamp (UTC) |
| UpdatedAt | REAL | Last update timestamp (UTC) |
| IsEdited | BOOLEAN | Edit flag |

## 🔧 Configuration

### Changing the Port

Edit `src/task_manager.pas`:

```pascal
HttpServer := TRestHttpServer.Create(
  '8080',  // Change this port number
  [Server],
  '+',
  useBidirSocket
);
```

### Database Location

The database is stored at `solution1/data/tasks.db3` by default.

To change it, edit `src/task_manager.pas`:

```pascal
Server := TRestServerDB.Create(Model, 'your/path/tasks.db3');
```

## 🐛 Troubleshooting

**Server won't start**:
- Check if port 8080 is already in use
- Ensure you have write permissions to the `data/` directory

**Compilation fails**:
- Verify FPC is installed: `fpc -version`
- Run `./install_dependencies.sh` to install all dependencies
- Check mORMot2 location: `../mORMot2/src/` must exist
- Ensure static libraries are present: `../mORMot2/static/x86_64-linux/`

**Web interface doesn't load tasks**:
- Ensure the server is running
- Check browser console for errors
- Verify CORS is enabled (it is by default)

## 📝 License

Open source - free to use and modify.

## 🙏 Acknowledgments

- Built with [mORMot2](https://github.com/synopse/mORMot2) by Arnaud Bouchez
- Compiled with [Free Pascal](https://www.freepascal.org/)

## 📚 Documentation

- [README.md](README.md) - This file (overview and quick start)
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and design
- [API.md](API.md) - Complete API reference
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [SOA_SERVICES.md](SOA_SERVICES.md) - SOA Services layer documentation
- [COMMENTS_FEATURE.md](COMMENTS_FEATURE.md) - Task comments feature documentation

## 🎓 Learning Resources

- [mORMot2 Documentation](https://synopse.info)
- [mORMot2 GitHub Repository](https://github.com/synopse/mORMot2)
- [Free Pascal Documentation](https://www.freepascal.org/docs.html)

## ✨ Future Enhancements

Potential features for future versions:

- [ ] User authentication and authorization
- [ ] Task assignments to users
- [ ] File attachments
- [ ] Search and advanced filtering
- [ ] Export to CSV/JSON
- [ ] Email notifications
- [ ] WebSocket support for real-time updates
- [ ] Mobile app using the same API
- [ ] Multi-language support

## 📞 Support

For issues and questions:
- Check the documentation files
- Review mORMot2 examples in `../mORMot2/ex/`
- Visit [mORMot2 forum](https://synopse.info)

---

**Made with ❤️ using Free Pascal and mORMot2**
