unit ExceptionPluginU;


















      var AllowLoad: Boolean);






















var
   Comp : TComponent;
begin
   Comp := HostApplication.MainForm.FindComponent('Listbox1');
   if Comp <> nil then
      TListBox(Comp).Items.Add(e.message);
end;

procedure TuilPlugin1.uilPlugin1Initialize(Sender: TObject;
  var AllowLoad: Boolean);
var
   Comp : TComponent;
begin
   HostApplication.OnException := ExceptionHandler;
   Comp := HostApplication.MainForm.FindComponent('StatusBar1');
   if Comp <> nil then
      TStatusBar(Comp).SimpleText := 'Exception Handler installed.';
end;

end.