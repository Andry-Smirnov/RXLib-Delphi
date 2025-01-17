{*******************************************************}
{                                                       }
{         Delphi VCL Extensions (RX)                    }
{                                                       }
{         Copyright (c) 1997, 1998 Master-Bank          }
{                                                       }
{ Patched by Polaris Software                           }
{*******************************************************}

unit RxMRUList;

{$I RX.INC}
{$R-,B-}

interface

uses
  SysUtils, Classes, Menus, IniFiles{$IFNDEF VER80}, Registry{$ENDIF},
  {$IFDEF RX_D6}Types, {$ENDIF}
  RxPlacemnt;

type
  TRecentStrings = class;

{ TMRUManager }

  TGetItemEvent = procedure(Sender: TObject; var Caption: string;
    var ShortCut: TShortCut; UserData: LongInt) of object;
  TReadItemEvent = procedure(Sender: TObject; IniFile: TObject;
    const Section: string; Index: Integer; var RecentName: string;
    var UserData: LongInt) of object;
  TWriteItemEvent = procedure(Sender: TObject; IniFile: TObject;
    const Section: string; Index: Integer; const RecentName: string;
    UserData: LongInt) of object;
  TClickMenuEvent = procedure(Sender: TObject; const RecentName,
    Caption: string; UserData: LongInt) of object;

  TAccelDelimiter = (adTab, adSpace);
  TRecentMode = (rmInsert, rmAppend);

  TMRUManager = class(TComponent)
  private
    FList: TStrings;
    FItems: TList;
    FIniLink: TIniLink;
    FSeparateSize: Word;
    FAutoEnable: Boolean;
    FAutoUpdate: Boolean;
    FShowAccelChar: Boolean;
    FRemoveOnSelect: Boolean;
    FStartAccel: Cardinal;
    FAccelDelimiter: TAccelDelimiter;
    FRecentMenu: TMenuItem;
    FOnChange: TNotifyEvent;
    FOnGetItem: TGetItemEvent;
    FOnClick: TClickMenuEvent;
    FOnReadItem: TReadItemEvent;
    FOnWriteItem: TWriteItemEvent;
    procedure ListChanged(Sender: TObject);
    procedure ClearRecentMenu;
    procedure SetRecentMenu(Value: TMenuItem);
    procedure SetSeparateSize(Value: Word);
    function GetStorage: TFormPlacement;
    procedure SetStorage(Value: TFormPlacement);
    function GetCapacity: Integer;
    procedure SetCapacity(Value: Integer);
    function GetMode: TRecentMode;
    procedure SetMode(Value: TRecentMode);
    procedure SetStartAccel(Value: Cardinal);
    procedure SetShowAccelChar(Value: Boolean);
    procedure SetAccelDelimiter(Value: TAccelDelimiter);
    procedure SetAutoEnable(Value: Boolean);
    procedure AddMenuItem(Item: TMenuItem);
    procedure MenuItemClick(Sender: TObject);
    procedure IniSave(Sender: TObject);
    procedure IniLoad(Sender: TObject);
    procedure InternalLoad(Ini: TObject; const Section: string);
    procedure InternalSave(Ini: TObject; const Section: string);
  protected
    procedure Change; dynamic;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoReadItem(Ini: TObject; const Section: string;
      Index: Integer; var RecentName: string; var UserData: LongInt); dynamic;
    procedure DoWriteItem(Ini: TObject; const Section: string; Index: Integer;
      const RecentName: string; UserData: LongInt); dynamic;
    procedure GetItemData(var Caption: string; var ShortCut: TShortCut;
      UserData: LongInt); dynamic;
    procedure DoClick(const RecentName, Caption: string; UserData: LongInt); dynamic;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const RecentName: string; UserData: LongInt);
    procedure Clear;
    procedure Remove(const RecentName: string);
    procedure UpdateRecentMenu;
    {$IFNDEF VER80}
    procedure LoadFromRegistry(Ini: TRegIniFile; const Section: string);
    procedure SaveToRegistry(Ini: TRegIniFile; const Section: string);
    {$ENDIF}
    procedure LoadFromIni(Ini: TIniFile; const Section: string);
    procedure SaveToIni(Ini: TIniFile; const Section: string);
    property Strings: TStrings read FList;
  published
    property AccelDelimiter: TAccelDelimiter read FAccelDelimiter write SetAccelDelimiter default adTab;
    property AutoEnable: Boolean read FAutoEnable write SetAutoEnable default True;
    property AutoUpdate: Boolean read FAutoUpdate write FAutoUpdate default True;
    property Capacity: Integer read GetCapacity write SetCapacity default 10;
    property Mode: TRecentMode read GetMode write SetMode default rmInsert;
    property RemoveOnSelect: Boolean read FRemoveOnSelect write FRemoveOnSelect default False;
    property IniStorage: TFormPlacement read GetStorage write SetStorage;
    property SeparateSize: Word read FSeparateSize write SetSeparateSize default 0;
    property RecentMenu: TMenuItem read FRecentMenu write SetRecentMenu;
    property ShowAccelChar: Boolean read FShowAccelChar write SetShowAccelChar default True;
    property StartAccel: Cardinal read FStartAccel write SetStartAccel default 1;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick: TClickMenuEvent read FOnClick write FOnClick;
    property OnGetItemData: TGetItemEvent read FOnGetItem write FOnGetItem;
    property OnReadItem: TReadItemEvent read FOnReadItem write FOnReadItem;
    property OnWriteItem: TWriteItemEvent read FOnWriteItem write FOnWriteItem;
  end;

{ TRecentStrings }

  TRecentStrings = class(TStringList)
  private
    FMaxSize: Integer;
    FMode: TRecentMode;
    procedure SetMaxSize(Value: Integer);
  public
    constructor Create;
    function Add(const S: string): Integer; override;
    function AddObject(const S: string; AObject: TObject): Integer; override;
    procedure AddStrings(Strings: TStrings); override;
    procedure DeleteExceed;
    procedure Remove(const S: string);
    property MaxSize: Integer read FMaxSize write SetMaxSize;
    property Mode: TRecentMode read FMode write FMode;
  end;

implementation

uses
  Controls, RxMaxMin, RxAppUtils; // Polaris

const
  siRecentItem = 'Item_%d';
  siRecentData = 'User_%d';

{ TMRUManager }

constructor TMRUManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList := TRecentStrings.Create;
  FItems := TList.Create;
  TRecentStrings(FList).OnChange := ListChanged;
  FIniLink := TIniLink.Create;
  FIniLink.OnSave := IniSave;
  FIniLink.OnLoad := IniLoad;
  FAutoUpdate := True;
  FAutoEnable := True;
  FShowAccelChar := True;
  FStartAccel := 1;
end;

destructor TMRUManager.Destroy;
begin
  ClearRecentMenu;
  FIniLink.Free;
  TRecentStrings(FList).OnChange := nil;
  FList.Free;
  FItems.Free;
  FItems := nil;
  inherited Destroy;
end;

procedure TMRUManager.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = RecentMenu) and (Operation = opRemove) then
    RecentMenu := nil;
end;

procedure TMRUManager.GetItemData(var Caption: string; var ShortCut: TShortCut;
  UserData: LongInt);
begin
  if Assigned(FOnGetItem) then FOnGetItem(Self, Caption, ShortCut, UserData);
end;

procedure TMRUManager.DoClick(const RecentName, Caption: string; UserData: LongInt);
begin
  if Assigned(FOnClick) then FOnClick(Self, RecentName, Caption, UserData);
end;

procedure TMRUManager.MenuItemClick(Sender: TObject);
var
  I: Integer;
begin
  if Sender is TMenuItem then
  begin
    I := TMenuItem(Sender).Tag;
    if (I >= 0) and (I < FList.Count) then
    try
      DoClick(FList[I], TMenuItem(Sender).Caption, LongInt(FList.Objects[I]));
    finally
      if RemoveOnSelect then Remove(FList[I]);
    end;
  end;
end;

function TMRUManager.GetCapacity: Integer;
begin
  Result := TRecentStrings(FList).MaxSize;
end;

procedure TMRUManager.SetCapacity(Value: Integer);
begin
  TRecentStrings(FList).MaxSize := Value;
end;

function TMRUManager.GetMode: TRecentMode;
begin
  Result := TRecentStrings(FList).Mode;
end;

procedure TMRUManager.SetMode(Value: TRecentMode);
begin
  TRecentStrings(FList).Mode := Value;
end;

function TMRUManager.GetStorage: TFormPlacement;
begin
  Result := FIniLink.Storage;
end;

procedure TMRUManager.SetStorage(Value: TFormPlacement);
begin
  FIniLink.Storage := Value;
end;

procedure TMRUManager.SetAutoEnable(Value: Boolean);
begin
  if FAutoEnable <> Value then
  begin
    FAutoEnable := Value;
    if Assigned(FRecentMenu) and FAutoEnable then
      FRecentMenu.Enabled := FRecentMenu.Count > 0;
  end;
end;

procedure TMRUManager.SetStartAccel(Value: Cardinal);
begin
  if FStartAccel <> Value then
  begin
    FStartAccel := Value;
    if FAutoUpdate then UpdateRecentMenu;
  end;
end;

procedure TMRUManager.SetAccelDelimiter(Value: TAccelDelimiter);
begin
  if FAccelDelimiter <> Value then
  begin
    FAccelDelimiter := Value;
    if FAutoUpdate and ShowAccelChar then UpdateRecentMenu;
  end;
end;

procedure TMRUManager.SetShowAccelChar(Value: Boolean);
begin
  if FShowAccelChar <> Value then
  begin
    FShowAccelChar := Value;
    if FAutoUpdate then UpdateRecentMenu;
  end;
end;

procedure TMRUManager.Add(const RecentName: string; UserData: LongInt);
begin
  TRecentStrings(FList).AddObject(RecentName, TObject(UserData));
end;

procedure TMRUManager.Clear;
begin
  FList.Clear;
end;

procedure TMRUManager.Remove(const RecentName: string);
begin
  TRecentStrings(FList).Remove(RecentName);
end;

procedure TMRUManager.AddMenuItem(Item: TMenuItem);
begin
  if Assigned(Item) then
  begin
    FRecentMenu.Add(Item);
    FItems.Add(Item);
  end;
end;

procedure TMRUManager.UpdateRecentMenu;
const
  AccelDelimChars: array[TAccelDelimiter] of Char = (#9, ' ');
var
  I: Integer;
  L: Cardinal;
  S: string;
  C: string;
  ShortCut: TShortCut;
  Item: TMenuItem;
begin
  ClearRecentMenu;
  if Assigned(FRecentMenu) then
    begin
      if (FList.Count > 0) and (FRecentMenu.Count > 0) then
        AddMenuItem(NewLine);
      for I := 0 to FList.Count - 1 do
        begin
          if (FSeparateSize > 0) and (I > 0) and (I mod FSeparateSize = 0) then
            AddMenuItem(NewLine);
          S := FList[I];
          ShortCut := scNone;
          GetItemData(S, ShortCut, LongInt(FList.Objects[I]));
          Item := NewItem(GetShortHint(S), ShortCut, False, True,
            MenuItemClick, 0, '');
          Item.Hint := GetLongHint(S);
          if FShowAccelChar then
            begin
              L := Cardinal(I) + FStartAccel;
              if L < 10 then
                C := AnsiChar('&') + AnsiChar(Ord('0') + L)
              else if L <= (Ord('Z') + 10) then
                C := AnsiChar('&') + AnsiChar(L + Ord('A') - 10)
              else
                C := ' ';
              Item.Caption := string(C) + AccelDelimChars[FAccelDelimiter] + Item.Caption;
            end;
          Item.Tag := I;
          AddMenuItem(Item);
        end;
      if AutoEnable then
        FRecentMenu.Enabled := FRecentMenu.Count > 0;
    end;
end;

procedure TMRUManager.ClearRecentMenu;
var
  Item: TMenuItem;
begin
  while FItems.Count > 0 do
  begin
    Item := TMenuItem(FItems.Last);
    if Assigned(FRecentMenu) and (FRecentMenu.IndexOf(Item) >= 0) then
      Item.Free;
    FItems.Remove(Item);
  end;
  if Assigned(FRecentMenu) and AutoEnable then
    FRecentMenu.Enabled := FRecentMenu.Count > 0;
end;

procedure TMRUManager.SetRecentMenu(Value: TMenuItem);
begin
  ClearRecentMenu;
  FRecentMenu := Value;
  {$IFNDEF VER80}
  if Value <> nil then Value.FreeNotification(Self);
  {$ENDIF}
  UpdateRecentMenu;
end;

procedure TMRUManager.SetSeparateSize(Value: Word);
begin
  if FSeparateSize <> Value then
  begin
    FSeparateSize := Value;
    if FAutoUpdate then UpdateRecentMenu;
  end;
end;

procedure TMRUManager.ListChanged(Sender: TObject);
begin
  Change;
  if FAutoUpdate then UpdateRecentMenu;
end;

procedure TMRUManager.IniSave(Sender: TObject);
begin
  if (Name <> '') and (FIniLink.IniObject <> nil) then
    InternalSave(FIniLink.IniObject, FIniLink.RootSection +
      GetDefaultSection(Self));
end;

procedure TMRUManager.IniLoad(Sender: TObject);
begin
  if (Name <> '') and (FIniLink.IniObject <> nil) then
    InternalLoad(FIniLink.IniObject, FIniLink.RootSection +
      GetDefaultSection(Self));
end;

procedure TMRUManager.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TMRUManager.DoReadItem(Ini: TObject; const Section: string;
  Index: Integer; var RecentName: string; var UserData: LongInt);
begin
  if Assigned(FOnReadItem) then
    FOnReadItem(Self, Ini, Section, Index, RecentName, UserData)
  else
  begin
    RecentName := IniReadString(Ini, Section, Format(siRecentItem, [Index]), RecentName);
    UserData := IniReadInteger(Ini, Section, Format(siRecentData, [Index]), UserData);
  end;
end;

procedure TMRUManager.DoWriteItem(Ini: TObject; const Section: string;
  Index: Integer; const RecentName: string; UserData: LongInt);
begin
  if Assigned(FOnWriteItem) then
    FOnWriteItem(Self, Ini, Section, Index, RecentName, UserData)
  else
  begin
    IniWriteString(Ini, Section, Format(siRecentItem, [Index]), RecentName);
    if UserData = 0 then
      IniDeleteKey(Ini, Section, Format(siRecentData, [Index]))
    else
      IniWriteInteger(Ini, Section, Format(siRecentData, [Index]), UserData);
  end;
end;

procedure TMRUManager.InternalLoad(Ini: TObject; const Section: string);
var
  I: Integer;
  S: string;
  UserData: LongInt;
  AMode: TRecentMode;
begin
  AMode := Mode;
  FList.BeginUpdate;
  try
    FList.Clear;
    Mode := rmInsert;
    for I := TRecentStrings(FList).MaxSize - 1 downto 0 do
    begin
      S := '';
      UserData := 0;
      DoReadItem(Ini, Section, I, S, UserData);
      if S <> '' then Add(S, UserData);
    end;
  finally
    Mode := AMode;
    FList.EndUpdate;
  end;
end;

procedure TMRUManager.InternalSave(Ini: TObject; const Section: string);
var
  I: Integer;
begin
  IniEraseSection(Ini, Section);
  for I := 0 to FList.Count - 1 do
    DoWriteItem(Ini, Section, I, FList[I], LongInt(FList.Objects[I]));
end;

{$IFNDEF VER80}

procedure TMRUManager.LoadFromRegistry(Ini: TRegIniFile; const Section: string);
begin
  InternalLoad(Ini, Section);
end;

procedure TMRUManager.SaveToRegistry(Ini: TRegIniFile; const Section: string);
begin
  InternalSave(Ini, Section);
end;
{$ENDIF}

procedure TMRUManager.LoadFromIni(Ini: TIniFile; const Section: string);
begin
  InternalLoad(Ini, Section);
end;

procedure TMRUManager.SaveToIni(Ini: TIniFile; const Section: string);
begin
  InternalSave(Ini, Section);
end;

{ TRecentStrings }

constructor TRecentStrings.Create;
begin
  inherited Create;
  FMaxSize := 10;
  FMode := rmInsert;
end;

procedure TRecentStrings.SetMaxSize(Value: Integer);
begin
  if FMaxSize <> Value then
  begin
    FMaxSize := Max(1, Value);
    DeleteExceed;
  end;
end;

procedure TRecentStrings.DeleteExceed;
var
  I: Integer;
begin
  BeginUpdate;
  try
    if FMode = rmInsert then
    begin
      for I := Count - 1 downto FMaxSize do
        Delete(I);
    end
    else
    begin { rmAppend }
      while Count > FMaxSize do
        Delete(0);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TRecentStrings.Remove(const S: string);
var
  I: Integer;
begin
  I := IndexOf(S);
  if I >= 0 then Delete(I);
end;

function TRecentStrings.Add(const S: string): Integer;
begin
  Result := IndexOf(S);
  if Result >= 0 then
  begin
    if FMode = rmInsert then
      Move(Result, 0)
    else { rmAppend }
      Move(Result, Count - 1);
  end
  else
  begin
    BeginUpdate;
    try
      if FMode = rmInsert then
        Insert(0, S)
      else { rmAppend }
        Insert(Count, S);
      DeleteExceed;
    finally
      EndUpdate;
    end;
  end;
  if FMode = rmInsert then
    Result := 0
  else { rmAppend }
    Result := Count - 1;
end;

function TRecentStrings.AddObject(const S: string; AObject: TObject): Integer;
begin
  Result := IndexOf(S);
  if Result >= 0 then
  begin
    if FMode = rmInsert then
      Move(Result, 0)
    else { rmAppend }
      Move(Result, Count - 1);
  end
  else
  begin
    BeginUpdate;
    try
      if FMode = rmInsert then
        InsertObject(0, S, AObject)
      else { rmAppend }
        InsertObject(Count, S, AObject);
      DeleteExceed;
    finally
      EndUpdate;
    end;
  end;
  if FMode = rmInsert then
    Result := 0
  else { rmAppend }
    Result := Count - 1;
end;

procedure TRecentStrings.AddStrings(Strings: TStrings);
var
  I: Integer;
begin
  BeginUpdate;
  try
    if FMode = rmInsert then
    begin
      for I := Min(Strings.Count, FMaxSize) - 1 downto 0 do
        AddObject(Strings[I], Strings.Objects[I]);
    end
    else
    begin { rmAppend }
      for I := 0 to Min(Strings.Count, FMaxSize) - 1 do
        AddObject(Strings[I], Strings.Objects[I]);
    end;
    DeleteExceed;
  finally
    EndUpdate;
  end;
end;

end.