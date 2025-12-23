
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
    
    /// Self-test method for validation
    procedure SelfTest;
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
  try
    if ExistingTags.Count > 0 then
      raise EServiceException.Create('Tag with this name already exists');
  finally
    ExistingTags.Free;
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
      raise EServiceException.CreateUtf8('Tag % not found', [TagID]);
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
  
  Tag := TTag.Create(Server.Orm, TagID);
  try
    if Tag.ID = 0 then
      raise EServiceException.CreateUtf8('Tag % not found', [TagID]);
    
    // Validate input
    if Trim(Name) = '' then
      raise EServiceException.Create('Tag name cannot be empty');
    
    // Check for duplicate tag names (excluding current tag)
    ExistingTags := Server.Orm.RetrieveList(TTag, 
      'Name=? AND ID<>?', [LowerCase(Trim(Name)), TagID]);
    try
      if ExistingTags.Count > 0 then
        raise EServiceException.Create('Tag with this name already exists');
    finally
      ExistingTags.Free;
    end;
    
    // Use provided color or keep existing
    if (Color = '') or not IsValidColor(Color) then
      ActualColor := Tag.Color
    else
      ActualColor := Color;
    
    Tag.Name := LowerCase(Trim(Name));
    Tag.Color := ActualColor;
    result := Server.Orm.Update(Tag);
  finally
    Tag.Free;
  end;
end;

function TTagService.DeleteTag(TagID: TID): boolean;
var
  Tag: TTag;
begin
  result := false;
  
  // Check if tag exists
  Tag := TTag.Create(Server.Orm, TagID);
  try
    if Tag.ID = 0 then
      raise EServiceException.CreateUtf8('Tag % not found', [TagID]);
  finally
    Tag.Free;
  end;
  
  // Delete all task-tag associations first
  Server.Orm.ExecuteFmt('DELETE FROM TaskTag WHERE TagID=?', [TagID], []);
  
  // Delete the tag
  result := Server.Orm.Delete(TTag, TagID);
end;

function TTagService.ListTags: TVariantDynArray;
var
  Tags: TObjectList;
  Tag: TTag;
  i: integer;
begin
  Tags := Server.Orm.RetrieveList(TTag, '', []);
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
  Existing: TObjectList;
begin
  result := false;
  
  // Check if association already exists
  Existing := Server.Orm.RetrieveList(TTaskTag, 
    'TaskID=? AND TagID=?', [TaskID, TagID]);
  try
    if Existing.Count > 0 then
    begin
      result := true; // Already associated
      exit;
    end;
  finally
    Existing.Free;
  end;
  
  // Create new association
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
  result := Server.Orm.ExecuteFmt(
    'DELETE FROM TaskTag WHERE TaskID=? AND TagID=?', 
    [TaskID, TagID], []);
end;

function TTagService.GetTaskTags(TaskID: TID): TVariantDynArray;
var
  TaskTags: TObjectList;
  TaskTag: TTaskTag;
  Tag: TTag;
  i: integer;
begin
  TaskTags := Server.Orm.RetrieveList(TTaskTag, 'TaskID=?', [TaskID]);
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
begin
  TaskTags := Server.Orm.RetrieveList(TTaskTag, 'TagID=?', [TagID]);
  try
    SetLength(result, TaskTags.Count);
    for i := 0 to TaskTags.Count - 1 do
    begin
      TaskTag := TTaskTag(TaskTags[i]);
      TDocVariantData(result[i]).InitObject([
        'taskId', TaskTag.TaskID
      ]);
    end;
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
  if Trim(SearchTerm) = '' then
  begin
    result := ListTags;
    exit;
  end;
  
  Tags := Server.Orm.RetrieveList(TTag, 
    'Name LIKE ?', ['%' + LowerCase(Trim(SearchTerm)) + '%']);
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

procedure TTagService.SelfTest;
var
  TagID1, TagID2: TID;
  Tags: TVariantDynArray;
  TaskTags: TVariantDynArray;
begin
  WriteLn('=== Tag Service Self-Test ===');
  
  // Test 1: Create tags
  WriteLn('Test 1: Creating tags...');
  TagID1 := CreateTag('urgent', '#FF0000');
  TagID2 := CreateTag('work', '#0000FF');
  WriteLn('  Created tag IDs: ', TagID1, ', ', TagID2);
  
  // Test 2: List tags
  WriteLn('Test 2: Listing tags...');
  Tags := ListTags;
  WriteLn('  Found ', Length(Tags), ' tags');
  
  // Test 3: Search tags
  WriteLn('Test 3: Searching tags...');
  Tags := SearchTags('urg');
  WriteLn('  Search for "urg" found ', Length(Tags), ' tags');
  
  // Test 4: Add tag to task (assuming task ID 1 exists)
  WriteLn('Test 4: Adding tag to task...');
  if AddTagToTask(1, TagID1) then
    WriteLn('  Successfully added tag to task');
  
  // Test 5: Get task tags
  WriteLn('Test 5: Getting task tags...');
  TaskTags := GetTaskTags(1);
  WriteLn('  Task has ', Length(TaskTags), ' tags');
  
  WriteLn('=== Tag Service Self-Test Complete ===');
end;

end.
