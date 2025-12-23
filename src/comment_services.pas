
unit comment_services;

{$mode objfpc}{$H+}

interface

uses
  mormot.core.base,
  mormot.core.interfaces;

type
  { ICommentService - Service interface for managing task comments
    This interface defines the business logic operations for creating,
    retrieving, updating, and deleting comments on tasks. }
  ICommentService = interface(IInvokable)
    ['{B8F3A2C1-9D4E-4F2A-8C7B-1E6D5A9F3B2C}']
    
    { Creates a new comment on a task
      @param TaskID The ID of the task to comment on
      @param Content The text content of the comment
      @param Author The name/identifier of the comment author
      @returns The ID of the newly created comment, or 0 on failure }
    function CreateComment(TaskID: TID; const Content, Author: RawUtf8): TID;
    
    { Retrieves a specific comment by ID
      @param CommentID The ID of the comment to retrieve
      @returns A variant containing the comment data, or null if not found }
    function GetComment(CommentID: TID): Variant;
    
    { Updates an existing comment's content
      @param CommentID The ID of the comment to update
      @param Content The new content for the comment
      @returns True if the update was successful, false otherwise }
    function UpdateComment(CommentID: TID; const Content: RawUtf8): boolean;
    
    { Deletes a comment
      @param CommentID The ID of the comment to delete
      @returns True if the deletion was successful, false otherwise }
    function DeleteComment(CommentID: TID): boolean;
    
    { Lists all comments for a specific task
      @param TaskID The ID of the task
      @returns An array of variants containing the comments, ordered by creation date }
    function GetTaskComments(TaskID: TID): TVariantDynArray;
    
    { Counts the number of comments on a task
      @param TaskID The ID of the task
      @returns The number of comments on the task }
    function GetCommentCount(TaskID: TID): integer;
    
    { Deletes all comments for a specific task
      @param TaskID The ID of the task
      @returns The number of comments deleted }
    function DeleteTaskComments(TaskID: TID): integer;
  end;

implementation

end.
