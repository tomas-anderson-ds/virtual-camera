unit RegIni;

interface

uses
  FMX.Forms, System.SysUtils, WinApi.Windows, Registry, System.Classes;

type
  TRegIni = class
  private

  public
    constructor Create; overload;
    destructor Destroy; override;

    function ReadSection(RootKey:HKEY; Key: String; var Strings: TStringList): ULONG;
    function DeleteSection(RootKey:HKEY; Key: String): Boolean;

    function ReadInteger(RootKey:HKEY; Key: String; Name: String; DefaultValue: Integer): Integer;
    function WriteInteger(RootKey:HKEY; Key: String; Name: String; Value: Integer): Boolean;

    function ReadString(RootKey:HKEY; Key: String; Name: String; DefaultValue: String): String;
    function WriteString(RootKey:HKEY; Key: String; Name: String; Value: String): Boolean;
  end;

implementation

constructor TRegIni.Create;
begin
  inherited Create;

end;

function TRegIni.DeleteSection(RootKey:HKEY; Key: String): Boolean;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := RootKey;

    Reg.DeleteKey(Key);
    Reg.CloseKey;

  finally
    Reg.Free
  end;
end;

function TRegIni.ReadSection(RootKey:HKEY; Key: String; var Strings: TStringList): ULONG;
var
  i: ULONG;
  Reg: TRegistry;
  RegKeyInfo: TRegKeyInfo;
begin
  Result := 0;

  Reg := TRegistry.Create;
  try
    Reg.RootKey := RootKey;

    if Reg.OpenKeyReadOnly(Key) then
    begin
      if (Reg.GetKeyInfo(RegKeyInfo)) then
      begin
        Result := RegKeyInfo.NumValues;

        if Result > 0 then
        begin

          Reg.GetValueNames(Strings);

        end;
      end;
      Reg.CloseKey;
    end
  finally
    Reg.Free
  end;
end;

function TRegIni.ReadInteger(RootKey:HKEY; Key: String; Name: String; DefaultValue: Integer): Integer;
var
  Reg: TRegistry;
begin
  Result := DefaultValue;

  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := RootKey;

      if Reg.OpenKeyReadOnly(Key) then
      begin
        Result := Reg.ReadInteger(Name);
        Reg.CloseKey;
      end
      else
        Result := DefaultValue;
    finally
      Reg.Free
    end;
  except
  end;
end;

function TRegIni.ReadString(RootKey:HKEY; Key: String; Name: String; DefaultValue: String): String;
var
  Reg: TRegistry;
begin
  Result := DefaultValue;

  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := RootKey;

      // if Reg.KeyExists(Key + '\' + Name) then
      if Reg.OpenKeyReadOnly(Key) then
      begin
        Result := Reg.ReadString(Name);
        if Result = '' then
          Result := DefaultValue;
        Reg.CloseKey;
      end
      else
        Result := DefaultValue;
    finally
      Reg.Free
    end;
  except
  end;
end;

function TRegIni.WriteInteger(RootKey:HKEY; Key: String; Name: String; Value: Integer): Boolean;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := RootKey;

    Result := Reg.OpenKey(Key, True);

    if Result then
    begin
      Reg.WriteInteger(Name, Value);
      Reg.CloseKey;
    end;
  finally
    Reg.Free
  end;
end;

function TRegIni.WriteString(RootKey:HKEY; Key: String; Name: String; Value: String): Boolean;
var
  i: ULONG;
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := RootKey;

    Result := Reg.OpenKey(Key, True);

    if Result then
    begin
      Reg.WriteString(Name, Value);

      Reg.CloseKey;
    end;
  finally
    Reg.Free
  end;
end;

destructor TRegIni.Destroy;
begin

  inherited;
end;

end.
	  
	  }

