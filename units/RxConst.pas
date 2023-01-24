{*******************************************************}
{                                                       }
{         Delphi VCL Extensions (RX)                    }
{                                                       }
{         Copyright (c) 1995, 1996 AO ROSNO             }
{         Copyright (c) 1997, 1998 Master-Bank          }
{                                                       }
{ Patched by Polaris Software                           }
{ Patched by Jaro Benes                                 }
{ Patched by Andry Smirnov, 01.2023                     }
{*******************************************************}

unit RxConst;


interface


{$I RX.INC}


uses
  Controls;


const
  RX_VERSION = $0002004B; { 2.75 }
  RX_REVISION = '2.2012'; {last visit by patches and improvements}

{ Command message for Speedbar editor }
  CM_SPEEDBARCHANGED = CM_BASE + 80;
{ Command message for TRxSpeedButton }
  CM_RXBUTTONPRESSED = CM_BASE + 81;
{ Command messages for TRxWindowHook }
  CM_RECREATEWINDOW = CM_BASE + 82;
  CM_DESTROYHOOK = CM_BASE + 83;
{ Notify message for TRxTrayIcon }
  CM_TRAYICON = CM_BASE + 84;

  crHand = TCursor(14000);
  crDragHand = TCursor(14001);

{ TBitmap.GetTransparentColor from GRAPHICS.PAS uses this value }
  PaletteMask = $02000000;

{$IFDEF VER90}
  SDelphiKey = 'Software\Borland\Delphi\2.0';
{$ENDIF}

{$IFDEF VER93}
  SDelphiKey = 'Software\Borland\C++Builder\1.0';
{$ENDIF}

{$IFDEF VER100}
  SDelphiKey = 'Software\Borland\Delphi\3.0';
{$ENDIF}

{$IFDEF VER110}
  SDelphiKey = 'Software\Borland\C++Builder\3.0';
{$ENDIF}

{$IFDEF VER120}
  SDelphiKey = 'Software\Borland\Delphi\4.0';
{$ENDIF}

{$IFDEF VER125}
  SDelphiKey = 'Software\Borland\C++Builder\4.0';
{$ENDIF}

{$IFDEF VER130}
 {$IFDEF BCB}
  SDelphiKey = 'Software\Borland\C++Builder\5.0';
 {$ELSE}
  SDelphiKey = 'Software\Borland\Delphi\5.0';
 {$ENDIF}
{$ENDIF}

{$IFDEF VER140} // Polaris
  SDelphiKey = 'Software\Borland\Delphi\6.0'; {Delphi 6}
{$ENDIF}

{$IFDEF VER150} // JB
  SDelphiKey = 'Software\Borland\Delphi\7.0'; {Delphi 7}
{$ENDIF}

{$IFDEF VER170} // JB
  SDelphiKey = 'Software\Borland\BDS\3.0'; {Delphi 2005}
{$ENDIF}

{$IFDEF VER180} // JB
 {$IFDEF VER185} // JB
  SDelphiKey = 'Software\Borland\BDS\5.0'; {Delphi 2007}
 {$ELSE}
  SDelphiKey = 'Software\Borland\BDS\4.0'; {BDS 2006}
 {$ENDIF}
{$ENDIF}

{$IFDEF VER200} // JB
  SDelphiKey = 'Software\Codegear\BDS\6.0'; {Delphi 2009}
{$ENDIF}

{$IFDEF VER210} // JB
  SDelphiKey = 'Software\Codegear\BDS\7.0'; {Delphi 2010}
{$ENDIF}

{$IFDEF VER220} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\8.0'; {Delphi XE}
{$ENDIF}

{$IFDEF VER230} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\9.0'; {Delphi XE2}
{$ENDIF}

{$IFDEF VER240} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\10.0'; {Delphi XE3}
{$ENDIF}

{$IFDEF VER250} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\11.0'; {Delphi XE4}
{$ENDIF}

{$IFDEF VER260} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\12.0'; {Delphi XE5}
{$ENDIF}

{$IFDEF VER270} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\14.0'; {Delphi XE6}
{$ENDIF}

{$IFDEF VER280} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\15.0'; {Delphi XE7}
{$ENDIF}

{$IFDEF VER290} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\16.0'; {Delphi XE8}
{$ENDIF}

{$IFDEF VER300} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\17.0'; {Delphi 10 Seattle}
{$ENDIF}  

{$IFDEF VER310} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\18.0'; {Delphi 10.1 Berlin}
{$ENDIF}

{$IFDEF VER320} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\19.0'; {Delphi 10.2 Tokyo}
{$ENDIF}

{$IFDEF VER330} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\20.0'; {Delphi 10.3 Rio}
{$ENDIF}

{$IFDEF VER340} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\21.0'; {Delphi 10.4 Sydney}
{$ENDIF}

{$IFDEF VER350} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\22.0'; {Delphi 11}
{$ENDIF}

{$IFDEF VER360} // JB
  SDelphiKey = 'Software\Embarcadero\BDS\23.0'; {Delphi 1x+}
{$ENDIF}


implementation


uses
{$IFNDEF VER80}
  Windows,
{$ELSE}
  WinProcs,
{$ENDIF}
  Forms;


{$R *.RES}


initialization
  Screen.Cursors[crHand] := LoadCursor(hInstance, 'RX_HANDCUR');
  Screen.Cursors[crDragHand] := LoadCursor(hInstance, 'RX_DRAGCUR');


end.

