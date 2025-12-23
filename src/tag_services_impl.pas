
unit tag_services_impl;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  DateUtils,
  mormot.core.base,
  mormot.core.data,
  mormot.core.variants,
  mormot.core.json,
  mormot.core.datetime,
  mormot.core.interfaces,
  mormot.core.text,
  contnrs,
  mormot.orm.core,
  mormot.rest.core,
  mormot.rest.server,
  mormot.soa.core,
  mormot.soa.server,
  tag_models,
  tag_services;

type
  /// Implementation of the Tag Service
  TTagService = class(TInjectableObjectRest, ITagService)
  private
    function TagToVariant(Tag: TTag): Variant;
  public
    function CreateTag(const Name, Color: RawUtf8): TID;
    function GetTag(TagID: TID): Variant;
    function UpdateTag(TagID: TID; const Name, Color: RawUtf8): boolean;
    function DeleteTag(TagID: TID): boolean;
    function ListTags: TVariantDynArray;
    function AddTagToTask(TaskID: TID; TagID: TID): boolean;
    function RemoveTagFromTask(TaskID: TID; TagID: TID): boolean;
    function GetTaskTags(TaskID: TID): TVariantDynArray;
    function GetTasksByTag(TagID: TID): TVariantDynArray;
    function SearchTags(const SearchTerm: RawUtf8): TVariantDynArray;
    
    /// Self-test class method for validation
    class procedure SelfTest(aRestServer: TRestServer);
  end;

implementation

function TTagService.TagToVariant(Tag: TTag): Variant;
begin
  TDocVariantData(result).InitObject([
    'id', Tag.ID,
    'name', Tag.Name,
    'color', Tag.Color,
    'createdAt', DateTimeToIso8601(Tag.CreatedAt, true)
  ]);
end;

function TTagService.CreateTag(const Name, Color: RawUtf8): TID;
var
  Tag: TTag;
  ActualColor: RawUtf8;
  ExistingTags: TObjectList;
begin
  result := 0;
  
  // Validate input
  if Trim(Name) = '' then
    raise EServiceException.Create('Tag name cannot be empty');
  
  // Check for duplicate tag names (case-insensitive)
  ExistingTags := Server.Orm.RetrieveList(TTag, 
    'Name=?', [LowerCase(Trim(Name))]);
  if ExistingTags <> nil then
  begin
    try
      if ExistingTags.Count > 0 then
        raise EServiceException.Create('Tag with this name already exists');
    finally
      ExistingTags.Free;
    end;
  end;
  
  // Use provided color or default
  if (Color = '') or not IsValidColor(Color) then
    ActualColor := GetDefaultColor
  else
    ActualColor := Color;
  
  // Create the tag
  Tag := TTag.Create;
  try
    Tag.Name := LowerCase(Trim(Name));
    Tag.Color := ActualColor;
    Tag.CreatedAt := Now;
    result := Server.Orm.Add(Tag, true);
  finally
    Tag.Free;
  end;
end;

function TTagService.GetTag(TagID: TID): Variant;
var
  Tag: TTag;
begin
  Tag := TTag.Create(Server.Orm, TagID);
  try
    if Tag.ID = 0 then
      raise EServiceException.Create('Tag not found');
    
    result := TagToVariant(Tag);
  finally
    Tag.Free;
  end;
end;

function TTagService.UpdateTag(TagID: TID; const Name, Color: RawUtf8): boolean;
var
  Tag: TTag;
  ActualColor: RawUtf8;
  ExistingTags: TObjectList;
begin
  result := false;
  
  // Validate input
  if Trim(Name) = '' then
    raise EServiceException.Create('Tag name cannot be empty');
  
  // Load existing tag
  Tag := TTag.Create(Server.Orm, TagID);
  try
    if Tag.ID = 0 then
      raise EServiceException.Create('Tag not found');
    
    // Check for duplicate tag names (excluding current tag)
    ExistingTags := Server.Orm.RetrieveList(TTag, 
      'Name=? AND ID<>?', [LowerCase(Trim(Name)), TagID]);
    if ExistingTags <> nil then
    begin
      try
        if ExistingTags.Count > 0 then
          raise EServiceException.Create('Tag with this name already exists');
      finally
        ExistingTags.Free;
      end;
    end;
    
    // Use provided color or default
    if (Color = '') or not IsValidColor(Color) then
      ActualColor := GetDefaultColor
    else
      ActualColor := Color;
    
    // Update tag
    Tag.Name := LowerCase(Trim(Name));
    Tag.Color := ActualColor;
    
    result := Server.Orm.Update(Tag);
  finally
    Tag.Free;
  end;
end;

function TTagService.DeleteTag(TagID: TID): boolean;
var
  TaskTags: TObjectList;
begin
  result := false;
  
  // First, delete all task-tag associations
  TaskTags := Server.Orm.RetrieveList(TTaskTag, 'TagID=?', [TagID]);
  if TaskTags <> nil then
  begin
    try
      Server.Orm.Delete(TTaskTag, 'TagID=?', [TagID]);
    finally
      TaskTags.Free;
    end;
  end;
  
  // Then delete the tag itself
  result := Server.Orm.Delete(TTag, TagID);
end;

function TTagService.ListTags: TVariantDynArray;
var
  Tags: TObjectList;
  Tag: TTag;
  i: integer;
begin
  SetLength(result, 0);
  
  Tags := Server.Orm.RetrieveList(TTag, '', []);
  if Tags = nil then
    exit;
  
  try
    SetLength(result, Tags.Count);
    for i := 0 to Tags.Count - 1 do
    begin
      Tag := TTag(Tags[i]);
      result[i] := TagToVariant(Tag);
    end;
  finally
    Tags.Free;
  end;
end;

function TTagService.AddTagToTask(TaskID: TID; TagID: TID): boolean;
var
  TaskTag: TTaskTag;
  ExistingLinks: TObjectList;
begin
  result := false;
  
  // Check if link already exists
  ExistingLinks := Server.Orm.RetrieveList(TTaskTag, 
    'TaskID=? AND TagID=?', [TaskID, TagID]);
  if ExistingLinks <> nil then
  begin
    try
      if ExistingLinks.Count > 0 then
        exit; // Link already exists
    finally
      ExistingLinks.Free;
    end;
  end;
  
  // Create new task-tag link
  TaskTag := TTaskTag.Create;
  try
    TaskTag.TaskID := TaskID;
    TaskTag.TagID := TagID;
    TaskTag.CreatedAt := Now;
    result := Server.Orm.Add(TaskTag, true) > 0;
  finally
    TaskTag.Free;
  end;
end;

function TTagService.RemoveTagFromTask(TaskID: TID; TagID: TID): boolean;
begin
  result := Server.Orm.Delete(TTaskTag, 
    'TaskID=? AND TagID=?', [TaskID, TagID]);
end;

function TTagService.GetTaskTags(TaskID: TID): TVariantDynArray;
var
  TaskTags: TObjectList;
  TaskTag: TTaskTag;
  Tag: TTag;
  i: integer;
begin
  SetLength(result, 0);
  
  TaskTags := Server.Orm.RetrieveList(TTaskTag, 'TaskID=?', [TaskID]);
  if TaskTags = nil then
    exit;
  
  try
    SetLength(result, TaskTags.Count);
    for i := 0 to TaskTags.Count - 1 do
    begin
      TaskTag := TTaskTag(TaskTags[i]);
      Tag := TTag.Create(Server.Orm, TaskTag.TagID);
      try
        if Tag.ID > 0 then
          result[i] := TagToVariant(Tag);
      finally
        Tag.Free;
      end;
    end;
  finally
    TaskTags.Free;
  end;
end;

function TTagService.GetTasksByTag(TagID: TID): TVariantDynArray;
var
  TaskTags: TObjectList;
  TaskTag: TTaskTag;
  i: integer;
  TaskIDs: array of TID;
begin
  SetLength(result, 0);
  
  TaskTags := Server.Orm.RetrieveList(TTaskTag, 'TagID=?', [TagID]);
  if TaskTags = nil then
    exit;
  
  try
    SetLength(TaskIDs, TaskTags.Count);
    for i := 0 to TaskTags.Count - 1 do
    begin
      TaskTag := TTaskTag(TaskTags[i]);
      TaskIDs[i] := TaskTag.TaskID;
    end;
    
    SetLength(result, Length(TaskIDs));
    for i := 0 to High(TaskIDs) do
      result[i] := TaskIDs[i];
  finally
    TaskTags.Free;
  end;
end;

function TTagService.SearchTags(const SearchTerm: RawUtf8): TVariantDynArray;
var
  Tags: TObjectList;
  Tag: TTag;
  i: integer;
begin
  SetLength(result, 0);
  
  if SearchTerm = '' then
    exit;
  
  Tags := Server.Orm.RetrieveList(TTag, 
    'Name LIKE ?', ['%' + LowerCase(SearchTerm) + '%']);
  if Tags = nil then
    exit;
  
  try
    SetLength(result, Tags.Count);
    for i := 0 to Tags.Count - 1 do
    begin
      Tag := TTag(Tags[i]);
      result[i] := TagToVariant(Tag);
    end;
  finally
    Tags.Free;
  end;
end;

class procedure TTagService.SelfTest(aRestServer: TRestServer);
var
  Service: ITagService;
  TagID1, TagID2: TID;
  Tags: TVariantDynArray;
  TaskTags: TVariantDynArray;
  Success: boolean;
begin
  WriteLn('Running TTagService self-test...');
  
  if not aRestServer.Services.Resolve(ITagService, Service) then
  begin
    WriteLn('ERROR: Could not resolve ITagService');
    exit;
  end;
  
  try
    // Test 1: Create tags
    WriteLn('  Test 1: Creating tags...');
    TagID1 := Service.CreateTag('urgent', '#FF0000');
    TagID2 := Service.CreateTag('work', '#0000FF');
    WriteLn('    Created tag IDs: ', TagID1, ', ', TagID2);
    
    // Test 2: List tags
    WriteLn('  Test 2: Listing tags...');
    Tags := Service.ListTags;
    WriteLn('    Found ', Length(Tags), ' tags');
    
    // Test 3: Search tags
    WriteLn('  Test 3: Searching tags...');
    Tags := Service.SearchTags('urg');
    WriteLn('    Search for "urg" found ', Length(Tags), ' tags');
    
    // Test 4: Add tag to task (assuming task ID 1 exists)
    WriteLn('  Test 4: Adding tag to task...');
    Success := Service.AddTagToTask(1, TagID1);
    if Success then
      WriteLn('    Successfully added tag to task')
    else
      WriteLn('    Failed to add tag to task');
    
    // Test 5: Get task tags
    WriteLn('  Test 5: Getting task tags...');
    TaskTags := Service.GetTaskTags(1);
    WriteLn('    Task has ', Length(TaskTags), ' tags');
    
    // Test 6: Update tag
    WriteLn('  Test 6: Updating tag...');
    Success := Service.UpdateTag(TagID1, 'urgent-updated', '#FF00FF');
    WriteLn('    Update result: ', Success);
    
    // Test 7: Delete tag
    WriteLn('  Test 7: Deleting tag...');
    Success := Service.DeleteTag(TagID2);
    WriteLn('    Delete result: ', Success);
    
    WriteLn('Self-test completed successfully!');
  except
    on E: Exception do
      WriteLn('ERROR: ', E.Message);
  end;
end;

end.
