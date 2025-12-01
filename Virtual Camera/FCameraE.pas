//---------------------------------------------------------------------
//
// Camera for FireMonkey component
//
// Copyright (c) 2016-2022 WINSOFT
//
//---------------------------------------------------------------------

unit FCameraE;

interface

procedure Register;

implementation

uses System.Classes, DesignIntf, DesignEditors, System.SysUtils,
  System.TypInfo, System.UITypes, FMX.Dialogs, FCamera;

// TDeviceNameProperty

type
  TDeviceNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

function TDeviceNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TDeviceNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Devices: TFVideoCaptureDevices;
begin
  Devices := (GetComponent(0) as TFCamera).Devices;
  for I := 0 to Length(Devices) - 1 do
    Proc(Devices[I].Name);
end;

// TDevicePathProperty

type
  TDevicePathProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

function TDevicePathProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TDevicePathProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Devices: TFVideoCaptureDevices;
begin
  Devices := (GetComponent(0) as TFCamera).Devices;
  for I := 0 to Length(Devices) - 1 do
    Proc(Devices[I].Path);
end;

// TDeviceIndexProperty
{
type
  TDeviceIndexProperty = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

function TDeviceIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TDeviceIndexProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Devices: TFVideoCaptureDevices;
begin
  Devices := (GetComponent(0) as TFCamera).Devices;
  for I := 0 to Length(Devices) - 1 do
    Proc(IntToStr(I));
end;
}

// TAudioDeviceNameProperty

type
  TAudioDeviceNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

function TAudioDeviceNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TAudioDeviceNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Devices: TFAudioCaptureDevices;
begin
  Devices := (GetComponent(0) as TFCamera).AudioCaptureDevices;
  for I := 0 to Length(Devices) - 1 do
    Proc(Devices[I].Name);
end;

// TAudioDeviceIndexProperty
{
type
  TAudioDeviceIndexProperty = class(TIntegerProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

function TAudioDeviceIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TAudioDeviceIndexProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Devices: TWAudioCaptureDevices;
begin
  Devices := (GetComponent(0) as TFCamera).AudioCaptureDevices;
  for I := 0 to Length(Devices) - 1 do
    Proc(IntToStr(I));
end;
}

// TCompressorNameProperty

type
  TCompressorNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

function TCompressorNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TCompressorNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Compressors: TArray<string>;
begin
  Compressors := (GetComponent(0) as TFCamera).Compressors;
  for I := 0 to Length(Compressors) - 1 do
    Proc(Compressors[I]);
end;

// TAudioCompressorNameProperty

type
  TAudioCompressorNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

function TAudioCompressorNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paValueList];
end;

procedure TAudioCompressorNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Compressors: TArray<string>;
begin
  Compressors := (GetComponent(0) as TFCamera).AudioCompressors;
  for I := 0 to Length(Compressors) - 1 do
    Proc(Compressors[I]);
end;

// TOutputFileNameProperty

type
  TOutputFileNameProperty = class(TStringProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

procedure TOutputFileNameProperty.Edit;
begin
  with TOpenDialog.Create(nil) do
  try
    Filename := GetValue;
    Filter := 'ASF files (*.asf)|*.asf|AVI files (*.avi)|*.avi|All files (*.*)|*.*';
    Options := Options + [TOpenOption.ofNoValidate];
    if Execute then
      SetValue(Filename);
  finally
    Free;
  end;
end;

function TOutputFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paRevertable];
end;

// TFCameraEditor

type
  TFCameraEditor = class(TComponentEditor)
  private
    procedure ShowProperties;
  public
    procedure Edit; override;
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

procedure TFCameraEditor.ShowProperties;
var Camera: TFCamera;
begin
  Camera := Component as TFCamera;
  Camera.ShowPropertyDialog;
end;

procedure TFCameraEditor.Edit;
begin
  ShowProperties;
end;

function TFCameraEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TFCameraEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := '&Properties...';
    else Result := '';
  end;
end;

procedure TFCameraEditor.ExecuteVerb(Index: Integer);
begin
  case Index of
    0: ShowProperties;
  end;
end;

procedure Register;
begin
  RegisterComponents('System', [TFCamera]);
  RegisterPropertyEditor(TypeInfo(string), TFCamera, 'AudioCompressorName', TAudioCompressorNameProperty);
//  RegisterPropertyEditor(TypeInfo(Integer), TFCamera, 'AudioDeviceIndex', TAudioDeviceIndexProperty);
  RegisterPropertyEditor(TypeInfo(string), TFCamera, 'AudioDeviceName', TAudioDeviceNameProperty);
  RegisterPropertyEditor(TypeInfo(string), TFCamera, 'CompressorName', TCompressorNameProperty);
//  RegisterPropertyEditor(TypeInfo(Integer), TFCamera, 'DeviceIndex', TDeviceIndexProperty);
  RegisterPropertyEditor(TypeInfo(string), TFCamera, 'DeviceName', TDeviceNameProperty);
  RegisterPropertyEditor(TypeInfo(string), TFCamera, 'DevicePath', TDevicePathProperty);
  RegisterPropertyEditor(TypeInfo(string), TFCamera, 'OutputFileName', TOutputFileNameProperty);
  RegisterComponentEditor(TFCamera, TFCameraEditor);
end;

end.