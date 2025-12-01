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

{procedure TFrmProcessProperties.ModuleList_SaveSettings;
var
  i: ULONG;
  RegistryIni: TRegIni;
  AColumn: PVirtualTreeListViewColumn;
begin
  RegistryIni := TRegIni.Create;
  try

    RegistryIni.WriteInteger('\Software\Process Manager', 'ModulesSortType', ModuleList_SortType);
    RegistryIni.WriteInteger('\Software\Process Manager', 'ModulesSortColumn', ModuleList_SortIndex);
    RegistryIni.WriteString('\Software\Process Manager', 'ModulesSortCaption', ModuleList_SortCaption);

    RegistryIni.DeleteSection('\Software\Process Manager\ColumnsModules');

    if ModuleList_TreeListView.ColumnCount > 0 then
    begin
      for i := 0 to ModuleList_TreeListView.ColumnCount - 1 do
      begin
        ModuleList_TreeListView.GetColumn(i, AColumn);
        RegistryIni.WriteInteger('\Software\Process Manager\ColumnsModules', AColumn.Text, AColumn.Width);
      end;
    end;
  finally
    RegistryIni.Free;
  end;
end;

procedure TFrmProcessProperties.ModuleList_OpenSettings;
var
  i: ULONG;
  RegistryIni: TRegIni;
  Columns: TStringList;
  Column: TVirtualTreeListViewColumn;
begin
  ModuleList_VerifyThreadExit := False;
  ModuleList_VerifyThreadRuningCount := 0;

  InitializeCriticalSection(ModuleList_CriticalSection);

  RegistryIni := TRegIni.Create;
  try
    Columns := TStringList.Create;
    try

      ModuleList_RefreshFirstTime := True;

      ModuleList_SortType := RegistryIni.ReadInteger('\Software\Process Manager', 'ModulesSortType', 0);
      ModuleList_SortIndex := RegistryIni.ReadInteger('\Software\Process Manager', 'ModulesSortColumn', 0);
      ModuleList_SortCaption := RegistryIni.ReadString('\Software\Process Manager', 'ModulesSortCaption', 'Name');
	  
RegistryIni := TRegIni.Create;
  try
    RegistryIni.WriteInteger('\Software\Process Manager', 'FormPropertiesLeft', Left);
    RegistryIni.WriteInteger('\Software\Process Manager', 'FormPropertiesTop', Top);
    RegistryIni.WriteInteger('\Software\Process Manager', 'FormPropertiesWidth', Width);
    RegistryIni.WriteInteger('\Software\Process Manager', 'FormPropertiesHeight', Height);

    RegistryIni.WriteInteger('\Software\Process Manager', 'FormPropertiesPageIndex', PageControl1.ActivePageIndex);

    RegistryIni.WriteInteger('\Software\Process Manager', 'ThreadsSortType', ThreadList_SortType);
    RegistryIni.WriteInteger('\Software\Process Manager', 'ThreadsSortColumn', ThreadList_SortIndex);
    RegistryIni.WriteString('\Software\Process Manager', 'ThreadsSortCaption', ThreadList_SortCaption);
	  
	  }
