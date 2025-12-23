
unit task_services.impl;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  contnrs,
  mormot.core.base,
  mormot.core.data,
  mormot.core.variants,
  mormot.core.json,
  mormot.core.datetime,
  mormot.core.interfaces,
  mormot.core.os,
  mormot.orm.core,
  mormot.rest.core,
  mormot.rest.server,
  mormot.soa.core,
  mormot.soa.server,
  task_models,
  task_services;

type
  /// Task Service Implementation
  /// Provides business logic layer for task management
  TTaskService = class(TInjectableObjectRest, ITaskService)
  private
    function TaskToVariant(Task: TTask): Variant;
    function IsValidDueDate(const DueDateStr: RawUtf8): boolean;
  public
    /// Creates a new task with the specified properties
    function CreateTask(const Title, Description: RawUtf8; 
                        Priority: integer; const DueDate: RawUtf8): TID;
    
    /// Retrieves a task by ID and returns it as a variant
    function GetTask(TaskID: TID): Variant;
    
    /// Updates an existing task with new values
    function UpdateTask(TaskID: TID; const Title, Description: RawUtf8; 
                        Priority: integer; const DueDate: RawUtf8): boolean;
    
    /// Deletes a task by ID
    function DeleteTask(TaskID: TID): boolean;
    
    /// Lists all tasks optionally filtered by status
    function ListTasks(const Status: RawUtf8): TVariantDynArray;
    
    /// Marks a task as complete or incomplete
    function MarkComplete(TaskID: TID; IsComplete: boolean): boolean;
    
    /// Searches tasks by title or description
    function SearchTasks(const SearchTerm: RawUtf8): TVariantDynArray;
    
    /// Self-test method to verify service functionality
    class procedure SelfTest(aRestServer: TRestServer);
  end;

implementation

{ TTaskService }

function TTaskService.TaskToVariant(Task: TTask): Variant;
begin
  TDocVariantData(Result).InitObject([
    'id', Task.ID,
    'title', Task.Title,
    'description', Task.Description,
    'priority', Task.Priority,
    'priorityName', GetPriorityName(Task.Priority),
    'dueDate', DateTimeToIso8601(Task.DueDate, true),
    'status', Task.Status,
    'isCompleted', Task.IsCompleted,
    'createdAt', DateTimeToIso8601(Task.CreatedAt, true),
    'updatedAt', DateTimeToIso8601(Task.UpdatedAt, true)
  ]);
end;

function TTaskService.IsValidDueDate(const DueDateStr: RawUtf8): boolean;
var
  DueDate: TDateTime;
begin
  Result := false;
  if DueDateStr = '' then
  begin
    Result := true;  // Empty date is valid
    exit;
  end;
  
  try
    DueDate := Iso8601ToDateTime(DueDateStr);
    Result := DueDate > 0;
  except
    Result := false;
  end;
end;

function TTaskService.CreateTask(const Title, Description: RawUtf8; 
                                  Priority: integer; const DueDate: RawUtf8): TID;
var
  Task: TTask;
  DueDateValue: TDateTime;
begin
  Result := 0;
  
  // Validate input
  if Title = '' then
    raise EServiceException.Create('Task title cannot be empty');
  
  if (Priority < 1) or (Priority > 5) then
    raise EServiceException.Create('Priority must be between 1 and 5');
  
  if not IsValidDueDate(DueDate) then
    raise EServiceException.Create('Invalid due date format');
  
  // Parse due date
  if DueDate <> '' then
    DueDateValue := Iso8601ToDateTime(DueDate)
  else
    DueDateValue := 0;
  
  // Create task
  Task := TTask.Create;
  try
    Task.Title := Title;
    Task.Description := Description;
    Task.Priority := Priority;
    Task.DueDate := DueDateValue;
    Task.Status := GetDefaultStatus;
    Task.IsCompleted := false;
    Task.CreatedAt := NowUtc;
    Task.UpdatedAt := NowUtc;
    
    Result := Server.Orm.Add(Task, true);
  finally
    Task.Free;
  end;
end;

function TTaskService.GetTask(TaskID: TID): Variant;
var
  Task: TTask;
begin
  Task := TTask.Create(Server.Orm, TaskID);
  try
    if Task.ID = 0 then
      raise EServiceException.CreateUtf8('Task % not found', [TaskID]);
    
    Result := TaskToVariant(Task);
  finally
    Task.Free;
  end;
end;

function TTaskService.UpdateTask(TaskID: TID; const Title, Description: RawUtf8; 
                                  Priority: integer; const DueDate: RawUtf8): boolean;
var
  Task: TTask;
  DueDateValue: TDateTime;
begin
  Result := false;
  
  // Validate input
  if Title = '' then
    raise EServiceException.Create('Task title cannot be empty');
  
  if (Priority < 1) or (Priority > 5) then
    raise EServiceException.Create('Priority must be between 1 and 5');
  
  if not IsValidDueDate(DueDate) then
    raise EServiceException.Create('Invalid due date format');
  
  // Parse due date
  if DueDate <> '' then
    DueDateValue := Iso8601ToDateTime(DueDate)
  else
    DueDateValue := 0;
  
  // Update task
  Task := TTask.Create(Server.Orm, TaskID);
  try
    if Task.ID = 0 then
      raise EServiceException.CreateUtf8('Task % not found', [TaskID]);
    
    Task.Title := Title;
    Task.Description := Description;
    Task.Priority := Priority;
    Task.DueDate := DueDateValue;
    Task.UpdatedAt := NowUtc;
    
    Result := Server.Orm.Update(Task);
  finally
    Task.Free;
  end;
end;

function TTaskService.DeleteTask(TaskID: TID): boolean;
var
  Task: TTask;
begin
  Result := false;
  
  // Check if task exists
  Task := TTask.Create(Server.Orm, TaskID);
  try
    if Task.ID = 0 then
      raise EServiceException.CreateUtf8('Task % not found', [TaskID]);
  finally
    Task.Free;
  end;
  
  // Delete the task
  Result := Server.Orm.Delete(TTask, TaskID);
end;

function TTaskService.ListTasks(const Status: RawUtf8): TVariantDynArray;
var
  Tasks: TObjectList;
  Task: TTask;
  i: integer;
begin
  SetLength(Result, 0);
  
  // Build query based on status filter
  if (Status <> '') and IsValidStatus(Status) then
    Tasks := Server.Orm.RetrieveList(TTask, 'Status=?', [Status], '')
  else
    Tasks := Server.Orm.RetrieveList(TTask, '', [], '');
  
  if Tasks = nil then
    exit;
  
  try
    SetLength(Result, Tasks.Count);
    for i := 0 to Tasks.Count - 1 do
    begin
      Task := TTask(Tasks[i]);
      Result[i] := TaskToVariant(Task);
    end;
  finally
    Tasks.Free;
  end;
end;

function TTaskService.MarkComplete(TaskID: TID; IsComplete: boolean): boolean;
var
  Task: TTask;
begin
  Result := false;
  
  Task := TTask.Create(Server.Orm, TaskID);
  try
    if Task.ID = 0 then
      raise EServiceException.CreateUtf8('Task % not found', [TaskID]);
    
    Task.IsCompleted := IsComplete;
    Task.UpdatedAt := NowUtc;
    
    if IsComplete then
      Task.Status := 'completed'
    else
      Task.Status := 'pending';
    
    Result := Server.Orm.Update(Task);
  finally
    Task.Free;
  end;
end;

function TTaskService.SearchTasks(const SearchTerm: RawUtf8): TVariantDynArray;
var
  Tasks: TObjectList;
  Task: TTask;
  i: integer;
  SearchPattern: RawUtf8;
begin
  SetLength(Result, 0);
  
  if SearchTerm = '' then
  begin
    Result := ListTasks('');
    exit;
  end;
  
  SearchPattern := '%' + SearchTerm + '%';
  
  Tasks := Server.Orm.RetrieveList(TTask, 
    'Title LIKE ? OR Description LIKE ?', 
    [SearchPattern, SearchPattern], 
    '');
  
  if Tasks = nil then
    exit;
  
  try
    SetLength(Result, Tasks.Count);
    for i := 0 to Tasks.Count - 1 do
    begin
      Task := TTask(Tasks[i]);
      Result[i] := TaskToVariant(Task);
    end;
  finally
    Tasks.Free;
  end;
end;

class procedure TTaskService.SelfTest(aRestServer: TRestServer);
var
  Service: ITaskService;
  TaskID: TID;
  TaskData: Variant;
  TaskList: TVariantDynArray;
  Success: boolean;
begin
  WriteLn('Running TTaskService self-test...');
  
  if not aRestServer.Services.Resolve(ITaskService, Service) then
  begin
    WriteLn('ERROR: Could not resolve ITaskService');
    exit;
  end;
  
  try
    // Test 1: Create a task
    WriteLn('  Test 1: Creating task...');
    TaskID := Service.CreateTask(
      'Test Task', 
      'This is a test task', 
      3, 
      DateTimeToIso8601(Now + 7, true)
    );
    WriteLn('    Created task with ID: ', TaskID);
    
    // Test 2: Get the task
    WriteLn('  Test 2: Retrieving task...');
    TaskData := Service.GetTask(TaskID);
    WriteLn('    Retrieved task title: ', TDocVariantData(TaskData).U['title']);
    
    // Test 3: Update the task
    WriteLn('  Test 3: Updating task...');
    Success := Service.UpdateTask(
      TaskID,
      'Updated Test Task',
      'This task has been updated',
      5,
      DateTimeToIso8601(Now + 3, true)
    );
    WriteLn('    Update result: ', Success);
    
    // Test 4: Mark as complete
    WriteLn('  Test 4: Marking task as complete...');
    Success := Service.MarkComplete(TaskID, true);
    WriteLn('    Mark complete result: ', Success);
    
    // Test 5: List all tasks
    WriteLn('  Test 5: Listing all tasks...');
    TaskList := Service.ListTasks('');
    WriteLn('    Found ', Length(TaskList), ' tasks');
    
    // Test 6: Search tasks
    WriteLn('  Test 6: Searching for "Updated"...');
    TaskList := Service.SearchTasks('Updated');
    WriteLn('    Found ', Length(TaskList), ' matching tasks');
    
    // Test 7: Delete the task
    WriteLn('  Test 7: Deleting task...');
    Success := Service.DeleteTask(TaskID);
    WriteLn('    Delete result: ', Success);
    
    WriteLn('Self-test completed successfully!');
  except
    on E: Exception do
      WriteLn('ERROR during self-test: ', E.Message);
  end;
end;

end.
