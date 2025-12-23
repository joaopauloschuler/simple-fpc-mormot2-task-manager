
program task_manager;

{$mode objfpc}{$H+}

uses
  {$ifdef unix}
  cthreads,
  {$endif}
  SysUtils,
  mormot.core.base,
  mormot.core.os,
  mormot.core.log,
  mormot.core.data,
  mormot.core.interfaces,
  mormot.orm.core,
  mormot.rest.core,
  mormot.rest.server,
  mormot.rest.sqlite3,
  mormot.rest.http.server,
  mormot.soa.core,
  mormot.soa.server,
  mormot.net.server,
  mormot.db.raw.sqlite3.static,
  task_models,
  task_services,
  task_services.impl,
  tag_models,
  tag_services,
  tag_services_impl;

var
  Model: TOrmModel;
  Server: TRestServerDB;
  HttpServer: TRestHttpServer;
  
procedure CreateSampleData;
var
  Task: TTask;
  Tag: TTag;
  TagID1, TagID2, TagID3: TID;
  TaskTag: TTaskTag;
begin
  WriteLn('Creating sample tasks and tags...');
  
  // Create sample tags
  Tag := TTag.Create;
  try
    Tag.Name := 'urgent';
    Tag.Color := '#FF3333';
    Tag.CreatedAt := Now;
    TagID1 := Server.Orm.Add(Tag, true);
  finally
    Tag.Free;
  end;
  
  Tag := TTag.Create;
  try
    Tag.Name := 'work';
    Tag.Color := '#3498DB';
    Tag.CreatedAt := Now;
    TagID2 := Server.Orm.Add(Tag, true);
  finally
    Tag.Free;
  end;
  
  Tag := TTag.Create;
  try
    Tag.Name := 'personal';
    Tag.Color := '#2ECC71';
    Tag.CreatedAt := Now;
    TagID3 := Server.Orm.Add(Tag, true);
  finally
    Tag.Free;
  end;
  
  WriteLn('Sample tags created: urgent, work, personal');
  
  // Create sample tasks
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
    
    // Add tags to this task
    TaskTag := TTaskTag.Create;
    try
      TaskTag.TaskID := Task.ID;
      TaskTag.TagID := TagID2; // work tag
      TaskTag.CreatedAt := Now;
      Server.Orm.Add(TaskTag, true);
    finally
      TaskTag.Free;
    end;
  finally
    Task.Free;
  end;
  
  Task := TTask.Create;
  try
    Task.Title := 'Implement Tag System';
    Task.Description := 'Add tagging functionality to categorize tasks';
    Task.Priority := 3;
    Task.DueDate := Now + 1;
    Task.Status := 'completed';
    Task.IsCompleted := true;
    Task.CreatedAt := Now - 2;
    Task.UpdatedAt := Now;
    Server.Orm.Add(Task, true);
    
    // Add tags to this task
    TaskTag := TTaskTag.Create;
    try
      TaskTag.TaskID := Task.ID;
      TaskTag.TagID := TagID2; // work tag
      TaskTag.CreatedAt := Now;
      Server.Orm.Add(TaskTag, true);
    finally
      TaskTag.Free;
    end;
    
    TaskTag := TTaskTag.Create;
    try
      TaskTag.TaskID := Task.ID;
      TaskTag.TagID := TagID1; // urgent tag
      TaskTag.CreatedAt := Now;
      Server.Orm.Add(TaskTag, true);
    finally
      TaskTag.Free;
    end;
  finally
    Task.Free;
  end;
  
  WriteLn('Sample tasks created successfully');
end;

procedure RunSelfTest;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('Running Service Self-Tests');
  WriteLn('========================================');
  WriteLn('');
  
  TTaskService.SelfTest(Server);
  
  WriteLn('');
  TTagService.SelfTest(Server);
  
  WriteLn('');
  WriteLn('========================================');
  WriteLn('Self-Tests Completed');
  WriteLn('========================================');
  WriteLn('');
end;

procedure Run;
begin
  WriteLn('mORMot2 Task Manager Server');
  WriteLn('============================');
  WriteLn('');
  
  // Create ORM model with all entities
  Model := TOrmModel.Create([TTask, TTag, TTaskTag], 'taskmanager');
  try
    WriteLn('Creating database...');
    
    // Create REST server with SQLite database
    Server := TRestServerDB.Create(Model, 'solution1/data/tasks.db3');
    try
      // Create tables if they don't exist
      Server.CreateMissingTables;
      
      WriteLn('Database created successfully');
      
      // Register SOA services
      WriteLn('Registering services...');
      Server.ServiceDefine(TTaskService, [ITaskService], sicShared);
      Server.ServiceDefine(TTagService, [ITagService], sicShared);
      WriteLn('Services registered successfully');
      
      // Create sample data if database is empty
      if Server.Orm.TableRowCount(TTask) = 0 then
        CreateSampleData;
      
      // Run self-test
      RunSelfTest;
      
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
        WriteLn('  http://localhost:8080/taskmanager/Tag');
        WriteLn('');
        WriteLn('SOA Services available at:');
        WriteLn('  http://localhost:8080/taskmanager/TaskService');
        WriteLn('  http://localhost:8080/taskmanager/TagService');
        WriteLn('');
        WriteLn('Web Interface:');
        WriteLn('  Open static/index.html in your browser');
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
  // Register interfaces before using them
  TInterfaceFactory.RegisterInterfaces([
    TypeInfo(ITaskService),
    TypeInfo(ITagService)
  ]);
  
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
