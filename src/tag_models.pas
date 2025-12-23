
unit tag_models;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  mormot.core.base,
  mormot.core.data,
  mormot.orm.core;

type
  /// Tag entity for categorizing tasks
  // Represents a tag/label that can be applied to tasks
  TTag = class(TOrm)
  private
    fName: RawUtf8;
    fColor: RawUtf8;
    fCreatedAt: TDateTime;
  published
    /// Tag name (unique identifier, e.g., "urgent", "work", "personal")
    property Name: RawUtf8 read fName write fName;
    
    /// Color code for display (e.g., "#FF5733" or "red")
    property Color: RawUtf8 read fColor write fColor;
    
    /// Timestamp when tag was created
    property CreatedAt: TDateTime read fCreatedAt write fCreatedAt;
  end;

  /// Junction table for many-to-many relationship between tasks and tags
  TTaskTag = class(TOrm)
  private
    fTaskID: TID;
    fTagID: TID;
    fCreatedAt: TDateTime;
  published
    /// Reference to the task
    property TaskID: TID read fTaskID write fTaskID;
    
    /// Reference to the tag
    property TagID: TID read fTagID write fTagID;
    
    /// Timestamp when this association was created
    property CreatedAt: TDateTime read fCreatedAt write fCreatedAt;
  end;

/// Helper function to validate color format (basic validation)
function IsValidColor(const Color: RawUtf8): boolean;

/// Helper function to get default color
function GetDefaultColor: RawUtf8;

implementation

function IsValidColor(const Color: RawUtf8): boolean;
begin
  // Basic validation: either a hex color (#RRGGBB) or a named color
  result := (Length(Color) > 0) and 
            ((Color[1] = '#') or (Pos('#', Color) = 0));
end;

function GetDefaultColor: RawUtf8;
begin
  result := '#3498db'; // Nice blue color
end;

end.
