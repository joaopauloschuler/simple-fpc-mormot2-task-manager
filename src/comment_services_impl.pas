
unit comment_services_impl;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  contnrs,
  mormot.core.base,
  mormot.core.data,
  mormot.core.json,
  mormot.core.variants,
  mormot.core.datetime,
  mormot.core.os,
  mormot.rest.core,
  mormot.rest.server,
  mormot.orm.core,
  mormot.soa.core,
  mormot.soa.server,
  comment_models,
  comment_services,
  task_models;

type
  { TCommentService - Implementation of the ICommentService interface
    This class provides the actual business logic for comment operations,
    including validation, database access, and error handling. }
  TCommentService = class(TInjectableObjectRest, ICommentService)
  private
    { Converts a TComment ORM object to a variant for JSON serialization }
    function CommentToVariant(Comment: TComment): Variant;
    
    { Validates that a task exists in the database }
    function TaskExists(TaskID: TID): boolean;
  public
    function CreateComment(TaskID: TID; const Content, Author: RawUtf8): TID;
    function GetComment(CommentID: TID): Variant;
    function UpdateComment(CommentID: TID; const Content: RawUtf8): boolean;
    function DeleteComment(CommentID: TID): boolean;
    function GetTaskComments(TaskID: TID): TVariantDynArray;
    function GetCommentCount(TaskID: TID): integer;
    function DeleteTaskComments(TaskID: TID): integer;
  end;

implementation

function TCommentService.CommentToVariant(Comment: TComment): Variant;
begin
  TDocVariantData(result).InitObject([
    'id', Comment.ID,
    'taskId', Comment.TaskID,
    'content', Comment.Content,
    'author', Comment.Author,
    'createdAt', DateTimeToIso8601(Comment.CreatedAt, true),
    'updatedAt', DateTimeToIso8601(Comment.UpdatedAt, true),
    'isEdited', Comment.IsEdited
  ]);
end;

function TCommentService.TaskExists(TaskID: TID): boolean;
var
  Task: TTask;
begin
  Task := TTask.Create(Server.Orm, TaskID);
  try
    result := Task.ID <> 0;
  finally
    Task.Free;
  end;
end;

function TCommentService.CreateComment(TaskID: TID; const Content, Author: RawUtf8): TID;
var
  Comment: TComment;
  CurrentTime: TDateTime;
begin
  result := 0;
  
  // Validate that the task exists
  if not TaskExists(TaskID) then
  begin
    Server.InternalLog('CreateComment: Task % not found', [TaskID], sllWarning);
    exit;
  end;
  
  // Validate comment content
  if not IsValidCommentContent(Content) then
  begin
    Server.InternalLog('CreateComment: Invalid content length', sllWarning);
    exit;
  end;
  
  // Validate author is provided
  if Length(Author) = 0 then
  begin
    Server.InternalLog('CreateComment: Author is required', sllWarning);
    exit;
  end;
  
  Comment := TComment.Create;
  try
    CurrentTime := NowUtc;
    Comment.TaskID := TaskID;
    Comment.Content := Content;
    Comment.Author := Author;
    Comment.CreatedAt := CurrentTime;
    Comment.UpdatedAt := CurrentTime;
    Comment.IsEdited := false;
    
    result := Server.Orm.Add(Comment, true);
    if result > 0 then
      Server.InternalLog('CreateComment: Created comment % for task %', 
        [result, TaskID], sllInfo);
  finally
    Comment.Free;
  end;
end;

function TCommentService.GetComment(CommentID: TID): Variant;
var
  Comment: TComment;
begin
  TDocVariantData(result).InitObject([]);
  
  Comment := TComment.Create(Server.Orm, CommentID);
  try
    if Comment.ID = 0 then
    begin
      Server.InternalLog('GetComment: Comment % not found', [CommentID], sllWarning);
      exit;
    end;
    
    result := CommentToVariant(Comment);
  finally
    Comment.Free;
  end;
end;

function TCommentService.UpdateComment(CommentID: TID; const Content: RawUtf8): boolean;
var
  Comment: TComment;
begin
  result := false;
  
  // Validate comment content
  if not IsValidCommentContent(Content) then
  begin
    Server.InternalLog('UpdateComment: Invalid content length', sllWarning);
    exit;
  end;
  
  Comment := TComment.Create(Server.Orm, CommentID);
  try
    if Comment.ID = 0 then
    begin
      Server.InternalLog('UpdateComment: Comment % not found', [CommentID], sllWarning);
      exit;
    end;
    
    // Only update if content has changed
    if Comment.Content <> Content then
    begin
      Comment.Content := Content;
      Comment.UpdatedAt := NowUtc;
      Comment.IsEdited := true;
      
      result := Server.Orm.Update(Comment);
      if result then
        Server.InternalLog('UpdateComment: Updated comment %', [CommentID], sllInfo);
    end
    else
      result := true; // No change needed, consider it successful
  finally
    Comment.Free;
  end;
end;

function TCommentService.DeleteComment(CommentID: TID): boolean;
var
  Comment: TComment;
begin
  result := false;
  
  // First verify the comment exists
  Comment := TComment.Create(Server.Orm, CommentID);
  try
    if Comment.ID = 0 then
    begin
      Server.InternalLog('DeleteComment: Comment % not found', [CommentID], sllWarning);
      exit;
    end;
  finally
    Comment.Free;
  end;
  
  // Delete the comment
  result := Server.Orm.Delete(TComment, CommentID);
  if result then
    Server.InternalLog('DeleteComment: Deleted comment %', [CommentID], sllInfo);
end;

function TCommentService.GetTaskComments(TaskID: TID): TVariantDynArray;
var
  Comments: TObjectList;
  Comment: TComment;
  i: integer;
begin
  SetLength(result, 0);
  
  // Retrieve all comments for the task, ordered by creation date
  Comments := Server.Orm.RetrieveList(TComment, 
    'TaskID=? ORDER BY CreatedAt ASC', [TaskID]);
  try
    if Comments = nil then
      exit;
      
    SetLength(result, Comments.Count);
    for i := 0 to Comments.Count - 1 do
    begin
      Comment := TComment(Comments[i]);
      result[i] := CommentToVariant(Comment);
    end;
    
    Server.InternalLog('GetTaskComments: Retrieved % comments for task %', 
      [Comments.Count, TaskID], sllInfo);
  finally
    Comments.Free;
  end;
end;

function TCommentService.GetCommentCount(TaskID: TID): integer;
var
  Comments: TObjectList;
begin
  // TableRowCount doesn't support WHERE clause easily, so use RetrieveList
  Comments := Server.Orm.RetrieveList(TComment, 'TaskID=?', [TaskID]);
  try
    if Comments = nil then
      result := 0
    else
      result := Comments.Count;
  finally
    Comments.Free;
  end;
end;

function TCommentService.DeleteTaskComments(TaskID: TID): integer;
var
  Comments: TObjectList;
  Comment: TComment;
  i: integer;
begin
  result := 0;
  
  // Retrieve all comments for the task
  Comments := Server.Orm.RetrieveList(TComment, 'TaskID=?', [TaskID]);
  try
    if Comments = nil then
      exit;
      
    // Delete each comment
    for i := 0 to Comments.Count - 1 do
    begin
      Comment := TComment(Comments[i]);
      if Server.Orm.Delete(TComment, Comment.ID) then
        Inc(result);
    end;
    
    if result > 0 then
      Server.InternalLog('DeleteTaskComments: Deleted % comments from task %', 
        [result, TaskID], sllInfo);
  finally
    Comments.Free;
  end;
end;

end.
