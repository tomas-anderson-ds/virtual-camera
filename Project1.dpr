program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  RegIni,
  Winapi.Windows,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

var
   RegistryIni: TRegIni;

begin
  GlobalUseDX := True;
  GlobalUseDXSoftware := False;
  GlobalDisableFocusEffect := True;

  if RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'PerformanceMode', 0) = 1 then
  begin
    GlobalUseGPUCanvas := True;
  end;

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
