{*******************************************************}
{                                                       }
{         Delphi VCL Extensions (RX)                    }
{                                                       }
{         Copyright (c) 2001,2002 SGB Software          }
{         Copyright (c) 1997, 1998 Fedor Koshevnikov,   }
{                        Igor Pavluk and Serge Korolev  }
{                                                       }
{*******************************************************}


unit RXClock;

interface

{$I RX.INC}


uses Windows, SysUtils, Messages, Classes, Graphics, Controls,
    Forms, StdCtrls, ExtCtrls, Menus, RxTimer, RTLConsts;

type
  TShowClock = (scDigital, scAnalog);
  TPaintMode = (pmPaintAll, pmHandPaint);

  TRxClockTime = packed record
    Hour, Minute, Second: Word;
  end;

  TRxGetTimeEvent = procedure (Sender: TObject; var ATime: TDateTime) of object;

{ TRxClock }

  TRxClock = class(TCustomPanel)
  private
    { Private declarations }
    FTimer: TRxTimer;
    FAutoSize: Boolean;
    FShowMode: TShowClock;
    FTwelveHour: Boolean;
    FLeadingZero: Boolean;
    FShowSeconds: Boolean;
    FAlarm: TDateTime;
    FAlarmEnabled: Boolean;
    FHooked: Boolean;
    FDotsColor: TColor;
    FAlarmWait: Boolean;
    FDisplayTime: TRxClockTime;
    FClockRect: TRect;
    FClockRadius: Longint;
    FClockCenter: TPoint;
    FOnGetTime: TRxGetTimeEvent;
    FOnAlarm: TNotifyEvent;
    procedure TimerExpired(Sender: TObject);
    procedure GetTime(var T: TRxClockTime);
    function IsAlarmTime(ATime: TDateTime): Boolean;
    procedure SetShowMode(Value: TShowClock);
    function GetAlarmElement(Index: Integer): Byte;
    procedure SetAlarmElement(Index: Integer; Value: Byte);
    procedure SetDotsColor(Value: TColor);
    procedure SetTwelveHour(Value: Boolean);
    procedure SetLeadingZero(Value: Boolean);
    procedure SetShowSeconds(Value: Boolean);
    procedure PaintAnalogClock(PaintMode: TPaintMode);
    procedure Paint3DFrame(var Rect: TRect);
    procedure DrawAnalogFace;
    procedure CircleClock(MaxWidth, MaxHeight: Integer);
    procedure DrawSecondHand(Pos: Integer);
    procedure DrawFatHand(Pos: Integer; HourHand: Boolean);
    procedure PaintTimeStr(var Rect: TRect; FullTime: Boolean);
    procedure ResizeFont(const Rect: TRect);
    procedure ResetAlarm;
    procedure CheckAlarm;
    function FormatSettingsChange(var Message: TMessage): Boolean;
    procedure CMCtl3DChanged(var Message: TMessage); message CM_CTL3DCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMTimeChange(var Message: TMessage); message WM_TIMECHANGE;
  protected
    { Protected declarations }
    procedure SetAutoSize(Value: Boolean); override;
    procedure Alarm; dynamic;
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure CreateWnd; override;
    procedure DestroyWindowHandle; override;
    procedure Loaded; override;
    procedure Paint; override;
    function GetSystemTime: TDateTime; virtual;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetAlarmTime(AlarmTime: TDateTime);
    procedure UpdateClock;
  published
    { Published declarations }
    property AlarmEnabled: Boolean read FAlarmEnabled write FAlarmEnabled default False;
    property AlarmHour: Byte Index 1 read GetAlarmElement write SetAlarmElement default 0;
    property AlarmMinute: Byte Index 2 read GetAlarmElement write SetAlarmElement default 0;
    property AlarmSecond: Byte Index 3 read GetAlarmElement write SetAlarmElement default 0;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default False;
    property BevelInner default bvLowered;
    property BevelOuter default bvRaised;
    property DotsColor: TColor read FDotsColor write SetDotsColor default clTeal;
    property ShowMode: TShowClock read FShowMode write SetShowMode default scDigital;
    property ShowSeconds: Boolean read FShowSeconds write SetShowSeconds default True;
    property TwelveHour: Boolean read FTwelveHour write SetTwelveHour default False;
    property LeadingZero: Boolean read FLeadingZero write SetLeadingZero default True;
    property Align;
    property BevelWidth;
    property BorderWidth;
    property BorderStyle;
{$IFDEF RX_D4}
    property Anchors;
    property Constraints;
    property UseDockManager default True;
    property DockSite;
    property DragKind;
    property FullRepaint;
{$ENDIF}
    property Color;
    property Ctl3D;
    property Cursor;
    property DragMode;
    property DragCursor;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnAlarm: TNotifyEvent read FOnAlarm write FOnAlarm;
    property OnGetTime: TRxGetTimeEvent read FOnGetTime write FOnGetTime;
    property OnClick;
    property OnDblClick;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnDragOver;
    property OnDragDrop;
    property OnEndDrag;
    property OnResize;
{$IFDEF RX_D5}
    property OnContextPopup;
{$ENDIF}
{$IFDEF WIN32}
    property OnStartDrag;
{$ENDIF}
{$IFDEF RX_D4}
    property OnCanResize;
    property OnConstrainedResize;
    property OnDockDrop;
    property OnDockOver;
    property OnEndDock;
    property OnGetSiteInfo;
    property OnStartDock;
    property OnUnDock;
{$ENDIF}
  end;

implementation

uses Consts, VCLUtils;

const
  Registered: Boolean = False;

type
  PPointArray = ^TPointArray;
  TPointArray = array [0..60 * 2 - 1] of TSmallPoint;

const
  ClockData: array[0..60 * 4 - 1] of Byte = (
    $00, $00, $C1, $E0, $44, $03, $EC, $E0, $7F, $06, $6F, $E1,
    $A8, $09, $48, $E2, $B5, $0C, $74, $E3, $9F, $0F, $F0, $E4,
    $5E, $12, $B8, $E6, $E9, $14, $C7, $E8, $39, $17, $17, $EB,
    $48, $19, $A2, $ED, $10, $1B, $60, $F0, $8C, $1C, $4B, $F3,
    $B8, $1D, $58, $F6, $91, $1E, $81, $F9, $14, $1F, $BC, $FC,
    $40, $1F, $00, $00, $14, $1F, $44, $03, $91, $1E, $7F, $06,
    $B8, $1D, $A8, $09, $8C, $1C, $B5, $0C, $10, $1B, $A0, $0F,
    $48, $19, $5E, $12, $39, $17, $E9, $14, $E9, $14, $39, $17,
    $5E, $12, $48, $19, $9F, $0F, $10, $1B, $B5, $0C, $8C, $1C,
    $A8, $09, $B8, $1D, $7F, $06, $91, $1E, $44, $03, $14, $1F,
    $00, $00, $3F, $1F, $BC, $FC, $14, $1F, $81, $F9, $91, $1E,
    $58, $F6, $B8, $1D, $4B, $F3, $8C, $1C, $60, $F0, $10, $1B,
    $A2, $ED, $48, $19, $17, $EB, $39, $17, $C7, $E8, $E9, $14,
    $B8, $E6, $5E, $12, $F0, $E4, $9F, $0F, $74, $E3, $B5, $0C,
    $48, $E2, $A8, $09, $6F, $E1, $7F, $06, $EC, $E0, $44, $03,
    $C1, $E0, $00, $00, $EC, $E0, $BC, $FC, $6F, $E1, $81, $F9,
    $48, $E2, $58, $F6, $74, $E3, $4B, $F3, $F0, $E4, $60, $F0,
    $B8, $E6, $A2, $ED, $C7, $E8, $17, $EB, $17, $EB, $C7, $E8,
    $A2, $ED, $B8, $E6, $61, $F0, $F0, $E4, $4B, $F3, $74, $E3,
    $58, $F6, $48, $E2, $81, $F9, $6F, $E1, $BC, $FC, $EC, $E0);

const
  AlarmSecDelay = 60; { seconds for try alarm event after alarm time occured }
  MaxDotWidth   = 25; { maximum Hour-marking dot width  }
  MinDotWidth   = 2;  { minimum Hour-marking dot width  }
  MinDotHeight  = 1;  { minimum Hour-marking dot height }

  { distance from the center of the clock to... }
  HourSide   = 7;   { ...either side of the Hour hand   }
  MinuteSide = 5;   { ...either side of the Minute hand }
  HourTip    = 60;  { ...the tip of the Hour hand       }
  MinuteTip  = 80;  { ...the tip of the Minute hand     }
  SecondTip  = 80;  { ...the tip of the Second hand     }
  HourTail   = 15;  { ...the tail of the Hour hand      }
  MinuteTail = 20;  { ...the tail of the Minute hand    }

  { conversion factors }
  CirTabScale = 8000; { circle table values scale down value  }
  MmPerDm     = 100;  { millimeters per decimeter             }

  { number of hand positions on... }
  HandPositions = 60;                    { ...entire clock         }
  SideShift     = (HandPositions div 4); { ...90 degrees of clock  }
  TailShift     = (HandPositions div 2); { ...180 degrees of clock }

const
  // ANDRY 2019.10.29 remove warning
  SInvalidTime = '''''%s'''' is not a valid time';

var
  CircleTab: PPointArray;
  HRes: Integer;    { width of the display (in pixels)                    }
  VRes: Integer;    { height of the display (in raster lines)             }
  AspectH: Longint; { number of pixels per decimeter on the display       }
  AspectV: Longint; { number of raster lines per decimeter on the display }

{ Exception routine }

procedure InvalidTime(Hour, Min, Sec: Word);
var
  sTime: string[50];
begin
  sTime := IntToStr(Hour) + TimeSeparator + IntToStr(Min) +
    TimeSeparator + IntToStr(Sec);
  raise EConvertError.CreateFmt(ResStr(SInvalidTime), [sTime]);
end;

function VertEquiv(l: Integer): Integer;
begin
  VertEquiv := Longint(l) * AspectV div AspectH;
end;

function HorzEquiv(l: Integer): Integer;
begin
  HorzEquiv := Longint(l) * AspectH div AspectV;
end;

function LightColor(Color: TColor): TColor;
var
  L: Longint;
  C: array[1..3] of Byte;
  I: Byte;
begin
  L := ColorToRGB(Color);
  C[1] := GetRValue(L); C[2] := GetGValue(L); C[3] := GetBValue(L);
  for I := 1 to 3 do begin
    if C[I] = $FF then begin
      Result := clBtnHighlight;
      Exit;
    end;
    if C[I] <> 0 then
      if C[I] = $C0 then C[I] := $FF
      else C[I] := C[I] + $7F;
  end;
  Result := TColor(RGB(C[1], C[2], C[3]));
end;

procedure ClockInit;
var
  Pos: Integer;   { hand position Index into the circle table }
  vSize: Integer; { height of the display in millimeters      }
  hSize: Integer; { width of the display in millimeters       }
  DC: HDC;
begin
  DC := GetDC(0);
  try
    VRes := GetDeviceCaps(DC, VERTRES);
    HRes := GetDeviceCaps(DC, HORZRES);
    vSize := GetDeviceCaps(DC, VERTSIZE);
    hSize := GetDeviceCaps(DC, HORZSIZE);
  finally
    ReleaseDC(0, DC);
  end;
  AspectV := (Longint(VRes) * MmPerDm) div Longint(vSize);
  AspectH := (Longint(HRes) * MmPerDm) div Longint(hSize);
  CircleTab := PPointArray(@ClockData);
  for Pos := 0 to HandPositions - 1 do
    CircleTab^[Pos].Y := VertEquiv(CircleTab^[Pos].Y);
end;

function HourHandPos(T: TRxClockTime): Integer;
begin
  Result := (T.Hour * 5) + (T.Minute div 12);
end;

{ Digital clock font routine }

procedure SetNewFontSize(Canvas: TCanvas; const Text: string;
  MaxH, MaxW: Integer);
const
  fHeight = 1000;
var
  Font: TFont;
  NewH: Integer;
begin
  Font := Canvas.Font;
  { empiric calculate character height by cell height }
  MaxH := MulDiv(MaxH, 4, 5);
  with Font do begin
    Height := -fHeight;
    NewH := MulDiv(fHeight, MaxW, Canvas.TextWidth(Text));
    if NewH > MaxH then NewH := MaxH;
    Height := -NewH;
  end;
end;

{ TRxClock }

constructor TRxClock.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if not Registered then begin
    ClockInit;
    Registered := True;
  end;
  Caption := TimeToStr(Time);
  ControlStyle := ControlStyle - [csSetCaption] 
    {$IFDEF WIN32} - [csReplicatable] {$ENDIF};
  BevelInner := bvLowered;
  BevelOuter := bvRaised;
  FTimer := TRxTimer.Create(Self);
  FTimer.Interval := 450; { every second }
  FTimer.OnTimer := TimerExpired;
  FDotsColor := clTeal;
  FShowSeconds := True;
  FLeadingZero := True;
  GetTime(FDisplayTime);
  if FDisplayTime.Hour >= 12 then Dec(FDisplayTime.Hour, 12);
  FAlarmWait := True;
  FAlarm := EncodeTime(0, 0, 0, 0);
end;

destructor TRxClock.Destroy;
begin
  if FHooked then begin
    Application.UnhookMainWindow(FormatSettingsChange);
    FHooked := False;
  end;
  inherited Destroy;
end;

procedure TRxClock.Loaded;
begin
  inherited Loaded;
  ResetAlarm;
end;

procedure TRxClock.CreateWnd;
begin
  inherited CreateWnd;
  if not (csDesigning in ComponentState) and not (IsLibrary or FHooked) then
  begin
    Application.HookMainWindow(FormatSettingsChange);
    FHooked := True;
  end;
end;

procedure TRxClock.DestroyWindowHandle;
begin
  if FHooked then begin
    Application.UnhookMainWindow(FormatSettingsChange);
    FHooked := False;
  end;
  inherited DestroyWindowHandle;
end;

procedure TRxClock.CMCtl3DChanged(var Message: TMessage);
begin
  inherited;
  if ShowMode = scAnalog then Invalidate;
end;

procedure TRxClock.CMTextChanged(var Message: TMessage);
begin
  { Skip this message, no repaint }
end;

procedure TRxClock.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
  if AutoSize then Realign;
end;

procedure TRxClock.WMTimeChange(var Message: TMessage);
begin
  inherited;
  Invalidate;
  CheckAlarm;
end;

function TRxClock.FormatSettingsChange(var Message: TMessage): Boolean;
begin
  Result := False;
  case Message.Msg of
    WM_WININICHANGE:
      begin
        Invalidate;
        if AutoSize then Realign;
      end;
  end;
end;

function TRxClock.GetSystemTime: TDateTime;
begin
  Result := SysUtils.Time;
  if Assigned(FOnGetTime) then FOnGetTime(Self, Result);
end;

procedure TRxClock.GetTime(var T: TRxClockTime);
var
  MSec: Word;
begin
  with T do
    DecodeTime(GetSystemTime, Hour, Minute, Second, MSec);
end;

procedure TRxClock.UpdateClock;
begin
  Invalidate;
  if AutoSize then Realign;
  Update;
end;

procedure TRxClock.ResetAlarm;
begin
  FAlarmWait := (FAlarm > GetSystemTime) or (FAlarm = 0);
end;

function TRxClock.IsAlarmTime(ATime: TDateTime): Boolean;
var
  Hour, Min, Sec, MSec: Word;
  AHour, AMin, ASec: Word;
begin
  DecodeTime(FAlarm, Hour, Min, Sec, MSec);
  DecodeTime(ATime, AHour, AMin, ASec, MSec);
  Result := {FAlarmWait and} (Hour = AHour) and (Min = AMin) and
    (ASec >= Sec) and (ASec <= Sec + AlarmSecDelay);
end;

procedure TRxClock.ResizeFont(const Rect: TRect);
var
  H, W: Integer;
  DC: HDC;
  TimeStr: string;
begin
  H := Rect.Bottom - Rect.Top - 4;
  W := (Rect.Right - Rect.Left - 30);
  if (H <= 0) or (W <= 0) then Exit;
  DC := GetDC(0);
  try
    Canvas.Handle := DC;
    Canvas.Font := Font;
    TimeStr := '88888';
    if FShowSeconds then TimeStr := TimeStr + '888';
    if FTwelveHour then begin
      if Canvas.TextWidth(TimeAMString) > Canvas.TextWidth(TimePMString) then
        TimeStr := TimeStr + ' ' + TimeAMString
      else TimeStr := TimeStr + ' ' + TimePMString;
    end;
    SetNewFontSize(Canvas, TimeStr, H, W);
    Font := Canvas.Font;
  finally
    Canvas.Handle := 0;
    ReleaseDC(0, DC);
  end;
end;

procedure TRxClock.AlignControls(AControl: TControl; var Rect: TRect);
{$IFDEF RX_D4}
var
  InflateWidth: Integer;
{$ENDIF}
begin
  inherited AlignControls(AControl, Rect);
  FClockRect := Rect;
{$IFDEF RX_D4}
  InflateWidth := BorderWidth + 1;
  if BevelOuter <> bvNone then Inc(InflateWidth, BevelWidth);
  if BevelInner <> bvNone then Inc(InflateWidth, BevelWidth);
  InflateRect(FClockRect, -InflateWidth, -InflateWidth);
{$ENDIF}
  with FClockRect do CircleClock(Right - Left, Bottom - Top);
  if AutoSize then ResizeFont(Rect);
end;

procedure TRxClock.Alarm;
begin
  if Assigned(FOnAlarm) then FOnAlarm(Self);
end;

procedure TRxClock.SetAutoSize(Value: Boolean);
begin
  inherited SetAutoSize(Value);
  FAutoSize := Value;
  if FAutoSize then begin
    Invalidate;
    Realign;
  end;
end;

procedure TRxClock.SetTwelveHour(Value: Boolean);
begin
  if FTwelveHour <> Value then begin
    FTwelveHour := Value;
    Invalidate;
    if AutoSize then Realign;
  end;
end;

procedure TRxClock.SetLeadingZero(Value: Boolean);
begin
  if FLeadingZero <> Value then begin
    FLeadingZero := Value;
    Invalidate;
  end;
end;

procedure TRxClock.SetShowSeconds(Value: Boolean);
begin
  if FShowSeconds <> Value then begin
    {if FShowSeconds and (ShowMode = scAnalog) then
      DrawSecondHand(FDisplayTime.Second);}
    FShowSeconds := Value;
    Invalidate;
    if AutoSize then Realign;
  end;
end;

procedure TRxClock.SetDotsColor(Value: TColor);
begin
  if Value <> FDotsColor then begin
    FDotsColor := Value;
    Invalidate;
  end;
end;

procedure TRxClock.SetShowMode(Value: TShowClock);
begin
  if FShowMode <> Value then begin
    FShowMode := Value;
    Invalidate;
  end;
end;

function TRxClock.GetAlarmElement(Index: Integer): Byte;
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(FAlarm, Hour, Min, Sec, MSec);
  case Index of
    1: Result := Hour;
    2: Result := Min;
    3: Result := Sec;
    else Result := 0;
  end;
end;

procedure TRxClock.SetAlarmElement(Index: Integer; Value: Byte);
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(FAlarm, Hour, Min, Sec, MSec);
  case Index of
    1: Hour := Value;
    2: Min := Value;
    3: Sec := Value;
    else Exit;
  end;
  if (Hour < 24) and (Min < 60) and (Sec < 60) then begin
    FAlarm := EncodeTime(Hour, Min, Sec, 0);
    ResetAlarm;
  end
  else InvalidTime(Hour, Min, Sec);
end;

procedure TRxClock.SetAlarmTime(AlarmTime: TDateTime);
var
  Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(FAlarm, Hour, Min, Sec, MSec);
  if (Hour < 24) and (Min < 60) and (Sec < 60) then begin
    FAlarm := Frac(AlarmTime);
    ResetAlarm;
  end
  else InvalidTime(Hour, Min, Sec);
end;

procedure TRxClock.TimerExpired(Sender: TObject);
var
  DC: HDC;
  Rect: TRect;
  InflateWidth: Integer;
begin
  DC := GetDC(Handle);
  try
    Canvas.Handle := DC;
    Canvas.Brush.Color := Color;
    Canvas.Font := Font;
    Canvas.Pen.Color := Font.Color;
    if FShowMode = scAnalog then PaintAnalogClock(pmHandPaint)
    else begin
      Rect := GetClientRect;
      InflateWidth := BorderWidth;
      if BevelOuter <> bvNone then Inc(InflateWidth, BevelWidth);
      if BevelInner <> bvNone then Inc(InflateWidth, BevelWidth);
      InflateRect(Rect, -InflateWidth, -InflateWidth);
      PaintTimeStr(Rect, False);
    end;
  finally
    Canvas.Handle := 0;
    ReleaseDC(Handle, DC);
  end;
  CheckAlarm;
end;

procedure TRxClock.CheckAlarm;
begin
  if FAlarmEnabled and IsAlarmTime(GetSystemTime) then begin
    if FAlarmWait then begin
      FAlarmWait := False;
      Alarm;
    end;
  end
  else ResetAlarm;
end;

procedure TRxClock.DrawAnalogFace;
var
  Pos, DotHeight, DotWidth: Integer;
  DotCenter: TPoint;
  R: TRect;
  SaveBrush, SavePen: TColor;
  MinDots: Boolean;
begin
  DotWidth := (MaxDotWidth * Longint(FClockRect.Right - FClockRect.Left)) div HRes;
  DotHeight := VertEquiv(DotWidth);
  if DotHeight < MinDotHeight then DotHeight := MinDotHeight;
  if DotWidth < MinDotWidth then DotWidth := MinDotWidth;
  DotCenter.X := DotWidth div 2;
  DotCenter.Y := DotHeight div 2;
  InflateRect(FClockRect, -DotCenter.Y, -DotCenter.X);
  FClockRadius := ((FClockRect.Right - FClockRect.Left) div 2);
  FClockCenter.X := FClockRect.Left + FClockRadius;
  FClockCenter.Y := FClockRect.Top + ((FClockRect.Bottom - FClockRect.Top) div 2);
  InflateRect(FClockRect, DotCenter.Y, DotCenter.X);
  SaveBrush := Canvas.Brush.Color;
  SavePen := Canvas.Pen.Color;
  try
    Canvas.Brush.Color := Canvas.Pen.Color;
    MinDots := ((DotWidth > MinDotWidth) and (DotHeight > MinDotHeight));
    for Pos := 0 to HandPositions - 1 do begin
      R.Top := (CircleTab^[Pos].Y * FClockRadius) div CirTabScale + FClockCenter.Y;
      R.Left := (CircleTab^[Pos].X * FClockRadius) div CirTabScale + FClockCenter.X;
      if (Pos mod 5) <> 0 then begin
        if MinDots then begin
          if Ctl3D then begin
            Canvas.Brush.Color := clBtnShadow;
            OffsetRect(R, -1, -1);
            R.Right := R.Left + 2;
            R.Bottom := R.Top + 2;
            Canvas.FillRect(R);
            Canvas.Brush.Color := clBtnHighlight;
            OffsetRect(R, 1, 1);
            Canvas.FillRect(R);
            Canvas.Brush.Color := Self.Color;
          end;
          R.Right := R.Left + 1;
          R.Bottom := R.Top + 1;
          Canvas.FillRect(R);
        end;
      end
      else begin
        R.Right := R.Left + DotWidth;
        R.Bottom := R.Top + DotHeight;
        OffsetRect(R, -DotCenter.X, -DotCenter.Y);
        if Ctl3D and MinDots then
          with Canvas do begin
            Brush.Color := FDotsColor;
            Brush.Style := bsSolid;
            FillRect(R);
            Frame3D(Canvas, R, LightColor(FDotsColor), clWindowFrame, 1);
          end;
        Canvas.Brush.Color := Canvas.Pen.Color;
        if not (Ctl3D and MinDots) then Canvas.FillRect(R);
      end;
    end;
  finally
    Canvas.Brush.Color := SaveBrush;
    Canvas.Pen.Color := SavePen;
  end;
end;

procedure TRxClock.CircleClock(MaxWidth, MaxHeight: Integer);
var
  ClockHeight: Integer;
  ClockWidth: Integer;
begin
  if MaxWidth > HorzEquiv(MaxHeight) then begin
    ClockWidth := HorzEquiv(MaxHeight);
    FClockRect.Left := FClockRect.Left + ((MaxWidth - ClockWidth) div 2);
    FClockRect.Right := FClockRect.Left + ClockWidth;
  end
  else begin
    ClockHeight := VertEquiv(MaxWidth);
    FClockRect.Top := FClockRect.Top + ((MaxHeight - ClockHeight) div 2);
    FClockRect.Bottom := FClockRect.Top + ClockHeight;
  end;
end;

procedure TRxClock.DrawSecondHand(Pos: Integer);
var
  Radius: Longint;
  SaveMode: TPenMode;
begin
  Radius := (FClockRadius * SecondTip) div 100;
  SaveMode := Canvas.Pen.Mode;
  Canvas.Pen.Mode := pmNot;
  try
    Canvas.MoveTo(FClockCenter.X, FClockCenter.Y);
    Canvas.LineTo(FClockCenter.X + ((CircleTab^[Pos].X * Radius) div
      CirTabScale), FClockCenter.Y + ((CircleTab^[Pos].Y * Radius) div
      CirTabScale));
  finally
    Canvas.Pen.Mode := SaveMode;
  end;
end;

procedure TRxClock.DrawFatHand(Pos: Integer; HourHand: Boolean);
var
  ptSide, ptTail, ptTip: TPoint;
  Index, Hand: Integer;
  Scale: Longint;
  SaveMode: TPenMode;
begin
  if HourHand then Hand := HourSide else Hand := MinuteSide;
  Scale := (FClockRadius * Hand) div 100;
  Index := (Pos + SideShift) mod HandPositions;
  ptSide.Y := (CircleTab^[Index].Y * Scale) div CirTabScale;
  ptSide.X := (CircleTab^[Index].X * Scale) div CirTabScale;
  if HourHand then Hand := HourTip else Hand := MinuteTip;
  Scale := (FClockRadius * Hand) div 100;
  ptTip.Y := (CircleTab^[Pos].Y * Scale) div CirTabScale;
  ptTip.X := (CircleTab^[Pos].X * Scale) div CirTabScale;
  if HourHand then Hand := HourTail else Hand := MinuteTail;
  Scale := (FClockRadius * Hand) div 100;
  Index := (Pos + TailShift) mod HandPositions;
  ptTail.Y := (CircleTab^[Index].Y * Scale) div CirTabScale;
  ptTail.X := (CircleTab^[Index].X * Scale) div CirTabScale;
  with Canvas do begin
    SaveMode := Pen.Mode;
    Pen.Mode := pmCopy;
    try
      MoveTo(FClockCenter.X + ptSide.X, FClockCenter.Y + ptSide.Y);
      LineTo(FClockCenter.X + ptTip.X, FClockCenter.Y + ptTip.Y);
      MoveTo(FClockCenter.X - ptSide.X, FClockCenter.Y - ptSide.Y);
      LineTo(FClockCenter.X + ptTip.X, FClockCenter.Y + ptTip.Y);
      MoveTo(FClockCenter.X + ptSide.X, FClockCenter.Y + ptSide.Y);
      LineTo(FClockCenter.X + ptTail.X, FClockCenter.Y + ptTail.Y);
      MoveTo(FClockCenter.X - ptSide.X, FClockCenter.Y - ptSide.Y);
      LineTo(FClockCenter.X + ptTail.X, FClockCenter.Y + ptTail.Y);
    finally
      Pen.Mode := SaveMode;
    end;
  end;
end;

procedure TRxClock.PaintAnalogClock(PaintMode: TPaintMode);
var
  NewTime: TRxClockTime;
begin
  Canvas.Pen.Color := Font.Color;
  Canvas.Brush.Color := Color;
  SetBkMode(Canvas.Handle, TRANSPARENT);
  if PaintMode = pmPaintAll then begin
    with Canvas do begin
      FillRect(FClockRect);
      Pen.Color := Self.Font.Color;
      DrawAnalogFace;
      DrawFatHand(HourHandPos(FDisplayTime), True);
      DrawFatHand(FDisplayTime.Minute, False);
      Pen.Color := Brush.Color;
      if ShowSeconds then DrawSecondHand(FDisplayTime.Second);
    end;
  end
  else begin
    with Canvas do begin
      Pen.Color := Brush.Color;
      GetTime(NewTime);
      if NewTime.Hour >= 12 then Dec(NewTime.Hour, 12);
      if (NewTime.Second <> FDisplayTime.Second) then
        if ShowSeconds then DrawSecondHand(FDisplayTime.Second);
      if ((NewTime.Minute <> FDisplayTime.Minute) or
        (NewTime.Hour <> FDisplayTime.Hour)) then
      begin
        DrawFatHand(FDisplayTime.Minute, False);
        DrawFatHand(HourHandPos(FDisplayTime), True);
        Pen.Color := Self.Font.Color;
        DrawFatHand(NewTime.Minute, False);
        DrawFatHand(HourHandPos(NewTime), True);
      end;
      Pen.Color := Brush.Color;
      if (NewTime.Second <> FDisplayTime.Second) then begin
        if ShowSeconds then DrawSecondHand(NewTime.Second);
        FDisplayTime := NewTime;
      end;
    end;
  end;
end;

procedure TRxClock.PaintTimeStr(var Rect: TRect; FullTime: Boolean);
var
  FontHeight, FontWidth, FullWidth, I, L, H: Integer;
  TimeStr, SAmPm: string;
  NewTime: TRxClockTime;

  function IsPartSym(Idx, Num: Byte): Boolean;
  var
    TwoSymHour: Boolean;
  begin
    TwoSymHour := (H >= 10) or FLeadingZero;
    case Idx of
      1: begin {hours}
           Result := True;
         end;
      2: begin {minutes}
           if TwoSymHour then Result := (Num in [4, 5])
           else Result := (Num in [3, 4]);
         end;
      3: begin {seconds}
           if TwoSymHour then Result := FShowSeconds and (Num in [7, 8])
           else Result := FShowSeconds and (Num in [6, 7]);
         end;
      else Result := False;
    end;
  end;

  procedure DrawSym(Sym: Char; Num: Byte);
  begin
    if FullTime or
      ((NewTime.Second <> FDisplayTime.Second) and IsPartSym(3, Num)) or
      ((NewTime.Minute <> FDisplayTime.Minute) and IsPartSym(2, Num)) or
      (NewTime.Hour <> FDisplayTime.Hour) then
    begin
      Canvas.FillRect(Rect);
      DrawText(Canvas.Handle, @Sym, 1, Rect, DT_EXPANDTABS or
        DT_VCENTER or DT_CENTER or DT_NOCLIP or DT_SINGLELINE);
    end;
  end;

begin
  GetTime(NewTime);
  H := NewTime.Hour;
  if NewTime.Hour >= 12 then Dec(NewTime.Hour, 12);
  if FTwelveHour then begin
    if H > 12 then Dec(H, 12) else if H = 0 then H := 12;
  end;
  if (not FullTime) and (NewTime.Hour <> FDisplayTime.Hour) then begin
    Repaint;
    Exit;
  end;
  if FLeadingZero then TimeStr := 'hh:mm' else TimeStr := 'h:mm';
  if FShowSeconds then TimeStr := TimeStr + ':ss';
  if FTwelveHour then TimeStr := TimeStr + ' ampm';
  with NewTime do
    TimeStr := FormatDateTime(TimeStr, GetSystemTime);
  if (H >= 10) or FLeadingZero then L := 5 else L := 4;
  if FShowSeconds then Inc(L, 3);
  SAmPm := Copy(TimeStr, L + 1, MaxInt);
  with Canvas do begin
    Font := Self.Font;
    FontHeight := TextHeight('8');
    FontWidth := TextWidth('8');
    FullWidth := TextWidth(SAmPm) + (L * FontWidth);
    with Rect do begin
      Left := ((Right + Left) - FullWidth) div 2 {shr 1};
      Right := Left + FullWidth;
      Top := ((Bottom + Top) - FontHeight) div 2 {shr 1};
      Bottom := Top + FontHeight;
    end;
    Brush.Color := Color;
    for I := 1 to L do begin
      Rect.Right := Rect.Left + FontWidth;
      DrawSym(TimeStr[I], I);
      Inc(Rect.Left, FontWidth);
    end;
    if FullTime or (NewTime.Hour <> FDisplayTime.Hour) then begin
      Rect.Right := Rect.Left + TextWidth(SAmPm);
      DrawText(Handle, @SAmPm[1], Length(SAmPm), Rect,
        DT_EXPANDTABS or DT_VCENTER or DT_NOCLIP or DT_SINGLELINE);
    end;
  end;
  FDisplayTime := NewTime;
end;

procedure TRxClock.Paint3DFrame(var Rect: TRect);
var
  TopColor, BottomColor: TColor;

  procedure AdjustColors(Bevel: TPanelBevel);
  begin
    TopColor := clBtnHighlight;
    if Bevel = bvLowered then TopColor := clBtnShadow;
    BottomColor := clBtnShadow;
    if Bevel = bvLowered then BottomColor := clBtnHighlight;
  end;

begin
  Rect := GetClientRect;
  with Canvas do begin
    Brush.Color := Color;
    FillRect(Rect);
  end;
  if BevelOuter <> bvNone then begin
    AdjustColors(BevelOuter);
    Frame3D(Canvas, Rect, TopColor, BottomColor, BevelWidth);
  end;
  InflateRect(Rect, -BorderWidth, -BorderWidth);
  if BevelInner <> bvNone then begin
    AdjustColors(BevelInner);
    Frame3D(Canvas, Rect, TopColor, BottomColor, BevelWidth);
  end;
end;

procedure TRxClock.Paint;
var
  R: TRect;
begin
  Paint3DFrame(R);
  case FShowMode of
    scDigital: PaintTimeStr(R, True);
    scAnalog: PaintAnalogClock(pmPaintAll);
  end;
end;

end.