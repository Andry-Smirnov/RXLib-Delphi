unit ChangePropertiesPluginU;

interface

uses
   Windows,
   Messages,
   SysUtils,
   Classes,
   Dialogs,
   Forms,
   Buttons,
   StdCtrls,   
   RxPlugin;

type

  TuilPlugin1 = class(TRxPlugin)
    procedure uilPlugin1Commands0Execute(Sender: TObject);
    procedure uilPlugin1Commands1Execute(Sender: TObject);
    procedure uilPlugin1Commands2Execute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function RegisterPlugin : TuilPlugin1; stdcall;

implementation

{$R *.DFM}

// IMPORTANT NOTE: If you change the name of the Plugin container,
// you must set the type below to the same type. (Delphi changes
// the declaration, but not the procedure itself. Both the return
// type and the type created must be the same as the declared type above.
function RegisterPlugin : TuilPlugin1;
begin
  Result := TuilPlugin1.Create(nil);
end;

procedure TuilPlugin1.uilPlugin1Commands0Execute(Sender: TObject);
begin
   HostApplication.MainForm.Caption := InputBox('Change Form Caption','New Caption:', HostApplication.MainForm.Caption);
end;

procedure TuilPlugin1.uilPlugin1Commands1Execute(Sender: TObject);
var
   Comp : TComponent;
begin
   Comp := HostApplication.MainForm.FindComponent('Button1');
   if assigned(Comp) then
      TButton(Comp).Enabled := not TButton(Comp).Enabled;
end;

procedure TuilPlugin1.uilPlugin1Commands2Execute(Sender: TObject);
var
   Comp : TComponent;
begin
   Comp := HostApplication.MainForm.FindComponent('Listbox1');
   if assigned(Comp) then
      TListBox(Comp).Items.Add(InputBox('Add to listbox','Item:','Enter item here'));
end;

end.