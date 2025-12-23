
unit task_services;

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
  task_models;

type
  /// Task Service Interface
  ITaskService = interface(IInvokable)
    ['{12345678-ABCD-EFAB-1234-567890ABCDEF}']
    
    function CreateTask(const Title, Description: RawUtf8; 
                        Priority: integer; const DueDate: RawUtf8): TID;
    function GetTask(TaskID: TID): Variant;
    function UpdateTask(TaskID: TID; const Title, Description: RawUtf8; 
                        Priority: integer; const DueDate: RawUtf8): boolean;
    function DeleteTask(TaskID: TID): boolean;
    function ListTasks(const Status: RawUtf8): TVariantDynArray;
    function MarkComplete(TaskID: TID; IsComplete: boolean): boolean;
    function SearchTasks(const SearchTerm: RawUtf8): TVariantDynArray;
  end;

implementation

end.
