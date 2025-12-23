
unit tag_services;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  mormot.core.base,
  mormot.core.data,
  mormot.core.variants,
  mormot.core.json,
  mormot.core.datetime,
  mormot.core.interfaces,
  mormot.orm.core,
  mormot.rest.core,
  mormot.rest.server,
  tag_models;

type
  /// Tag Service Interface
  ITagService = interface(IInvokable)
    ['{23456789-BCDE-FABC-2345-678901BCDEF0}']
    
    /// Create a new tag
    function CreateTag(const Name, Color: RawUtf8): TID;
    
    /// Get a tag by ID
    function GetTag(TagID: TID): Variant;
    
    /// Update an existing tag
    function UpdateTag(TagID: TID; const Name, Color: RawUtf8): boolean;
    
    /// Delete a tag (and all its task associations)
    function DeleteTag(TagID: TID): boolean;
    
    /// List all tags
    function ListTags: TVariantDynArray;
    
    /// Add a tag to a task
    function AddTagToTask(TaskID: TID; TagID: TID): boolean;
    
    /// Remove a tag from a task
    function RemoveTagFromTask(TaskID: TID; TagID: TID): boolean;
    
    /// Get all tags for a specific task
    function GetTaskTags(TaskID: TID): TVariantDynArray;
    
    /// Get all tasks with a specific tag
    function GetTasksByTag(TagID: TID): TVariantDynArray;
    
    /// Search tags by name
    function SearchTags(const SearchTerm: RawUtf8): TVariantDynArray;
  end;

implementation

end.
