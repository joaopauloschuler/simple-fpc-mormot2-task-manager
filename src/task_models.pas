
unit task_models;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  DateUtils,
  mormot.core.base,
  mormot.core.data,
  mormot.orm.core;

type
  /// Task entity for ORM persistence
  // Represents a single task in the task management system
  TTask = class(TOrm)
  private
    fTitle: RawUtf8;
    fDescription: RawUtf8;
    fPriority: integer;
    fDueDate: TDateTime;
    fStatus: RawUtf8;
    fIsCompleted: boolean;
    fCreatedAt: TDateTime;
    fUpdatedAt: TDateTime;
  published
    /// Task title (required)
    property Title: RawUtf8 read fTitle write fTitle;
    
    /// Task description (optional, can be empty)
    property Description: RawUtf8 read fDescription write fDescription;
    
    /// Priority level: 1=Low, 2=Medium, 3=High
    property Priority: integer read fPriority write fPriority;
    
    /// Due date for the task
    property DueDate: TDateTime read fDueDate write fDueDate;
    
    /// Current status: 'pending', 'in_progress', 'completed'
    property Status: RawUtf8 read fStatus write fStatus;
    
    /// Quick flag for completed tasks
    property IsCompleted: boolean read fIsCompleted write fIsCompleted;
    
    /// Timestamp when task was created
    property CreatedAt: TDateTime read fCreatedAt write fCreatedAt;
    
    /// Timestamp when task was last updated
    property UpdatedAt: TDateTime read fUpdatedAt write fUpdatedAt;
  end;

/// Helper function to get priority name from integer value
function GetPriorityName(Priority: integer): RawUtf8;

/// Helper function to validate task status
function IsValidStatus(const Status: RawUtf8): boolean;

/// Helper function to get default status
function GetDefaultStatus: RawUtf8;

implementation

function GetPriorityName(Priority: integer): RawUtf8;
begin
  case Priority of
    1: result := 'Low';
    2: result := 'Medium';
    3: result := 'High';
  else
    result := 'Unknown';
  end;
end;

function IsValidStatus(const Status: RawUtf8): boolean;
begin
  result := (Status = 'pending') or 
            (Status = 'in_progress') or 
            (Status = 'completed');
end;

function GetDefaultStatus: RawUtf8;
begin
  result := 'pending';
end;

end.
