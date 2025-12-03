unit Unit1;

interface

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows, Vcl.Graphics,  WinApi.Messages,
{$ENDIF}System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Platform.Win,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, Math, FMX.Filter.Effects, FMX.Effects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Utils, System.Math.Vectors, System.Win.ComObj,
  System.ImageList, FMX.ImgList, FMX.ListBox, FMX.Edit, FMX.Memo.Types, Vcl.Dialogs, FMX.Surfaces,
  FMX.ScrollBox, FMX.Memo, FCamera, FMX.Layouts, ShellAPI, RegIni;

type
  TFloat32Array = array [0 .. 512 - 1] of Float32;

  P2DFloat32Array = ^T2DFloat32Array;
  T2DFloat32Array = array [0 .. 512 - 1] of array [0 .. 512 - 1] of Float32;

type
  TFace = record
    Rect: TRectF;
    Probability: Float32;
  end;

type
  TFaceList = record
    Faces: array of TFace;
    Count: Int32;
  end;

type
  TDetectedFace = record
    Rect: TRectF;
    Probability: Float32;
  end;

type
  TDetectedFaceList = record
    Faces: array of TDetectedFace;
    SegmentFaces: array of TDetectedFace;
    Count: Int32;
  end;

type
  TFaceLandmarkData = record
    Points: array of TPointF;
    Count: Int32;
  end;

const
  LibraryName = 'vcamera.dll';

var
  LibraryModule: HMODULE = 0;
  psapiLibrary: HMODULE = 0;
  cudaLibrary: HMODULE = 0;

const
  RestoreSize = 512;

var
  ProgramVersion: String = '1.0.0.7';

const
  FaceMeshInputSize = 256;
  FaceMeshOutputSize = 1434;

type
  PInputDataFaceMesh = ^TInputDataFaceMesh;
  TInputDataFaceMesh = array [0 .. FaceMeshInputSize - 1] of array [0 .. FaceMeshInputSize - 1] of array [0 .. 3 - 1] of Float32;

type
  POutputDataFaceMesh = ^TOutputDataFaceMesh;
  TOutputDataFaceMesh = array [0 .. FaceMeshOutputSize - 1] of Float32;

const
  FaceDetectInputSize = 320;
  FaceDetectOutputSize = 2100;

type
  PInputDataFaceDetect = ^TInputDataFaceDetect;
  TInputDataFaceDetect = array [0 .. 3 - 1] of array [0 .. FaceDetectInputSize - 1] of array [0 .. FaceDetectInputSize - 1] of Float32;

type
  POutputDataFaceDetect = ^TOutputDataFaceDetect;
  TOutputDataFaceDetect = array [0 .. 5 - 1] of array [0 .. FaceDetectOutputSize - 1] of Float32;

type
  PInputDataFaceLandmark106 = ^TInputDataFaceLandmark106;
  TInputDataFaceLandmark106 = array [0 .. 3 - 1] of array [0 .. 192 - 1] of array [0 .. 192 - 1] of Float32;

type
  POutputDataFaceLandmark106 = ^TOutputDataFaceLandmark106;
  TOutputDataFaceLandmark106 = array [0 .. 212 - 1] of Float32;

type
  PLatentSourceInputData = ^TLatentSourceInputData;
  TLatentSourceInputData = array [0 .. 3 - 1] of array [0 .. 112 - 1] of array [0 .. 112 - 1] of Float32;

type
  PLatentTargetInputData = ^TLatentTargetInputData;
  TLatentTargetInputData = array [0 .. 3 - 1] of array [0 .. 128 - 1] of array [0 .. 128 - 1] of Float32;

type
  PLatentOutputData = ^TLatentOutputData;
  TLatentOutputData = array [0 .. 512 - 1] of Float32;

type
  POutputImageData = ^TOutputImageData;
  TOutputImageData = array [0 .. 3 - 1] of array [0 .. 128 - 1] of array [0 .. 128 - 1] of Float32;

type
  PRestoreImageData = ^TRestoreImageData;
  TRestoreImageData = array [0 .. 3 - 1] of array [0 .. RestoreSize - 1] of array [0 .. RestoreSize - 1] of Float32;

type
  PVirtualCameraData = ^TVirtualCameraData;
  TVirtualCameraData = array [0 .. 640 * 480 - 1] of array [0 .. 3 - 1] of Byte;

type
  TFunction_001 = function(
    swap_face_model_file_name: PAnsiChar;
    latent_model_file_name: PAnsiChar;
    face_detect_model_file_name: PAnsiChar;
    landmark_model_file_name: PAnsiChar;
    landmark106_model_file_name: PAnsiChar;
    a_name: PAnsiChar;
    segment_model_file_name: PAnsiChar;
    b_name: PAnsiChar;
    face_mesh_model_file_name: PAnsiChar;
    //CPU = 0
    //CUDA = 2,
    //OPENCL = 3
    //AUTO = 4
    ForwardType: Int32 = 2;//CUDA
    PlatformSize: Int32 = 0;
    PlatformId: Int32 = 0;
    DeviceId: Int32 = 0;
    ThreadCount: Int32 = 8): Float32; stdcall;

  TFunction_003 = function(input_image: Pointer; input_image_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  TFunction_006 = function(input_image: Pointer; input_image_size: Int32; image_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  TFunction_002 = function(input_image: Pointer; input_size: Int32; input_image_size: Int32; latent: Pointer; latent_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  TFunction_004 = function(input_image: Pointer; input_image_size: Int32; image_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  TFunction_005 = function(input_image: Pointer; input_image_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  TFunction_0051 = function(input_image: Pointer; input_image_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  TFunction_007 = function(input_image: Pointer; input_image_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  TFunction_008 = function(input_image: Pointer; input_image_size: Int32; image_size: Int32; output_data: Pointer; output_size: Int32): Float32; stdcall;
  // create
  TFunction_009 = function(width: Int32; height: Int32; framerate: Float32): Pointer; stdcall;
  // delete
  TFunction_010 = function(cam: Pointer): Pointer; stdcall;
  // send
  TFunction_011 = function(Camera: Pointer; image: Pointer): Pointer; stdcall;
  // wait
  // TFunction_012 = function(cam: Pointer): Bool; stdcall;
  // connected
  TFunction_013 = function(cam: Pointer): Bool; stdcall;
  TFunction_014 = function(serial: PAnsiChar): Int32; stdcall;
  // face mesh
  TFunction_017 = function(input_image: Pointer; input_image_size: Int32; output_data: Pointer; output_data_size: Int32): Float32; stdcall;

  TDllRegisterServer = function(): HRESULT; stdcall;
  TDllUnregisterServer = function(): HRESULT; stdcall;

  TGetProcessImageFileNameW = function(hProcess: THandle; lpImageFileName: LPTSTR; nSize: DWORD): DWORD; stdcall;
  TcuInit = function(): Int32; stdcall;
  TcuDriverGetVersion = function(version: Pointer): Int32; stdcall;

var
  Function_001: TFunction_001 = nil;
  Function_003: TFunction_003 = nil;
  Function_006: TFunction_006 = nil;
  Function_002: TFunction_002 = nil;
  Function_004: TFunction_004 = nil;
  Function_005: TFunction_005 = nil;
  Function_0051: TFunction_0051 = nil;
  Function_007: TFunction_007 = nil;
  Function_008: TFunction_008 = nil;
  Function_009: TFunction_009 = nil;
  Function_010: TFunction_010 = nil;
  // VirtualCameraWaitForConnection: TVirtualCameraWaitForConnection = nil;
  Function_011: TFunction_011 = nil;
  Function_013: TFunction_013 = nil;
  Function_014: TFunction_014 = nil;
  Function_017: TFunction_017 = nil;

  DllRegisterServer: TDllRegisterServer;
  DllUnregisterServer: TDllUnregisterServer;

  GetProcessImageFileNameW: TGetProcessImageFileNameW = nil;

  cuInit: TcuInit = nil;
  cuDriverGetVersion: TcuDriverGetVersion = nil;

var
  VectorMapList: TStringList;
  VectorMap: P2DFloat32Array;

  FilterContrast: TFilterContrast;
  FilterGaussianBlur: TFilterGaussianBlur;

  Camera: TFCamera;
  CameraDevices: TFVideoCaptureDevices;
  CameraIndex: Integer = 0;

  VirtualCamera: Pointer = nil;
  VirtualCameraData: PVirtualCameraData = nil;

  serial: PAnsiChar = '';
  message_key: PAnsiChar = '';

  FFPS: Float32 = 0;
  FFPSCount: Integer = 0;
  FFPSTotal: Integer = 0;

  Language: Integer = 0;

  PerformanceMode: Integer = 0;

  ApplicationFileName: String;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    Edit1: TEdit;
    ComboBox1: TComboBox;
    Timer1: TTimer;
    TrackBarSharpness: TTrackBar;
    TrackBarContrast: TTrackBar;
    LabelBrightness: TLabel;
    LabelContrast: TLabel;
    LabelSharpness: TLabel;
    LabelSaturation: TLabel;
    TrackBarSaturation: TTrackBar;
    TrackBarBrightness: TTrackBar;
    Image3: TImage;
    InvertEffect2: TInvertEffect;
    Button4: TButton;
    Button5: TButton;
    CheckBox1: TCheckBox;
    Rectangle1: TRectangle;
    ImageMain: TImage;
    Label1: TLabel;
    StyleBook1: TStyleBook;
    Image7: TImage;
    InvertEffect6: TInvertEffect;
    ImageList1: TImageList;
    AniIndicator1: TAniIndicator;
    Rectangle2: TRectangle;
    Image1: TImage;
    Image2: TImage;
    InvertEffect3: TInvertEffect;
    Image4: TImage;
    InvertEffect4: TInvertEffect;
    Image6: TImage;
    InvertEffect5: TInvertEffect;
    Label2: TLabel;
    Image8: TImage;
    InvertEffect7: TInvertEffect;
    Image9: TImage;
    InvertEffect8: TInvertEffect;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBarSharpnessChange(Sender: TObject);
    procedure TrackBarSaturationChange(Sender: TObject);
    procedure TrackBarContrastChange(Sender: TObject);
    procedure TrackBarBrightnessChange(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure Image3MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image3MouseEnter(Sender: TObject);
    procedure Image3MouseLeave(Sender: TObject);
    procedure Image3MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormActivate(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Image7Click(Sender: TObject);
    procedure Image7MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image7MouseEnter(Sender: TObject);
    procedure Image7MouseLeave(Sender: TObject);
    procedure Image7MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ComboBox1Change(Sender: TObject);
    procedure Image4MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image4MouseLeave(Sender: TObject);
    procedure Image4MouseEnter(Sender: TObject);
    procedure Image4MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image5MouseEnter(Sender: TObject);
    procedure Image5MouseLeave(Sender: TObject);
    procedure Image4Click(Sender: TObject);
    procedure Image6Click(Sender: TObject);
    procedure Image6MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image6MouseLeave(Sender: TObject);
    procedure Image6MouseEnter(Sender: TObject);
    procedure Image6MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image8Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormShow(Sender: TObject);
    procedure Image9Click(Sender: TObject);
    procedure Image10Click(Sender: TObject);
  private
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
  public
    ImageSourceBitmap: TBitmap;
    ImageTargetBitmap: TBitmap;

    DetectedFaceSourceList: TDetectedFaceList;
    DetectedFaceTargetList: TDetectedFaceList;

    SourceFaceMouthPointY: Single;
    SourceFaceLandmarkData: TFaceLandmarkData;
    FTargetFaceLandmarkDataA, FTargetFaceLandmarkData, TargetFaceLandmarkData: TFaceLandmarkData;

    LoadThread: TThread;

    procedure Load(Thread: TThread);
    procedure SwitchLanguage;
    function GetFaceList(Probability: Float32; NMS: Integer; OutputData: POutputDataFaceDetect): TFaceList;
    function FaceDetect(Probability: Float32; Bitmap: TBitmap; Stretch: Boolean = False; Frame: Boolean = False; FrameTop: Integer = 20; FrameBottom: Integer = 20): TDetectedFaceList;
    function GetLandmarkData106(Bitmap: TBitmap): TFaceLandmarkData;
    function GetFaceMeshLandmarks(Bitmap: TBitmap): TFaceLandmarkData;

    procedure GetSourceLatentImage(SourceBitmap:TBitmap; SourceRect:TRectF; var Bitmap:TBitmap; var LandmarkData: TFaceLandmarkData; var MouthPointY: Single);
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

var
  FaceDetectInputData: PInputDataFaceDetect;
  FaceDetectOutputData: POutputDataFaceDetect;
  LatentSourceInputData: PLatentSourceInputData;
  LatentTargetInputData: PLatentTargetInputData;
  LatentOutputData: PLatentOutputData;
  InputImageData: POutputImageData;
  OutputImageData: POutputImageData;
  InputDataFaceLandmark106: PInputDataFaceLandmark106;
  OutputDataFaceLandmark106: POutputDataFaceLandmark106;
  RestoreImageData: PRestoreImageData;
  InputDataFaceMesh: PInputDataFaceMesh;
  OutputDataFaceMesh: POutputDataFaceMesh;

procedure TForm1.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  inherited;
  Msg.Result := HTCAPTION;
end;

function Dot(const A: TFloat32Array; const B: P2DFloat32Array): TFloat32Array;
var
  X, Y: Integer;
begin
  for Y := 0 to 512 - 1 do
  begin
    Result[Y] := 0.0;
    for X := 0 to 512 - 1 do
      Result[Y] := Result[Y] + A[X] * B^[X][Y];
  end;
end;

function AngleOfLine(A, B: TPointF): Single;
begin
  if B.X = A.X then
    if B.Y > A.Y then
      Result := 90
    else
      Result := 270
  else
    Result := RadToDeg(ArcTan2(B.Y - A.Y, B.X - A.X));
  if Result < 0 then
    Result := Result;
end;

const
  PIDiv180 = 0.017453292519943295769236907684886;

procedure RotateF(RotAng: Float32; const X, Y: Single; out Nx, Ny: Single);
var
  SinVal: Single;
  CosVal: Single;
begin
  RotAng := RotAng * PIDiv180;
  SinVal := Sin(RotAng);
  CosVal := Cos(RotAng);
  Nx := (X * CosVal) - (Y * SinVal);
  Ny := (Y * CosVal) + (X * SinVal);
end;

procedure RotatePoint(const RotAng: Single; const X, Y, ox, oy: Single; out Nx, Ny: Single);
begin
  RotateF(RotAng, X - ox, Y - oy, Nx, Ny);
  Nx := Nx + ox;
  Ny := Ny + oy;
end;

function _Rotate(const RotAng: Single; const Point, OPoint: TPointF): TPointF;
begin
  RotatePoint(RotAng, Point.X, Point.Y, OPoint.X, OPoint.Y, Result.X, Result.Y);
end;

function RotatePolygon(const RotAng: Single; const Polygon: TPolygon; const OPoint: TPointF): TPolygon;
var
  i: Integer;
begin
  for i := 0 to Length(Polygon) - 1 do
    Result[i] := _Rotate(RotAng, Polygon[i], OPoint);
end;

procedure RotateBitmap(Angle: Single; Bitmap: TBitmap; Center: Boolean = False);
var
  FBitmap: TBitmap;
  FMatrixA, FMatrixB: TMatrix;
  FPoints: array of TPointF;
  FRect: TRectF;
begin
  if Angle = 0 then
    Exit;

  TMonitor.Enter(Bitmap);
  try
    FMatrixA := TMatrix.Identity;
    FMatrixA.m31 := -Bitmap.width / 2;
    FMatrixA.m32 := -Bitmap.height / 2;
    FMatrixA := FMatrixA * TMatrix.CreateRotation(DegToRad(Angle));
    SetLength(FPoints, 4);
    FPoints[0] := TPointF.Zero * FMatrixA;
    FPoints[1] := TPointF.Create(Bitmap.width, 0) * FMatrixA;
    FPoints[2] := TPointF.Create(Bitmap.width, Bitmap.height) * FMatrixA;
    FPoints[3] := TPointF.Create(0, Bitmap.height) * FMatrixA;
    FRect := NormalizeRectF(FPoints);
    FMatrixB := TMatrix.Identity;
    FMatrixB.m31 := Bitmap.width / 2;
    FMatrixB.m32 := Bitmap.height / 2;
    FMatrixA := FMatrixA * FMatrixB;

    FBitmap := TBitmap.Create(Trunc(FRect.width), Trunc(FRect.height));
    try
      if FBitmap.Canvas.BeginScene then
        try
          FBitmap.Canvas.Clear(TAlphaColorRec.Null);
          FBitmap.Canvas.SetMatrix(FMatrixA);
          if Center then
            FBitmap.Canvas.DrawBitmap(Bitmap, TRectF.Create(0, 0, Bitmap.width, Bitmap.height), TRectF.Create(0, 0, FRect.width, FRect.height), 1, False)
          else
            FBitmap.Canvas.DrawBitmap(Bitmap, TRectF.Create(0, 0, Bitmap.width, Bitmap.height), TRectF.Create(0, 0, Bitmap.width, Bitmap.height), 1, False);
        finally
          FBitmap.Canvas.EndScene;
        end;
      Bitmap.Assign(FBitmap);
    finally
      FBitmap.Free;
    end;
  finally
    TMonitor.Exit(Bitmap);
  end;
end;

function TForm1.GetFaceList(Probability: Float32; NMS: Integer; OutputData: POutputDataFaceDetect): TFaceList;
var
  i, X, Y: DWORD;
  FListNMS: array of TFace;
  FRect: TRectF;
  FExist: Boolean;
begin
  SetLength(Result.Faces, 0);
  Result.Count := 0;

  SetLength(FListNMS, 0);

  Y := 0;

  while True do
  begin
    if Y > FaceDetectOutputSize then
      Break;

    if ((OutputData[4][Y]) >= Probability) and ((OutputData[4][Y]) <= 1) then
    begin
      SetLength(FListNMS, Length(FListNMS) + 1);
      FListNMS[Length(FListNMS) - 1].Rect.Left := (OutputData[0][Y] - (OutputData[2][Y] * 0.5));
      FListNMS[Length(FListNMS) - 1].Rect.Top := (OutputData[1][Y] - (OutputData[3][Y] * 0.5));
      FListNMS[Length(FListNMS) - 1].Rect.width := (OutputData[2][Y]);
      FListNMS[Length(FListNMS) - 1].Rect.height := (OutputData[3][Y]);
      FListNMS[Length(FListNMS) - 1].Probability := OutputData[4][Y];

      if Length(FListNMS) > 0 then
      begin
        for i := Y - NMS to Y + NMS - 1 do
        begin
          if (OutputData[4][i] > OutputData[4][Y]) then
          begin
            FRect.Left := (OutputData[0][i] - (OutputData[2][i] * 0.5));
            FRect.Top := (OutputData[1][i] - (OutputData[3][i] * 0.5));
            FRect.width := (OutputData[2][i]);
            FRect.height := (OutputData[3][i]);

            for X := 0 to Length(FListNMS) - 1 do
            begin
              if IntersectRect(FListNMS[X].Rect, FRect) then
              begin
                if (FaceDetectInputSize * OutputData[0][i] > FListNMS[X].Rect.Left) and
                  (FaceDetectInputSize * OutputData[0][i] < FListNMS[X].Rect.Right) and
                  (FaceDetectInputSize * OutputData[1][i] > FListNMS[X].Rect.Top) and
                  (FaceDetectInputSize * OutputData[1][i] < FListNMS[X].Rect.Bottom) and
                  (OutputData[4][i] > FListNMS[X].Probability)
                then
                begin
                  FListNMS[X].Rect.Left := FRect.Left;
                  FListNMS[X].Rect.Top := FRect.Top;
                  FListNMS[X].Rect.width := FRect.width;
                  FListNMS[X].Rect.height := FRect.height;
                  FListNMS[X].Probability := OutputData[4][i];

                end;
              end;
            end;
          end;
        end;
      end;
    end;

    Inc(Y);
  end;

  if Length(FListNMS) > 0 then
  begin
    for Y := 0 to Length(FListNMS) - 1 do
    begin
      FExist := False;

      if (Length(Result.Faces) > 0) then
      begin
        for i := 0 to Length(Result.Faces) - 1 do
        begin
          if (IntersectRect(Result.Faces[i].Rect, FListNMS[Y].Rect)) then
          begin
            if ((Abs(Result.Faces[i].Rect.Top - FListNMS[Y].Rect.Top) < Result.Faces[i].Rect.height / 2)) and
              ((Abs(Result.Faces[i].Rect.Bottom - FListNMS[Y].Rect.Bottom) < Result.Faces[i].Rect.height / 2)) and
              ((Abs(Result.Faces[i].Rect.Left - FListNMS[Y].Rect.Left) < Result.Faces[i].Rect.width / 2)) and
              ((Abs(Result.Faces[i].Rect.Right - FListNMS[Y].Rect.Right) < Result.Faces[i].Rect.width / 2)) then
            begin
              if FListNMS[Y].Probability > Result.Faces[i].Probability then
              begin
                Result.Faces[i].Rect.Left := FListNMS[Y].Rect.Left;
                Result.Faces[i].Rect.Top := FListNMS[Y].Rect.Top;
                Result.Faces[i].Rect.Right := FListNMS[Y].Rect.Right;
                Result.Faces[i].Rect.Bottom := FListNMS[Y].Rect.Bottom;
                Result.Faces[i].Probability := FListNMS[Y].Probability;

              end;

              FExist := True;
              Break;
            end;
          end;
        end;
      end;

      if (FExist = False) then
      begin
        SetLength(Result.Faces, Length(Result.Faces) + 1);
        Result.Faces[Length(Result.Faces) - 1].Rect.Left := FListNMS[Y].Rect.Left;
        Result.Faces[Length(Result.Faces) - 1].Rect.Top := FListNMS[Y].Rect.Top;
        Result.Faces[Length(Result.Faces) - 1].Rect.width := FListNMS[Y].Rect.width;
        Result.Faces[Length(Result.Faces) - 1].Rect.height := FListNMS[Y].Rect.height;
        Result.Faces[Length(Result.Faces) - 1].Probability := FListNMS[Y].Probability;

        Result.Count := Length(Result.Faces);
      end;

    end;
  end;
end;

function TForm1.FaceDetect(Probability: Float32; Bitmap: TBitmap; Stretch: Boolean = False; Frame: Boolean = False; FrameTop: Integer = 20; FrameBottom: Integer = 20): TDetectedFaceList;
var
  i, X, Y: DWORD;
  FColors: PAlphaColorArray;
  FBitmapData: TBitmapData;
  FFaceList: TFaceList;
  FBitmap: TBitmap;
begin
  FBitmap := TBitmap.Create;
  try
    SetLength(FFaceList.Faces, 0);
    FFaceList.Count := 0;

    SetLength(Result.Faces, 0);
    Result.Count := 0;

    FBitmap.Width := FaceDetectInputSize;
    FBitmap.Height := FaceDetectInputSize;

    Bitmap.Canvas.BeginScene;
    try
      FBitmap.Canvas.BeginScene;
      try
        FBitmap.Canvas.Clear(TAlphaColorRec.Null);

        FBitmap.Canvas.DrawBitmap(
          Bitmap,
          Bitmap.Bounds,
          FBitmap.Bounds,
          1, False);
      finally
        FBitmap.Canvas.EndScene;
      end;
    finally
      Bitmap.Canvas.EndScene;
    end;

    if (FBitmap.Map(TMapAccess.Read, FBitmapData)) then
    begin
      try
        for Y := 0 to FaceDetectInputSize - 1 do
        begin
          FColors := PAlphaColorArray(FBitmapData.GetScanline(Y));

          for X := 0 to FaceDetectInputSize - 1 do
          begin
            FaceDetectInputData[0][Y][X] := (TAlphaColorRec(FColors[X]).R / 255);
            FaceDetectInputData[1][Y][X] := (TAlphaColorRec(FColors[X]).G / 255);
            FaceDetectInputData[2][Y][X] := (TAlphaColorRec(FColors[X]).B / 255);
          end;
        end;

        Function_004(
          FaceDetectInputData, SizeOf(TInputDataFaceDetect), FaceDetectInputSize,
          FaceDetectOutputData, SizeOf(TOutputDataFaceDetect));

      finally
        FBitmap.Unmap(FBitmapData);
      end;
    end;

    FFaceList := GetFaceList(Probability, 10, FaceDetectOutputData);

    if FFaceList.Count > 0 then
    begin
      SetLength(Result.Faces, Length(FFaceList.Faces));
      SetLength(Result.SegmentFaces, Length(FFaceList.Faces));
      Result.Count := FFaceList.Count;

      for i := 0 to FFaceList.Count - 1 do
      begin
        Result.Faces[i].Rect.Left := (FFaceList.Faces[i].Rect.Left * (Bitmap.Width / FBitmap.Width));
        Result.Faces[i].Rect.Top := (FFaceList.Faces[i].Rect.Top * (Bitmap.Height / FBitmap.Height));
        Result.Faces[i].Rect.Right := (FFaceList.Faces[i].Rect.Right * (Bitmap.Width / FBitmap.Width));
        Result.Faces[i].Rect.Bottom := (FFaceList.Faces[i].Rect.Bottom * (Bitmap.Height / FBitmap.Height));

        Result.Faces[i].Rect.Left := (Result.Faces[i].Rect.Left - ((Result.Faces[i].Rect.Height / 100) * 5));
        Result.Faces[i].Rect.Top := (Result.Faces[i].Rect.Top - ((Result.Faces[i].Rect.Height / 100) * 5));
        Result.Faces[i].Rect.Right := (Result.Faces[i].Rect.Right + ((Result.Faces[i].Rect.Height / 100) * 5));
        Result.Faces[i].Rect.Bottom := (Result.Faces[i].Rect.Bottom + ((Result.Faces[i].Rect.Height / 100) * 5));

        Result.SegmentFaces[i].Rect.Left := (FFaceList.Faces[i].Rect.Left * (Bitmap.Width / FBitmap.Width));
        Result.SegmentFaces[i].Rect.Top := (FFaceList.Faces[i].Rect.Top * (Bitmap.Height / FBitmap.Height));
        Result.SegmentFaces[i].Rect.Right := (FFaceList.Faces[i].Rect.Right * (Bitmap.Width / FBitmap.Width));
        Result.SegmentFaces[i].Rect.Bottom := (FFaceList.Faces[i].Rect.Bottom * (Bitmap.Height / FBitmap.Height));

        Result.SegmentFaces[i].Rect.Top := (Result.SegmentFaces[i].Rect.Top - ((Result.SegmentFaces[i].Rect.Bottom - Result.SegmentFaces[i].Rect.Top) / FrameTop));
        Result.SegmentFaces[i].Rect.Bottom := (Result.SegmentFaces[i].Rect.Bottom + ((Result.SegmentFaces[i].Rect.Bottom - Result.SegmentFaces[i].Rect.Top) / FrameBottom));
        Result.SegmentFaces[i].Rect.Left := (Result.SegmentFaces[i].Rect.CenterPoint.X - Result.SegmentFaces[i].Rect.Height / 2);
        Result.SegmentFaces[i].Rect.Width := (Result.SegmentFaces[i].Rect.Height);

      end;
    end;
  finally
    FBitmap.Free;
  end;
end;

function TForm1.GetLandmarkData106(Bitmap: TBitmap): TFaceLandmarkData;
var
  i, X, Y: DWORD;
  FColors: PAlphaColorArray;
  FBitmapData: TBitmapData;
begin
  SetLength(Result.Points, 0);
  Result.Count := 0;

  if (Bitmap.Map(TMapAccess.Read, FBitmapData)) then
  begin
    try
      for Y := 0 to 192 - 1 do
      begin
        FColors := PAlphaColorArray(FBitmapData.GetScanline(Y));

        for X := 0 to 192 - 1 do
        begin
          InputDataFaceLandmark106[0][Y][X] := (TAlphaColorRec(FColors[X]).R);
          InputDataFaceLandmark106[1][Y][X] := (TAlphaColorRec(FColors[X]).G);
          InputDataFaceLandmark106[2][Y][X] := (TAlphaColorRec(FColors[X]).B);
        end;
      end;

      Function_0051(
        InputDataFaceLandmark106, SizeOf(TInputDataFaceLandmark106),
        OutputDataFaceLandmark106, SizeOf(TOutputDataFaceLandmark106));

      SetLength(Result.Points, 106);
      Result.Count := 106;

      i := 0;

      for X := 0 to 106 - 1 do
      begin
        Result.Points[X].X := (OutputDataFaceLandmark106[i] * (Bitmap.Width / 2) + (Bitmap.Width / 2));
        Result.Points[X].Y := (OutputDataFaceLandmark106[i + 1] * (Bitmap.Height / 2) + (Bitmap.Height / 2));

        i := i + 2;
      end;
    finally
      Bitmap.Unmap(FBitmapData);
    end;
  end;
end;

function TForm1.GetFaceMeshLandmarks(Bitmap: TBitmap): TFaceLandmarkData;
var
  i, X, Y: DWORD;
  FColors: PAlphaColorArray;
  FBitmapData: TBitmapData;
begin
  SetLength(Result.Points, 0);
  Result.Count := 0;

  if (Bitmap.Map(TMapAccess.Read, FBitmapData)) then
  begin
    try
      for Y := 0 to FaceMeshInputSize - 1 do
      begin
        FColors := PAlphaColorArray(FBitmapData.GetScanline(Y));

        for X := 0 to FaceMeshInputSize - 1 do
        begin
          InputDataFaceMesh[Y][X][0] := (TAlphaColorRec(FColors[X]).R / 255);
          InputDataFaceMesh[Y][X][1] := (TAlphaColorRec(FColors[X]).G / 255);
          InputDataFaceMesh[Y][X][2] := (TAlphaColorRec(FColors[X]).B / 255);
        end;
      end;

      Function_017(
        InputDataFaceMesh, SizeOf(TInputDataFaceMesh),
        OutputDataFaceMesh, SizeOf(TOutputDataFaceMesh));

      SetLength(Result.Points, FaceMeshOutputSize div 3);
      Result.Count := FaceMeshOutputSize div 3;

      i := 0;

      for Y := 0 to FaceMeshOutputSize div 3 - 1 do
      begin
        Result.Points[Y].X := (OutputDataFaceMesh[i]);
        Result.Points[Y].Y := (OutputDataFaceMesh[i + 1]);

        i := i + 3;
      end;

    finally
      Bitmap.Unmap(FBitmapData);
    end;
  end;
end;

var ModelsLoaded: Boolean = False;

procedure TForm1.FormActivate(Sender: TObject);
var
  RegistryIni: TRegIni;
begin
  RegistryIni:= TRegIni.Create;
  try
    Image3.Opacity:= 0.8;
    Image4.Opacity:= 0.8;
    Image7.Opacity:= 0.8;

    if Assigned(Camera) then
    begin
      if Camera.DeviceIndex >= 0 then
      begin
        if Camera.SharpnessSupported then
        begin
          TrackBarSharpness.Min := Camera.SharpnessRange.Min;
          TrackBarSharpness.Max := Camera.SharpnessRange.Max;
          TrackBarSharpness.Frequency := Camera.SharpnessRange.Delta;
          TrackBarSharpness.Value := Camera.Sharpness;
        end;

        if Camera.ContrastSupported then
        begin
          TrackBarContrast.Min := Camera.ContrastRange.Min;
          TrackBarContrast.Max := Camera.ContrastRange.Max;
          TrackBarContrast.Frequency := Camera.ContrastRange.Delta;
          TrackBarContrast.Value := Camera.Contrast;
        end;

        if Camera.BrightnessSupported then
        begin
          TrackBarBrightness.Min := Camera.BrightnessRange.Min;
          TrackBarBrightness.Max := Camera.BrightnessRange.Max;
          TrackBarBrightness.Frequency := Camera.BrightnessRange.Delta;
          TrackBarBrightness.Value := Camera.Brightness;
        end;

        if Camera.SaturationSupported then
        begin
          TrackBarSaturation.Min := Camera.SaturationRange.Min;
          TrackBarSaturation.Max := Camera.SaturationRange.Max;
          TrackBarSaturation.Frequency := Camera.SaturationRange.Delta;
          TrackBarSaturation.Value := Camera.Saturation;
        end;
      end;
    end;
  finally
    RegistryIni.Free;
  end;
end;

procedure TForm1.Load(Thread: TThread);
var
  i, X, Y: DWORD;
  FResult: Int32;
  FDevices: TFVideoCaptureDevices;
  FCode: PAnsiChar;
  FFileName: PWideChar;
  S: String;
  FSize: Int32;
  FDriverVersion:Pointer;
  RegistryIni: TRegIni;
begin
  if ModelsLoaded = False then
  begin
    try
      VectorMapList := TStringList.Create;
      VectorMapList.LoadFromFile('latent.data');

      GetMem(VectorMap, SizeOf(T2DFloat32Array));

      i := 0;

      for Y := 0 to 512 - 1 do
      begin
        for X := 0 to 512 - 1 do
        begin
          VectorMap[Y][X] := StrToFloat(VectorMapList.Strings[i]);
          Inc(i);
        end;
      end;

      Function_001 := GetProcAddress(LibraryModule, 'Function_001');
      Function_003 := GetProcAddress(LibraryModule, 'Function_003');
      Function_002 := GetProcAddress(LibraryModule, 'Function_002');
      Function_004 := GetProcAddress(LibraryModule, 'Function_004');
      Function_005 := GetProcAddress(LibraryModule, 'Function_005');
      Function_0051 := GetProcAddress(LibraryModule, 'Function_0051');
      Function_006 := GetProcAddress(LibraryModule, 'Function_006');
      Function_007 := GetProcAddress(LibraryModule, 'Function_007');
      Function_008 := GetProcAddress(LibraryModule, 'Function_008');
      Function_009 := GetProcAddress(LibraryModule, 'Function_009');
      Function_010 := GetProcAddress(LibraryModule, 'Function_010');
      Function_011 := GetProcAddress(LibraryModule, 'Function_011');
      Function_013 := GetProcAddress(LibraryModule, 'Function_013');
      Function_014 := GetProcAddress(LibraryModule, 'Function_014');
      Function_017 := GetProcAddress(LibraryModule, 'Function_017');

      DllRegisterServer := GetProcAddress(LibraryModule, 'DllRegisterServer');
      DllUnregisterServer := GetProcAddress(LibraryModule, 'DllUnregisterServer');

      if (@Function_001 = nil) or (@Function_002 = nil) or (@Function_003 = nil) or (@Function_004 = nil) or
          (@Function_009 = nil) or (@Function_010 = nil) or (@Function_011 = nil) or (@Function_013 = nil) or
          (@Function_005 = nil) or (@Function_0051 = nil) or (@Function_006 = nil) or (@Function_007 = nil) or (@Function_008 = nil) or
          (@Function_014 = nil) or (@Function_017 = nil) or (@DllRegisterServer = nil) or (@DllUnregisterServer = nil) then
      begin
        Exit;
      end;

      Function_001('swapper.nn', 'latent.nn', 'detect.nn', '', 'landmark.nn', '', '', '', 'mesh.nn');

    finally
      if Assigned(Camera) then
      begin
        if Camera.DeviceIndex >= 0 then
        begin
          Button1.Enabled := True;
          Image3.Enabled := True;
          Image4.Enabled := True;
          Image7.Enabled := True;
          Image9.Enabled := True;
        end;
      end;
      AniIndicator1.Visible := False;
      ModelsLoaded:= True;
      Invalidate;
      ImageMain.InvalidateRect(ImageMain.ClipRect);
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i, X, Y: DWORD;
  FResult: Int32;
  FDevices: TFVideoCaptureDevices;
  FCode: PAnsiChar;
  FFileName: PWideChar;
  FSize: Int32;
  RegistryIni: TRegIni;
  FDriverVersion:Pointer;
begin
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);

  Randomize;

  RegistryIni:= TRegIni.Create;
  try
  if RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'PerformanceMode', 0) = 1 then
  begin
    PerformanceMode:= 1;
  end
  else
  begin
    PerformanceMode:= 0;
  end;

  if PerformanceMode = 1 then
  begin
    Quality := TCanvasQuality.HighPerformance;
    Image9.Bitmap.Assign(ImageList1.Source[2].MultiResBitmap[0].Bitmap);
    Edit1.Text:= '52';
  end
  else
  begin
    Quality := TCanvasQuality.HighQuality;
    Image9.Bitmap.Assign(ImageList1.Source[3].MultiResBitmap[0].Bitmap);
    Edit1.Text:= '52';
  end;

  psapiLibrary := WinApi.Windows.LoadLibrary('psapi.dll');
  GetProcessImageFileNameW := GetProcAddress(psapiLibrary, 'GetProcessImageFileNameW');
  GetMem(FFileName, 256);
  try
    if GetProcessImageFileNameW(GetCurrentProcess, FFileName, 256) > 0 then
      ApplicationFileName := GetCurrentDir + '\' + ExtractFileName(FFileName);
  finally
    FreeMem(FFileName);
  end;

  RegistryIni.WriteString(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\DirectX\UserGpuPreferences', ApplicationFileName, 'GpuPreference=2;');

  LibraryModule := WinApi.Windows.LoadLibrary(LibraryName);

  if LibraryModule = 0 then
  begin
    Exit;
  end;

  GetMem(LatentSourceInputData, SizeOf(TLatentSourceInputData));
  GetMem(LatentTargetInputData, SizeOf(TLatentTargetInputData));
  GetMem(LatentOutputData, SizeOf(TLatentOutputData));
  GetMem(OutputImageData, SizeOf(TOutputImageData));
  GetMem(InputImageData, SizeOf(TOutputImageData));
  GetMem(FaceDetectInputData, SizeOf(TInputDataFaceDetect));
  GetMem(FaceDetectOutputData, SizeOf(TOutputDataFaceDetect));
  GetMem(InputDataFaceLandmark106, SizeOf(TInputDataFaceLandmark106));
  GetMem(OutputDataFaceLandmark106, SizeOf(TOutputDataFaceLandmark106));
  GetMem(RestoreImageData, SizeOf(TRestoreImageData));
  GetMem(VirtualCameraData, SizeOf(TVirtualCameraData));
  GetMem(InputDataFaceMesh, SizeOf(TInputDataFaceMesh));
  GetMem(OutputDataFaceMesh, SizeOf(TOutputDataFaceMesh));

  LoadThread := TThread.CreateAnonymousThread(
    procedure
    begin
      Load(LoadThread);
    end);


  AniIndicator1.Position.X := (Rectangle1.AbsoluteClipRect.Left + Rectangle1.Width / 2) - AniIndicator1.Width / 2;
  AniIndicator1.Position.Y := (Rectangle1.AbsoluteClipRect.Top + Rectangle1.Height / 2) - AniIndicator1.Height / 2;
  AniIndicator1.Visible := True;
  LoadThread.Start;

  ImageSourceBitmap := TBitmap.Create;
  ImageTargetBitmap := TBitmap.Create;

  FilterContrast := TFilterContrast.Create(nil);
  FilterGaussianBlur := TFilterGaussianBlur.Create(nil);

  if RegistryIni.ReadString(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Language', 'english') = 'russian' then
  begin
    Form1.Label2.Text := 'Виртуальная Камера - ' + ProgramVersion;
    Caption := 'Виртуальная Камера - ' + ProgramVersion;

    Language:= 0;
    Image4.Hint:= 'Switch to English';
    Button3.Text:= 'Старт';

    LabelSharpness.Text:= 'Чёткость';
    LabelContrast.Text:= 'Контрастность';
    LabelBrightness.Text:= 'Яркость';
    LabelSaturation.Text:= 'Насыщенность';

    Button1.Text:= 'Открыть...';

    Image3.Hint:= 'Открыть настройки камеры';
    Image7.Hint:= 'Показывать количество кадров в секунду';

    if PerformanceMode = 0 then
      Image9.Hint:= 'Включить режим высокой производительности'
    else if PerformanceMode = 1 then
      Image9.Hint:= 'Отключить режим высокой производительности';

    Label1.Text := '0 : кадр/с';
  end
  else if RegistryIni.ReadString(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Language', 'english') = 'english' then
  begin
    Form1.Label2.Text := 'Virtual Camera - ' + ProgramVersion;
    Caption := 'Virtual Camera - ' + ProgramVersion;

    Language:= 1;
    Image4.Hint:= 'Переключиться на Русский';
    Button3.Text:= 'Start';

    LabelSharpness.Text:= 'Sharpness';
    LabelContrast.Text:= 'Contrast';
    LabelBrightness.Text:= 'Brightness';
    LabelSaturation.Text:= 'Saturation';

    Button1.Text:= 'Open...';

    Image3.Hint:= 'Open camera settings';
    Image7.Hint:= 'Show number of frames per second';

    if PerformanceMode = 0 then
      Image9.Hint:= 'Enable high performance mode'
    else if PerformanceMode = 1 then
      Image9.Hint:= 'Disable high performance mode';

    Label1.Text := '0 : fps';
  end;

  Camera := TFCamera.Create(nil);
  Camera.Active := False;
  Camera.CaptureType := TFCaptureType.ctGrabber;

  SetLength(CameraDevices, 0);

  if Length(Camera.Devices) > 0 then
  begin
    ComboBox1.Items.BeginUpdate;
    try
      ComboBox1.Items.Clear;
      FDevices := Camera.Devices;

      if Length(FDevices) > 0 then
      begin
        for i := 0 to Length(FDevices) - 1 do
        begin
          if FDevices[i].name <> 'SD Virtual Camera' then
          begin
            SetLength(CameraDevices, Length(CameraDevices) + 1);
            CameraDevices[Length(CameraDevices) - 1]:= FDevices[i];

            ComboBox1.Items.Add(FDevices[i].name);
          end;
        end;
      end;
    finally
      ComboBox1.Items.EndUpdate;
    end;
  end;

  if ComboBox1.Items.Count > 0 then
  begin
    ComboBox1.ItemIndex := 0;
    Camera.DeviceIndex:= 0;
    CameraIndex:= 0;

    try
      Camera.Sharpness := RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Sharpness', Camera.Sharpness);
      Camera.Contrast := RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Contrast', Camera.Contrast);
      Camera.Brightness := RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Brightness', Camera.Brightness);
      Camera.Saturation := RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Saturation', Camera.Saturation);
      Camera.BacklightCompensation := RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'BacklightCompensation', Camera.BacklightCompensation);
      Camera.WhiteBalance := RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'WhiteBalance', Camera.WhiteBalance);
      if RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'WhiteBalanceAuto', 0) = 1 then
        Camera.WhiteBalanceAuto:= True
      else
        Camera.WhiteBalanceAuto:= False;
      Camera.WhiteBalance := RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'BacklightCompensation', Camera.BacklightCompensation);
      if RegistryIni.ReadInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'BacklightCompensationAuto', 0) = 1 then
        Camera.BacklightCompensationAuto:= True
      else
        Camera.BacklightCompensationAuto:= False;
    except
    end;
  end;

  finally
    RegistryIni.Free;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  RegistryIni: TRegIni;
begin
  RegistryIni:= TRegIni.Create;
  try
    Image3.Opacity:= 0.8;

    if Assigned(Camera) then
    begin
      if Camera.DeviceIndex >= 0 then
      begin
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Sharpness', Camera.Sharpness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Contrast', Camera.Contrast);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Brightness', Camera.Brightness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Saturation', Camera.Saturation);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'WhiteBalance', Camera.WhiteBalance);
        if Camera.WhiteBalanceAuto then
          RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'WhiteBalanceAuto', 1)
        else
          RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'WhiteBalanceAuto', 0);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'BacklightCompensation', Camera.BacklightCompensation);
        if Camera.BacklightCompensationAuto then
          RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'BacklightCompensationAuto', 1)
        else
          RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'BacklightCompensationAuto', 0);
      end;
    end;
  finally
    RegistryIni.Free;
  end;
end;

procedure TForm1.Image8Click(Sender: TObject);
begin
  WindowState := TWindowState.wsMinimized;
end;

procedure TForm1.Image9Click(Sender: TObject);
var
  RegistryIni: TRegIni;
  FMessage: String;
begin
  if PerformanceMode = 0 then
  begin
     if Language = 1 then
       FMessage:= 'You must restart the application to apply these changes. Restart application?'
     else if Language = 0 then
       FMessage:= 'Чтобы изменения вступили в силу необходимо перезапустить приложение. Перезапустить программу?';

     if MessageDlg(FMessage, mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
     begin
       PerformanceMode:= 1;
       RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'PerformanceMode', PerformanceMode);
       Image9.Bitmap.Assign(ImageList1.Source[2].MultiResBitmap[0].Bitmap);
       ShellExecute(FmxHandleToHWND(Handle), nil, PWideChar(ApplicationFileName), nil, nil, SW_SHOWNORMAL);
       Application.Terminate;
     end;
  end
  else
  begin
    if Language = 1 then
       FMessage:= 'You must restart the application to apply these changes. Restart application?'
     else if Language = 0 then
       FMessage:= 'Чтобы изменения вступили в силу необходимо перезапустить приложение. Перезапустить программу?';

    if MessageDlg(FMessage, mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
    begin
      PerformanceMode:= 0;
      RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'PerformanceMode', PerformanceMode);
      Image9.Bitmap.Assign(ImageList1.Source[3].MultiResBitmap[0].Bitmap);
      ShellExecute(FmxHandleToHWND(Handle), nil, PWideChar(ApplicationFileName), nil, nil, SW_SHOWNORMAL);
      Application.Terminate;
    end;
  end;

end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
const
  SC_DRAGMOVE = $F012;
begin
  if (X < Image8.AbsoluteRect.Left - 5) and (Y <= 30) then
  begin
    ReleaseCapture;
    SendMessage(FmxHandleToHWND(Handle), WM_SYSCOMMAND, SC_DRAGMOVE, 0);
  end;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
begin
  Image3.Opacity:= 0.8;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  if ModelsLoaded then
  begin
    AniIndicator1.Visible := False;
    Invalidate;
    ImageMain.InvalidateRect(ImageMain.ClipRect);
  end;
end;

procedure DrawLandmarks(Bitmap:TBitmap; LandmarkData: TFaceLandmarkData);
var
  i, X, Y: DWORD;
begin
  Bitmap.Canvas.BeginScene;
  try
    Bitmap.Canvas.Stroke.Color := TAlphaColorRec.Red;
    for Y := 0 to LandmarkData.Count - 1 do
    begin
      Bitmap.Canvas.DrawRect(
        RectF(
        LandmarkData.Points[Y].X - 1,
        LandmarkData.Points[Y].Y - 1,
        LandmarkData.Points[Y].X + 1,
        LandmarkData.Points[Y].Y + 1),
        0, 0, AllCorners, 1);
    end;
  finally
    Bitmap.Canvas.EndScene;
  end;
end;

procedure TForm1.GetSourceLatentImage(SourceBitmap:TBitmap; SourceRect:TRectF; var Bitmap:TBitmap; var LandmarkData: TFaceLandmarkData; var MouthPointY: Single);
var
  i: DWORD;
  FBitmap: TBitmap;
  FRect, FFaceRect: TRectF;
  FScale: Single;
  FSourceAngle: Single;
  FLandmarkData: TFaceLandmarkData;
  FSourceEyePoint, FSourceMouthPoint: TPointF;
begin
  FBitmap := TBitmap.Create;

  if SourceRect.Left < 0 then
    SourceRect.Left := 0;
  if SourceRect.Top < 0 then
    SourceRect.Top := 0;
  if SourceRect.Right > SourceBitmap.Width then
    SourceRect.Right := SourceBitmap.Width;
  if SourceRect.Bottom > SourceBitmap.Height then
    SourceRect.Bottom := SourceBitmap.Height;

  if PerformanceMode = 1 then
  begin
    FRect := SourceRect.FitInto(RectF(0, 0, 192, 192));
    FBitmap.Resize(192, 192);
  end
  else
  begin
    FRect := SourceRect.FitInto(RectF(0, 0, 256, 256));
    FBitmap.Resize(256, 256);
  end;

  FBitmap.Canvas.BeginScene;
  FBitmap.Canvas.Clear(TAlphaColorRec.Null);
  FBitmap.Canvas.DrawBitmap(
    ImageSourceBitmap,
    SourceRect,
    FRect,
    1, False);
  FBitmap.Canvas.EndScene;

  if PerformanceMode = 1 then
    FLandmarkData := GetLandmarkData106(FBitmap)
  else
    FLandmarkData := GetFaceMeshLandmarks(FBitmap);

  {FBitmap.Canvas.BeginScene;
  try
    FBitmap.Canvas.Stroke.Color := TAlphaColorRec.Red;
    for i := 0 to FLandmarkData.Count - 1 do
    begin
      FBitmap.Canvas.DrawRect(
      RectF(
      FLandmarkData.Points[i].X - 1,
      FLandmarkData.Points[i].Y - 1,
      FLandmarkData.Points[i].X + 1,
      FLandmarkData.Points[i].Y + 1),
      0, 0, AllCorners, 1);
    end;
  finally
    FBitmap.Canvas.EndScene;
  end;}

  if PerformanceMode = 1 then
    FSourceAngle := AngleOfLine(FLandmarkData.Points[38], FLandmarkData.Points[88])
  else
    FSourceAngle := AngleOfLine(FLandmarkData.Points[468], FLandmarkData.Points[473]);

  FBitmap.Resize(Round(SourceRect.Width), Round(SourceRect.Height));
  FBitmap.Canvas.BeginScene;
  FBitmap.Canvas.Clear(TAlphaColorRec.Null);
  FBitmap.Canvas.DrawBitmap(
    ImageSourceBitmap,
    SourceRect,
    FBitmap.Bounds,
    1, False);
  FBitmap.Canvas.EndScene;

  if PerformanceMode = 1 then
    FScale:= SourceRect.Width / 192
  else
    FScale:= SourceRect.Width / 256;

  for i := 0 to FLandmarkData.Count - 1 do
  begin
    FLandmarkData.Points[i].X := FLandmarkData.Points[i].X * FScale;
    FLandmarkData.Points[i].Y := FLandmarkData.Points[i].Y * FScale;
  end;

  RotateBitmap(-FSourceAngle, FBitmap);

  for i := 0 to FLandmarkData.Count - 1 do
  begin
    RotatePoint(-FSourceAngle,
      FLandmarkData.Points[i].X, FLandmarkData.Points[i].Y,
      SourceRect.Width / 2, SourceRect.Height / 2,
      FLandmarkData.Points[i].X, FLandmarkData.Points[i].Y);
  end;

  SetLength(LandmarkData.Points, FLandmarkData.Count);
  LandmarkData.Count := FLandmarkData.Count;
  for i := 0 to FLandmarkData.Count - 1 do
  begin
    LandmarkData.Points[i].X := FLandmarkData.Points[i].X;
    LandmarkData.Points[i].Y := FLandmarkData.Points[i].Y;
  end;

  FFaceRect.Left := FBitmap.Width;
  FFaceRect.Top := FBitmap.Height;
  FFaceRect.Right := 0;
  FFaceRect.Bottom := 0;

  for i := 0 to FLandmarkData.Count - 1 do
  begin
    if (FLandmarkData.Points[i].X < FFaceRect.Left) then
      FFaceRect.Left := FLandmarkData.Points[i].X;

    if (FLandmarkData.Points[i].Y < FFaceRect.Top) then
      FFaceRect.Top := FLandmarkData.Points[i].Y;

    if (FLandmarkData.Points[i].X > FFaceRect.Right) then
      FFaceRect.Right := FLandmarkData.Points[i].X;

    if (FLandmarkData.Points[i].Y > FFaceRect.Bottom) then
      FFaceRect.Bottom := FLandmarkData.Points[i].Y;
  end;

  if PerformanceMode = 1 then
  begin
    FSourceMouthPoint.X := FLandmarkData.Points[60].X;
    FSourceMouthPoint.Y := FLandmarkData.Points[62].Y + ((FLandmarkData.Points[60].Y - FLandmarkData.Points[62].Y) / 2);

    //точка уровня глаз
    FSourceEyePoint.X:= (FLandmarkData.Points[72].X);
    FSourceEyePoint.Y:= (FLandmarkData.Points[72].Y);
  end
  else
  begin
    FSourceMouthPoint.X := FLandmarkData.Points[14].X;
    FSourceMouthPoint.Y := FLandmarkData.Points[13].Y + ((FLandmarkData.Points[14].Y - FLandmarkData.Points[13].Y) / 2);

    //точка уровня глаз
    FSourceEyePoint.X:= (FLandmarkData.Points[6].X);
    FSourceEyePoint.Y:= (FLandmarkData.Points[6].Y + ((FLandmarkData.Points[168].Y - FLandmarkData.Points[6].Y) / 2));
  end;

  FFaceRect.Left := FFaceRect.Left - FFaceRect.Width * (10 / 100);
  FFaceRect.Top := 0;
  FFaceRect.Right := FFaceRect.Right + FFaceRect.Width * (10 / 100);
  FFaceRect.Bottom  := FFaceRect.Bottom + FFaceRect.Width * (10 / 100);

  FScale := (128 - StrToInt(Edit1.Text)) / (FFaceRect.Bottom - FSourceEyePoint.Y);

  FRect.Left := FFaceRect.Left * FScale - (FSourceEyePoint.X * FScale - 64);
  FRect.Top :=  - (FSourceEyePoint.Y * FScale - StrToInt(Edit1.Text));
  FRect.Right := FFaceRect.Right * FScale - (FSourceEyePoint.X * FScale - 64);
  FRect.Bottom := FFaceRect.Bottom * FScale + FRect.Top;

  Bitmap.Resize(128, 128);
  Bitmap.Canvas.BeginScene;
  Bitmap.Canvas.Clear(TAlphaColorRec.Null);
  Bitmap.Canvas.EndScene;

  Bitmap.Canvas.BeginScene;
  Bitmap.Canvas.DrawBitmap(
    FBitmap,
    FFaceRect,
    FRect,
    1, False);
  Bitmap.Canvas.EndScene;

  MouthPointY := FSourceMouthPoint.Y  * FScale + FRect.Top;

  if CheckBox1.IsChecked then
  begin
    Bitmap.Canvas.BeginScene;
    Bitmap.Canvas.Fill.Color := TAlphaColorRec.Red;
    Bitmap.Canvas.FillRect(RectF(64, 0, 64 + 1, Bitmap.Height), 0, 0, AllCorners, 1);
    Bitmap.Canvas.FillRect(RectF(0, StrToInt(Edit1.Text), Bitmap.Width, StrToInt(Edit1.Text) + 1), 0, 0, AllCorners, 1);
    Bitmap.Canvas.FillRect(RectF(0, FSourceMouthPoint.Y  * FScale + FRect.Top, Bitmap.Width, FSourceMouthPoint.Y  * FScale + FRect.Top + 1), 0, 0, AllCorners, 1);
    Bitmap.Canvas.EndScene;
  end;

  FBitmap.Free;
end;


procedure TForm1.Image10Click(Sender: TObject);
begin
  //
end;

procedure TForm1.Image3Click(Sender: TObject);
begin
  if Assigned(Camera) then
    Camera.ShowPropertyDialog;
end;

procedure TForm1.Image3MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  (Sender as TImage).Opacity:= 0.8;
end;

procedure TForm1.Image3MouseEnter(Sender: TObject);
begin
  //if Assigned(Camera) then
    //if Camera.Active then
      (Sender as TImage).Opacity:= 1;
end;

procedure TForm1.Image3MouseLeave(Sender: TObject);
begin
  //if Assigned(Camera) then
    //if Camera.Active then
      (Sender as TImage).Opacity:= 0.8;
end;

procedure TForm1.Image3MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  //if Assigned(Camera) then
    //if Camera.Active then
      (Sender as TImage).Opacity:= 1;
end;

procedure TForm1.Image5MouseEnter(Sender: TObject);
begin
  (Sender as TImage).Opacity:= 1;
end;

procedure TForm1.Image5MouseLeave(Sender: TObject);
begin
  (Sender as TImage).Opacity:= 0.75;
end;

procedure TForm1.Image6Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.Image6MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  (Sender as TImage).Opacity:= 0.7;
end;

procedure TForm1.Image6MouseEnter(Sender: TObject);
begin
  (Sender as TImage).Opacity:= 0.85;
end;

procedure TForm1.Image6MouseLeave(Sender: TObject);
begin
   (Sender as TImage).Opacity:= 0.95;
end;

procedure TForm1.Image6MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  (Sender as TImage).Opacity:= 0.95;
end;

procedure TForm1.SwitchLanguage;
var
  RegistryIni: TRegIni;
begin
  if RegistryIni.ReadString(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Language', 'russian') = 'english' then
  begin
    RegistryIni.WriteString(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Language', 'russian');
    Language:= 0;
    Image4.Hint:= 'Switch to English';
    if Button3.Text = 'Start' then
      Button3.Text:= 'Старт';
    if Button3.Text = 'Stop' then
      Button3.Text:= 'Стоп';

    LabelSharpness.Text:= 'Чёткость';
    LabelContrast.Text:= 'Контрастность';
    LabelBrightness.Text:= 'Яркость';
    LabelSaturation.Text:= 'Насыщенность';

    Button1.Text:= 'Открыть...';

    Image3.Hint:= 'Открыть настройки камеры';
    Image7.Hint:= 'Показывать количество кадров в секунду';

    if PerformanceMode = 0 then
      Image9.Hint:= 'Включить режим высокой производительности'
    else if PerformanceMode = 1 then
      Image9.Hint:= 'Отключить режим высокой производительности';

    Form1.Label2.Text := 'Виртуальная Камера - ' + ProgramVersion;
    Caption:= 'Виртуальная Камера - ' + ProgramVersion;
  end
  else if RegistryIni.ReadString(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Language', 'russian') = 'russian' then
  begin
    RegistryIni.WriteString(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Language', 'english');
    Language:= 1;
    Image4.Hint:= 'Переключиться на Русский';
    if Button3.Text = 'Старт' then
      Button3.Text:= 'Start';
    if Button3.Text = 'Стоп' then
      Button3.Text:= 'Stop';

    LabelSharpness.Text:= 'Sharpness';
    LabelContrast.Text:= 'Contrast';
    LabelBrightness.Text:= 'Brightness';
    LabelSaturation.Text:= 'Saturation';

    Button1.Text:= 'Open...';

    Image3.Hint:= 'Open camera settings';
    Image7.Hint:= 'Show number of frames per second';

    if PerformanceMode = 0 then
      Image9.Hint:= 'Enable high performance mode'
    else if PerformanceMode = 1 then
      Image9.Hint:= 'Disable high performance mode';

    Form1.Label2.Text := 'Virtual Camera - ' + ProgramVersion;
    Caption:= 'Virtual Camera - ' + ProgramVersion;
  end;
end;

procedure TForm1.Image4Click(Sender: TObject);
begin
  (Sender as TImage).Opacity:= 1;

  SwitchLanguage;
end;

procedure TForm1.Image4MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  //
end;

procedure TForm1.Image4MouseEnter(Sender: TObject);
begin
  //
end;

procedure TForm1.Image4MouseLeave(Sender: TObject);
begin
  //
end;

procedure TForm1.Image4MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  //
end;

var ShowFrameRate: Boolean = False;

procedure TForm1.Image7Click(Sender: TObject);
var
  RegistryIni: TRegIni;
begin
  if ShowFrameRate then
  begin
     Image7.Bitmap.Assign(ImageList1.Source[1].MultiResBitmap[0].Bitmap);
     ShowFrameRate:= False;
     Label1.Visible:= False;
  end
  else
  begin
    Image7.Bitmap.Assign(ImageList1.Source[0].MultiResBitmap[0].Bitmap);
    ShowFrameRate:= True;
    Label1.Visible:= True;
  end;
end;

procedure TForm1.Image7MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  (Sender as TImage).Opacity:= 0.8;
end;

procedure TForm1.Image7MouseEnter(Sender: TObject);
var
  RegistryIni: TRegIni;
begin
   (Sender as TImage).Opacity:= 1;
end;

procedure TForm1.Image7MouseLeave(Sender: TObject);
begin
   (Sender as TImage).Opacity:= 0.8;
end;

procedure TForm1.Image7MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  (Sender as TImage).Opacity:= 1;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  i, X, Y: DWORD;
  FBitmap: TBitmap;
  FRect, FSourceRect: TRectF;
  FBitmapData: TBitmapData;
  FColors: PAlphaColorArray;
  FNorm: Float32;
  FVectorLatent: TFloat32Array;
  FEnabled: Boolean;
begin
  FBitmap := TBitmap.Create;
  try
    if OpenDialog1.Execute then
    begin
      try
        FEnabled:= Timer1.Enabled;
        Timer1.Enabled:= False;

        ImageSourceBitmap.LoadFromFile(OpenDialog1.FileName);

        DetectedFaceSourceList := FaceDetect(0.5, ImageSourceBitmap, False, False, 25, 25);

        if DetectedFaceSourceList.Count > 0 then
        begin
          FRect := DetectedFaceSourceList.SegmentFaces[0].Rect;
          if FRect.Left < 0 then
            FRect.Left := 0;
          if FRect.Top < 0 then
            FRect.Top := 0;
          if FRect.Right > ImageSourceBitmap.width then
            FRect.Right := ImageSourceBitmap.width;
          if FRect.Bottom > ImageSourceBitmap.height then
            FRect.Bottom := ImageSourceBitmap.height;

          Image1.Bitmap.Resize(128, 128);
          Image1.Bitmap.Canvas.BeginScene;
          try
            Image1.Bitmap.Canvas.DrawBitmap(
              ImageSourceBitmap,
              FRect,
              Image1.Bitmap.Bounds,
              1, False);
          finally
            Image1.Bitmap.Canvas.EndScene;
          end;

          FSourceRect := DetectedFaceSourceList.SegmentFaces[0].Rect;

          GetSourceLatentImage(ImageSourceBitmap, FSourceRect, FBitmap, SourceFaceLandmarkData, SourceFaceMouthPointY);

          FBitmap.Resize(112, 112);

          //FilterContrast.Input := ImageSourceBitmap;
          //FilterContrast.Contrast := 1.5;
          //ImageSourceBitmap.Assign(FilterContrast.Output);

          FBitmap.Map(TMapAccess.Read, FBitmapData);
          for Y := 0 to 112 - 1 do
          begin
            FColors := PAlphaColorArray(FBitmapData.GetScanline(Y));

            for X := 0 to 112 - 1 do
            begin
              LatentSourceInputData[0][Y][X] := (TAlphaColorRec(FColors[X]).R / 255);
              LatentSourceInputData[1][Y][X] := (TAlphaColorRec(FColors[X]).G / 255);
              LatentSourceInputData[2][Y][X] := (TAlphaColorRec(FColors[X]).B / 255);
            end;
          end;
          FBitmap.Unmap(FBitmapData);

          Function_003(
            LatentSourceInputData, SizeOf(TLatentSourceInputData),
            LatentOutputData, SizeOf(TLatentOutputData));

          for i := 0 to 512 - 1 do
            FVectorLatent[i] := LatentOutputData[i];

          FVectorLatent := Dot(FVectorLatent, VectorMap);

          for i := 0 to 512 - 1 do
            LatentOutputData[i] := FVectorLatent[i];

          FNorm := 0.0;

          for i := 0 to 512 - 1 do
            FNorm := FNorm + Sqr(LatentOutputData[i]);

          FNorm := Sqrt(FNorm);

          for i := 0 to 512 - 1 do
            LatentOutputData[i] := (LatentOutputData[i] / FNorm);

          if Assigned(Image1.Bitmap) then
            Image2.Visible:=False
          else
            Image2.Visible:=True;

          Button3.Enabled := True;
        end;
      finally
        Timer1.Enabled:= FEnabled;
      end;
    end;
  finally
     FBitmap.Free;
  end;

  TrackBarSharpness.SetFocus;
end;


procedure TForm1.Button5Click(Sender: TObject);
begin
  //
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  if CameraIndex <> ComboBox1.ItemIndex then
  begin
    if Assigned(Camera) then
    begin
      if (Camera.Active = True)  then
      begin
        Timer1.Enabled := False;

        Camera.Stop;
        Camera.Active := False;
        Camera.Free;
        Camera:= nil;

        Button3.Text := 'Старт';
        TrackBarSharpness.SetFocus;

        if Assigned(Image1.Bitmap) then
          Image2.Visible:=False
        else
          Image2.Visible:=True;
      end;
    end;
  end;
end;

var FTargetRect, TargetRect: TRectF;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  FTickCountInference: Int64;
  i, X, Y, FPixel, FFaceIndex: DWORD;
  FBitmap, FFaceBitmap, FBitmapMask: TBitmap;
  FRect, FSourceRect, FFaceRect: TRectF;
  FScale, FLeft, FTop, FWidth, FHeight: Single;
  FSourceAngle, FTargetAngle: Single;
  FColors, FColorsMask: PAlphaColorArray;
  FColor, FColorMask: TAlphaColorRec;
  FBitmapData, FBitmapDataMask, FBitmapDataFace: TBitmapData;
  FSourceMouthPoint: TPointF;
  FSourceEyePoint: TPointF;
  FTargetMouthPoint: TPointF;
  FTargetEyePoint: TPointF;
  FTargetFacePolygon: TPolygon;
  FTargetEyeTop, FTargetMouthTop: Single;
  FDifference: Single;
begin
  Sleep(1);

  FTickCountInference := TThread.GetTickCount;

  FBitmap := TBitmap.Create;
  FFaceBitmap := TBitmap.Create;

  if Assigned(Camera) then
    if Camera.Active then
      Camera.CurrentImageToBitmap(ImageTargetBitmap);

  DetectedFaceTargetList := FaceDetect(0.25, ImageTargetBitmap, False, False, 25, 25);

  if DetectedFaceTargetList.Count = 0 then
    Exit;

  FFaceIndex:= 0;

  FLeft:= Abs(DetectedFaceTargetList.SegmentFaces[0].Rect.CenterPoint.X - (ImageTargetBitmap.Width / 2));
  FTop:= Abs(DetectedFaceTargetList.SegmentFaces[0].Rect.CenterPoint.Y - (ImageTargetBitmap.Height / 2));
  FDifference:= DetectedFaceTargetList.SegmentFaces[0].Probability;

  if DetectedFaceTargetList.Count > 1 then
  begin
    for i := 0 to DetectedFaceTargetList.Count - 1 do
    begin
      if (Abs(DetectedFaceTargetList.SegmentFaces[i].Rect.CenterPoint.X - (ImageTargetBitmap.Width / 2)) < FLeft) or
      (Abs(DetectedFaceTargetList.SegmentFaces[i].Rect.CenterPoint.Y - (ImageTargetBitmap.Height / 2)) < FTop) or
        (FDifference > DetectedFaceTargetList.SegmentFaces[i].Probability) then
      begin
        FLeft:= Abs(DetectedFaceTargetList.SegmentFaces[i].Rect.CenterPoint.X - (ImageTargetBitmap.Width / 2));
        FTop:= Abs(DetectedFaceTargetList.SegmentFaces[i].Rect.CenterPoint.Y - (ImageTargetBitmap.Height / 2));
        FDifference:= DetectedFaceTargetList.SegmentFaces[i].Probability;
        FFaceIndex:= i;
      end;
    end;
  end;

  TargetRect := DetectedFaceTargetList.SegmentFaces[FFaceIndex].Rect;

  if TargetRect.Left < 0 then
    TargetRect.Left := 0;
  if TargetRect.Top < 0 then
    TargetRect.Top := 0;
  if TargetRect.Right > ImageTargetBitmap.Width then
    TargetRect.Right := ImageTargetBitmap.Width;
  if TargetRect.Bottom > ImageTargetBitmap.Height then
    TargetRect.Bottom := ImageTargetBitmap.Height;

  if (Abs(FTargetRect.Left - TargetRect.Left) >= 8) or (Abs(FTargetRect.Top - TargetRect.Top) >= 8) or
    (Abs(FTargetRect.Right - TargetRect.Right) >= 8) or (Abs(FTargetRect.Bottom - TargetRect.Bottom) >= 8) then
    FTargetRect:= TargetRect;

  if PerformanceMode = 1 then
  begin
    FRect := FTargetRect.FitInto(RectF(0, 0, 192, 192));
    FBitmap.Resize(192, 192);
  end
  else
  begin
    FRect := FTargetRect.FitInto(RectF(0, 0, 256, 256));
    FBitmap.Resize(256, 256);
  end;

  FBitmap.Canvas.BeginScene;
  FBitmap.Canvas.Clear(TAlphaColorRec.Null);
  FBitmap.Canvas.DrawBitmap(
    ImageTargetBitmap,
    FTargetRect,
    FRect,
    1, False);
  FBitmap.Canvas.EndScene;

  FilterContrast.Input := FBitmap;
  FilterContrast.Contrast := 1.0;
  FBitmap.Assign(FilterContrast.Output);

  if PerformanceMode = 1 then
    FTargetFaceLandmarkData := GetLandmarkData106(FBitmap)
  else
    FTargetFaceLandmarkData := GetFaceMeshLandmarks(FBitmap);

  SetLength(TargetFaceLandmarkData.Points, Length(FTargetFaceLandmarkData.Points));
  TargetFaceLandmarkData.Count:= FTargetFaceLandmarkData.Count;

  SetLength(FTargetFaceLandmarkDataA.Points, Length(FTargetFaceLandmarkData.Points));
  FTargetFaceLandmarkDataA.Count:= FTargetFaceLandmarkData.Count;

  FDifference:= 1.0;

  if PerformanceMode = 1 then
  begin
    if (Abs(FTargetFaceLandmarkData.Points[72].X - FTargetFaceLandmarkDataA.Points[72].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[72].Y - FTargetFaceLandmarkDataA.Points[72].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[60].X - FTargetFaceLandmarkDataA.Points[60].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[60].Y - FTargetFaceLandmarkDataA.Points[60].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[33].X - FTargetFaceLandmarkDataA.Points[33].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[33].Y - FTargetFaceLandmarkDataA.Points[33].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[40].X - FTargetFaceLandmarkDataA.Points[40].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[40].Y - FTargetFaceLandmarkDataA.Points[40].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[94].X - FTargetFaceLandmarkDataA.Points[94].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[94].Y - FTargetFaceLandmarkDataA.Points[94].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[87].X - FTargetFaceLandmarkDataA.Points[87].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[87].Y - FTargetFaceLandmarkDataA.Points[87].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[62].X - FTargetFaceLandmarkDataA.Points[62].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[62].Y - FTargetFaceLandmarkDataA.Points[62].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[0].X - FTargetFaceLandmarkDataA.Points[0].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[0].Y - FTargetFaceLandmarkDataA.Points[0].Y) >= FDifference) then
    begin
      for i := 0 to FTargetFaceLandmarkData.Count - 1 do
      begin
        TargetFaceLandmarkData.Points[i].X := FTargetFaceLandmarkData.Points[i].X;
        TargetFaceLandmarkData.Points[i].Y := FTargetFaceLandmarkData.Points[i].Y;
      end;

      for i := 0 to FTargetFaceLandmarkData.Count - 1 do
      begin
        FTargetFaceLandmarkDataA.Points[i].X := FTargetFaceLandmarkData.Points[i].X;
        FTargetFaceLandmarkDataA.Points[i].Y := FTargetFaceLandmarkData.Points[i].Y;
      end;
    end
    else
    begin
      for i := 0 to FTargetFaceLandmarkDataA.Count - 1 do
      begin
        TargetFaceLandmarkData.Points[i].X := FTargetFaceLandmarkDataA.Points[i].X;
        TargetFaceLandmarkData.Points[i].Y := FTargetFaceLandmarkDataA.Points[i].Y;
      end;
    end;
  end
  else
  begin
    if (Abs(FTargetFaceLandmarkData.Points[6].X - FTargetFaceLandmarkDataA.Points[6].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[6].Y - FTargetFaceLandmarkDataA.Points[6].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[13].X - FTargetFaceLandmarkDataA.Points[13].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[13].Y - FTargetFaceLandmarkDataA.Points[13].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[14].X - FTargetFaceLandmarkDataA.Points[14].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[14].Y - FTargetFaceLandmarkDataA.Points[14].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[159].X - FTargetFaceLandmarkDataA.Points[159].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[159].Y - FTargetFaceLandmarkDataA.Points[159].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[145].X - FTargetFaceLandmarkDataA.Points[145].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[145].Y - FTargetFaceLandmarkDataA.Points[145].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[374].X - FTargetFaceLandmarkDataA.Points[374].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[374].Y - FTargetFaceLandmarkDataA.Points[374].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[386].X - FTargetFaceLandmarkDataA.Points[386].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[386].Y - FTargetFaceLandmarkDataA.Points[386].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[152].X - FTargetFaceLandmarkDataA.Points[152].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[152].Y - FTargetFaceLandmarkDataA.Points[152].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[61].X - FTargetFaceLandmarkDataA.Points[61].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[61].Y - FTargetFaceLandmarkDataA.Points[61].Y) >= FDifference) or

    (Abs(FTargetFaceLandmarkData.Points[291].X - FTargetFaceLandmarkDataA.Points[291].X) >= FDifference) or
    (Abs(FTargetFaceLandmarkData.Points[291].Y - FTargetFaceLandmarkDataA.Points[291].Y) >= FDifference) then
    begin
      for i := 0 to FTargetFaceLandmarkData.Count - 1 do
      begin
        TargetFaceLandmarkData.Points[i].X := FTargetFaceLandmarkData.Points[i].X;
        TargetFaceLandmarkData.Points[i].Y := FTargetFaceLandmarkData.Points[i].Y;
      end;

      for i := 0 to FTargetFaceLandmarkData.Count - 1 do
      begin
        FTargetFaceLandmarkDataA.Points[i].X := FTargetFaceLandmarkData.Points[i].X;
        FTargetFaceLandmarkDataA.Points[i].Y := FTargetFaceLandmarkData.Points[i].Y;
      end;
    end
    else
    begin
      for i := 0 to FTargetFaceLandmarkDataA.Count - 1 do
      begin
        TargetFaceLandmarkData.Points[i].X := FTargetFaceLandmarkDataA.Points[i].X;
        TargetFaceLandmarkData.Points[i].Y := FTargetFaceLandmarkDataA.Points[i].Y;
      end;
    end;
  end;

  /////
  if PerformanceMode = 1 then
  begin
    FTargetAngle := AngleOfLine(TargetFaceLandmarkData.Points[38], TargetFaceLandmarkData.Points[88]);
    FScale := FTargetRect.Width / 192;
  end
  else
  begin
    FTargetAngle := AngleOfLine(TargetFaceLandmarkData.Points[468], TargetFaceLandmarkData.Points[473]);
    FScale := FTargetRect.Width / 256;
  end;

  FBitmap.Resize(Round(FTargetRect.Width), Round(FTargetRect.Height));
  FBitmap.Canvas.BeginScene;
  FBitmap.Canvas.Clear(TAlphaColorRec.Null);
  FBitmap.Canvas.DrawBitmap(
    ImageTargetBitmap,
    FTargetRect,
    FBitmap.Bounds,
    1, False);
  FBitmap.Canvas.EndScene;

  for i := 0 to TargetFaceLandmarkData.Count - 1 do
  begin
    TargetFaceLandmarkData.Points[i].X := TargetFaceLandmarkData.Points[i].X * FScale;
    TargetFaceLandmarkData.Points[i].Y := TargetFaceLandmarkData.Points[i].Y * FScale;
  end;

  if PerformanceMode = 1 then
  begin
    FTop := 5;
    TargetFaceLandmarkData.Points[43].X := TargetFaceLandmarkData.Points[43].X - 5;
    TargetFaceLandmarkData.Points[43].Y := TargetFaceLandmarkData.Points[43].Y - FTop;
    TargetFaceLandmarkData.Points[48].Y := TargetFaceLandmarkData.Points[48].Y - FTop;
    TargetFaceLandmarkData.Points[49].Y := TargetFaceLandmarkData.Points[49].Y - FTop;
    TargetFaceLandmarkData.Points[50].Y := TargetFaceLandmarkData.Points[50].Y - FTop;
    TargetFaceLandmarkData.Points[51].Y := TargetFaceLandmarkData.Points[51].Y - FTop;
    TargetFaceLandmarkData.Points[102].Y := TargetFaceLandmarkData.Points[102].Y - FTop;
    TargetFaceLandmarkData.Points[103].Y := TargetFaceLandmarkData.Points[103].Y - FTop;
    TargetFaceLandmarkData.Points[104].Y := TargetFaceLandmarkData.Points[104].Y - FTop;
    TargetFaceLandmarkData.Points[105].Y := TargetFaceLandmarkData.Points[105].Y - FTop;
    TargetFaceLandmarkData.Points[101].X := TargetFaceLandmarkData.Points[101].X + 5;
    TargetFaceLandmarkData.Points[101].Y := TargetFaceLandmarkData.Points[101].Y - FTop;

    TargetFaceLandmarkData.Points[8].Y := TargetFaceLandmarkData.Points[22].Y - FTop;
    TargetFaceLandmarkData.Points[0].Y := TargetFaceLandmarkData.Points[22].Y - FTop;
    TargetFaceLandmarkData.Points[24].Y := TargetFaceLandmarkData.Points[22].Y - FTop;
    TargetFaceLandmarkData.Points[7].Y := TargetFaceLandmarkData.Points[22].Y - FTop;
    TargetFaceLandmarkData.Points[23].Y := TargetFaceLandmarkData.Points[22].Y - FTop;
  end;


  if PerformanceMode = 1 then
  begin
    FTargetMouthPoint.X := TargetFaceLandmarkData.Points[60].X;
    FTargetMouthPoint.Y := TargetFaceLandmarkData.Points[62].Y + ((TargetFaceLandmarkData.Points[60].Y - TargetFaceLandmarkData.Points[62].Y) / 2);

    //точка уровня глаз
    FTargetEyePoint.X:= (TargetFaceLandmarkData.Points[72].X);
    FTargetEyePoint.Y:= (TargetFaceLandmarkData.Points[72].Y);
  end
  else
  begin
    FTargetMouthPoint.X := TargetFaceLandmarkData.Points[14].X;
    FTargetMouthPoint.Y := TargetFaceLandmarkData.Points[13].Y + ((TargetFaceLandmarkData.Points[14].Y - TargetFaceLandmarkData.Points[13].Y) / 2);

    //точка уровня глаз
    FTargetEyePoint.X:= (TargetFaceLandmarkData.Points[6].X);
    FTargetEyePoint.Y:= ((TargetFaceLandmarkData.Points[6].Y + ((TargetFaceLandmarkData.Points[168].Y - TargetFaceLandmarkData.Points[6].Y) / 2)));
  end;

  FScale := (SourceFaceMouthPointY - StrToInt(Edit1.Text)) / (FTargetMouthPoint.Y - FTargetEyePoint.Y);

  FFaceRect.Left := (64 - FTargetEyePoint.X * FScale);
  FFaceRect.Top := (StrToInt(Edit1.Text) - FTargetEyePoint.Y * FScale);
  FFaceRect.Right := (FBitmap.Width * FScale + FFaceRect.Left) ;
  FFaceRect.Bottom := (FBitmap.Height * FScale + FFaceRect.Top) ;

  FFaceBitmap.Resize(128, 128);
  FFaceBitmap.Canvas.BeginScene;
  FFaceBitmap.Canvas.Clear(TAlphaColorRec.Null);
  FFaceBitmap.Canvas.EndScene;

  FFaceBitmap.Canvas.BeginScene;
  FFaceBitmap.Canvas.DrawBitmap(
    FBitmap,
    FBitmap.Bounds,
    FFaceRect,
    1, False);
  FFaceBitmap.Canvas.EndScene;

  for i := 0 to TargetFaceLandmarkData.Count - 1 do
  begin
    TargetFaceLandmarkData.Points[i].X := TargetFaceLandmarkData.Points[i].X * FScale + FFaceRect.Left;
    TargetFaceLandmarkData.Points[i].Y := TargetFaceLandmarkData.Points[i].Y * FScale + FFaceRect.Top;
  end;

  {if CheckBox1.IsChecked then
  begin
    FFaceBitmap.Canvas.BeginScene;
    FFaceBitmap.Canvas.Fill.Color := TAlphaColorRec.Red;
    FFaceBitmap.Canvas.FillRect(RectF(64, 0, 64 + 1, FFaceBitmap.Height), 0, 0, AllCorners, 1);
    FFaceBitmap.Canvas.FillRect(RectF(0, StrToInt(Edit1.Text), FFaceBitmap.Width, StrToInt(Edit1.Text) + 1), 0, 0, AllCorners, 1);
    FFaceBitmap.Canvas.FillRect(RectF(0, SourceFaceMouthPointY, FFaceBitmap.Width, SourceFaceMouthPointY + 1), 0, 0, AllCorners, 1);
    FFaceBitmap.Canvas.EndScene;
  end;}

  //Image2.Bitmap.Assign(FFaceBitmap);

  FScale := (FTargetMouthPoint.Y - FTargetEyePoint.Y) / (SourceFaceMouthPointY - StrToInt(Edit1.Text));

  TargetRect.Left:= FTargetRect.Left - FFaceRect.Left * FScale;
  TargetRect.Top:= FTargetRect.Top - FFaceRect.Top * FScale;
  TargetRect.Width:= FTargetRect.Width - (FFaceRect.Width - 128) * FScale;
  TargetRect.Height:= FTargetRect.Height - (FFaceRect.Height - 128) * FScale;

  if FFaceBitmap.Map(TMapAccess.Read, FBitmapData) then
  begin
    try
      for Y := 0 to 128 - 1 do
      begin
        FColors := PAlphaColorArray(FBitmapData.GetScanline(Y));

        for X := 0 to 128 - 1 do
        begin
          LatentTargetInputData[0][Y][X] := (TAlphaColorRec(FColors[X]).R / 255);
          LatentTargetInputData[1][Y][X] := (TAlphaColorRec(FColors[X]).G / 255);
          LatentTargetInputData[2][Y][X] := (TAlphaColorRec(FColors[X]).B / 255);
        end;
      end;
    finally
      FFaceBitmap.Unmap(FBitmapData);
    end;
  end;

    Function_002(LatentTargetInputData, 128, SizeOf(TOutputImageData),
      LatentOutputData, SizeOf(TLatentOutputData),
      OutputImageData, SizeOf(TOutputImageData));

    FBitmap.Resize(128, 128);
    FBitmap.Canvas.BeginScene;
    FBitmap.Canvas.Clear(TAlphaColorRec.Null);
    FBitmap.Canvas.EndScene;

    if (FBitmap.Map(TMapAccess.ReadWrite, FBitmapData)) then
    begin
      try
        for Y := 0 to 128 - 1 do
        begin
          for X := 0 to 128 - 1 do
          begin
            if (X > FFaceRect.Left) and (Y > FFaceRect.Top)  and (X < FFaceRect.Right) and (Y < FFaceRect.Bottom) then
            begin
              FColor.R := Round(255 * OutputImageData[0][Y][X]);
              FColor.G := Round(255 * OutputImageData[1][Y][X]);
              FColor.B := Round(255 * OutputImageData[2][Y][X]);
              FColor.A := 255;

              FBitmapData.SetPixel(X, Y, FColor.Color);
            end;
          end;
        end;
      finally
        FBitmap.Unmap(FBitmapData);
      end;
    end;

    if PerformanceMode = 1 then
    begin
      SetLength(FTargetFacePolygon, 0);

      FLeft := 5;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[1].X + FLeft;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[1].Y;

      SetLength(FTargetFacePolygon, 0);
      for i := 9 to 16 do
      begin
        SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[i].X + FLeft;
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[i].Y;
      end;

      for i := 2 to 8 do
      begin
        SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[i].X + FLeft;
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[i].Y;
      end;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[0].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[0].Y;

      FLeft := 5;

      for i := 24 downto 18 do
      begin
        SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[i].X - FLeft;
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[i].Y;
      end;

      for i := 32 downto 25 do
      begin
        SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[i].X - FLeft;
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[i].Y;
      end;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[17].X - FLeft;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[17].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[101].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[101].Y;

      for i := 105 downto 102 do
      begin
        SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[i].X;
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[i].Y;
      end;

      for i := 50 downto 48 do
      begin
        SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[i].X;
        FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[i].Y;
      end;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[43].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[43].Y;
    end
    else
    begin
      SetLength(FTargetFacePolygon, 0);

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[143].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[143].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[139].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[139].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[139].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[139].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[71].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[71].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[68].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[68].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[104].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[104].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[69].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[69].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[108].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[108].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[151].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[151].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[337].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[337].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[299].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[299].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[333].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[333].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[298].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[298].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[301].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[301].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[368].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[368].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[372].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[372].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[345].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[345].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[352].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[352].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[411].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[411].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[434].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[434].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[430].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[430].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[431].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[431].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[262].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[262].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[428].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[428].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[199].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[199].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[208].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[208].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[32].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[32].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[211].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[211].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[210].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[210].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[214].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[214].Y;
      ////////////

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[61].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[61].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[76].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[76].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[62].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[62].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[78].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[78].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[95].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[95].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[88].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[88].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[178].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[178].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[87].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[87].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[14].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[14].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[317].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[317].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[402].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[402].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[318].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[318].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[324].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[324].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[308].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[308].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[415].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[415].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[310].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[310].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[311].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[311].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[312].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[312].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[13].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[13].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[82].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[82].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[81].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[81].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[80].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[80].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[191].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[191].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[78].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[78].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[61].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[61].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[214].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[214].Y;

      //////////
      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[187].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[187].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[123].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[123].Y;

      SetLength(FTargetFacePolygon, Length(FTargetFacePolygon) + 1);
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].X := TargetFaceLandmarkData.Points[116].X;
      FTargetFacePolygon[Length(FTargetFacePolygon) - 1].Y := TargetFaceLandmarkData.Points[116].Y;
    end;

    FBitmapMask := TBitmap.Create(128, 128);
    try
      FBitmapMask.Canvas.BeginScene;
      try
        FBitmapMask.Canvas.Clear(TAlphaColorRec.Null);
        FBitmapMask.Canvas.Stroke.Color := TAlphaColorRec.White;
        FBitmapMask.Canvas.Fill.Color := TAlphaColorRec.White;
        FBitmapMask.Canvas.FillPolygon(FTargetFacePolygon, 1);
      finally
        FBitmapMask.Canvas.EndScene;
      end;

      FilterGaussianBlur.Input := FBitmapMask;
      if PerformanceMode = 1 then
       FilterGaussianBlur.BlurAmount := 1.5
      else
       FilterGaussianBlur.BlurAmount := 1.0;
      FBitmapMask.Assign(FilterGaussianBlur.Output);

      FFaceBitmap.Resize(128, 128);
      FFaceBitmap.Canvas.BeginScene;
      FFaceBitmap.Canvas.Clear(TAlphaColorRec.Null);
      FFaceBitmap.Canvas.EndScene;

      FBitmap.Map(TMapAccess.Read, FBitmapData);
      try
        FBitmapMask.Map(TMapAccess.ReadWrite, FBitmapDataMask);
        try
          FFaceBitmap.Canvas.BeginScene;
          try
            for Y := 0 to FFaceBitmap.Height - 1 do
            begin
              FColors := PAlphaColorArray(FBitmapData.GetScanline(Y));
              FColorsMask := PAlphaColorArray(FBitmapDataMask.GetScanline(Y));

              for X := 0 to FFaceBitmap.width - 1 do
              begin
                FColor.R := TAlphaColorRec(FColors[X]).R;
                FColor.G := TAlphaColorRec(FColors[X]).G;
                FColor.B := TAlphaColorRec(FColors[X]).B;

                if TAlphaColorRec(FColorsMask[X]).R > 0 then
                begin
                  FFaceBitmap.Canvas.Stroke.Color := FColor.Color;
                  FFaceBitmap.Canvas.Fill.Color := FColor.Color;
                  FFaceBitmap.Canvas.FillRect(RectF(X, Y, X + 1, Y + 1), (TAlphaColorRec(FColorsMask[X]).A / (255 / 100)) / 100);
                end;
              end;
            end;
          finally
            FFaceBitmap.Canvas.EndScene;
          end;
        finally
          FBitmapMask.Unmap(FBitmapDataMask);
        end;
      finally
        FBitmap.Unmap(FBitmapData);
      end;
    finally
      FBitmapMask.Free;
    end;

  if CheckBox1.IsChecked then
  begin
    FFaceBitmap.Canvas.BeginScene;
    try
      FFaceBitmap.Canvas.Stroke.Color := TAlphaColorRec.Red;
      for Y := 0 to TargetFaceLandmarkData.Count - 1 do
      begin
        FFaceBitmap.Canvas.DrawRect(
        RectF(
          TargetFaceLandmarkData.Points[Y].X,
          TargetFaceLandmarkData.Points[Y].Y,
          TargetFaceLandmarkData.Points[Y].X + 1,
          TargetFaceLandmarkData.Points[Y].Y + 1),
        0, 0, AllCorners, 1);
      end;
    finally
      FFaceBitmap.Canvas.EndScene;
    end;
  end;

  ImageTargetBitmap.Canvas.BeginScene;
  ImageTargetBitmap.Canvas.DrawBitmap(
    FFaceBitmap,
    FFaceBitmap.Bounds,
    TargetRect,
    0.85, False);

  ImageTargetBitmap.Canvas.EndScene;

  ImageMain.Bitmap.Resize(ImageTargetBitmap.Width, ImageTargetBitmap.Height);

  ImageMain.Bitmap.Canvas.BeginScene;
  ImageMain.Bitmap.Canvas.DrawBitmap(
    ImageTargetBitmap,
    ImageTargetBitmap.Bounds,
    ImageTargetBitmap.Bounds,
    1, False);
  ImageMain.Bitmap.Canvas.EndScene;

  //ImageMain.Bitmap.Assign(ImageTargetBitmap);

  if Function_013(VirtualCamera) then
  begin
    FPixel := 0;

    ImageTargetBitmap.Map(TMapAccess.Read, FBitmapData);
    try
      for Y := 0 to ImageTargetBitmap.height - 1 do
      begin
        FColors := PAlphaColorArray(FBitmapData.GetScanline(Y));

        for X := 0 to ImageTargetBitmap.width - 1 do
        begin
          VirtualCameraData[FPixel][0] := TAlphaColorRec(FColors[X]).B;
          VirtualCameraData[FPixel][1] := TAlphaColorRec(FColors[X]).G;
          VirtualCameraData[FPixel][2] := TAlphaColorRec(FColors[X]).R;

          Inc(FPixel);
        end;
      end;

      Function_011(VirtualCamera, VirtualCameraData);
    finally
      ImageTargetBitmap.Unmap(FBitmapData);
    end;
  end;

  if CheckBox1.IsChecked then
  begin
    ImageMain.Bitmap.Canvas.BeginScene;
    ImageMain.Bitmap.Canvas.Stroke.Color := TAlphaColorRec.Red;
    ImageMain.Bitmap.Canvas.DrawRect(FTargetRect, 1);
    ImageMain.Bitmap.Canvas.EndScene;
  end;

  FFaceBitmap.Free;
  FBitmap.Free;

  FFPS := FFPS + (TThread.GetTickCount - FTickCountInference) / 1000;
  FFPSTotal := FFPSTotal + Round(1 / ((TThread.GetTickCount - FTickCountInference) / 1000));
  Inc(FFPSCount);

  if FFPS >= 1 then
  begin
    // Caption := 'FPS: ' + FloatToStr( (TThread.GetTickCount - FTickCountInference) / 1000);
    if Language = 0 then
      Label1.Text :=  IntToStr(FFPSTotal div FFPSCount) + ' : кадр/с'
    else if Language = 1 then
      Label1.Text := IntToStr(FFPSTotal div FFPSCount) + ' : fps';

    FFPS := 0;
    FFPSCount := 0;
    FFPSTotal := 0;
  end;
end;


procedure TForm1.Button3Click(Sender: TObject);
var
  i: Integer;
  FResult: HResult;
begin
  try
  if Assigned(Camera) then
  begin
    if (Camera.Active = True) or (Button3.Text = 'Стоп') or (Button3.Text = 'Stop') then
    begin
      Timer1.Enabled := False;

      Camera.Stop;
      Camera.Active := False;
      Camera.Free;
      Camera:= nil;
      if Language = 0 then
      begin
        Button3.Text := 'Старт';
        Label1.Text := '0 : кадр/с';
      end
      else if Language = 1 then
      begin
        Button3.Text:= 'Start';
        Label1.Text := '0 : fps';
      end;

      Exit;
    end;
  end;

  if (Assigned(Image1.Bitmap) = False) or (DetectedFaceSourceList.Count = 0)then
    Exit;

  if Assigned(Camera) then
  begin
    if (Camera.Active = True) then
    begin
      Camera.Stop;
      Camera.Active := False;
    end;

    Camera.Free;
    Camera:= nil;
  end;

  try
    Camera := TFCamera.Create(nil);
    Camera.Active := False;
    Camera.CaptureType := TFCaptureType.ctGrabber;
  except
  end;

  for i := 0 to Length(Camera.Devices) - 1 do
  begin
    if Camera.Devices[i].Path = CameraDevices[ComboBox1.ItemIndex].Path then
    begin
      Camera.DeviceIndex := i;
      CameraIndex:= ComboBox1.ItemIndex;
      Break;
    end;
  end;

  for i := 0 to Length(Camera.SupportedFormats) - 1 do
  begin
    if (Camera.SupportedFormats[i].Width = 640) and (Camera.SupportedFormats[i].Height = 480) then
    begin
      if (10000000 div Camera.SupportedFormats[i].AvgTimePerFrame >= 24) then
      begin
        Camera.Format := Camera.SupportedFormats[CameraIndex];

        ImageTargetBitmap.width := Camera.Format.Width;
        ImageTargetBitmap.height := Camera.Format.Height;

        if VirtualCamera = nil then
        begin
          VirtualCamera := Function_009(Camera.Format.Width, Camera.Format.Height, 0);
        end;

        if VirtualCamera <> nil then
        begin
          if Camera.SharpnessSupported then
          begin
            TrackBarSharpness.Min := Camera.SharpnessRange.Min;
            TrackBarSharpness.Max := Camera.SharpnessRange.Max;
            TrackBarSharpness.Frequency := Camera.SharpnessRange.Delta;
            TrackBarSharpness.Value := Camera.Sharpness;
          end;

          if Camera.ContrastSupported then
          begin
            TrackBarContrast.Min := Camera.ContrastRange.Min;
            TrackBarContrast.Max := Camera.ContrastRange.Max;
            TrackBarContrast.Frequency := Camera.ContrastRange.Delta;
            TrackBarContrast.Value := Camera.Contrast;
          end;

          if Camera.BrightnessSupported then
          begin
            TrackBarBrightness.Min := Camera.BrightnessRange.Min;
            TrackBarBrightness.Max := Camera.BrightnessRange.Max;
            TrackBarBrightness.Frequency := Camera.BrightnessRange.Delta;
            TrackBarBrightness.Value := Camera.Brightness;
          end;

          if Camera.SaturationSupported then
          begin
            TrackBarSaturation.Min := Camera.SaturationRange.Min;
            TrackBarSaturation.Max := Camera.SaturationRange.Max;
            TrackBarSaturation.Frequency := Camera.SaturationRange.Delta;
            TrackBarSaturation.Value := Camera.Saturation;
          end;

          Camera.Active := True;

          if Camera.Active = True then
          begin
            try
              Camera.Run;
            except
              CheckError(FResult);

              if FResult <> 0 then
              begin
                MessageBox(0, PWideChar('Камера ' + Camera.Devices[CameraIndex].Name + ' используется другим приложением, в приложении для звонков, мессенджерах, стриминга и т.д. выберите устройство с названием SD Virtual Camera'), 'SD Virtual Camera', 0);
              end;

              Camera.Active := False;
              Exit;
            end;

            if Language = 0 then
              Button3.Text := 'Стоп'
            else if Language = 1 then
              Button3.Text:= 'Stop';

            Timer1.Enabled := True;
          end;
        end;

        Break;
      end;
    end;
  end;
  finally
    TrackBarSharpness.SetFocus;
  end;
end;


procedure TForm1.TrackBarBrightnessChange(Sender: TObject);
var
  RegistryIni: TRegIni;
begin
  if Assigned(Camera) then
    if Camera.Active then
    begin
      Camera.Brightness := Trunc(TrackBarBrightness.Value);

      RegistryIni:= TRegIni.Create;
      try
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Sharpness', Camera.Sharpness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Contrast', Camera.Contrast);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Brightness', Camera.Brightness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Saturation', Camera.Saturation);
      finally
        RegistryIni.Free;
      end;
    end;
end;

procedure TForm1.TrackBarContrastChange(Sender: TObject);
var
  RegistryIni: TRegIni;
begin
  if Assigned(Camera) then
    if Camera.Active then
    begin
      Camera.Contrast := Trunc(TrackBarContrast.Value);

      RegistryIni:= TRegIni.Create;
      try
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Sharpness', Camera.Sharpness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Contrast', Camera.Contrast);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Brightness', Camera.Brightness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Saturation', Camera.Saturation);
      finally
        RegistryIni.Free;
      end;
    end;
end;


procedure TForm1.TrackBarSaturationChange(Sender: TObject);
var
  RegistryIni: TRegIni;
begin
  if Assigned(Camera) then
    if Camera.Active then
    begin
      Camera.Saturation := Trunc(TrackBarSaturation.Value);

      RegistryIni:= TRegIni.Create;
      try
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Sharpness', Camera.Sharpness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Contrast', Camera.Contrast);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Brightness', Camera.Brightness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Saturation', Camera.Saturation);
      finally
        RegistryIni.Free;
      end;
    end;
end;

procedure TForm1.TrackBarSharpnessChange(Sender: TObject);
var
  RegistryIni: TRegIni;
begin
  if Assigned(Camera) then
    if Camera.Active then
    begin
      Camera.Sharpness := Trunc(TrackBarSharpness.Value);

      RegistryIni:= TRegIni.Create;
      try
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Sharpness', Camera.Sharpness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Contrast', Camera.Contrast);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Brightness', Camera.Brightness);
        RegistryIni.WriteInteger(HKEY_CURRENT_USER, 'SOFTWARE\SDVirtualCamera', 'Saturation', Camera.Saturation);
      finally
        RegistryIni.Free;
      end;
    end;
end;

end.

