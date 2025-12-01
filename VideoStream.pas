//---------------------------------------------------------------------
// Video Stream 1.6
// Copyright (c) 2018-2021 WINSOFT
//---------------------------------------------------------------------

//{$define TRIAL} // trial version, comment this line for full version

unit VideoStream;

{$ifdef CONDITIONALEXPRESSIONS}
  {$if CompilerVersion >= 24} // Delphi XE3 or higher
    {$LEGACYIFEND ON}
  {$ifend}

  {$if CompilerVersion >= 22} // Delphi XE or higher
    {$define DXEPLUS}
  {$ifend}

  {$if CompilerVersion >= 34}
    {$define D104PLUS} // Delphi 10.4 or higher
  {$ifend}
{$endif}

interface

uses
  IdTCPServer, IdCustomHTTPServer, IdHTTPServer, IdHTTP, Types
  {$ifdef DXEPLUS}, IdContext {$endif DXEPLUS}, Classes, SysUtils,
  System.Net.HttpClientComponent;

type
  TImageNeededEvent = procedure(const Path: string; PathParams: TStrings; var JpegImage: TByteDynArray; var SendImage: Boolean) of object;
  TImageAvailableEvent = procedure(JpegImage: TByteDynArray) of object;

  TVideoServer = class
  private
    FIdHTTPServer: TIdHTTPServer;
    FOnImageNeeded: TImageNeededEvent;
    function GetActive: Boolean;
    function GetPort: Integer;
    procedure IdHTTPServerCommandGet(
      {$ifdef DXEPLUS} AContext: TIdContext; {$else} AThread: TIdPeerThread; {$endif}
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure SetActive(Value: Boolean);
    procedure SetPort(Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    property Active: Boolean read GetActive write SetActive;
    property IdHTTPServer: TIdHTTPServer read FIdHTTPServer;
    property Port: Integer read GetPort write SetPort;
    property OnImageNeeded: TImageNeededEvent read FOnImageNeeded write FOnImageNeeded;
  end;

  TVideoClient = class
  private
    FActive: Boolean;
{$ifdef NEXTGEN}
    FBoundary: TBytes;
{$else}
    FBoundary: AnsiString;
{$endif NEXTGEN}
    FNetHTTPClient: TNetHTTPClient;
    FStream: TMemoryStream;
    FImageSize: Integer;
    FImageStart: Integer;
    FImage: TByteDynArray;
    FUrl: string;
    FOnImageAvailable: TImageAvailableEvent;
    function GetActive: Boolean;
    function GetUrl: string;
    procedure NetHTTPClientReceiveData(const Sender: TObject; AContentLength,
      AReadCount: Int64; var Abort: Boolean);
    procedure NetHTTPClientRequestError(const Sender: TObject; const AError: string);
  {$ifdef D104PLUS}
    procedure NetHTTPClientRequestException(const Sender: TObject; const AError: Exception);
  {$endif D104PLUS}
    procedure SetActive(Value: Boolean);
    procedure SetUrl(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;

    property Active: Boolean read GetActive write SetActive;
    property NetHTTPClient: TNetHTTPClient read FNetHTTPClient;
    property Url: string read GetUrl write SetUrl;
    property OnImageAvailable: TImageAvailableEvent read FOnImageAvailable write FOnImageAvailable;
  end;

implementation

uses System.Net.HttpClient {$ifdef TRIAL} {$ifdef MSWINDOWS}, Windows {$else}, FMX.Dialogs {$endif MSWINDOWS} {$endif TRIAL};

{$ifdef TRIAL}
var WasTrialMessage: Boolean = False;

procedure ShowTrialMessage;
begin
  if not WasTrialMessage then
  begin
    WasTrialMessage := True;
{$ifdef MSWINDOWS}
    MessageBox(0,
      'A trial version of Video Stream started.' + #13#13 +
      'Please note that trial version is supposed to be used for evaluation only. ' +
      'If you wish to distribute Video Stream as part of your ' +
      'application, you must register from website at https://www.winsoft.sk.' + #13#13 +
      'Thank you for trialing Video Stream.',
      'Video Stream, Copyright (c) 2018-2021 WINSOFT', MB_OK or MB_ICONINFORMATION);
{$else}
    ShowMessage(
      'Video Stream' + #13#10 +
      'Copyright (c) 2018-2021 WINSOFT' + #13#10#13#10 +
      'A trial version of Video Stream started.' + #13#10#13#10 +
      'Please note that trial version is supposed to be used for evaluation only. ' +
      'If you wish to distribute Video Stream as part of your ' +
      'application, you must register from website at https://www.winsoft.sk.' + #13#10#13#10 +
      'Thank you for trialing Video Stream.');
{$endif MSWINDOWS}
  end;
end;
{$endif TRIAL}

{$ifdef NEXTGEN}
function ToUtf8(const Text: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(Text);
end;
{$endif NEXTGEN}

const
{$ifdef NEXTGEN}
  NewLineStr = #$D#$A;
{$else}
  NewLine = AnsiString(#$D#$A);
{$endif NEXTGEN}

// TVideoServer

constructor TVideoServer.Create;
begin
  inherited Create;
  FIdHTTPServer := TIdHTTPServer.Create(nil);
  FIdHTTPServer.DefaultPort := 8080;
  FIdHTTPServer.OnCommandGet := IdHTTPServerCommandGet;
{$ifdef TRIAL}
  ShowTrialMessage;
{$endif TRIAL}
end;

destructor TVideoServer.Destroy;
begin
  Active := False;
  FIdHTTPServer.Free;
  inherited Destroy;
end;

function TVideoServer.GetActive: Boolean;
begin
  Result := FIdHTTPServer.Active;
end;

procedure TVideoServer.SetActive(Value: Boolean);
begin
  FIdHTTPServer.Active := Value;
end;

function TVideoServer.GetPort: Integer;
begin
  Result := FIdHTTPServer.DefaultPort;
end;

procedure TVideoServer.SetPort(Value: Integer);
begin
  FIdHTTPServer.DefaultPort := Value;
end;

const
{$ifdef NEXTGEN}
  ContentTypePrefixStr = 'multipart/x-mixed-replace; boundary=';
  ServerBoundaryStr = 'D64D1570B86342BFB88CB26B5BFA0E5F';
  PrefixedServerBoundaryStr = '--' + ServerBoundaryStr;
{$else}
  ContentTypePrefix = AnsiString('multipart/x-mixed-replace; boundary=');
  ServerBoundary = AnsiString('D64D1570B86342BFB88CB26B5BFA0E5F');
  PrefixedServerBoundary = AnsiString('--') + ServerBoundary;
{$endif NEXTGEN}

procedure TVideoServer.IdHTTPServerCommandGet(
  {$ifdef DXEPLUS} AContext: TIdContext; {$else} AThread: TIdPeerThread; {$endif}
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
const
{$ifdef NEXTGEN}
  ContentTypeStr = 'Content-Type: image/jpeg';
  ContentLengthStr = 'Content-Length: ';
{$else}
  ContentType = AnsiString('Content-Type: image/jpeg');
  ContentLength = AnsiString('Content-Length: ');
{$endif NEXTGEN}
var
  JpegImage: TByteDynArray;
  SendImage: Boolean;
  ContentStream: TMemoryStream;
{$ifdef NEXTGEN}
  JpegLength: TBytes;
  NewLine: TBytes;
  PrefixedServerBoundary: TBytes;
  ContentType: TBytes;
  ContentLength: TBytes;
{$else}
  JpegLength: AnsiString;
{$endif NEXTGEN}
begin
  if Assigned(FOnImageNeeded) then
  begin
{$ifdef NEXTGEN}
    AResponseInfo.ContentType := ContentTypePrefixStr + ServerBoundaryStr;
{$else}
    AResponseInfo.ContentType := ContentTypePrefix + ServerBoundary;
{$endif NEXTGEN}

    AResponseInfo.Expires := EncodeDate(2000, 1, 1);
    AResponseInfo.Pragma := 'no-cache';
    AResponseInfo.CacheControl := 'no-store, no-cache, must-revalidate, pre-check=0, post-check=0, max-age=0';
    AResponseInfo.Connection := 'close';
    AResponseInfo.ContentLength := -2; // force to remove ContentLength header
    AResponseInfo.WriteHeader;

    ContentStream := TMemoryStream.Create;
    try
{$ifdef DXEPLUS}
      while AContext.Connection.Connected do
{$else}
      while AThread.Connection.Connected do
{$endif}
      begin
        SendImage := True;
        FOnImageNeeded(ARequestInfo.Document, ARequestInfo.Params, JpegImage, SendImage);
        if (JpegImage <> nil) and SendImage then
        begin
          ContentStream.Position := 0;
{$ifdef NEXTGEN}
          NewLine := ToUtf8(NewLineStr);
          PrefixedServerBoundary := ToUtf8(PrefixedServerBoundaryStr);
          ContentType := ToUtf8(ContentTypeStr);
          ContentLength := ToUtf8(ContentLengthStr);

          ContentStream.WriteBuffer(PrefixedServerBoundary[0], Length(PrefixedServerBoundary));
          ContentStream.WriteBuffer(NewLine[0], Length(NewLine));
          ContentStream.WriteBuffer(ContentType[0], Length(ContentType));
          ContentStream.WriteBuffer(NewLine[0], Length(NewLine));
          ContentStream.WriteBuffer(ContentLength[0], Length(ContentLength));
          JpegLength := ToUtf8(IntToStr(Length(JpegImage)));
          ContentStream.WriteBuffer(JpegLength[0], Length(JpegLength));
          ContentStream.WriteBuffer(NewLine[0], Length(NewLine));
          ContentStream.WriteBuffer(NewLine[0], Length(NewLine));
{$else}
          ContentStream.WriteBuffer(PrefixedServerBoundary[1], Length(PrefixedServerBoundary));
          ContentStream.WriteBuffer(NewLine[1], Length(NewLine));
          ContentStream.WriteBuffer(ContentType[1], Length(ContentType));
          ContentStream.WriteBuffer(NewLine[1], Length(NewLine));
          ContentStream.WriteBuffer(ContentLength[1], Length(ContentLength));
          JpegLength := AnsiString(IntToStr(Length(JpegImage)));
          ContentStream.WriteBuffer(JpegLength[1], Length(JpegLength));
          ContentStream.WriteBuffer(NewLine[1], Length(NewLine));
          ContentStream.WriteBuffer(NewLine[1], Length(NewLine));
{$endif NEXTGEN}
          ContentStream.WriteBuffer(JpegImage[0], Length(JpegImage));
          ContentStream.Size := ContentStream.Position;
          ContentStream.Position := 0;

          AResponseInfo.FreeContentStream := False;
          AResponseInfo.ContentStream := ContentStream;
          AResponseInfo.WriteContent;
        end;
      end;
    finally
      ContentStream.Free;
    end
  end;
end;

// TVideoClient

constructor TVideoClient.Create;
begin
  inherited Create;
  FStream := TMemoryStream.Create;
  FNetHTTPClient := TNetHTTPClient.Create(nil);
  FNetHTTPClient.Asynchronous := True;
  FNetHTTPClient.OnReceiveData := NetHTTPClientReceiveData;
  FNetHTTPClient.OnRequestError := NetHTTPClientRequestError;
{$ifdef D104PLUS}
  FNetHTTPClient.OnRequestException := NetHTTPClientRequestException;
{$endif D104PLUS}

{$ifdef TRIAL}
  ShowTrialMessage;
{$endif TRIAL}
end;

destructor TVideoClient.Destroy;
begin
  try
    Active := False;
  except
  end;
  FNetHTTPClient.Free;
  FStream.Free;
  inherited Destroy;
end;

function TVideoClient.GetActive: Boolean;
begin
  Result := FActive;
end;

procedure TVideoClient.SetActive(Value: Boolean);
begin
  if Active <> Value then
    if Value then
    try
      FActive := True;
{$ifdef NEXTGEN}
      FBoundary := nil;
{$else}
      FBoundary := '';
{$endif NEXTGEN}
      FImageSize := 0;
      FStream.Size := 0;
      FNetHTTPClient.Get(FUrl, FStream);
    except
      on E: Exception do
      begin
        FActive := False;
        raise;
      end;
    end
    else
      FActive := False;
end;

function TVideoClient.GetUrl: string;
begin
  Result := FUrl;
end;

procedure TVideoClient.SetUrl(const Value: string);
begin
  FUrl := Value;
end;

function FindBytesInMemory(Bytes: PByte; BytesSize: Integer; Memory: PByte; MemorySize: Integer): Integer;
var I, J: Integer;
begin
  Result := -1;
  for I := 0 to MemorySize - BytesSize do
  begin
    J := 0;
    while J < BytesSize do
    begin
      if Memory[I + J] <> Bytes[J] then
        Break;
      Inc(J);
    end;

    if J = BytesSize then // found
    begin
      Result := I;
      Break;
    end;
  end;
end;

procedure TVideoClient.NetHTTPClientReceiveData(const Sender: TObject; AContentLength,
  AReadCount: Int64; var Abort: Boolean);
const
{$ifdef NEXTGEN}
  BoundaryPostfixStr = NewLineStr + NewLineStr;
{$else}
  BoundaryPostfix = AnsiString(NewLine + NewLine);
{$endif NEXTGEN}
var
  Done: Boolean;
  BoundaryStartIndex, BoundaryStart, BoundaryEnd, StartIndex, I: Integer;
  Digit: Byte;
{$ifdef NEXTGEN}
  BoundaryPostfix: TBytes;
{$endif NEXTGEN}
begin
  if not FActive then
    Abort := True
  else if FStream.Size > 0 then
  begin
{$ifdef NEXTGEN}
    BoundaryPostfix := ToUtf8(BoundaryPostfixStr);
{$endif NEXTGEN}

    repeat
      Done := True;

      if FImageSize > 0 then
        if FStream.Size >= FImageStart + FImageSize then
        begin
          SetLength(FImage, FImageSize);
          Move(PByte(FStream.Memory)[FImageStart], FImage[0], FImageSize);

          Move(PByte(FStream.Memory)[FImageStart + FImageSize], FStream.Memory^, FStream.Size - FImageStart - FImageSize);
          FStream.Size := FStream.Size - FImageStart - FImageSize;
          FImageSize := 0;

          if Assigned(FOnImageAvailable) then
            FOnImageAvailable(FImage);
        end;

      if FImageSize = 0 then
      begin
{$ifdef NEXTGEN}
        if FBoundary = nil then
{$else}
        if FBoundary = '' then
{$endif NEXTGEN}
        begin
          // try to find boundary
          if FStream.Size > 2 then
          begin
            BoundaryStartIndex := 0;
            if (PByte(FStream.Memory)[0] = $D) and (PByte(FStream.Memory)[1] = $A) then
              BoundaryStartIndex := 2; // skip #$D#$A

            if (PByte(FStream.Memory)[BoundaryStartIndex] = Ord('-')) and (PByte(FStream.Memory)[BoundaryStartIndex + 1] = Ord('-')) then
            begin
              I := BoundaryStartIndex + 2;
              while I < FStream.Size - 1 do
              begin
                if (PByte(FStream.Memory)[I] = $D) and (PByte(FStream.Memory)[I + 1] = $A) then
                  Break;
                Inc(I);
              end;

              if I < FStream.Size - 1 then
              begin
                SetLength(FBoundary, I - BoundaryStartIndex);
{$ifdef NEXTGEN}
                Move((PByte(FStream.Memory) + BoundaryStartIndex)^, FBoundary[0], Length(FBoundary));
                FBoundary := FBoundary + ToUtf8(#$D#$A +
                  'Content-Type: image/jpeg' + #$D#$A +
                  'Content-Length: ');
                BoundaryStart := FindBytesInMemory(@FBoundary[0], Length(FBoundary), PByte(FStream.Memory) + BoundaryStartIndex, FStream.Size - BoundaryStartIndex);
                if BoundaryStart = -1 then
                  FBoundary := nil;
{$else}
                Move((PByte(FStream.Memory) + BoundaryStartIndex)^, FBoundary[1], Length(FBoundary));
                FBoundary := FBoundary + #$D#$A +
                  'Content-Type: image/jpeg' + #$D#$A +
                  'Content-Length: ';
                BoundaryStart := FindBytesInMemory(@FBoundary[1], Length(FBoundary), PByte(FStream.Memory) + BoundaryStartIndex, FStream.Size - BoundaryStartIndex);
                if BoundaryStart = -1 then
                  FBoundary := '';
{$endif NEXTGEN}
              end
            end
            else
              FStream.Size := 0; // boundary not found
          end;
        end;

{$ifdef NEXTGEN}
        if FBoundary <> nil then
{$else}
        if FBoundary <> '' then
{$endif NEXTGEN}
        begin
{$ifdef NEXTGEN}
          BoundaryStart := FindBytesInMemory(@FBoundary[0], Length(FBoundary), FStream.Memory, FStream.Size);
{$else}
          BoundaryStart := FindBytesInMemory(@FBoundary[1], Length(FBoundary), FStream.Memory, FStream.Size);
{$endif NEXTGEN}
          if BoundaryStart <> -1 then
          begin
            StartIndex := BoundaryStart + Length(FBoundary);
{$ifdef NEXTGEN}
            BoundaryEnd := FindBytesInMemory(@BoundaryPostfix[0], Length(BoundaryPostfix), @PByte(FStream.Memory)[StartIndex], FStream.Size - StartIndex);
{$else}
            BoundaryEnd := FindBytesInMemory(@BoundaryPostfix[1], Length(BoundaryPostfix), @PByte(FStream.Memory)[StartIndex], FStream.Size - StartIndex);
{$endif NEXTGEN}
            if BoundaryEnd <> -1 then
            begin
              BoundaryEnd := StartIndex + BoundaryEnd;
              FImageStart := BoundaryEnd + Length(BoundaryPostfix);

              for I := StartIndex to BoundaryEnd - 1 do
              begin
                Digit := PByte(FStream.Memory)[I];
                if (Digit < Ord('0')) or (Digit > Ord('9')) then
                begin
                  FImageSize := 0;
                  Break;
                end;
                FImageSize := FImageSize * 10 + (Ord(Digit) - Ord('0'));
              end;

              if FImageSize = 0 then
              begin
                // boundary seems to be invalid, so delete it
                Move(PByte(FStream.Memory)[FImageStart], FStream.Memory^, FStream.Size - FImageStart);
                FStream.Size := FStream.Size - FImageStart;
              end;

              Done := False; // retrieve image or try to find next boundary
            end;
          end;
        end
      end;
    until Done;

    if not FActive then
      Abort := True;
  end;
end;

procedure TVideoClient.NetHTTPClientRequestError(const Sender: TObject; const AError: string);
begin
  Active := False;
end;

{$ifdef D104PLUS}
procedure TVideoClient.NetHTTPClientRequestException(const Sender: TObject; const AError: Exception);
begin
  Active := False;
end;
{$endif D104PLUS}

end.