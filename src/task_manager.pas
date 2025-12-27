
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
  mormot.core.text,
  mormot.core.unicode,
  mormot.core.interfaces,
  mormot.orm.core,
  mormot.rest.core,
  mormot.rest.server,
  mormot.rest.sqlite3,
  mormot.rest.http.server,
  mormot.soa.core,
  mormot.soa.server,
  mormot.net.server,
  mormot.net.http,
  mormot.db.raw.sqlite3.static,
  task_models,
  task_services,
  task_services_impl,
  tag_models,
  tag_services,
  tag_services_impl,
  comment_models,
  comment_services,
  comment_services_impl;

type
  { TStaticFileServer - Helper class to serve static files }
  TStaticFileServer = class
  public
    Folder: TFileName;
    function ServeFile(Ctxt: THttpServerRequestAbstract): cardinal;
  end;

var
  Model: TOrmModel;
  Server: TRestServerDB;
  HttpServer: TRestHttpServer;
  StaticServer: TStaticFileServer;

function TStaticFileServer.ServeFile(Ctxt: THttpServerRequestAbstract): cardinal;
var
  FileName: TFileName;
  RequestPath: RawUtf8;
begin
  // Get the path after /static/
  RequestPath := Ctxt.Url;
  if IdemPChar(pointer(RequestPath), '/STATIC/') then
    Delete(RequestPath, 1, 8)
  else if IdemPChar(pointer(RequestPath), '/STATIC') then
    RequestPath := 'index.html';
  
  // Default to index.html if empty
  if (RequestPath = '') or (RequestPath = '/') then
    RequestPath := 'index.html';
    
  // Build full file path
  FileName := Folder + Utf8ToString(StringReplaceChars(RequestPath, '/', PathDelim));
  
  // Check if file exists
  if FileExists(FileName) then
  begin
    // Serve the file using mORMot's static file mechanism
    Ctxt.OutContentType := STATICFILE_CONTENT_TYPE;
    Ctxt.OutContent := StringToUtf8(FileName);
    result := HTTP_SUCCESS;
  end
  else
  begin
    Ctxt.OutContentType := TEXT_CONTENT_TYPE;
    Ctxt.OutContent := 'File not found: ' + RequestPath;
    result := HTTP_NOTFOUND;
  end;
end;
  
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
var
  DataFolder: string;
  DBFileName: string;
begin
  WriteLn('mORMot2 Task Manager Server');
  WriteLn('============================');
  WriteLn('');
  
  // Create ORM model with all entities
  Model := TOrmModel.Create([TTask, TTag, TTaskTag, TComment], 'taskmanager');
  try
    // Determine data folder from the binary location
    DataFolder := ExtractFilePath(ParamStr(0)) + '..' + PathDelim + 'data';
    DBFileName := DataFolder + PathDelim + 'tasks.db3';
    WriteLn('Creating database: ', DBFileName);
    
    // Create REST server with SQLite database
    Server := TRestServerDB.Create(Model, DBFileName);
    try
      // Create tables if they don't exist
      Server.CreateMissingTables;
      
      WriteLn('Database created successfully');
      
      // Register SOA services
      WriteLn('Registering services...');
      Server.ServiceDefine(TTaskService, [ITaskService], sicShared);
      Server.ServiceDefine(TTagService, [ITagService], sicShared);
      Server.ServiceDefine(TCommentService, [ICommentService], sicShared);
      WriteLn('Services registered successfully');
      
      // Create sample data if database is empty
      if Server.Orm.TableRowCount(TTask) = 0 then
        CreateSampleData;
      
      // Run self-test
      RunSelfTest;
      
      WriteLn('Starting HTTP server...');
      
      // Setup static file server
      StaticServer := TStaticFileServer.Create;
      StaticServer.Folder := ExtractFilePath(ParamStr(0)) + '..' + PathDelim + 'static' + PathDelim;
      WriteLn('Static folder: ', StaticServer.Folder);
      
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
        
        // Register static file routes
        HttpServer.Route.Get('/static/<path:path>', @StaticServer.ServeFile);
        HttpServer.Route.Get('/static', @StaticServer.ServeFile);
        WriteLn('Static file serving enabled at /static/');
        
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
        WriteLn('  http://localhost:8080/taskmanager/CommentService');
        WriteLn('');
        WriteLn('Web Interface:');
        WriteLn('  http://localhost:8080/static/index.html');
        WriteLn('');
        WriteLn('Press [Enter] to quit');
        WriteLn('');
        
        ReadLn;
        
        WriteLn('Shutting down...');
      finally
        HttpServer.Free;
        StaticServer.Free;
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
    TypeInfo(ITagService),
    TypeInfo(ICommentService)
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
