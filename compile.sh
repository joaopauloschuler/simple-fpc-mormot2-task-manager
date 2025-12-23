
#!/bin/bash
# mORMot2 Task Manager - Compilation Script

echo "mORMot2 Task Manager - Compilation Script"
echo "=========================================="
echo ""

# Check if FPC is installed
if ! command -v fpc &> /dev/null; then
    echo "Error: Free Pascal Compiler (fpc) is not installed"
    exit 1
fi

echo "Compiling task_manager..."
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

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Compilation successful!"
    echo "✓ Binary: bin/task_manager"
    echo ""
    echo "To run the server:"
    echo "  ./bin/task_manager"
    echo ""
    echo "The server will be available at:"
    echo "  http://localhost:8080"
    echo ""
    echo "Open static/index.html in your browser to use the web interface"
else
    echo ""
    echo "✗ Compilation failed!"
    exit 1
fi
