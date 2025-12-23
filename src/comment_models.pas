
unit comment_models;

{$mode objfpc}{$H+}

interface

uses
  mormot.core.base,
  mormot.core.data,
  mormot.orm.core;

type
  { TComment - Represents a comment/note on a task
    This class provides the ORM model for task comments, allowing users
    to add timestamped notes and discussions to tasks. }
  TComment = class(TOrm)
  private
    fTaskID: TID;
    fContent: RawUtf8;
    fAuthor: RawUtf8;
    fCreatedAt: TDateTime;
    fUpdatedAt: TDateTime;
    fIsEdited: boolean;
  published
    { The ID of the task this comment belongs to }
    property TaskID: TID read fTaskID write fTaskID;
    
    { The content/text of the comment }
    property Content: RawUtf8 read fContent write fContent;
    
    { The author/creator of the comment }
    property Author: RawUtf8 read fAuthor write fAuthor;
    
    { When the comment was created }
    property CreatedAt: TDateTime read fCreatedAt write fCreatedAt;
    
    { When the comment was last updated }
    property UpdatedAt: TDateTime read fUpdatedAt write fUpdatedAt;
    
    { Whether the comment has been edited after creation }
    property IsEdited: boolean read fIsEdited write fIsEdited;
  end;

{ Helper function to validate comment content
  Returns true if the content is valid (not empty and within length limits) }
function IsValidCommentContent(const Content: RawUtf8): boolean;

{ Helper function to get the maximum allowed comment length }
function GetMaxCommentLength: integer;

implementation

uses
  SysUtils;

const
  MAX_COMMENT_LENGTH = 10000; // Maximum characters in a comment
  MIN_COMMENT_LENGTH = 1;     // Minimum characters in a comment

function IsValidCommentContent(const Content: RawUtf8): boolean;
var
  Len: integer;
begin
  Len := Length(Content);
  result := (Len >= MIN_COMMENT_LENGTH) and (Len <= MAX_COMMENT_LENGTH);
end;

function GetMaxCommentLength: integer;
begin
  result := MAX_COMMENT_LENGTH;
end;

end.
