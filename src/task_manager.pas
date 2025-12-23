
program task_manager;

{$mode objfpc}{$H+}
{$define NOSQLITE3STATIC}
{$define PUREPASCAL}
{$define NOASMX64}

uses
  {$ifdef unix}
  cthreads,
  {$endif}
  SysUtils,
  mormot.core.base,
  mormot.core.os,
  mormot.core.log,
  mormot.core.data,
  mormot.orm.core,
  mormot.rest.core,
  mormot.rest.server,
  mormot.rest.sqlite3,
  mormot.rest.http.server,
  mormot.net.server,
  task_models;

var
  Model: TOrmModel;
  Server: TRestServerDB;
  HttpServer: TRestHttpServer;
  
procedure CreateSampleData;
var
  Task: TTask;
begin
  WriteLn('Creating sample tasks...');
  
  Task := TTask.Create;
  try
    Task.Title := 'Welcome to Task Manager';
    Task.Description := 'This is a sample task created automatically';
    Task.Priority := 2;
    Task.DueDate := Now + 7;
    Task.Status := 'pending';
    Task.IsCompleted := false;
    Task.CreatedAt := Now;
    Task.UpdatedAt := Now;
    Server.Orm.Add(Task, true);
  finally
    Task.Free;
  end;
  
  Task := TTask.Create;
  try
    Task.Title := 'Learn mORMot2';
    Task.Description := 'Study the mORMot2 framework documentation';
    Task.Priority := 3;
    Task.DueDate := Now + 3;
    Task.Status := 'in_progress';
    Task.IsCompleted := false;
    Task.CreatedAt := Now;
    Task.UpdatedAt := Now;
    Server.Orm.Add(Task, true);
  finally
    Task.Free;
  end;
  
  WriteLn('Sample tasks created successfully');
end;

procedure Run;
begin
  WriteLn('mORMot2 Task Manager Server');
  WriteLn('============================');
  WriteLn('');
  
  // Create ORM model
  Model := TOrmModel.Create([TTask], 'taskmanager');
  try
    WriteLn('Creating database...');
    
    // Create REST server with SQLite database
    Server := TRestServerDB.Create(Model, 'solution1/data/tasks.db3');
    try
      // Create tables if they don''t exist
      Server.CreateMissingTables;
      
      WriteLn('Database created successfully');
      
      // Create sample data if database is empty
      if Server.Orm.TableRowCount(TTask) = 0 then
        CreateSampleData;
      
      WriteLn('Starting HTTP server...');
      
      // Create HTTP server on port 8080
      HttpServer := TRestHttpServer.Create(
        '8080',
        [Server],
        '+',
        useBidirSocket
      );
      try
        // Enable CORS for web clients
        HttpServer.AccessControlAllowOrigin := '*';
        
        WriteLn('');
        WriteLn('Server running successfully!');
        WriteLn('');
        WriteLn('REST API available at:');
        WriteLn('  http://localhost:8080/taskmanager/Task');
        WriteLn('');
        WriteLn('Examples:');
        WriteLn('  GET  http://localhost:8080/taskmanager/Task - List all tasks');
        WriteLn('  GET  http://localhost:8080/taskmanager/Task/1 - Get task by ID');
        WriteLn('  POST http://localhost:8080/taskmanager/Task - Create new task');
        WriteLn('');
        WriteLn('Press [Enter] to quit');
        WriteLn('');
        
        ReadLn;
        
        WriteLn('Shutting down...');
      finally
        HttpServer.Free;
      end;
    finally
      Server.Free;
    end;
  finally
    Model.Free;
  end;
end;

begin
  try
    Run;
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.Message);
      ReadLn;
    end;
  end;
end.
