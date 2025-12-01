//---------------------------------------------------------------------
// Camera for FireMonkey component
//---------------------------------------------------------------------

unit FCamera;

{$if CompilerVersion = 23}
  {$define DXE2}
{$ifend}

{$if CompilerVersion >= 25} // Delphi XE4 or higher
  {$define DXE4PLUS}
{$ifend}

{$if CompilerVersion >= 26} // Delphi XE5 or higher
  {$define DXE5PLUS}
{$ifend}

{$if CompilerVersion >= 28} // Delphi XE7 or higher
  {$define DXE7PLUS}
{$ifend}

{$if CompilerVersion >= 29} // Delphi XE8 or higher
  {$define DXE8PLUS}
{$ifend}

{$ifdef WIN32}
{$HPPEMIT '#pragma link "FCameraP.lib"'}
{$HPPEMIT '#pragma link "quartz.lib"'}
{$endif WIN32}

{$ifdef WIN64}
{$HPPEMIT '#pragma link "FCameraP.a"'}
{$HPPEMIT '#pragma link "quartz.a"'}
{$endif WIN64}

interface

uses System.Types, System.Classes, Winapi.Windows,
  System.SysUtils, System.UITypes, FDirectShow9,
  {$ifdef DXE5PLUS} FMX.Graphics {$else} FMX.Types {$endif DXE5PLUS}, FMX.Controls;

const
  PROPSETID_VIDCAP_CAMERACONTROL_FLASH: TGUID = '{785E8F49-63A2-4144-AB70-FFB278FA26CE}';

  KSPROPERTY_CAMERACONTROL_FLASH_PROPERTY_ID = 0;

  KSPROPERTY_CAMERACONTROL_FLASH_OFF  = $00000000;
  KSPROPERTY_CAMERACONTROL_FLASH_ON   = $00000001;
  KSPROPERTY_CAMERACONTROL_FLASH_AUTO = $00000002;

  KSPROPERTY_CAMERACONTROL_FLASH_FLAGS_AUTO   = $00000001;
  KSPROPERTY_CAMERACONTROL_FLASH_FLAGS_MANUAL = $00000002;

type
  KSPROPERTY_CAMERACONTROL_FLASH_S = record
    Flash: ULONG;
    Capabilities: ULONG;
  end;

const
  PROPSETID_VIDCAP_CAMERACONTROL_VIDEO_STABILIZATION: TGUID = '{43964BD3-7716-404e-8BE1-D299B20E50FD}';

  KSPROPERTY_CAMERACONTROL_VIDEO_STABILIZATION_MODE_PROPERTY_ID = 0;

  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_OFF    = $00000000;
  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_HIGH   = $00000001;
  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_MEDIUM = $00000002;
  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_LOW    = $00000003;
  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_AUTO   = $00000004;

  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_FLAGS_AUTO   = $00000001;
  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_FLAGS_MANUAL = $00000002;

type
  KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_S = record
    VideoStabilizationMode: ULONG;
    Capabilities: ULONG;
  end;

type
  TFVideoCaptureDevice = record
    Name: string;
    Description: string;
    Path: string;
  end;

  TFVideoCaptureDevices = array of TFVideoCaptureDevice;

  TFAudioCaptureDevice = record
    Name: string;
    Description: string;
    WaveInID: Integer;
  end;

  TFAudioCaptureDevices = array of TFAudioCaptureDevice;

  TFRange = record
    Min: Integer;
    Max: Integer;
    Delta: Integer;
    Default: Integer;
    Auto: Boolean;
    Manual: Boolean;
  end;

  TFFocalLength = record
    Ocular: Integer;
    ObjectiveMin: Integer;
    ObjectiveMax: Integer;
  end;

  TFFourCC = array [0..3] of Byte;

  TFCameraFormat = record
    MajorType: TGUID;
    SubType: TGUID;
    FormatType: TGUID;
    Width: Integer;
    Height: Integer;
    AvgTimePerFrame: TReferenceTime;
    FixedSizeSamples: Boolean;
    TemporalCompression: Boolean;
    SampleSize: Integer;
    Source: TRect;
    Target: TRect;
    BitRate: Integer;
    BitErrorRate: Integer;
    BitsPerPixel: Integer;
    Compression: TFFourCC;
    XPelsPerMeter: Integer;
    YPelsPerMeter: Integer;
  end;

  TFCameraFormats = array of TFCameraFormat;

  TFCameraState = (csUnknown, csInactive, csStopped, csPaused, csRunning);

  TFCaptureType = (ctAuto, ctGrabber, ctVmr9);

  TFOutputType = (otAuto, {otRgb1, otRgb4, otRgb8, otRgb565,} otRgb555, otRgb24,
    otRgb32, {otArgb1555, otArgb4444,} otArgb32 {, otA2R10G10B10, otA2B10G10R10});

  TFPowerLineFrequency = (pfUnknown, pfDisabled, pf50Hz, pf60Hz, pfAuto);

  TFScanMode = (smUnknown, smInterlace, smProgressive);

  TFFlashControl = (fcUnknown, fcAuto, fcManual);

  TFFlashMode = (fmUnknown, fmOff, fmOn, fmAuto);

  TFVideoStabilizationControl = (vcUnknown, vcAuto, vcManual);

  TFVideoStabilizationMode = (vmUnknown, vmOff, vmHigh, vmMedium, vmLow, vmAuto);

  TFMediaType = (mtAsf, mtAvi);

  TFImageFormat = (ifUnsupported, ifBmp, ifJpeg);

  TFImageAvailableEvent = procedure(Sender: TObject; SampleTime: Double) of object;

  EFCameraError = class(Exception)
  end;

  TFCamera = class;

  // ISampleGrabberCB is deprecated
  TFSampleGrabberCB = class(TInterfacedObject, ISampleGrabberCB)
  private
    FCamera: TFCamera;
    constructor Create(Camera: TFCamera);
    function SampleCB(SampleTime: Double; MediaSample: IMediaSample): HResult; stdcall;
    function BufferCB(SampleTime: Double; Buffer: PByte; BufferLen: LongInt): HResult; stdcall;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TFCamera = class(TComponent)
  private
    FActive: Boolean;
    FAMCameraControl: IAMCameraControl;
    FAMStreamConfig: IAMStreamConfig;
    FAMVideoControl: IAMVideoControl;
    FAMVideoProcAmp: IAMVideoProcAmp;
    FAspectRatio: Boolean;
    FAudioCaptureFilter: IBaseFilter;
    FAudioCompressorFilter: IBaseFilter;
    FAudioCompressorName: string;
    FAudioDeviceIndex: Integer;
    FAudioDeviceName: string;
//    FBasicAudio: IBasicAudio;
//    FBasicVideo: IBasicVideo;
//    FBasicVideo2: IBasicVideo2;
    FBorderColor: TAlphaColor;
    FCaptureFilter: IBaseFilter;
    FCaptureGraphBuilder2: ICaptureGraphBuilder2;
    FCapturePin: IPin;
    FCaptureType: TFCaptureType;
    FCompressorFilter: IBaseFilter;
    FCompressorName: string;
    FDeviceIndex: Integer;
    FDeviceName: string;
    FDevicePath: string;
    FGrabberUsed: Boolean;
    FGraphBuilder: IGraphBuilder;
    FInDoImageCount: Integer;
    FMediaControl: IMediaControl;
    FMediaEvent: IMediaEvent;
    FNullRenderer: IBaseFilter;
    FOnImageAvailable: TFImageAvailableEvent;
    FOutputFileName: string;
    FOutputFileType: TFMediaType;
    FOutputType: TFOutputType;
    FPreviewControl: TControl;
    FSampleGrabber: ISampleGrabber;
    FSampleGrabberCB: ISampleGrabberCB;
    FSampleGrabberFilter: IBaseFilter;
    FVideoMixingRenderer9Filter: IBaseFilter;
//    FVideoWindow: IVideoWindow;
    FVMRFilterConfig9: IVMRFilterConfig9;
    FVMRWindowlessControl9: IVMRWindowlessControl9;
    procedure CheckActive;
    procedure CheckAMCameraControl;
    procedure CheckAMVideoProcAmp;
    procedure CheckDeviceSelected;
    procedure CheckInactive;
    procedure CheckVmr9Active;
    function GetAbout: string;
    function GetActive: Boolean;
    function GetAMCameraControl: IAMCameraControl;
    function GetAMCameraControlAuto(Property_: TCameraControlProperty): Boolean;
    function GetAMCameraControlRange(Property_: TCameraControlProperty): TFRange;
    function GetAMCameraControlValue(Property_: TCameraControlProperty): Integer;
    function GetAMCameraControlValueSupported(Property_: TCameraControlProperty): Boolean;
    function GetAMCameraControlFlash: KSPROPERTY_CAMERACONTROL_FLASH_S;
    function GetAMCameraControlFlashSupported: Boolean;
    // function GetAMCameraControlFocus: KSPROPERTY_CAMERACONTROL_S;
    function GetAMCameraControlFocalLength: KSPROPERTY_CAMERACONTROL_FOCAL_LENGTH_S;
    function GetAMCameraControlVideoStabilizationMode: KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_S;
    function GetAMCameraControlVideoStabilizationModeSupported: Boolean;
    function GetAMStreamConfig: IAMStreamConfig;
    function GetAMVideoControl: IAMVideoControl;
    function GetAMVideoProcAmp: IAMVideoProcAmp;
    function GetAMVideoProcAmpAuto(Property_: TVideoProcAmpProperty): Boolean;
    function GetAMVideoProcAmpRange(Property_: TVideoProcAmpProperty): TFRange;
    function GetAMVideoProcAmpValue(Property_: TVideoProcAmpProperty): Integer;
    function GetAMVideoProcAmpValueSupported(Property_: TVideoProcAmpProperty): Boolean;
    function GetAspectRatio: Boolean;
    function GetAudioCaptureFilter: IBaseFilter;
    function GetAudioCaptureDevice: IBaseFilter;
    function GetAudioCaptureDeviceByIndex(Index: Integer): IBaseFilter;
    function GetAudioCaptureDeviceByName(const Name: string): IBaseFilter;
    function GetAudioCaptureDevices: TFAudioCaptureDevices;
    function GetAudioCompressor(const Name: string): IBaseFilter;
    function GetAudioCompressorFilter: IBaseFilter;
    function GetAudioCompressors: TArray<string>;
    function GetAudioDeviceIndex: Integer;
    function GetAudioDeviceName: string;
    function GetAudioEffect1(const Name: string): IBaseFilter;
    function GetAudioEffect2(const Name: string): IBaseFilter;
    function GetAudioEffects1: TArray<string>;
    function GetAudioEffects2: TArray<string>;
    function GetAutoExposurePriority: Boolean;
    function GetAutoExposurePriorityAuto: Boolean;
    function GetAutoExposurePrioritySupported: Boolean;
    function GetBacklightCompensation: Integer;
    function GetBacklightCompensationAuto: Boolean;
    function GetBacklightCompensationRange: TFRange;
    function GetBacklightCompensationSupported: Boolean;
{
    function GetBalance: Integer;
    function GetBasicAudio: IBasicAudio;
    function GetBasicVideo: IBasicVideo;
    function GetBasicVideo2: IBasicVideo2;
}
    function GetBorderColor: TAlphaColor;
    function GetBrightness: Integer;
    function GetBrightnessAuto: Boolean;
    function GetBrightnessRange: TFRange;
    function GetBrightnessSupported: Boolean;
    function GetCaptureFilter: IBaseFilter;
    function GetCaptureGraphBuilder2: ICaptureGraphBuilder2;
    function GetCapturePin: IPin;
    function GetCaptureType: TFCaptureType;
    function GetColorEnable: Integer;
    function GetColorEnableAuto: Boolean;
    function GetColorEnableRange: TFRange;
    function GetColorEnableSupported: Boolean;
    function GetColorEnabled: Boolean;
    function GetColorEnabledSupported: Boolean;
    function GetCompressor(const Name: string): IBaseFilter;
    function GetCompressorFilter: IBaseFilter;
    function GetCompressors: TArray<string>;
    function GetContrast: Integer;
    function GetContrastAuto: Boolean;
    function GetContrastRange: TFRange;
    function GetContrastSupported: Boolean;
    function GetDevice: IBaseFilter;
    function GetDeviceByIndex(Index: Integer): IBaseFilter;
    function GetDeviceByName(const Name: string): IBaseFilter;
    function GetDeviceByPath(const Path: string): IBaseFilter;
    function GetDeviceIndex: Integer;
    function GetDeviceName: string;
    function GetDevicePath: string;
    function GetDevices: TFVideoCaptureDevices;
    function GetDigitalMultiplier: Integer;
    function GetDigitalMultiplierAuto: Boolean;
    function GetDigitalMultiplierRange: TFRange;
    function GetDigitalMultiplierSupported: Boolean;
    function GetDigitalMultiplierLimit: Integer;
    function GetDigitalMultiplierLimitAuto: Boolean;
    function GetDigitalMultiplierLimitRange: TFRange;
    function GetDigitalMultiplierLimitSupported: Boolean;
    function GetExposure: Integer;
    function GetExposureAuto: Boolean;
    function GetExposureRange: TFRange;
    function GetExposureSupported: Boolean;
    function GetExposureRelative: Integer;
    function GetExposureRelativeAuto: Boolean;
    function GetExposureRelativeRange: TFRange;
    function GetExposureRelativeSupported: Boolean;
    function GetFlashControl: TFFlashControl;
    function GetFlashControlSupported: Boolean;
    function GetFlashMode: TFFlashMode;
    function GetFlashModeSupported: Boolean;
    function GetFocalLength: TFFocalLength;
    function GetFocalLengthSupported: Boolean;
    function GetFocus: Integer;
    function GetFocusAuto: Boolean;
    function GetFocusRange: TFRange;
    function GetFocusSupported: Boolean;
    function GetFocusRelative: Integer;
    function GetFocusRelativeAuto: Boolean;
    function GetFocusRelativeRange: TFRange;
    function GetFocusRelativeSupported: Boolean;
    function GetFormat: TFCameraFormat;
    function GetGain: Integer;
    function GetGainAuto: Boolean;
    function GetGainRange: TFRange;
    function GetGainSupported: Boolean;
    function GetGamma: Integer;
    function GetGammaAuto: Boolean;
    function GetGammaRange: TFRange;
    function GetGammaSupported: Boolean;
    function GetGraphBuilder: IGraphBuilder;
    function GetHue: Integer;
    function GetHueAuto: Boolean;
    function GetHueRange: TFRange;
    function GetHueSupported: Boolean;
    function GetIris: Integer;
    function GetIrisAuto: Boolean;
    function GetIrisRange: TFRange;
    function GetIrisSupported: Boolean;
    function GetIrisRelative: Integer;
    function GetIrisRelativeAuto: Boolean;
    function GetIrisRelativeRange: TFRange;
    function GetIrisRelativeSupported: Boolean;
    function GetMaxIdealVideoSize: TPoint;
    function GetMediaControl: IMediaControl;
    function GetMediaEvent: IMediaEvent;
    function GetMinIdealVideoSize: TPoint;
    function GetNativeAspectRatio: TPoint;
    function GetNativeVideoSize: TPoint;
    function GetNullRenderer: IBaseFilter;
    function GetPan: Integer;
    function GetPanAuto: Boolean;
    function GetPanRange: TFRange;
    function GetPanSupported: Boolean;
    function GetPanRelative: Integer;
    function GetPanRelativeAuto: Boolean;
    function GetPanRelativeRange: TFRange;
    function GetPanRelativeSupported: Boolean;
    function GetPowerLineFrequency: TFPowerLineFrequency;
    function GetPowerLineFrequencyAuto: Boolean;
//    function GetPowerLineFrequencyRange: TFRange; // unneeded
    function GetPowerLineFrequencySupported: Boolean;
    function GetPrivacy: Boolean;
    function GetPrivacyAuto: Boolean;
    function GetPrivacySupported: Boolean;
    function GetRoll: Integer;
    function GetRollAuto: Boolean;
    function GetRollRange: TFRange;
    function GetRollSupported: Boolean;
    function GetRollRelative: Integer;
    function GetRollRelativeAuto: Boolean;
    function GetRollRelativeRange: TFRange;
    function GetRollRelativeSupported: Boolean;
    function GetSampleGrabber: ISampleGrabber;
    function GetSampleGrabberCB: ISampleGrabberCB;
    function GetSampleGrabberFilter: IBaseFilter;
    function GetSaturation: Integer;
    function GetSaturationAuto: Boolean;
    function GetSaturationRange: TFRange;
    function GetSaturationSupported: Boolean;
    function GetScanMode: TFScanMode;
    function GetScanModeAuto: Boolean;
//    function GetScanModeRange: TFRange; // unneeded
    function GetSharpness: Integer;
    function GetSharpnessAuto: Boolean;
    function GetSharpnessRange: TFRange;
    function GetSharpnessSupported: Boolean;
    function GetState: TFCameraState;
    function GetSupportedFormats: TFCameraFormats;
    function GetTilt: Integer;
    function GetTiltAuto: Boolean;
    function GetTiltRange: TFRange;
    function GetTiltSupported: Boolean;
    function GetTiltRelative: Integer;
    function GetTiltRelativeAuto: Boolean;
    function GetTiltRelativeRange: TFRange;
    function GetTiltRelativeSupported: Boolean;
    function GetVideoCaptureDevice(out Device: TFVideoCaptureDevice): Integer;
    function GetVideoEffect1(const Name: string): IBaseFilter;
    function GetVideoEffect2(const Name: string): IBaseFilter;
    function GetVideoEffects1: TArray<string>;
    function GetVideoEffects2: TArray<string>;
    function GetVideoMixingRenderer9Filter: IBaseFilter;
    function GetVideoPositionDest: TRect;
    function GetVideoPositionSource: TRect;
    function GetVideoStabilizationControl: TFVideoStabilizationControl;
    function GetVideoStabilizationControlSupported: Boolean;
    function GetVideoStabilizationMode: TFVideoStabilizationMode;
    function GetVideoStabilizationModeSupported: Boolean;
//    function GetVideoWindow: IVideoWindow;
    function GetVMRFilterConfig9: IVMRFilterConfig9;
    function GetVMRWindowlessControl9: IVMRWindowlessControl9;
//    function GetVolume: Integer;
    function GetWhiteBalance: Integer;
    function GetWhiteBalanceAuto: Boolean;
    function GetWhiteBalanceRange: TFRange;
    function GetWhiteBalanceSupported: Boolean;
    function GetZoom: Integer;
    function GetZoomAuto: Boolean;
    function GetZoomRange: TFRange;
    function GetZoomSupported: Boolean;
    function GetZoomRelative: Integer;
    function GetZoomRelativeAuto: Boolean;
    function GetZoomRelativeRange: TFRange;
    function GetZoomRelativeSupported: Boolean;
    procedure ReleaseInterfaces;
    procedure SetAbout(const Value: string);
    procedure SetAMCameraControlAuto(Property_: TCameraControlProperty; Value: Boolean);
    procedure SetAMCameraControlValue(Property_: TCameraControlProperty; Value: Integer);
    procedure SetAMCameraControlFlash(const Value: KSPROPERTY_CAMERACONTROL_FLASH_S);
    procedure SetAMCameraControlVideoStabilizationMode(const Value: KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_S);
    procedure SetAMVideoProcAmpAuto(Property_: TVideoProcAmpProperty; Value: Boolean);
    procedure SetAMVideoProcAmpValue(Property_: TVideoProcAmpProperty; Value: Integer);
    procedure SetAspectRatio(Value: Boolean);
    procedure SetAudioCompressorName(const Value: string);
    procedure SetAudioDeviceIndex(Value: Integer);
    procedure SetAudioDeviceName(const Value: string);
    procedure SetAutoExposurePriority(Value: Boolean);
    procedure SetAutoExposurePriorityAuto(Value: Boolean);
    procedure SetBacklightCompensation(Value: Integer);
    procedure SetBacklightCompensationAuto(Value: Boolean);
//    procedure SetBalance(Value: Integer);
    procedure SetBorderColor(Value: TAlphaColor);
    procedure SetBrightness(Value: Integer);
    procedure SetBrightnessAuto(Value: Boolean);
    procedure SetCaptureType(Value: TFCaptureType);
    procedure SetColorEnable(Value: Integer);
    procedure SetColorEnableAuto(Value: Boolean);
    procedure SetColorEnabled(Value: Boolean);
    procedure SetCompressorName(const Value: string);
    procedure SetContrast(Value: Integer);
    procedure SetContrastAuto(Value: Boolean);
    procedure SetDeviceIndex(Value:Integer);
    procedure SetDeviceName(const Value: string);
    procedure SetDevicePath(const Value: string);
    procedure SetDigitalMultiplier(Value: Integer);
    procedure SetDigitalMultiplierAuto(Value: Boolean);
    procedure SetDigitalMultiplierLimit(Value: Integer);
    procedure SetDigitalMultiplierLimitAuto(Value: Boolean);
    procedure SetExposure(Value: Integer);
    procedure SetExposureAuto(Value: Boolean);
    procedure SetExposureRelative(Value: Integer);
    procedure SetExposureRelativeAuto(Value: Boolean);
    procedure SetFlashControl(Value: TFFlashControl);
    procedure SetFlashMode(Value: TFFlashMode);
    procedure SetFocus(Value: Integer);
    procedure SetFocusAuto(Value: Boolean);
    procedure SetFocusRelative(Value: Integer);
    procedure SetFocusRelativeAuto(Value: Boolean);
    procedure SetFormat(const Format: TFCameraFormat);
    procedure SetGain(Value: Integer);
    procedure SetGainAuto(Value: Boolean);
    procedure SetGamma(Value: Integer);
    procedure SetGammaAuto(Value: Boolean);
    procedure SetHue(Value: Integer);
    procedure SetHueAuto(Value: Boolean);
    procedure SetIris(Value: Integer);
    procedure SetIrisAuto(Value: Boolean);
    procedure SetIrisRelative(Value: Integer);
    procedure SetIrisRelativeAuto(Value: Boolean);
    procedure SetOnImageAvailable(Value: TFImageAvailableEvent);
    procedure SetOutputFileName(const Value: string);
    procedure SetOutputFileType(const Value: TFMediaType);
    procedure SetOutputType(Value: TFOutputType);
    procedure SetPan(Value: Integer);
    procedure SetPanAuto(Value: Boolean);
    procedure SetPanRelative(Value: Integer);
    procedure SetPanRelativeAuto(Value: Boolean);
    procedure SetPreviewControl(Value: TControl);
    procedure SetPowerLineFrequency(Value: TFPowerLineFrequency);
    procedure SetPowerLineFrequencyAuto(Value: Boolean);
    procedure SetPrivacy(Value: Boolean);
    procedure SetPrivacyAuto(Value: Boolean);
    procedure SetRoll(Value: Integer);
    procedure SetRollAuto(Value: Boolean);
    procedure SetRollRelative(Value: Integer);
    procedure SetRollRelativeAuto(Value: Boolean);
    procedure SetSaturation(Value: Integer);
    procedure SetSaturationAuto(Value: Boolean);
    procedure SetScanMode(Value: TFScanMode);
    procedure SetScanModeAuto(Value: Boolean);
    procedure SetSharpness(Value: Integer);
    procedure SetSharpnessAuto(Value: Boolean);
    procedure SetTilt(Value: Integer);
    procedure SetTiltAuto(Value: Boolean);
    procedure SetTiltRelative(Value: Integer);
    procedure SetTiltRelativeAuto(Value: Boolean);
    procedure SetVideoPositionDest(const Value: TRect);
    procedure SetVideoPositionSource(const Value: TRect);
    procedure SetVideoStabilizationControl(Value: TFVideoStabilizationControl);
    procedure SetVideoStabilizationMode(Value: TFVideoStabilizationMode);
//    procedure SetVolume(Value: Integer);
    procedure SetWhiteBalance(Value: Integer);
    procedure SetWhiteBalanceAuto(Value: Boolean);
    procedure SetZoom(Value: Integer);
    procedure SetZoomAuto(Value: Boolean);
    procedure SetZoomRelative(Value: Integer);
    procedure SetZoomRelativeAuto(Value: Boolean);
    procedure SetActive(Value: Boolean);
    procedure ShowPropertyDialog(AnInterface: IInterface); overload;
    function DoImageAvailable(SampleTime: Double): HResult;
    function SampleCB(SampleTime: Double; MediaSample: IMediaSample): HResult; stdcall;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CurrentImageToBitmap: TBitmap; overload;
    function CurrentImageToBitmap(Bitmap: TBitmap): Boolean; overload;
    function CurrentImageToBitmap(Bitmap: TBitmap; MemoryStream: TMemoryStream): Boolean; overload;
    function CurrentImageToFile(const FileName: string): TFImageFormat;
    function CurrentImageToStream(Stream: TStream): TFImageFormat;
    procedure Pause;
    procedure Run;
    procedure ShowPropertyDialog; overload;
    procedure ShowStreamPropertyDialog;
    procedure Stop;
    property AMCameraControl: IAMCameraControl read GetAMCameraControl;
    property AMStreamConfig: IAMStreamConfig read GetAMStreamConfig;
    property AMVideoControl: IAMVideoControl read GetAMVideoControl;
    property AMVideoProcAmp: IAMVideoProcAmp read GetAMVideoProcAmp;
    property AudioCaptureDevice: IBaseFilter read GetAudioCaptureDevice;
    property AudioCaptureDeviceByIndex[Index: Integer]: IBaseFilter read GetAudioCaptureDeviceByIndex;
    property AudioCaptureDeviceByName[const Name: string]: IBaseFilter read GetAudioCaptureDeviceByName;
    property AudioCaptureDevices: TFAudioCaptureDevices read GetAudioCaptureDevices;
    property AudioCaptureFilter: IBaseFilter read GetAudioCaptureFilter;
    property AudioCompressor[const Name: string]: IBaseFilter read GetAudioCompressor;
    property AudioCompressorFilter: IBaseFilter read GetAudioCompressorFilter;
    property AudioCompressors: TArray<string> read GetAudioCompressors;
    property AudioDeviceIndex: Integer read GetAudioDeviceIndex write SetAudioDeviceIndex default -1;
    property AudioEffect1[const Name: string]: IBaseFilter read GetAudioEffect1;
    property AudioEffect2[const Name: string]: IBaseFilter read GetAudioEffect2;
    property AudioEffects1: TArray<string> read GetAudioEffects1;
    property AudioEffects2: TArray<string> read GetAudioEffects2;
    property AutoExposurePriority: Boolean read GetAutoExposurePriority write SetAutoExposurePriority;
    property AutoExposurePriorityAuto: Boolean read GetAutoExposurePriorityAuto write SetAutoExposurePriorityAuto;
    property AutoExposurePrioritySupported: Boolean read GetAutoExposurePrioritySupported;
    property BacklightCompensation: Integer read GetBacklightCompensation write SetBacklightCompensation;
    property BacklightCompensationAuto: Boolean read GetBacklightCompensationAuto write SetBacklightCompensationAuto;
    property BacklightCompensationRange: TFRange read GetBacklightCompensationRange;
    property BacklightCompensationSupported: Boolean read GetBacklightCompensationSupported;
{
    property Balance: Integer read GetBalance write SetBalance;
    property BasicAudio: IBasicAudio read GetBasicAudio;
    property BasicVideo: IBasicVideo read GetBasicVideo;
    property BasicVideo2: IBasicVideo2 read GetBasicVideo2;
}
    property Brightness: Integer read GetBrightness write SetBrightness;
    property BrightnessAuto: Boolean read GetBrightnessAuto write SetBrightnessAuto;
    property BrightnessRange: TFRange read GetBrightnessRange;
    property BrightnessSupported: Boolean read GetBrightnessSupported;
    property CaptureFilter: IBaseFilter read GetCaptureFilter;
    property CaptureGraphBuilder2: ICaptureGraphBuilder2 read GetCaptureGraphBuilder2;
    property CapturePin: IPin read GetCapturePin;
    property ColorEnable: Integer read GetColorEnable write SetColorEnable;
    property ColorEnableAuto: Boolean read GetColorEnableAuto write SetColorEnableAuto;
    property ColorEnableRange: TFRange read GetColorEnableRange;
    property ColorEnableSupported: Boolean read GetColorEnableSupported;
    property ColorEnabled: Boolean read GetColorEnabled write SetColorEnabled;
    property ColorEnabledAuto: Boolean read GetColorEnableAuto write SetColorEnableAuto;
    property ColorEnabledSupported: Boolean read GetColorEnabledSupported;
    property Compressor[const Name: string]: IBaseFilter read GetCompressor;
    property CompressorFilter: IBaseFilter read GetCompressorFilter;
    property Compressors: TArray<string> read GetCompressors;
    property Contrast: Integer read GetContrast write SetContrast;
    property ContrastAuto: Boolean read GetContrastAuto write SetContrastAuto;
    property ContrastRange: TFRange read GetContrastRange;
    property ContrastSupported: Boolean read GetContrastSupported;
    property Device: IBaseFilter read GetDevice;
    property DeviceByIndex[Index: Integer]: IBaseFilter read GetDeviceByIndex;
    property DeviceByName[const Name: string]: IBaseFilter read GetDeviceByName;
    property DeviceByPath[const Path: string]: IBaseFilter read GetDeviceByPath;
    property DeviceIndex: Integer read GetDeviceIndex write SetDeviceIndex default -1;
    property Devices: TFVideoCaptureDevices read GetDevices;
    property DigitalMultiplier: Integer read GetDigitalMultiplier write SetDigitalMultiplier;
    property DigitalMultiplierAuto: Boolean read GetDigitalMultiplierAuto write SetDigitalMultiplierAuto;
    property DigitalMultiplierRange: TFRange read GetDigitalMultiplierRange;
    property DigitalMultiplierSupported: Boolean read GetDigitalMultiplierSupported;
    property DigitalMultiplierLimit: Integer read GetDigitalMultiplierLimit write SetDigitalMultiplierLimit;
    property DigitalMultiplierLimitAuto: Boolean read GetDigitalMultiplierLimitAuto write SetDigitalMultiplierLimitAuto;
    property DigitalMultiplierLimitRange: TFRange read GetDigitalMultiplierLimitRange;
    property DigitalMultiplierLimitSupported: Boolean read GetDigitalMultiplierLimitSupported;
    property Exposure: Integer read GetExposure write SetExposure;
    property ExposureAuto: Boolean read GetExposureAuto write SetExposureAuto;
    property ExposureRange: TFRange read GetExposureRange;
    property ExposureSupported: Boolean read GetExposureSupported;
    property ExposureRelative: Integer read GetExposureRelative write SetExposureRelative;
    property ExposureRelativeAuto: Boolean read GetExposureRelativeAuto write SetExposureRelativeAuto;
    property ExposureRelativeRange: TFRange read GetExposureRelativeRange;
    property ExposureRelativeSupported: Boolean read GetExposureRelativeSupported;
    property FlashControl: TFFlashControl read GetFlashControl write SetFlashControl;
    property FlashControlSupported: Boolean read GetFlashControlSupported;
    property FlashMode: TFFlashMode read GetFlashMode write SetFlashMode;
    property FlashModeSupported: Boolean read GetFlashModeSupported;
    property FocalLength: TFFocalLength read GetFocalLength;
    property FocalLengthSupported: Boolean read GetFocalLengthSupported;
    property Focus: Integer read GetFocus write SetFocus;
    property FocusAuto: Boolean read GetFocusAuto write SetFocusAuto;
    property FocusRange: TFRange read GetFocusRange;
    property FocusSupported: Boolean read GetFocusSupported;
    property FocusRelative: Integer read GetFocusRelative write SetFocusRelative;
    property FocusRelativeAuto: Boolean read GetFocusRelativeAuto write SetFocusRelativeAuto;
    property FocusRelativeRange: TFRange read GetFocusRelativeRange;
    property FocusRelativeSupported: Boolean read GetFocusRelativeSupported;
    property Format: TFCameraFormat read GetFormat write SetFormat;
    property Gain: Integer read GetGain write SetGain;
    property GainAuto: Boolean read GetGainAuto write SetGainAuto;
    property GainRange: TFRange read GetGainRange;
    property GainSupported: Boolean read GetGainSupported;
    property Gamma: Integer read GetGamma write SetGamma;
    property GammaAuto: Boolean read GetGammaAuto write SetGammaAuto;
    property GammaRange: TFRange read GetGammaRange;
    property GammaSupported: Boolean read GetGammaSupported;
    property GraphBuilder: IGraphBuilder read GetGraphBuilder;
    property Hue: Integer read GetHue write SetHue;
    property HueAuto: Boolean read GetHueAuto write SetHueAuto;
    property HueRange: TFRange read GetHueRange;
    property HueSupported: Boolean read GetHueSupported;
    property Iris: Integer read GetIris write SetIris;
    property IrisAuto: Boolean read GetIrisAuto write SetIrisAuto;
    property IrisRange: TFRange read GetIrisRange;
    property IrisSupported: Boolean read GetIrisSupported;
    property IrisRelative: Integer read GetIrisRelative write SetIrisRelative;
    property IrisRelativeAuto: Boolean read GetIrisRelativeAuto write SetIrisRelativeAuto;
    property IrisRelativeRange: TFRange read GetIrisRelativeRange;
    property IrisRelativeSupported: Boolean read GetIrisRelativeSupported;
    property MaxIdealVideoSize: TPoint read GetMaxIdealVideoSize;
    property MediaControl: IMediaControl read GetMediaControl;
    property MediaEvent: IMediaEvent read GetMediaEvent;
    property MinIdealVideoSize: TPoint read GetMinIdealVideoSize;
    property NativeAspectRatio: TPoint read GetNativeAspectRatio;
    property NativeVideoSize: TPoint read GetNativeVideoSize;
    property NullRenderer: IBaseFilter read GetNullRenderer;
    property Pan: Integer read GetPan write SetPan;
    property PanAuto: Boolean read GetPanAuto write SetPanAuto;
    property PanRange: TFRange read GetPanRange;
    property PanSupported: Boolean read GetPanSupported;
    property PanRelative: Integer read GetPanRelative write SetPanRelative;
    property PanRelativeAuto: Boolean read GetPanRelativeAuto write SetPanRelativeAuto;
    property PanRelativeRange: TFRange read GetPanRelativeRange;
    property PanRelativeSupported: Boolean read GetPanRelativeSupported;
    property PowerLineFrequency: TFPowerLineFrequency read GetPowerLineFrequency write SetPowerLineFrequency;
    property PowerLineFrequencyAuto: Boolean read GetPowerLineFrequencyAuto write SetPowerLineFrequencyAuto;
//    property PowerLineFrequencyRange: TFRange read GetPowerLineFrequencyRange; // unneeded
    property PowerLineFrequencySupported: Boolean read GetPowerLineFrequencySupported;
    property Privacy: Boolean read GetPrivacy write SetPrivacy;
    property PrivacyAuto: Boolean read GetPrivacyAuto write SetPrivacyAuto;
    property PrivacySupported: Boolean read GetPrivacySupported;
    property Roll: Integer read GetRoll write SetRoll;
    property RollAuto: Boolean read GetRollAuto write SetRollAuto;
    property RollRange: TFRange read GetRollRange;
    property RollSupported: Boolean read GetRollSupported;
    property RollRelative: Integer read GetRollRelative write SetRollRelative;
    property RollRelativeAuto: Boolean read GetRollRelativeAuto write SetRollRelativeAuto;
    property RollRelativeRange: TFRange read GetRollRelativeRange;
    property RollRelativeSupported: Boolean read GetRollRelativeSupported;
    property SampleGrabber: ISampleGrabber read GetSampleGrabber;
    property SampleGrabberCB: ISampleGrabberCB read GetSampleGrabberCB;
    property SampleGrabberFilter: IBaseFilter read GetSampleGrabberFilter;
    property Saturation: Integer read GetSaturation write SetSaturation;
    property SaturationAuto: Boolean read GetSaturationAuto write SetSaturationAuto;
    property SaturationRange: TFRange read GetSaturationRange;
    property SaturationSupported: Boolean read GetSaturationSupported;
    property ScanMode: TFScanMode read GetScanMode write SetScanMode;
    property ScanModeAuto: Boolean read GetScanModeAuto write SetScanModeAuto;
//    property ScanModeRange: TFRange read GetScanModeRange; // unneeded
    property Sharpness: Integer read GetSharpness write SetSharpness;
    property SharpnessAuto: Boolean read GetSharpnessAuto write SetSharpnessAuto;
    property SharpnessRange: TFRange read GetSharpnessRange;
    property SharpnessSupported: Boolean read GetSharpnessSupported;
    property State: TFCameraState read GetState;
    property SupportedFormats: TFCameraFormats read GetSupportedFormats;
    property Tilt: Integer read GetTilt write SetTilt;
    property TiltAuto: Boolean read GetTiltAuto write SetTiltAuto;
    property TiltRange: TFRange read GetTiltRange;
    property TiltSupported: Boolean read GetTiltSupported;
    property TiltRelative: Integer read GetTiltRelative write SetTiltRelative;
    property TiltRelativeAuto: Boolean read GetTiltRelativeAuto write SetTiltRelativeAuto;
    property TiltRelativeRange: TFRange read GetTiltRelativeRange;
    property TiltRelativeSupported: Boolean read GetTiltRelativeSupported;
    property VideoEffect1[const Name: string]: IBaseFilter read GetVideoEffect1;
    property VideoEffect2[const Name: string]: IBaseFilter read GetVideoEffect2;
    property VideoEffects1: TArray<string> read GetVideoEffects1;
    property VideoEffects2: TArray<string> read GetVideoEffects2;
    property VideoMixingRenderer9Filter: IBaseFilter read GetVideoMixingRenderer9Filter;
    property VideoPositionDest: TRect read GetVideoPositionDest write SetVideoPositionDest;
    property VideoPositionSource: TRect read GetVideoPositionSource write SetVideoPositionSource;
    property VideoStabilizationControl: TFVideoStabilizationControl read GetVideoStabilizationControl write SetVideoStabilizationControl;
    property VideoStabilizationControlSupported: Boolean read GetVideoStabilizationControlSupported;
    property VideoStabilizationMode: TFVideoStabilizationMode read GetVideoStabilizationMode write SetVideoStabilizationMode;
    property VideoStabilizationModeSupported: Boolean read GetVideoStabilizationModeSupported;
//    property VideoWindow: IVideoWindow read GetVideoWindow;
    property VMRFilterConfig9: IVMRFilterConfig9 read GetVMRFilterConfig9;
    property VMRWindowlessControl9: IVMRWindowlessControl9 read GetVMRWindowlessControl9;
//    property Volume: Integer read GetVolume write SetVolume;
    property WhiteBalance: Integer read GetWhiteBalance write SetWhiteBalance;
    property WhiteBalanceAuto: Boolean read GetWhiteBalanceAuto write SetWhiteBalanceAuto;
    property WhiteBalanceRange: TFRange read GetWhiteBalanceRange;
    property WhiteBalanceSupported: Boolean read GetWhiteBalanceSupported;
    property Zoom: Integer read GetZoom write SetZoom;
    property ZoomAuto: Boolean read GetZoomAuto write SetZoomAuto;
    property ZoomRange: TFRange read GetZoomRange;
    property ZoomSupported: Boolean read GetZoomSupported;
    property ZoomRelative: Integer read GetZoomRelative write SetZoomRelative;
    property ZoomRelativeAuto: Boolean read GetZoomRelativeAuto write SetZoomRelativeAuto;
    property ZoomRelativeRange: TFRange read GetZoomRelativeRange;
    property ZoomRelativeSupported: Boolean read GetZoomRelativeSupported;
  published
    property About: string read GetAbout write SetAbout stored False;
    property Active: Boolean read GetActive write SetActive default False;
    property AspectRatio: Boolean read GetAspectRatio write SetAspectRatio default False;
    property AudioCompressorName: string read FAudioCompressorName write SetAudioCompressorName;
    property AudioDeviceName: string read GetAudioDeviceName write SetAudioDeviceName;
    property BorderColor: TAlphaColor read GetBorderColor write SetBorderColor default TAlphaColorRec.Black;
    property CaptureType: TFCaptureType read GetCaptureType write SetCaptureType default ctAuto;
    property CompressorName: string read FCompressorName write SetCompressorName;
    property DeviceName: string read GetDeviceName write SetDeviceName;
    property DevicePath: string read GetDevicePath write SetDevicePath;
    property OutputFileName: string read FOutputFileName write SetOutputFileName;
    property OutputFileType: TFMediaType read FOutputFileType write SetOutputFileType default mtAsf;
    property OutputType: TFOutputType read FOutputType write SetOutputType default otAuto;
    property PreviewControl: TControl read FPreviewControl write SetPreviewControl;
    property OnImageAvailable: TFImageAvailableEvent read FOnImageAvailable write SetOnImageAvailable;
  end;

procedure CheckError(Result: HResult);

implementation

uses System.Win.ComObj, Winapi.ActiveX, FMX.Platform.Win, FMX.Forms;

{$ifndef DXE7PLUS}
function ApplicationHWND: HWND;
begin
  Result := 0
end;
{$endif}

function BooleanToInt(Value: Boolean): Integer;
begin
  if Value then
    Result := 1
  else
    Result := 0
end;

function IsNullGUID(const GUID: TGUID): Boolean;
begin
  Result := IsEqualGUID(GUID, GUID_NULL);
end;

procedure CheckError(Result: HResult);
var ErrorText: array [0..MAX_ERROR_TEXT_LEN - 1] of WideChar;
begin
  if not Succeeded(Result) then
    if AMGetErrorTextW(Result, ErrorText, SizeOf(ErrorText) div SizeOf(WideChar)) = 0 then
      OleError(Result)
    else
      raise EOleSysError.Create(ErrorText, Result, 0);
end;

procedure Check(Condition: Boolean; const Message: string);
begin
  if not Condition then
    raise EFCameraError.Create(Message);
end;

procedure CheckNull(AnInterface: IInterface; const Name: string);
begin
  Check(AnInterface <> nil, 'Cannot retrieve ''' + name + ''' interface');
end;

function UnsupportedProperty(ResultCode: HResult): Boolean;
begin
  Result := (ResultCode = E_PROP_SET_UNSUPPORTED) or (ResultCode = E_PROP_ID_UNSUPPORTED);
end;

procedure FreeMediaType(MediaType: PAMMediaType);
begin
  if MediaType.cbFormat <> 0 then
  begin
    CoTaskMemFree(MediaType.pbFormat);
    MediaType.cbFormat := 0;
    MediaType.pbFormat := nil;
  end;

  if MediaType.pUnk <> nil then
    MediaType.pUnk := nil;
end;

procedure DeleteMediaType(MediaType: PAMMediaType);
begin
  if MediaType <> nil then
  begin
    FreeMediaType(MediaType);
    CoTaskMemFree(MediaType);
  end;
end;

function GetEnumMoniker(const GUID: TGUID): IEnumMoniker;
var CreateDevEnum: ICreateDevEnum;
begin
  Result := nil;
  if Succeeded(CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC_SERVER, ICreateDevEnum, CreateDevEnum)) then
    if CreateDevEnum <> nil then
      if Succeeded(CreateDevEnum.CreateClassEnumerator(GUID, Result, 0)) then
        Exit;
  Result := nil;
end;

function GetFilters(const Category: TGUID): TArray<string>;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  PropertyBag: IPropertyBag;
  FriendlyName: OleVariant;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(Category);
  if EnumMoniker <> nil then
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
      if Moniker <> nil then
        if Succeeded(Moniker.BindToStorage(nil, nil, IPropertyBag, PropertyBag))then
          if PropertyBag <> nil then
            if Succeeded(PropertyBag.Read('FriendlyName', FriendlyName, nil)) then
            begin
              SetLength(Result, Length(Result) + 1);
              Result[Length(Result) - 1] := FriendlyName;
            end;
end;

function FindFilter(const Category: TGUID; const Name: string): IBaseFilter;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  PropertyBag: IPropertyBag;
  FriendlyName: OleVariant;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(Category);
  if EnumMoniker <> nil then
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
      if Moniker <> nil then
        if Succeeded(Moniker.BindToStorage(nil, nil, IPropertyBag, PropertyBag))then
          if PropertyBag <> nil then
            if Succeeded(PropertyBag.Read('FriendlyName', FriendlyName, nil)) then
              if FriendlyName = Name then
                if Succeeded(Moniker.BindToObject(nil, nil, IBaseFilter, Result)) then
                  Exit;
  Result := nil;
end;

{$ifdef TRIAL}
var WasTrialMessage: Boolean = False;

procedure ShowTrialMessage;
begin
  if not WasTrialMessage then
  begin
    WasTrialMessage := True;
    MessageBox(ApplicationHWND,
      'A trial version of Camera for FireMonkey started.' + #13#13 +
      'Please note that trial version is supposed to be used for evaluation only. ' +
      'If you wish to distribute Camera for FireMonkey as part of your ' +
      'application, you must register from website at https://www.winsoft.sk.' + #13#13 +
      'Thank you for trialing Camera for FireMonkey.',
      'Camera for FireMonkey, Copyright (c) 2016-2022 WINSOFT', MB_OK or MB_ICONINFORMATION);
  end;
end;
{$endif TRIAL}

// TFCamera

constructor TFCamera.Create(AOwner: TComponent);
begin
  inherited;
  FAudioDeviceIndex := -1;
  FBorderColor := TAlphaColorRec.Black;
  FCaptureType := ctAuto;
  FDeviceIndex := -1;
  FOutputFileType := mtAsf;

  {$ifdef TRIAL}
  if not (csDesigning in ComponentState) then
    ShowTrialMessage;
  {$endif}
end;

destructor TFCamera.Destroy;
begin
  Active := False;
  inherited;
end;

function TFCamera.GetAbout: string;
begin
  Result := 'Version 2.7, Copyright (c) 2016-2022 WINSOFT, https://www.winsoft.sk';
end;

procedure TFCamera.SetAbout(const Value: string);
begin
end;

function TFCamera.GetDevices: TFVideoCaptureDevices;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  ItemIndex: Integer;
  PropertyBag: IPropertyBag;
  FriendlyName: OleVariant;
  DevicePath: OleVariant;
  Description: OleVariant;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(CLSID_VideoInputDeviceCategory);
  if EnumMoniker <> nil then
  begin
    ItemIndex := 0;
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
      if Moniker <> nil then
      begin
        if Succeeded(Moniker.BindToStorage(nil, nil, IPropertyBag, PropertyBag))then
          if PropertyBag <> nil then
          begin
            SetLength(Result, ItemIndex + 1);

            if Succeeded(PropertyBag.Read('FriendlyName', FriendlyName, nil)) then
              Result[ItemIndex].Name := FriendlyName;

            if Succeeded(PropertyBag.Read('DevicePath', DevicePath, nil)) then
              Result[ItemIndex].Path := DevicePath;

            if Succeeded(PropertyBag.Read('Description', Description, nil)) then
              Result[ItemIndex].Description := Description;

            Inc(ItemIndex);
          end;
      end;
  end;
end;

function TFCamera.GetDeviceByName(const Name: string): IBaseFilter;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  PropertyBag: IPropertyBag;
  FriendlyName: OleVariant;
  DevicePath: OleVariant;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(CLSID_VideoInputDeviceCategory);
  if EnumMoniker <> nil then
  begin
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
      if Moniker <> nil then
        if Succeeded(Moniker.BindToStorage(nil, nil, IPropertyBag, PropertyBag))then
          if PropertyBag <> nil then
          begin
            if Succeeded(PropertyBag.Read('FriendlyName', FriendlyName, nil)) then
              if FriendlyName = Name then
                if Succeeded(Moniker.BindToObject(nil, nil, IBaseFilter, Result)) then
                  Exit;

            if Succeeded(PropertyBag.Read('DevicePath', DevicePath, nil)) then
              if DevicePath = Name then
                if Succeeded(Moniker.BindToObject(nil, nil, IBaseFilter, Result)) then
                  Exit;
          end;
  end;
  Result := nil;
end;

function TFCamera.GetDeviceByPath(const Path: string): IBaseFilter;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  PropertyBag: IPropertyBag;
  DevicePath: OleVariant;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(CLSID_VideoInputDeviceCategory);
  if EnumMoniker <> nil then
  begin
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
      if Moniker <> nil then
        if Succeeded(Moniker.BindToStorage(nil, nil, IPropertyBag, PropertyBag))then
          if PropertyBag <> nil then
            if Succeeded(PropertyBag.Read('DevicePath', DevicePath, nil)) then
              if DevicePath = Path then
                if Succeeded(Moniker.BindToObject(nil, nil, IBaseFilter, Result)) then
                  Exit;
  end;
  Result := nil;
end;

function TFCamera.GetDeviceByIndex(Index: Integer): IBaseFilter;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  ItemIndex: Integer;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(CLSID_VideoInputDeviceCategory);
  if EnumMoniker <> nil then
  begin
    ItemIndex := 0;
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
    begin
      if Index = ItemIndex then
        if Succeeded(Moniker.BindToObject(nil, nil, IBaseFilter, Result)) then
          Exit
        else
          Break;
      Inc(ItemIndex);
    end;
  end;
  Result := nil;
end;

function TFCamera.GetDevice: IBaseFilter;
begin
  if FDeviceName <> '' then
    Result := DeviceByName[FDeviceName]
  else if FDevicePath <> '' then
    Result := DeviceByPath[FDevicePath]
  else if FDeviceIndex <> -1 then
    Result := DeviceByIndex[FDeviceIndex]
  else
    Result := nil;
end;

function TFCamera.GetAudioCaptureDevices: TFAudioCaptureDevices;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  ItemIndex: Integer;
  PropertyBag: IPropertyBag;
  FriendlyName: OleVariant;
  Description: OleVariant;
  WaveInID: OleVariant;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(CLSID_AudioInputDeviceCategory);
  if EnumMoniker <> nil then
  begin
    ItemIndex := 0;
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
      if Moniker <> nil then
      begin
        if Succeeded(Moniker.BindToStorage(nil, nil, IPropertyBag, PropertyBag))then
          if PropertyBag <> nil then
          begin
            SetLength(Result, ItemIndex + 1);

            if Succeeded(PropertyBag.Read('FriendlyName', FriendlyName, nil)) then
              Result[ItemIndex].Name := FriendlyName;

            if Succeeded(PropertyBag.Read('Description', Description, nil)) then
              Result[ItemIndex].Description := Description;

            if Succeeded(PropertyBag.Read('WaveInID', WaveInID, nil)) then
              Result[ItemIndex].WaveInID := WaveInID;

            Inc(ItemIndex);
          end;
      end;
  end;    
end;

function TFCamera.GetAudioCaptureDeviceByName(const Name: string): IBaseFilter;
begin
  Result := FindFilter(CLSID_AudioInputDeviceCategory, Name);
end;

function TFCamera.GetAudioCaptureDeviceByIndex(Index: Integer): IBaseFilter;
var
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  ItemIndex: Integer;
begin
  Result := nil;
  EnumMoniker := GetEnumMoniker(CLSID_AudioInputDeviceCategory);
  if EnumMoniker <> nil then
  begin
    ItemIndex := 0;
    while EnumMoniker.Next(1, Moniker, nil) = S_OK do
    begin
      if Index = ItemIndex then
        if Succeeded(Moniker.BindToObject(nil, nil, IBaseFilter, Result)) then
          Exit
        else
          Break;
      Inc(ItemIndex);
    end;
  end;
  Result := nil;
end;

function TFCamera.GetAudioCaptureDevice: IBaseFilter;
begin
  if FAudioDeviceName <> '' then
    Result := AudioCaptureDeviceByName[FAudioDeviceName]
  else if FAudioDeviceIndex <> -1 then
    Result := AudioCaptureDeviceByIndex[FAudioDeviceIndex]
  else
    Result := nil;
end;

function TFCamera.GetCompressors: TArray<string>;
begin
  Result := GetFilters(CLSID_VideoCompressorCategory);
end;

function TFCamera.GetCompressor(const Name: string): IBaseFilter;
begin
  Result := FindFilter(CLSID_VideoCompressorCategory, Name);
end;

function TFCamera.GetAudioCompressors: TArray<string>;
begin
  Result := GetFilters(CLSID_AudioCompressorCategory);
end;

function TFCamera.GetAudioCompressor(const Name: string): IBaseFilter;
begin
  Result := FindFilter(CLSID_AudioCompressorCategory, Name);
end;

function TFCamera.GetAudioEffects1: TArray<string>;
begin
  Result := GetFilters(CLSID_AudioEffects1Category);
end;

function TFCamera.GetAudioEffect1(const Name: string): IBaseFilter;
begin
  Result := FindFilter(CLSID_AudioEffects1Category, Name);
end;

function TFCamera.GetAudioEffects2: TArray<string>;
begin
  Result := GetFilters(CLSID_AudioEffects2Category);
end;

function TFCamera.GetAudioEffect2(const Name: string): IBaseFilter;
begin
  Result := FindFilter(CLSID_AudioEffects2Category, Name);
end;

function TFCamera.GetVideoEffects1: TArray<string>;
begin
  Result := GetFilters(CLSID_VideoEffects1Category);
end;

function TFCamera.GetVideoEffect1(const Name: string): IBaseFilter;
begin
  Result := FindFilter(CLSID_VideoEffects1Category, Name);
end;

function TFCamera.GetVideoEffects2: TArray<string>;
begin
  Result := GetFilters(CLSID_VideoEffects2Category);
end;

function TFCamera.GetVideoEffect2(const Name: string): IBaseFilter;
begin
  Result := FindFilter(CLSID_VideoEffects2Category, Name);
end;

function TFCamera.GetGraphBuilder: IGraphBuilder;
begin
  if FGraphBuilder = nil then
    if Failed(CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER, IGraphBuilder, FGraphBuilder)) then
      FGraphBuilder := nil;
  Result := FGraphBuilder;
end;

function TFCamera.GetCaptureGraphBuilder2: ICaptureGraphBuilder2;
begin
  if FCaptureGraphBuilder2 = nil then
    if GraphBuilder <> nil then
      if Failed(CoCreateInstance(CLSID_CaptureGraphBuilder2, nil, CLSCTX_INPROC_SERVER, ICaptureGraphBuilder2, FCaptureGraphBuilder2)) then
        FCaptureGraphBuilder2 := nil
      else if Failed(FCaptureGraphBuilder2.SetFiltergraph(FGraphBuilder)) then
        FCaptureGraphBuilder2 := nil;

  Result := FCaptureGraphBuilder2;
end;

function TFCamera.GetSampleGrabberFilter: IBaseFilter;
begin
  if FSampleGrabberFilter = nil then
    if Failed(CoCreateInstance(CLSID_SampleGrabber, nil, CLSCTX_INPROC_SERVER, IBaseFilter, FSampleGrabberFilter)) then
      FSampleGrabberFilter := nil;
  Result := FSampleGrabberFilter;
end;

function TFCamera.GetSampleGrabber: ISampleGrabber;
begin
  if FSampleGrabber = nil then
    if SampleGrabberFilter <> nil then
      if Failed(SampleGrabberFilter.QueryInterface(ISampleGrabber, FSampleGrabber)) then
        FSampleGrabber := nil;
  Result := FSampleGrabber;
end;

function TFCamera.GetSampleGrabberCB: ISampleGrabberCB;
begin
  if FSampleGrabberCB = nil then
    FSampleGrabberCB := TFSampleGrabberCB.Create(Self);
  Result := FSampleGrabberCB;
end;

function TFCamera.GetNullRenderer: IBaseFilter;
begin
  if FNullRenderer = nil then
    if Failed(CoCreateInstance(CLSID_NullRenderer, nil, CLSCTX_INPROC_SERVER, IBaseFilter, FNullRenderer)) then
      FNullRenderer := nil;
  Result := FNullRenderer;
end;

function TFCamera.GetVideoMixingRenderer9Filter: IBaseFilter;
begin
  if FVideoMixingRenderer9Filter = nil then
    if Failed(CoCreateInstance(CLSID_VideoMixingRenderer9, nil, CLSCTX_INPROC_SERVER, IBaseFilter, FVideoMixingRenderer9Filter)) then
      FVideoMixingRenderer9Filter := nil;
  Result := FVideoMixingRenderer9Filter;
end;

function TFCamera.GetVMRFilterConfig9: IVMRFilterConfig9;
begin
  if FVMRFilterConfig9 = nil then
    if VideoMixingRenderer9Filter <> nil then
      if Failed(VideoMixingRenderer9Filter.QueryInterface(IVMRFilterConfig9, FVMRFilterConfig9)) then
        FVMRFilterConfig9 := nil
      else if Failed(VMRFilterConfig9.SetRenderingMode(VMR9Mode_Windowless {or VMR9Mode_Renderless})) then
        FVMRFilterConfig9 := nil;
  Result := FVMRFilterConfig9;
end;

function TFCamera.GetVMRWindowlessControl9: IVMRWindowlessControl9;
begin
  if FVMRWindowlessControl9 = nil then
    if VideoMixingRenderer9Filter <> nil then
      if Failed(VideoMixingRenderer9Filter.QueryInterface(IVMRWindowlessControl9, FVMRWindowlessControl9)) then
        FVMRWindowlessControl9 := nil;
  Result := FVMRWindowlessControl9;
end;

function TFCamera.GetMediaControl: IMediaControl;
begin
  if FMediaControl = nil then
    if GraphBuilder <> nil then
      if Failed(GraphBuilder.QueryInterface(IMediaControl, FMediaControl)) then
        FMediaControl := nil;
  Result := FMediaControl;
end;

function TFCamera.GetMediaEvent: IMediaEvent;
begin
  if FMediaEvent = nil then
    if GraphBuilder <> nil then
      if Failed(GraphBuilder.QueryInterface(IMediaEvent, FMediaEvent)) then
        FMediaEvent := nil;
  Result := FMediaEvent;
end;

(*
function TFCamera.GetBasicAudio: IBasicAudio;
begin
  if FBasicAudio = nil then
    if GraphBuilder <> nil then
      if Failed(GraphBuilder.QueryInterface(IBasicAudio, FBasicAudio)) then
        FBasicAudio := nil;
  Result := FBasicAudio;
end;

function TFCamera.GetBasicVideo: IBasicVideo;
begin
  if FBasicVideo = nil then
    if GraphBuilder <> nil then
      if Failed(GraphBuilder.QueryInterface(IBasicVideo, FBasicVideo)) then
        FBasicVideo := nil;
  Result := FBasicVideo;
end;

function TFCamera.GetBasicVideo2: IBasicVideo2;
begin
  if FBasicVideo2 = nil then
    if GraphBuilder <> nil then
      if Failed(GraphBuilder.QueryInterface(IBasicVideo2, FBasicVideo2)) then
        FBasicVideo2 := nil;
  Result := FBasicVideo2;
end;

function TFCamera.GetVideoWindow: IVideoWindow;
begin
  if FVideoWindow = nil then
    if GraphBuilder <> nil then
      if Failed(GraphBuilder.QueryInterface(IVideoWindow, FVideoWindow)) then
        FVideoWindow := nil;
  Result := FVideoWindow;
end;
*)

function TFCamera.GetCaptureFilter: IBaseFilter;
begin
  if FCaptureFilter = nil then
    FCaptureFilter := Device;
  Result := FCaptureFilter;
end;

function TFCamera.GetAudioCaptureFilter: IBaseFilter;
begin
  if FAudioCaptureFilter = nil then
    FAudioCaptureFilter := AudioCaptureDevice;
  Result := FAudioCaptureFilter;
end;

function TFCamera.GetCompressorFilter: IBaseFilter;
begin
  if FCompressorFilter = nil then
    FCompressorFilter := Compressor[CompressorName];
  Result := FCompressorFilter;
end;

function TFCamera.GetAudioCompressorFilter: IBaseFilter;
begin
  if FAudioCompressorFilter = nil then
    FAudioCompressorFilter := AudioCompressor[AudioCompressorName];
  Result := FAudioCompressorFilter;
end;

function TFCamera.GetCapturePin: IPin;
var
  EnumPins: IEnumPins;
  Pin: IPin;
  KsPropertySet: IKsPropertySet;
  PinCategory: TGUID;
  Size: DWORD;
begin
  if FCapturePin = nil then
    if CaptureFilter <> nil then
      if Succeeded(CaptureFilter.EnumPins(EnumPins)) then
        if EnumPins <> nil then
          while EnumPins.Next(1, Pin, nil) = S_OK do
            if Succeeded(Pin.QueryInterface(IKsPropertySet, KsPropertySet)) then
              if Succeeded(KsPropertySet.Get(AMPROPSETID_Pin, AMPROPERTY_PIN_CATEGORY, nil, 0, PinCategory, SizeOf(PinCategory), Size)) then
                if Size = SizeOf(PinCategory) then
                  if IsEqualGUID(PinCategory, PIN_CATEGORY_CAPTURE) then
                  begin
                    FCapturePin := Pin;
                    Break;
                  end;
  Result := FCapturePin;
end;

function TFCamera.GetAMVideoProcAmp: IAMVideoProcAmp;
begin
  if FAMVideoProcAmp = nil then
    if CaptureFilter <> nil then
      if Failed(CaptureFilter.QueryInterface(IAMVideoProcAmp, FAMVideoProcAmp)) then
        FAMVideoProcAmp := nil;
  Result := FAMVideoProcAmp;
end;

function TFCamera.GetAMCameraControl: IAMCameraControl;
begin
  if FAMCameraControl = nil then
    if CaptureFilter <> nil then
      if Failed(CaptureFilter.QueryInterface(IAMCameraControl, FAMCameraControl)) then
        FAMCameraControl := nil;
  Result := FAMCameraControl;
end;

function TFCamera.GetAMStreamConfig: IAMStreamConfig;
begin
  if FAMStreamConfig = nil then
    if CapturePin <> nil then
      if Failed(CapturePin.QueryInterface(IAMStreamConfig, FAMStreamConfig)) then
        FAMStreamConfig := nil;
  Result := FAMStreamConfig;
end;

function TFCamera.GetAMVideoControl: IAMVideoControl;
begin
  if FAMVideoControl = nil then
    if CaptureFilter <> nil then
      if Failed(CaptureFilter.QueryInterface(IAMVideoControl, FAMVideoControl)) then
        FAMVideoControl := nil;
  Result := FAMVideoControl;
end;

function TFCamera.GetVideoCaptureDevice(out Device: TFVideoCaptureDevice): Integer;
var
  Devices: TFVideoCaptureDevices;
  I: Integer;
begin
  Result := -1;
  Devices := nil;
  if FDeviceName <> '' then
  begin
    Devices := Self.Devices;
    for I := 0 to Length(Devices) - 1 do
      if (FDeviceName = Devices[I].Name) or (FDeviceName = Devices[I].Path) then
      begin
        Result := I;
        Device := Devices[I];
        Exit;
      end;
  end
  else if FDevicePath <> '' then
  begin
    Devices := Self.Devices;
    for I := 0 to Length(Devices) - 1 do
      if FDevicePath = Devices[I].Path then
      begin
        Result := I;
        Device := Devices[I];
        Exit;
      end;
  end
  else if FDeviceIndex <> -1 then
  begin
    Devices := Self.Devices;
    if (FDeviceIndex >= 0) and (FDeviceIndex < Length(Devices)) then
    begin
      Result := FDeviceIndex;
      Device := Devices[FDeviceIndex];
    end;
  end
end;

function TFCamera.GetDeviceIndex: Integer;
var Device: TFVideoCaptureDevice;
begin
  Result := FDeviceIndex;
  if not (csDesigning in ComponentState) then
    if not (csLoading in ComponentState) then
      if Result = -1 then
        Result := GetVideoCaptureDevice(Device);
end;

procedure TFCamera.SetDeviceIndex(Value: Integer);
begin
  if FDeviceIndex <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FDeviceIndex := Value;
    if FDeviceIndex <> -1 then
    begin
      FDeviceName := '';
      FDevicePath := '';
    end;
    ReleaseInterfaces;
  end;
end;

function TFCamera.GetDeviceName: string;
var Device: TFVideoCaptureDevice;
begin
  Result := FDeviceName;
  if not (csDesigning in ComponentState) then
    if not (csLoading in ComponentState) then
      if Result = '' then
        if GetVideoCaptureDevice(Device) <> -1 then
          Result := Device.Name;
end;

procedure TFCamera.SetDeviceName(const Value: string);
begin
  if FDeviceName <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FDeviceName := Value;
    if FDeviceName <> '' then
    begin
      FDeviceIndex := -1;
      FDevicePath := '';
    end;
    ReleaseInterfaces;
  end;
end;

function TFCamera.GetDevicePath: string;
var Device: TFVideoCaptureDevice;
begin
  Result := FDevicePath;
  if not (csDesigning in ComponentState) then
    if not (csLoading in ComponentState) then
      if Result = '' then
        if GetVideoCaptureDevice(Device) <> -1 then
          Result := Device.Path;
end;

procedure TFCamera.SetDevicePath(const Value: string);
begin
  if FDevicePath <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FDevicePath := Value;
    if FDevicePath <> '' then
    begin
      FDeviceIndex := -1;
      FDeviceName := '';
    end;
    ReleaseInterfaces;
  end;
end;

function TFCamera.GetAudioDeviceName: string;
var Devices: TFAudioCaptureDevices;
begin
  Result := FAudioDeviceName;
  Devices := nil;
  if not (csDesigning in ComponentState) then
    if not (csLoading in ComponentState) then
      if Result = '' then
        if FAudioDeviceIndex <> -1 then
        begin
          Devices := AudioCaptureDevices;
          if (FAudioDeviceIndex >= 0) and (FAudioDeviceIndex < Length(Devices)) then
            Result := Devices[FAudioDeviceIndex].Name;
        end;
end;

procedure TFCamera.SetAudioDeviceName(const Value: string);
begin
  if FAudioDeviceName <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FAudioDeviceName := Value;
    FAudioCaptureFilter := nil;
    if FAudioDeviceName <> '' then
      FAudioDeviceIndex := -1;
  end;
end;

function TFCamera.GetAudioDeviceIndex: Integer;
var
  Devices: TFAudioCaptureDevices;
  I: Integer;
begin
  Result := FAudioDeviceIndex;
  Devices := nil;
  if not (csDesigning in ComponentState) then
    if not (csLoading in ComponentState) then
      if Result = -1 then
       if FAudioDeviceName <> '' then
       begin
         Devices := AudioCaptureDevices;
         for I := 0 to Length(Devices) - 1 do
           if Devices[I].Name = FAudioDeviceName then
           begin
             Result := I;
             Exit;
           end;
       end;
end;

procedure TFCamera.SetAudioDeviceIndex(Value: Integer);
begin
  if FAudioDeviceIndex <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FAudioDeviceIndex := Value;
    FAudioCaptureFilter := nil;
    if FAudioDeviceIndex <> -1 then
      FAudioDeviceName := '';
  end;
end;

procedure TFCamera.SetCompressorName(const Value: string);
begin
  if FCompressorName <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FCompressorName := Value;
    FCompressorFilter := nil;
  end;
end;

procedure TFCamera.SetAudioCompressorName(const Value: string);
begin
  if FAudioCompressorName <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FAudioCompressorName := Value;
    FAudioCompressorFilter := nil;
  end;
end;

procedure TFCamera.SetPreviewControl(Value: TControl);
begin
  if FPreviewControl <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FPreviewControl := Value;
  end;
end;

procedure TFCamera.Pause;
begin
  CheckActive;
  CheckError(FMediaControl.Pause);
end;

procedure TFCamera.Run;
begin
  CheckActive;
  CheckError(FMediaControl.Run);
end;

procedure TFCamera.Stop;
begin
  CheckActive;
  CheckError(FMediaControl.Stop);
end;

procedure TFCamera.CheckDeviceSelected;
begin
  Check((FDeviceName <> '') or (FDevicePath <> '') or (FDeviceIndex <> -1), 'Camera device not selected');
  Check(CaptureFilter <> nil, 'Camera device not found');
end;

procedure TFCamera.CheckActive;
begin
  Check(Active, 'Cannot perform this operation on inactive camera component');
end;

procedure TFCamera.CheckInactive;
begin
  Check(not Active, 'Cannot perform this operation on active camera component');
end;

function GetCameraFormat(MediaType: PAMMediaType): TFCameraFormat;
var MediaHeader: PVideoInfoHeader;
begin
  MediaHeader := MediaType.pbFormat;
  Check(MediaHeader <> nil, 'Invalid MediaHeader');
  Result.MajorType := MediaType.majortype;
  Result.SubType := MediaType.subtype;
  Result.FormatType := MediaType.formattype;
  Result.Width := MediaHeader.bmiHeader.biWidth;
  Result.Height := MediaHeader.bmiHeader.biHeight;
  Result.AvgTimePerFrame := MediaHeader.AvgTimePerFrame;
  Result.FixedSizeSamples := MediaType.bFixedSizeSamples;
  Result.TemporalCompression := MediaType.bTemporalCompression;
  Result.SampleSize := MediaType.lSampleSize;
  Result.Source := MediaHeader.rcSource;
  Result.Target := MediaHeader.rcTarget;
  Result.BitRate := MediaHeader.dwBitRate;
  Result.BitErrorRate := MediaHeader.dwBitErrorRate;
  Result.BitsPerPixel := MediaHeader.bmiHeader.biBitCount;
  Cardinal(Result.Compression) := MediaHeader.bmiHeader.biCompression;
  Result.XPelsPerMeter := MediaHeader.bmiHeader.biXPelsPerMeter;
  Result.YPelsPerMeter := MediaHeader.bmiHeader.biYPelsPerMeter;
end;

function TFCamera.GetSupportedFormats: TFCameraFormats;
var
  EnumMediaTypes: IEnumMediaTypes;
  MediaType: PAMMediaType;
  Index: Integer;
begin
  Result := nil;
  CheckDeviceSelected;
  CheckNull(CapturePin, 'Capture IPin');
  CheckError(CapturePin.EnumMediaTypes(EnumMediaTypes));
  CheckNull(EnumMediaTypes, 'IEnumMediaTypes');
  Index := 0;
  while EnumMediaTypes.Next(1, MediaType, nil) = S_OK do
  begin
    if IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo {FORMAT_VideoInfo2}) then
      if MediaType.cbFormat >= SizeOf(TVideoInfoHeader) then
      begin
        SetLength(Result, Index + 1);
        Result[Index] := GetCameraFormat(MediaType);
        Inc(Index);
      end;
    DeleteMediaType(MediaType);
  end;
end;

function TFCamera.GetFormat: TFCameraFormat;
var MediaType: PAMMediaType;
begin
  CheckDeviceSelected;
  CheckNull(AMStreamConfig, 'IAMStreamConfig');
  CheckError(AMStreamConfig.GetFormat(MediaType));
  try
    Check(IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo), 'Incorrect format type');
    Check(MediaType.cbFormat >= SizeOf(TVideoInfoHeader), 'Incorrect format size');
    Result := GetCameraFormat(MediaType);
  finally
    DeleteMediaType(MediaType);
  end;
end;

procedure TFCamera.SetFormat(const Format: TFCameraFormat);
var
  EnumMediaTypes: IEnumMediaTypes;
  MediaType: PAMMediaType;
  MediaHeader: PVideoInfoHeader;
begin
  CheckDeviceSelected;
  CheckNull(CapturePin, 'Capture IPin');
  CheckError(CapturePin.EnumMediaTypes(EnumMediaTypes));
  CheckNull(EnumMediaTypes, 'IEnumMediaTypes');
  while EnumMediaTypes.Next(1, MediaType, nil) = S_OK do
  try
    if IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo) then
      if MediaType.cbFormat >= SizeOf(TVideoInfoHeader) then
      begin
        MediaHeader := MediaType.pbFormat;
        if MediaHeader <> nil then
        begin
          if (Format.Width = MediaHeader.bmiHeader.biWidth) and
            (Format.Height = MediaHeader.bmiHeader.biHeight) and
            (Format.AvgTimePerFrame = MediaHeader.AvgTimePerFrame) and
            (Format.BitsPerPixel = MediaHeader.bmiHeader.biBitCount) and
            (IsNullGUID(Format.MajorType) or IsEqualGUID(Format.MajorType, MediaType.majortype)) and
            (IsNullGUID(Format.SubType) or IsEqualGUID(Format.SubType, MediaType.subtype)) and
            (IsNullGUID(Format.FormatType) or IsEqualGUID(Format.FormatType, MediaType.formattype)) then
          begin
            CheckNull(AMStreamConfig, 'IAMStreamConfig');
            CheckError(AMStreamConfig.SetFormat(MediaType));
            Exit;
          end;
        end;
      end;
  finally
    DeleteMediaType(MediaType);
  end;

  raise EFCameraError.Create('Format not found');
end;

procedure TFCamera.ShowPropertyDialog;
begin
  CheckDeviceSelected;
  ShowPropertyDialog(CaptureFilter);
end;

procedure TFCamera.ShowStreamPropertyDialog;
var AMStreamConfig: IAMStreamConfig;
begin
  CheckDeviceSelected;
  CheckNull(CaptureGraphBuilder2, 'ICaptureGraphBuilder2');
  CheckError(CaptureGraphBuilder2.FindInterface(@PIN_CATEGORY_capture, @MEDIATYPE_Video, CaptureFilter, IID_IAMStreamConfig, AMStreamConfig));
  CheckNull(AMStreamConfig, 'IAMStreamConfig');
  ShowPropertyDialog(AMStreamConfig);
end;

procedure TFCamera.ShowPropertyDialog(AnInterface: IInterface);
var
  SpecifyPropertyPages: ISpecifyPropertyPages;
  Pages: TCAGUID;
  FilterInfo: TFilterInfo;
//  Handle: HWND;
begin
  CheckError(AnInterface.QueryInterface(ISpecifyPropertyPages, SpecifyPropertyPages));
  CheckNull(SpecifyPropertyPages, 'ISpecifyPropertyPages');
  CheckError(SpecifyPropertyPages.GetPages(Pages));
  try
    CheckError(CaptureFilter.QueryFilterInfo(FilterInfo));
//    Handle := ApplicationHWND;
    CheckError(OleCreatePropertyFrame({Handle} 0, 0, 0, FilterInfo.achName, 1, @AnInterface, Pages.cElems, Pages.pElems, 0, 0, nil));
  finally
    CoTaskMemFree(Pages.pElems);
  end;
end;

procedure TFCamera.CheckAMVideoProcAmp;
begin
  CheckDeviceSelected;
  CheckNull(AMVideoProcAmp, 'IAMVideoProcAmp');
end;

function TFCamera.GetAMVideoProcAmpValueSupported(Property_: TVideoProcAmpProperty): Boolean;
var
  Flags: TVideoProcAmpFlags;
  Value: Integer;
begin
  CheckDeviceSelected;
  if AMVideoProcAmp = nil then
    Result := False
  else  
    Result := not UnsupportedProperty(AMVideoProcAmp.Get(Property_, Value, Flags));
end;

function TFCamera.GetAMVideoProcAmpValue(Property_: TVideoProcAmpProperty): Integer;
var Flags: TVideoProcAmpFlags;
begin
  CheckAMVideoProcAmp;
  CheckError(AMVideoProcAmp.Get(Property_, Result, Flags));
end;

procedure TFCamera.SetAMVideoProcAmpValue(Property_: TVideoProcAmpProperty; Value: Integer);
var
  CurrentValue: Integer;
  Flags: TVideoProcAmpFlags;
begin
  CheckAMVideoProcAmp;
  CheckError(AMVideoProcAmp.Get(Property_, CurrentValue, Flags));
  CheckError(AMVideoProcAmp.Set_(Property_, Value, Flags));
end;

function TFCamera.GetAMVideoProcAmpAuto(Property_: TVideoProcAmpProperty): Boolean;
var
  Value: Integer;
  Flags: TVideoProcAmpFlags;
begin
  CheckAMVideoProcAmp;
  CheckError(AMVideoProcAmp.Get(Property_, Value, Flags));
  Result := Flags = VideoProcAmp_Flags_Auto;
end;

procedure TFCamera.SetAMVideoProcAmpAuto(Property_: TVideoProcAmpProperty; Value: Boolean);
var
  CurrentValue: Integer;
  Flags: TVideoProcAmpFlags;
begin
  CheckAMVideoProcAmp;
  CheckError(AMVideoProcAmp.Get(Property_, CurrentValue, Flags));
  if Value then
    Flags := TVideoProcAmpFlags(VideoProcAmp_Flags_Auto)
  else
    Flags := TVideoProcAmpFlags(VideoProcAmp_Flags_Manual);
  CheckError(AMVideoProcAmp.Set_(Property_, CurrentValue, Flags));
end;

function TFCamera.GetAMVideoProcAmpRange(Property_: TVideoProcAmpProperty): TFRange;
var Flags: TVideoProcAmpFlags;
begin
  CheckAMVideoProcAmp;
  CheckError(AMVideoProcAmp.GetRange(Property_, Result.Min, Result.Max, Result.Delta, Result.Default, Flags));
  Result.Auto := (Ord(Flags) and Ord(VideoProcAmp_Flags_Auto)) <> 0;
  Result.Manual := (Ord(Flags) and Ord(VideoProcAmp_Flags_Manual)) <> 0;
end;

function TFCamera.GetBrightness: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_Brightness);
end;

procedure TFCamera.SetBrightness(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_Brightness, Value);
end;

function TFCamera.GetBrightnessSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_Brightness);
end;

function TFCamera.GetBrightnessAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_Brightness);
end;

procedure TFCamera.SetBrightnessAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_Brightness, Value);
end;

function TFCamera.GetBrightnessRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_Brightness);
end;

function TFCamera.GetContrast: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_Contrast);
end;

procedure TFCamera.SetContrast(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_Contrast, Value);
end;

function TFCamera.GetContrastSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_Contrast);
end;

function TFCamera.GetContrastAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_Contrast);
end;

procedure TFCamera.SetContrastAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_Contrast, Value);
end;

function TFCamera.GetContrastRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_Contrast);
end;

function TFCamera.GetHue: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_Hue);
end;

procedure TFCamera.SetHue(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_Hue, Value);
end;

function TFCamera.GetHueSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_Hue);
end;

function TFCamera.GetHueAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_Hue);
end;

procedure TFCamera.SetHueAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_Hue, Value);
end;

function TFCamera.GetHueRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_Hue);
end;

function TFCamera.GetSaturation: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_Saturation);
end;

procedure TFCamera.SetSaturation(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_Saturation, Value);
end;

function TFCamera.GetSaturationSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_Saturation);
end;

function TFCamera.GetSaturationAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_Saturation);
end;

procedure TFCamera.SetSaturationAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_Saturation, Value);
end;

function TFCamera.GetSaturationRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_Saturation);
end;

function TFCamera.GetSharpness: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_Sharpness);
end;

procedure TFCamera.SetSharpness(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_Sharpness, Value);
end;

function TFCamera.GetSharpnessSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_Sharpness);
end;

function TFCamera.GetSharpnessAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_Sharpness);
end;

procedure TFCamera.SetSharpnessAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_Sharpness, Value);
end;

function TFCamera.GetSharpnessRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_Sharpness);
end;

function TFCamera.GetGamma: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_Gamma);
end;

procedure TFCamera.SetGamma(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_Gamma, Value);
end;

function TFCamera.GetGammaSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_Gamma);
end;

function TFCamera.GetGammaAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_Gamma);
end;

procedure TFCamera.SetGammaAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_Gamma, Value);
end;

function TFCamera.GetGammaRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_Gamma);
end;

function TFCamera.GetColorEnable: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_ColorEnable);
end;

procedure TFCamera.SetColorEnable(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_ColorEnable, Value);
end;

function TFCamera.GetColorEnableSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_ColorEnable);
end;

function TFCamera.GetColorEnableAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_ColorEnable);
end;

procedure TFCamera.SetColorEnableAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_ColorEnable, Value);
end;

function TFCamera.GetColorEnableRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_ColorEnable);
end;

function TFCamera.GetColorEnabled: Boolean;
begin
  Result := ColorEnable <> 0;
end;

procedure TFCamera.SetColorEnabled(Value: Boolean);
begin
  if Value then
    ColorEnable := 1
  else
    ColorEnable := 0
end;

function TFCamera.GetColorEnabledSupported: Boolean;
begin
  Result := ColorEnableSupported;
end;

function TFCamera.GetWhiteBalance: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_WhiteBalance);
end;

procedure TFCamera.SetWhiteBalance(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_WhiteBalance, Value);
end;

function TFCamera.GetWhiteBalanceSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_WhiteBalance);
end;

function TFCamera.GetWhiteBalanceAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_WhiteBalance);
end;

procedure TFCamera.SetWhiteBalanceAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_WhiteBalance, Value);
end;

function TFCamera.GetWhiteBalanceRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_WhiteBalance);
end;

function TFCamera.GetBacklightCompensation: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_BacklightCompensation);
end;

procedure TFCamera.SetBacklightCompensation(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_BacklightCompensation, Value);
end;

function TFCamera.GetBacklightCompensationSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_BacklightCompensation);
end;

function TFCamera.GetBacklightCompensationAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_BacklightCompensation);
end;

procedure TFCamera.SetBacklightCompensationAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_BacklightCompensation, Value);
end;

function TFCamera.GetBacklightCompensationRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_BacklightCompensation);
end;

function TFCamera.GetGain: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_Gain);
end;

procedure TFCamera.SetGain(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_Gain, Value);
end;

function TFCamera.GetGainSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_Gain);
end;

function TFCamera.GetGainAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_Gain);
end;

procedure TFCamera.SetGainAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_Gain, Value);
end;

function TFCamera.GetGainRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_Gain);
end;

function TFCamera.GetDigitalMultiplier: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_DigitalMultiplier);
end;

procedure TFCamera.SetDigitalMultiplier(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_DigitalMultiplier, Value);
end;

function TFCamera.GetDigitalMultiplierSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_DigitalMultiplier);
end;

function TFCamera.GetDigitalMultiplierAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_DigitalMultiplier);
end;

procedure TFCamera.SetDigitalMultiplierAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_DigitalMultiplier, Value);
end;

function TFCamera.GetDigitalMultiplierRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_DigitalMultiplier);
end;

function TFCamera.GetDigitalMultiplierLimit: Integer;
begin
  Result := GetAMVideoProcAmpValue(VideoProcAmp_DigitalMultiplierLimit);
end;

procedure TFCamera.SetDigitalMultiplierLimit(Value: Integer);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_DigitalMultiplierLimit, Value);
end;

function TFCamera.GetDigitalMultiplierLimitSupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_DigitalMultiplierLimit);
end;

function TFCamera.GetDigitalMultiplierLimitAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_DigitalMultiplierLimit);
end;

procedure TFCamera.SetDigitalMultiplierLimitAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_DigitalMultiplierLimit, Value);
end;

function TFCamera.GetDigitalMultiplierLimitRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_DigitalMultiplierLimit);
end;

function DecodePowerLineFrequency(Value: Integer): TFPowerLineFrequency;
begin
  case Value of
    0: Result := pfDisabled;
    1: Result := pf50Hz;
    2: Result := pf60Hz;
    3: Result := pfAuto;
    else Result := pfUnknown;
  end;
end;

function Encode(PowerLineFrequency: TFPowerLineFrequency): Integer; overload;
begin
  case PowerLineFrequency of
    pfDisabled: Result := 0;
    pf50Hz: Result := 1;
    pf60Hz: Result := 2;
    pfAuto: Result := 3;
    else {pfUnknown} Result := 0;
  end;
end;

function TFCamera.GetPowerLineFrequency: TFPowerLineFrequency;
begin
  Result := DecodePowerLineFrequency(GetAMVideoProcAmpValue(VideoProcAmp_PowerLineFrequency));
end;

procedure TFCamera.SetPowerLineFrequency(Value: TFPowerLineFrequency);
begin
  SetAMVideoProcAmpValue(VideoProcAmp_PowerLineFrequency, Encode(Value));
end;

function TFCamera.GetPowerLineFrequencySupported: Boolean;
begin
  Result := GetAMVideoProcAmpValueSupported(VideoProcAmp_PowerLineFrequency);
end;

function TFCamera.GetPowerLineFrequencyAuto: Boolean;
begin
  Result := GetAMVideoProcAmpAuto(VideoProcAmp_PowerLineFrequency);
end;

procedure TFCamera.SetPowerLineFrequencyAuto(Value: Boolean);
begin
  SetAMVideoProcAmpAuto(VideoProcAmp_PowerLineFrequency, Value);
end;

{
function TFCamera.GetPowerLineFrequencyRange: TFRange;
begin
  Result := GetAMVideoProcAmpRange(VideoProcAmp_PowerLineFrequency);
end;
}

procedure TFCamera.CheckAMCameraControl;
begin
  CheckDeviceSelected;
  CheckNull(AMCameraControl, 'IAMCameraControl');
end;

function TFCamera.GetAMCameraControlValue(Property_: TCameraControlProperty): Integer;
var Flags: TCameraControlFlags;
begin
  CheckAMCameraControl;
  CheckError(AMCameraControl.Get(Property_, Result, Flags));
end;

function TFCamera.GetAMCameraControlValueSupported(Property_: TCameraControlProperty): Boolean;
var
  Value: Integer;
  Flags: TCameraControlFlags;
begin
  CheckDeviceSelected;
  if AMCameraControl = nil then
    Result := False
  else
    Result := not UnsupportedProperty(AMCameraControl.Get(Property_, Value, Flags));
end;

procedure TFCamera.SetAMCameraControlValue(Property_: TCameraControlProperty; Value: Integer);
var
  CurrentValue: Integer;
  Flags: TCameraControlFlags;
begin
  CheckAMCameraControl;
  CheckError(AMCameraControl.Get(Property_, CurrentValue, Flags));
  CheckError(AMCameraControl.Set_(Property_, Value, Flags));
end;

function TFCamera.GetAMCameraControlAuto(Property_: TCameraControlProperty): Boolean;
var
  Value: Integer;
  Flags: TCameraControlFlags;
begin
  CheckAMCameraControl;
  CheckError(AMCameraControl.Get(Property_, Value, Flags));
  Result := Flags = CameraControl_Flags_Auto;
end;

procedure TFCamera.SetAMCameraControlAuto(Property_: TCameraControlProperty; Value: Boolean);
var
  CurrentValue: Integer;
  Flags: TCameraControlFlags;
begin
  CheckAMCameraControl;
  CheckError(AMCameraControl.Get(Property_, CurrentValue, Flags));
  if Value then
    Flags := TCameraControlFlags(CameraControl_Flags_Auto)
  else
    Flags := TCameraControlFlags(CameraControl_Flags_Manual);
  CheckError(AMCameraControl.Set_(Property_, CurrentValue, Flags));
end;

function TFCamera.GetAMCameraControlRange(Property_: TCameraControlProperty): TFRange;
var Flags: TCameraControlFlags;
begin
  CheckAMCameraControl;
  CheckError(AMCameraControl.GetRange(Property_, Result.Min, Result.Max, Result.Delta, Result.Default, Flags));
  Result.Auto := (Ord(Flags) and Ord(CameraControl_Flags_Auto)) <> 0;
  Result.Manual := (Ord(Flags) and Ord(CameraControl_Flags_Manual)) <> 0;
end;

function TFCamera.GetPan: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_Pan);
end;

procedure TFCamera.SetPan(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_Pan, Value);
end;

function TFCamera.GetPanSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Pan);
end;

function TFCamera.GetPanAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Pan);
end;

procedure TFCamera.SetPanAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Pan, Value);
end;

function TFCamera.GetPanRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_Pan);
end;

function TFCamera.GetPanRelative: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_PanRelative);
end;

procedure TFCamera.SetPanRelative(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_PanRelative, Value);
end;

function TFCamera.GetPanRelativeSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_PanRelative);
end;

function TFCamera.GetPanRelativeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_PanRelative);
end;

procedure TFCamera.SetPanRelativeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_PanRelative, Value);
end;

function TFCamera.GetPanRelativeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_PanRelative);
end;

function TFCamera.GetTilt: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_Tilt);
end;

procedure TFCamera.SetTilt(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_Tilt, Value);
end;

function TFCamera.GetTiltSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Tilt);
end;

function TFCamera.GetTiltAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Tilt);
end;

procedure TFCamera.SetTiltAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Tilt, Value);
end;

function TFCamera.GetTiltRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_Tilt);
end;

function TFCamera.GetTiltRelative: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_TiltRelative);
end;

procedure TFCamera.SetTiltRelative(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_TiltRelative, Value);
end;

function TFCamera.GetTiltRelativeSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_TiltRelative);
end;

function TFCamera.GetTiltRelativeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_TiltRelative);
end;

procedure TFCamera.SetTiltRelativeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_TiltRelative, Value);
end;

function TFCamera.GetTiltRelativeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_TiltRelative);
end;

function TFCamera.GetRoll: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_Roll);
end;

procedure TFCamera.SetRoll(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_Roll, Value);
end;

function TFCamera.GetRollSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Roll);
end;

function TFCamera.GetRollAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Roll);
end;

procedure TFCamera.SetRollAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Roll, Value);
end;

function TFCamera.GetRollRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_Roll);
end;

function TFCamera.GetRollRelative: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_RollRelative);
end;

procedure TFCamera.SetRollRelative(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_RollRelative, Value);
end;

function TFCamera.GetRollRelativeSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_RollRelative);
end;

function TFCamera.GetRollRelativeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_RollRelative);
end;

procedure TFCamera.SetRollRelativeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_RollRelative, Value);
end;

function TFCamera.GetRollRelativeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_RollRelative);
end;

function TFCamera.GetZoom: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_Zoom);
end;

procedure TFCamera.SetZoom(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_Zoom, Value);
end;

function TFCamera.GetZoomSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Zoom);
end;

function TFCamera.GetZoomAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Zoom);
end;

procedure TFCamera.SetZoomAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Zoom, Value);
end;

function TFCamera.GetZoomRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_Zoom);
end;

function TFCamera.GetZoomRelative: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_ZoomRelative);
end;

procedure TFCamera.SetZoomRelative(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_ZoomRelative, Value);
end;

function TFCamera.GetZoomRelativeSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_ZoomRelative);
end;

function TFCamera.GetZoomRelativeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_ZoomRelative);
end;

procedure TFCamera.SetZoomRelativeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_ZoomRelative, Value);
end;

function TFCamera.GetZoomRelativeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_ZoomRelative);
end;

function TFCamera.GetExposure: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_Exposure);
end;

procedure TFCamera.SetExposure(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_Exposure, Value);
end;

function TFCamera.GetExposureSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Exposure);
end;

function TFCamera.GetExposureAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Exposure);
end;

procedure TFCamera.SetExposureAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Exposure, Value);
end;

function TFCamera.GetExposureRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_Exposure);
end;

function TFCamera.GetExposureRelative: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_ExposureRelative);
end;

procedure TFCamera.SetExposureRelative(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_ExposureRelative, Value);
end;

function TFCamera.GetExposureRelativeSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_ExposureRelative);
end;

function TFCamera.GetExposureRelativeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_ExposureRelative);
end;

procedure TFCamera.SetExposureRelativeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_ExposureRelative, Value);
end;

function TFCamera.GetExposureRelativeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_ExposureRelative);
end;

function TFCamera.GetIris: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_Iris);
end;

procedure TFCamera.SetIris(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_Iris, Value);
end;

function TFCamera.GetIrisSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Iris);
end;

function TFCamera.GetIrisAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Iris);
end;

procedure TFCamera.SetIrisAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Iris, Value);
end;

function TFCamera.GetIrisRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_Iris);
end;

function TFCamera.GetIrisRelative: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_IrisRelative);
end;

procedure TFCamera.SetIrisRelative(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_IrisRelative, Value);
end;

function TFCamera.GetIrisRelativeSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_IrisRelative);
end;

function TFCamera.GetIrisRelativeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_IrisRelative);
end;

procedure TFCamera.SetIrisRelativeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_IrisRelative, Value);
end;

function TFCamera.GetIrisRelativeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_IrisRelative);
end;

function TFCamera.GetFocus: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_Focus);
end;

procedure TFCamera.SetFocus(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_Focus, Value);
end;

function TFCamera.GetFocusSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Focus);
end;

function TFCamera.GetFocusAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Focus);
end;

procedure TFCamera.SetFocusAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Focus, Value);
end;

function TFCamera.GetFocusRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_Focus);
end;

function TFCamera.GetFocusRelative: Integer;
begin
  Result := GetAMCameraControlValue(CameraControl_FocusRelative);
end;

procedure TFCamera.SetFocusRelative(Value: Integer);
begin
  SetAMCameraControlValue(CameraControl_FocusRelative, Value);
end;

function TFCamera.GetFocusRelativeSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_FocusRelative);
end;

function TFCamera.GetFocusRelativeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_FocusRelative);
end;

procedure TFCamera.SetFocusRelativeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_FocusRelative, Value);
end;

function TFCamera.GetFocusRelativeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_FocusRelative);
end;

function DecodeScanMode(Value: Integer): TFScanMode;
begin
  case Value of
    0: Result := smInterlace;
    1: Result := smProgressive;
    else Result := smUnknown;
  end;
end;

function Encode(ScanMode: TFScanMode): Integer; overload;
begin
  case ScanMode of
    smInterlace: Result := 0;
    smProgressive: Result := 1;
    else {smUnknown} Result := 0;
  end;
end;

function TFCamera.GetScanMode: TFScanMode;
begin
  Result := DecodeScanMode(GetAMCameraControlValue(CameraControl_ScanMode));
end;

procedure TFCamera.SetScanMode(Value: TFScanMode);
begin
  SetAMCameraControlValue(CameraControl_ScanMode, Encode(Value));
end;

function TFCamera.GetScanModeAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_ScanMode);
end;

procedure TFCamera.SetScanModeAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_ScanMode, Value);
end;

{
function TFCamera.GetScanModeRange: TFRange;
begin
  Result := GetAMCameraControlRange(CameraControl_ScanMode);
end;
}

function TFCamera.GetAMCameraControlFocalLength: KSPROPERTY_CAMERACONTROL_FOCAL_LENGTH_S;
var
  KsPropertySet: IKsPropertySet;
  Size: DWORD;
begin
  CheckDeviceSelected;
  FillChar(Result, SizeOf(Result), 0);
  OleCheck(CaptureFilter.QueryInterface(IKsPropertySet, KsPropertySet));
  OleCheck(KsPropertySet.Get(PROPSETID_VIDCAP_CAMERACONTROL, TAMPropertyPin(KSPROPERTY_CAMERACONTROL_FOCAL_LENGTH), nil, 0, Result, SizeOf(Result), Size));
end;

function TFCamera.GetFocalLength: TFFocalLength;
var FocalLengthS: KSPROPERTY_CAMERACONTROL_FOCAL_LENGTH_S;
begin
  FocalLengthS := GetAMCameraControlFocalLength;
  Result.Ocular := FocalLengthS.lOcularFocalLength;
  Result.ObjectiveMin := FocalLengthS.lObjectiveFocalLengthMin;
  Result.ObjectiveMax := FocalLengthS.lObjectiveFocalLengthMax;
end;

function TFCamera.GetFocalLengthSupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_FocalLength);
end;

function TFCamera.GetPrivacy: Boolean;
begin
  Result := GetAMCameraControlValue(CameraControl_Privacy) <> 0;
end;

procedure TFCamera.SetPrivacy(Value: Boolean);
begin
  SetAMCameraControlValue(CameraControl_Privacy, BooleanToInt(Value));
end;

function TFCamera.GetPrivacySupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_Privacy);
end;

function TFCamera.GetPrivacyAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_Privacy);
end;

procedure TFCamera.SetPrivacyAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_Privacy, Value);
end;

function TFCamera.GetAutoExposurePriority: Boolean;
begin
  Result := GetAMCameraControlValue(CameraControl_Privacy) <> 0;
end;

procedure TFCamera.SetAutoExposurePriority(Value: Boolean);
begin
  SetAMCameraControlValue(CameraControl_AutoExposurePriority, BooleanToInt(Value))
end;

function TFCamera.GetAutoExposurePrioritySupported: Boolean;
begin
  Result := GetAMCameraControlValueSupported(CameraControl_AutoExposurePriority);
end;

function TFCamera.GetAutoExposurePriorityAuto: Boolean;
begin
  Result := GetAMCameraControlAuto(CameraControl_AutoExposurePriority);
end;

procedure TFCamera.SetAutoExposurePriorityAuto(Value: Boolean);
begin
  SetAMCameraControlAuto(CameraControl_AutoExposurePriority, Value);
end;

function TFCamera.GetAMCameraControlFlash: KSPROPERTY_CAMERACONTROL_FLASH_S;
var
  KsPropertySet: IKsPropertySet;
  Size: DWORD;
begin
  CheckDeviceSelected;
  FillChar(Result, SizeOf(Result), 0);
  OleCheck(CaptureFilter.QueryInterface(IKsPropertySet, KsPropertySet));
  OleCheck(KsPropertySet.Get(PROPSETID_VIDCAP_CAMERACONTROL_FLASH, TAMPropertyPin(KSPROPERTY_CAMERACONTROL_FLASH_PROPERTY_ID), nil, 0, Result, SizeOf(Result), Size));
end;

function TFCamera.GetAMCameraControlFlashSupported: Boolean;
var
  KsPropertySet: IKsPropertySet;
  Size: DWORD;
begin
  CheckDeviceSelected;
  FillChar(Result, SizeOf(Result), 0);
  OleCheck(CaptureFilter.QueryInterface(IKsPropertySet, KsPropertySet));
  Result := not UnsupportedProperty(KsPropertySet.Get(PROPSETID_VIDCAP_CAMERACONTROL_FLASH, TAMPropertyPin(KSPROPERTY_CAMERACONTROL_FLASH_PROPERTY_ID), nil, 0, Result, SizeOf(Result), Size));
end;

procedure TFCamera.SetAMCameraControlFlash(const Value: KSPROPERTY_CAMERACONTROL_FLASH_S);
var KsPropertySet: IKsPropertySet;
begin
  CheckDeviceSelected;
  OleCheck(CaptureFilter.QueryInterface(IKsPropertySet, KsPropertySet));
  OleCheck(KsPropertySet.Set_(PROPSETID_VIDCAP_CAMERACONTROL_FLASH, TAMPropertyPin(KSPROPERTY_CAMERACONTROL_FLASH_PROPERTY_ID), nil, 0, @Value, SizeOf(Value)));
end;

function DecodeFlashControl(Value: Integer): TFFlashControl;
begin
  case Value of
    KSPROPERTY_CAMERACONTROL_FLASH_FLAGS_AUTO: Result := fcAuto;
    KSPROPERTY_CAMERACONTROL_FLASH_FLAGS_MANUAL: Result := fcManual;
    else Result := fcUnknown;
  end;
end;

function Encode(FlashControl: TFFlashControl): Integer; overload;
begin
  case FlashControl of
    fcAuto: Result := KSPROPERTY_CAMERACONTROL_FLASH_FLAGS_AUTO;
    fcManual: Result := KSPROPERTY_CAMERACONTROL_FLASH_FLAGS_MANUAL;
    else {fcUnknown} Result := KSPROPERTY_CAMERACONTROL_FLASH_FLAGS_AUTO;
  end;
end;

function TFCamera.GetFlashControl: TFFlashControl;
begin
  Result := DecodeFlashControl(GetAMCameraControlFlash.Capabilities);
end;

function TFCamera.GetFlashControlSupported: Boolean;
begin
  Result := GetAMCameraControlFlashSupported;
end;

procedure TFCamera.SetFlashControl(Value: TFFlashControl);
var Flash: KSPROPERTY_CAMERACONTROL_FLASH_S;
begin
  Flash := GetAMCameraControlFlash;
  Flash.Capabilities := Encode(Value);
  SetAMCameraControlFlash(Flash);
end;

function DecodeFlashMode(Value: Integer): TFFlashMode;
begin
  case Value of
    KSPROPERTY_CAMERACONTROL_FLASH_OFF: Result := fmOff;
    KSPROPERTY_CAMERACONTROL_FLASH_ON: Result := fmOn;
    KSPROPERTY_CAMERACONTROL_FLASH_AUTO: Result := fmAuto;
    else Result := fmUnknown;
  end;
end;

function Encode(FlashMode: TFFlashMode): Integer; overload;
begin
  case FlashMode of
    fmOff: Result := KSPROPERTY_CAMERACONTROL_FLASH_OFF;
    fmOn: Result := KSPROPERTY_CAMERACONTROL_FLASH_ON;
    fmAuto: Result := KSPROPERTY_CAMERACONTROL_FLASH_AUTO;
    else {fmUnknown} Result := KSPROPERTY_CAMERACONTROL_FLASH_OFF;
  end;
end;

function TFCamera.GetFlashMode: TFFlashMode;
begin
  Result := DecodeFlashMode(GetAMCameraControlFlash.Flash);
end;

procedure TFCamera.SetFlashMode(Value: TFFlashMode);
var Flash: KSPROPERTY_CAMERACONTROL_FLASH_S;
begin
  Flash := GetAMCameraControlFlash;
  Flash.Flash := Encode(Value);
  SetAMCameraControlFlash(Flash);
end;

function TFCamera.GetFlashModeSupported: Boolean;
begin
  Result := GetAMCameraControlFlashSupported;
end;

function TFCamera.GetAMCameraControlVideoStabilizationMode: KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_S;
var
  KsPropertySet: IKsPropertySet;
  Size: DWORD;
begin
  CheckDeviceSelected;
  FillChar(Result, SizeOf(Result), 0);
  OleCheck(CaptureFilter.QueryInterface(IKsPropertySet, KsPropertySet));
  OleCheck(KsPropertySet.Get(PROPSETID_VIDCAP_CAMERACONTROL_VIDEO_STABILIZATION, TAMPropertyPin(KSPROPERTY_CAMERACONTROL_VIDEO_STABILIZATION_MODE_PROPERTY_ID), nil, 0, Result, SizeOf(Result), Size));
end;

function TFCamera.GetAMCameraControlVideoStabilizationModeSupported: Boolean;
var
  KsPropertySet: IKsPropertySet;
  Size: DWORD;
begin
  CheckDeviceSelected;
  FillChar(Result, SizeOf(Result), 0);
  OleCheck(CaptureFilter.QueryInterface(IKsPropertySet, KsPropertySet));
  Result := not UnsupportedProperty(KsPropertySet.Get(PROPSETID_VIDCAP_CAMERACONTROL_VIDEO_STABILIZATION, TAMPropertyPin(KSPROPERTY_CAMERACONTROL_VIDEO_STABILIZATION_MODE_PROPERTY_ID), nil, 0, Result, SizeOf(Result), Size));
end;

procedure TFCamera.SetAMCameraControlVideoStabilizationMode(const Value: KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_S);
var KsPropertySet: IKsPropertySet;
begin
  CheckDeviceSelected;
  OleCheck(CaptureFilter.QueryInterface(IKsPropertySet, KsPropertySet));
  OleCheck(KsPropertySet.Set_(PROPSETID_VIDCAP_CAMERACONTROL_VIDEO_STABILIZATION, TAMPropertyPin(KSPROPERTY_CAMERACONTROL_VIDEO_STABILIZATION_MODE_PROPERTY_ID), nil, 0, @Value, SizeOf(Value)));
end;

function DecodeVideoStabilizationControl(Value: Integer): TFVideoStabilizationControl;
begin
  case Value of
    KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_FLAGS_AUTO: Result := vcAuto;
    KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_FLAGS_MANUAL: Result := vcManual;
    else Result := vcUnknown;
  end;
end;

function Encode(VideoStabilizationControl: TFVideoStabilizationControl): Integer; overload;
begin
  case VideoStabilizationControl of
    vcAuto: Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_FLAGS_AUTO;
    vcManual: Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_FLAGS_MANUAL;
    else {vcUnknown} Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_FLAGS_AUTO;
  end;
end;

function TFCamera.GetVideoStabilizationControl: TFVideoStabilizationControl;
begin
  Result := DecodeVideoStabilizationControl(GetAMCameraControlVideoStabilizationMode.Capabilities);
end;

function TFCamera.GetVideoStabilizationControlSupported: Boolean;
begin
  Result := GetAMCameraControlVideoStabilizationModeSupported;
end;

procedure TFCamera.SetVideoStabilizationControl(Value: TFVideoStabilizationControl);
var VideoStabilization: KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_S;
begin
  VideoStabilization := GetAMCameraControlVideoStabilizationMode;
  VideoStabilization.Capabilities := Encode(Value);
  SetAMCameraControlVideoStabilizationMode(VideoStabilization);
end;

function DecodeVideoStabilizationMode(Value: Integer): TFVideoStabilizationMode;
begin
  case Value of
    KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_OFF: Result := vmOff;
    KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_HIGH: Result := vmHigh;
    KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_MEDIUM: Result := vmMedium;
    KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_LOW: Result := vmLow;
    KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_AUTO: Result := vmAuto;
    else Result := vmUnknown;
  end;
end;

function Encode(VideoStabilizationMode: TFVideoStabilizationMode): Integer; overload;
begin
  case VideoStabilizationMode of
    vmOff: Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_OFF;
    vmHigh: Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_HIGH;
    vmMedium: Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_MEDIUM;
    vmLow: Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_LOW;
    vmAuto: Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_AUTO;
    else {vmUnknown} Result := KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_OFF;
  end;
end;

function TFCamera.GetVideoStabilizationMode: TFVideoStabilizationMode;
begin
  Result := DecodeVideoStabilizationMode(GetAMCameraControlVideoStabilizationMode.VideoStabilizationMode);
end;

function TFCamera.GetVideoStabilizationModeSupported: Boolean;
begin
  Result := GetAMCameraControlVideoStabilizationModeSupported;
end;

procedure TFCamera.SetVideoStabilizationMode(Value: TFVideoStabilizationMode);
var VideoStabilization: KSPROPERTY_CAMERACONTROL_VIDEOSTABILIZATION_MODE_S;
begin
  VideoStabilization := GetAMCameraControlVideoStabilizationMode;
  VideoStabilization.VideoStabilizationMode := Encode(Value);
  SetAMCameraControlVideoStabilizationMode(VideoStabilization);
end;

const
  Rv: array [0..255] of Integer = (
    -175, -174, -172, -171, -169, -168, -167, -165, -164, -163, -161, -160, -159, -157, -156, -154,
    -153, -152, -150, -149, -148, -146, -145, -143, -142, -141, -139, -138, -137, -135, -134, -132,
    -131, -130, -128, -127, -126, -124, -123, -121, -120, -119, -117, -116, -115, -113, -112, -111,
    -109, -108, -106, -105, -104, -102, -101, -100, -98, -97, -95, -94, -93, -91, -90, -89,
    -87, -86, -84, -83, -82, -80, -79, -78, -76, -75, -74, -72, -71, -69, -68, -67,
    -65, -64, -63, -61, -60, -58, -57, -56, -54, -53, -52, -50, -49, -47, -46, -45,
    -43, -42, -41, -39, -38, -37, -35, -34, -32, -31, -30, -28, -27, -26, -24, -23,
    -21, -20, -19, -17, -16, -15, -13, -12, -10, -9, -8, -6, -5, -4, -2, -1,
    0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 15, 16, 17, 19, 20,
    21, 23, 24, 26, 27, 28, 30, 31, 32, 34, 35, 37, 38, 39, 41, 42,
    43, 45, 46, 47, 49, 50, 52, 53, 54, 56, 57, 58, 60, 61, 63, 64,
    65, 67, 68, 69, 71, 72, 74, 75, 76, 78, 79, 80, 82, 83, 84, 86,
    87, 89, 90, 91, 93, 94, 95, 97, 98, 100, 101, 102, 104, 105, 106, 108,
    109, 111, 112, 113, 115, 116, 117, 119, 120, 121, 123, 124, 126, 127, 128, 130,
    131, 132, 134, 135, 137, 138, 139, 141, 142, 143, 145, 146, 148, 149, 150, 152,
    153, 154, 156, 157, 159, 160, 161, 163, 164, 165, 167, 168, 169, 171, 172, 174);
  Gv: array [0..255] of Integer = (
    89, 88, 87, 87, 86, 85, 85, 84, 83, 83, 82, 81, 80, 80, 79, 78,
    78, 77, 76, 76, 75, 74, 73, 73, 72, 71, 71, 70, 69, 69, 68, 67,
    67, 66, 65, 64, 64, 63, 62, 62, 61, 60, 60, 59, 58, 57, 57, 56,
    55, 55, 54, 53, 53, 52, 51, 50, 50, 49, 48, 48, 47, 46, 46, 45,
    44, 43, 43, 42, 41, 41, 40, 39, 39, 38, 37, 36, 36, 35, 34, 34,
    33, 32, 32, 31, 30, 30, 29, 28, 27, 27, 26, 25, 25, 24, 23, 23,
    22, 21, 20, 20, 19, 18, 18, 17, 16, 16, 15, 14, 13, 13, 12, 11,
    11, 10, 9, 9, 8, 7, 6, 6, 5, 4, 4, 3, 2, 2, 1, 0,
    0, 0, -1, -2, -2, -3, -4, -4, -5, -6, -6, -7, -8, -9, -9, -10,
    -11, -11, -12, -13, -13, -14, -15, -16, -16, -17, -18, -18, -19, -20, -20, -21,
    -22, -23, -23, -24, -25, -25, -26, -27, -27, -28, -29, -30, -30, -31, -32, -32,
    -33, -34, -34, -35, -36, -36, -37, -38, -39, -39, -40, -41, -41, -42, -43, -43,
    -44, -45, -46, -46, -47, -48, -48, -49, -50, -50, -51, -52, -53, -53, -54, -55,
    -55, -56, -57, -57, -58, -59, -60, -60, -61, -62, -62, -63, -64, -64, -65, -66,
    -67, -67, -68, -69, -69, -70, -71, -71, -72, -73, -73, -74, -75, -76, -76, -77,
    -78, -78, -79, -80, -80, -81, -82, -83, -83, -84, -85, -85, -86, -87, -87, -88);
  Gu: array [0..255] of Integer = (
    43, 42, 42, 42, 41, 41, 41, 40, 40, 40, 39, 39, 39, 38, 38, 38,
    37, 37, 37, 36, 36, 36, 35, 35, 35, 34, 34, 34, 33, 33, 33, 32,
    32, 32, 31, 31, 31, 30, 30, 30, 29, 29, 29, 28, 28, 28, 27, 27,
    27, 26, 26, 25, 25, 25, 24, 24, 24, 23, 23, 23, 22, 22, 22, 21,
    21, 21, 20, 20, 20, 19, 19, 19, 18, 18, 18, 17, 17, 17, 16, 16,
    16, 15, 15, 15, 14, 14, 14, 13, 13, 13, 12, 12, 12, 11, 11, 11,
    10, 10, 10, 9, 9, 9, 8, 8, 8, 7, 7, 7, 6, 6, 6, 5,
    5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 1, 1, 1, 0, 0,
    0, 0, 0, -1, -1, -1, -2, -2, -2, -3, -3, -3, -4, -4, -4, -5,
    -5, -5, -6, -6, -6, -7, -7, -7, -8, -8, -8, -9, -9, -9, -10, -10,
    -10, -11, -11, -11, -12, -12, -12, -13, -13, -13, -14, -14, -14, -15, -15, -15,
    -16, -16, -16, -17, -17, -17, -18, -18, -18, -19, -19, -19, -20, -20, -20, -21,
    -21, -21, -22, -22, -22, -23, -23, -23, -24, -24, -24, -25, -25, -25, -26, -26,
    -27, -27, -27, -28, -28, -28, -29, -29, -29, -30, -30, -30, -31, -31, -31, -32,
    -32, -32, -33, -33, -33, -34, -34, -34, -35, -35, -35, -36, -36, -36, -37, -37,
    -37, -38, -38, -38, -39, -39, -39, -40, -40, -40, -41, -41, -41, -42, -42, -42);
  Bu: array [0..255] of Integer = (
    -221, -220, -218, -216, -214, -213, -211, -209, -207, -206, -204, -202, -200, -199, -197, -195,
    -194, -192, -190, -188, -187, -185, -183, -181, -180, -178, -176, -174, -173, -171, -169, -168,
    -166, -164, -162, -161, -159, -157, -155, -154, -152, -150, -148, -147, -145, -143, -142, -140,
    -138, -136, -135, -133, -131, -129, -128, -126, -124, -123, -121, -119, -117, -116, -114, -112,
    -110, -109, -107, -105, -103, -102, -100, -98, -97, -95, -93, -91, -90, -88, -86, -84,
    -83, -81, -79, -77, -76, -74, -72, -71, -69, -67, -65, -64, -62, -60, -58, -57,
    -55, -53, -51, -50, -48, -46, -45, -43, -41, -39, -38, -36, -34, -32, -31, -29,
    -27, -25, -24, -22, -20, -19, -17, -15, -13, -12, -10, -8, -6, -5, -3, -1,
    0, 1, 3, 5, 6, 8, 10, 12, 13, 15, 17, 19, 20, 22, 24, 25,
    27, 29, 31, 32, 34, 36, 38, 39, 41, 43, 45, 46, 48, 50, 51, 53,
    55, 57, 58, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81,
    83, 84, 86, 88, 90, 91, 93, 95, 97, 98, 100, 102, 103, 105, 107, 109,
    110, 112, 114, 116, 117, 119, 121, 123, 124, 126, 128, 129, 131, 133, 135, 136,
    138, 140, 142, 143, 145, 147, 148, 150, 152, 154, 155, 157, 159, 161, 162, 164,
    166, 168, 169, 171, 173, 174, 176, 178, 180, 181, 183, 185, 187, 188, 190, 192,
    194, 195, 197, 199, 200, 202, 204, 206, 207, 209, 211, 213, 214, 216, 218, 220);

// YUY2 Sampling: 4:2:2 Packed
procedure Yuy2ToRgba(Data: PByte; Width, Height: Integer; Rgba: PCardinal; HorizMirror, VertMirror: Boolean);
var
  I, J: Integer;
  Y, U, V: Integer;
  R, G, B: Integer;
  YPtr, UPtr, VPtr: PByte;
  RgbaIndex: Integer;
  Skip: Boolean;
begin
  YPtr := Data;
  UPtr := @Data[1];
  VPtr := @Data[3];

  U := 0; // to avoid warning
  V := 0; // to avoid warning

  Skip := False;
  for I := Height - 1 downto 0 do
    for J := Width - 1 downto 0 do
    begin
      Y := YPtr^;
      Inc(YPtr, 2);

      if not Skip then
      begin
        U := UPtr^;
        Inc(UPtr, 4);
        V := VPtr^;
        Inc(VPtr, 4);
      end;
      Skip := not Skip;

      R := Y + Rv[V];
      if R < 0 then
        R := 0
      else if R > 255 then
        R := 255;

      G := Y + Gv[V] + Gu[U];
      if G < 0 then
        G := 0
      else if G > 255 then
        G := 255;

      B := Y + Bu[U];
      if B < 0 then
        B := 0
      else if B > 255 then
        B := 255;

      if VertMirror then
        if HorizMirror then
          RgbaIndex := I * Width + J
        else
          RgbaIndex := I * Width + (Width - (J + 1))
      else
        if HorizMirror then
          RgbaIndex := (Height - (I + 1)) * Width + J
        else
          RgbaIndex := (Height - (I + 1)) * Width + (Width - (J + 1));

      PCardinal(PByte(Rgba) + RgbaIndex shl 2)^ := $FF000000 or Cardinal(R shl 16) or Cardinal(G shl 8) or Cardinal(B);
    end;
end;

// NV12 Sampling: 4:2:0 Planar
procedure NV12ToRgba(Data: PByte; Width, Height: Integer; Rgba: PCardinal; HorizMirror, VertMirror: Boolean);
var
  I, J: Integer;
  Y, U, V: Integer;
  R, G, B: Integer;
  YPtr, UVPtr: PByte;
  RgbaIndex: Integer;
  Skip, RepeatRow: Boolean;
begin
  YPtr := Data;
  UVPtr := @Data[Width * Height]; // UV values are located after Y values

  U := 0; // to avoid warning
  V := 0; // to avoid warning

  Skip := False;
  RepeatRow := False;
  for I := Height - 1 downto 0 do
  begin
    if RepeatRow then
      Dec(UVPtr, Width);
    RepeatRow := not RepeatRow;

    for J := Width - 1 downto 0 do
    begin
      Y := YPtr^;
      Inc(YPtr);
      if not Skip then
      begin
        U := UVPtr^;
        Inc(UVPtr);
        V := UVPtr^;
        Inc(UVPtr);
      end;
      Skip := not Skip;

      R := Y + Rv[V];
      if R < 0 then
        R := 0
      else if R > 255 then
        R := 255;

      G := Y + Gv[V] + Gu[U];
      if G < 0 then
        G := 0
      else if G > 255 then
        G := 255;

      B := Y + Bu[U];
      if B < 0 then
        B := 0
      else if B > 255 then
        B := 255;

      if VertMirror then
        if HorizMirror then
          RgbaIndex := I * Width + J
        else
          RgbaIndex := I * Width + (Width - (J + 1))
      else
        if HorizMirror then
          RgbaIndex := (Height - (I + 1)) * Width + J
        else
          RgbaIndex := (Height - (I + 1)) * Width + (Width - (J + 1));

      PCardinal(PByte(Rgba) + RgbaIndex shl 2)^ := $FF000000 or Cardinal(R shl 16) or Cardinal(G shl 8) or Cardinal(B);
    end;
  end;
end;

function TFCamera.CurrentImageToStream(Stream: TStream): TFImageFormat;
const
  MJpg = Ord('M') + Ord('J') shl 8 + Ord('P') shl 16 + Ord('G') shl 24;
var
  MediaType: TAMMediaType;
  MediaHeader: PVideoInfoHeader;
  BufferSize: LongInt;
  Buffer: TBytes;
  Rgba: array of Cardinal;
  BitmapInfoHeader: PBitmapInfoHeader;
  BitmapFileHeader: TBitmapFileHeader;
begin
  CheckActive;

  Result := ifUnsupported;
  if FGrabberUsed then
  begin
    CheckError(FSampleGrabber.GetConnectedMediaType(MediaType));
    try
      if IsEqualGUID(MediaType.formattype, FORMAT_VideoInfo) then
        if MediaType.cbFormat >= SizeOf(TVideoInfoHeader) then
        begin
          MediaHeader := MediaType.pbFormat;
          if MediaHeader <> nil then
          begin
            BitmapInfoHeader := @MediaHeader.bmiHeader;

            if not Succeeded(FSampleGrabber.GetCurrentBuffer(BufferSize, nil)) then
              Exit;
            SetLength(Buffer, BufferSize);
            CheckError(FSampleGrabber.GetCurrentBuffer(BufferSize, Buffer));

            if BitmapInfoHeader.biCompression = MJpg then
            begin
              // MEDIASUBTYPE_MJPG
              Result := ifJpeg;
              if Buffer <> nil then
                Stream.WriteBuffer(Buffer[0], BufferSize);
            end
            else
            begin
              BitmapFileHeader.bfType := Ord('B') + Word(Ord('M') shl 8);
              BitmapFileHeader.bfSize := SizeOf(BitmapFileHeader) + BitmapInfoHeader.biSize + DWORD(BufferSize);
              BitmapFileHeader.bfReserved1 := 0;
              BitmapFileHeader.bfReserved2 := 0;
              BitmapFileHeader.bfOffBits := SizeOf(BitmapFileHeader) + BitmapInfoHeader.biSize;

              if (BitmapInfoHeader.biPlanes = 1)
                and (BitmapInfoHeader.biBitCount = 16)
                and (BitmapInfoHeader.biCompression = $32595559 {YUY2}) then
              begin
                // MEDIASUBTYPE_YUY2
                SetLength(Rgba, BitmapInfoHeader.biWidth * BitmapInfoHeader.biHeight);
                Yuy2ToRgba(@Buffer[0], BitmapInfoHeader.biWidth, BitmapInfoHeader.biHeight, @Rgba[0], False, True);

                BitmapFileHeader.bfSize := SizeOf(BitmapFileHeader) + BitmapInfoHeader.biSize + DWORD(Length(Rgba) * SizeOf(Cardinal));
                BitmapInfoHeader.biBitCount := 32;
                BitmapInfoHeader.biCompression := BI_RGB;
                BitmapInfoHeader.biSizeImage := 0;
                BitmapInfoHeader.biClrUsed := 0;
                BitmapInfoHeader.biClrImportant := 0;

                Stream.WriteBuffer(BitmapFileHeader, SizeOf(BitmapFileHeader));
                Stream.WriteBuffer(BitmapInfoHeader^, BitmapInfoHeader.biSize);
                Stream.WriteBuffer(Rgba[0], Length(Rgba) * SizeOf(Cardinal));
                Result := ifBmp;
              end
              else if (BitmapInfoHeader.biPlanes = 1)
                and (BitmapInfoHeader.biBitCount = 12)
                and (BitmapInfoHeader.biCompression = $3231564E {NV12}) then
              begin
                // MEDIASUBTYPE_NV12
                SetLength(Rgba, BitmapInfoHeader.biWidth * BitmapInfoHeader.biHeight);
                Nv12ToRgba(@Buffer[0], BitmapInfoHeader.biWidth, BitmapInfoHeader.biHeight, @Rgba[0], False, True);

                BitmapFileHeader.bfSize := SizeOf(BitmapFileHeader) + BitmapInfoHeader.biSize + DWORD(Length(Rgba) * SizeOf(Cardinal));
                BitmapInfoHeader.biBitCount := 32;
                BitmapInfoHeader.biCompression := BI_RGB;
                BitmapInfoHeader.biSizeImage := 0;
                BitmapInfoHeader.biClrUsed := 0;
                BitmapInfoHeader.biClrImportant := 0;

                Stream.WriteBuffer(BitmapFileHeader, SizeOf(BitmapFileHeader));
                Stream.WriteBuffer(BitmapInfoHeader^, BitmapInfoHeader.biSize);
                Stream.WriteBuffer(Rgba[0], Length(Rgba) * SizeOf(Cardinal));
                Result := ifBmp;
              end
              else
              begin
                // MEDIASUBTYPE_ARGB32, MEDIASUBTYPE_RGB32, MEDIASUBTYPE_RGB24, ... 
                Stream.WriteBuffer(BitmapFileHeader, SizeOf(BitmapFileHeader));
                Stream.WriteBuffer(BitmapInfoHeader^, BitmapInfoHeader.biSize);
                if Buffer <> nil then
                  Stream.WriteBuffer(Buffer[0], BufferSize);
                Result := ifBmp;
              end
            end
          end;
        end;
    finally
      FreeMediaType(@MediaType);
    end;
  end
  else
  begin
    CheckError(VMRWindowlessControl9.GetCurrentImage(PByte(BitmapInfoHeader)));
    try
      BitmapFileHeader.bfType := Ord('B') + Word(Ord('M') shl 8);
      BitmapFileHeader.bfSize := SizeOf(BitmapFileHeader) + BitmapInfoHeader.biSize + BitmapInfoHeader.biSizeImage;
      BitmapFileHeader.bfReserved1 := 0;
      BitmapFileHeader.bfReserved2 := 0;
      BitmapFileHeader.bfOffBits := SizeOf(BitmapFileHeader) + BitmapInfoHeader.biSize;

      Stream.WriteBuffer(BitmapFileHeader, SizeOf(BitmapFileHeader));
      Stream.WriteBuffer(BitmapInfoHeader^, BitmapInfoHeader.biSize + BitmapInfoHeader.biSizeImage);
      Result := ifBmp;
    finally
      CoTaskMemFree(BitmapInfoHeader);
    end;
  end;
end;

function TFCamera.CurrentImageToFile(const FileName: string): TFImageFormat;
var FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    Result := CurrentImageToStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

function TFCamera.CurrentImageToBitmap: TBitmap;
begin
  Result := TBitmap.Create(0, 0);
  try
    CurrentImageToBitmap(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TFCamera.CurrentImageToBitmap(Bitmap: TBitmap): Boolean;
var MemoryStream: TMemoryStream;
begin
  MemoryStream := TMemoryStream.Create;
  try
    Result := CurrentImageToBitmap(Bitmap, MemoryStream);
  finally
    MemoryStream.Free;
  end;
end;

function TFCamera.CurrentImageToBitmap(Bitmap: TBitmap; MemoryStream: TMemoryStream): Boolean;
begin
  MemoryStream.Position := 0;
  CurrentImageToStream(MemoryStream);
  MemoryStream.Size := MemoryStream.Position;
  MemoryStream.Position := 0;
  Bitmap.LoadFromStream(MemoryStream);
  Result := True;
end;

function TFCamera.GetState: TFCameraState;
var FilterState: TFilterState;
begin
  if not Active then
    Result := csInactive
  else
  begin
    if Failed(MediaControl.GetState(0, FilterState)) then
      Result := csUnknown
    else
      case FilterState of
        State_Stopped: Result := csStopped;
        State_Paused: Result := csPaused;
        State_Running: Result := csRunning;
        else Result := csUnknown;
      end
  end;
end;

procedure TFCamera.Loaded;
begin
  inherited Loaded;
  SetActive(FActive);
end;

function TFCamera.GetActive: Boolean;
begin
  if not (csDesigning in ComponentState) then
    Result := FMediaControl <> nil
  else
    Result := FActive;
end;

function GetParentForm(Control: TControl): TCommonCustomForm;
begin
  Result := Control.Root as TCommonCustomForm;
end;

{$ifndef DXE5PLUS}
function FormToHWND(Form: TCommonCustomForm): HWND;
begin
  {$ifndef DXE4PLUS}
  if Form <> nil then
    Result := FmxHandleToHWND(Form.Handle)
  else
    Result := 0;
  {$else}
  if (Form <> nil) and (Form.Handle is TWinWindowHandle) then
    Result := TWinWindowHandle(Form.Handle).Wnd
  else
    Result := 0;
  {$endif}
end;
{$endif}

function Encode(MediaType: TFMediaType): TGUID; overload;
begin
  if MediaType = mtAsf then
    Result := MEDIASUBTYPE_Asf
  else
    Result := MEDIASUBTYPE_Avi
end;

function Encode(OutputType: TFOutputType): TGUID; overload;
begin
  case OutputType of
//    otRgb1:        Result := MEDIASUBTYPE_RGB1;
//    otRgb4:        Result := MEDIASUBTYPE_RGB4;
//    otRgb8:        Result := MEDIASUBTYPE_RGB8;
//    otRgb565:      Result := MEDIASUBTYPE_RGB565;
    otRgb555:      Result := MEDIASUBTYPE_RGB555;
    otRgb24:       Result := MEDIASUBTYPE_RGB24;
    otRgb32:       Result := MEDIASUBTYPE_RGB32;
//    otArgb1555:    Result := MEDIASUBTYPE_ARGB1555;
//    otArgb4444:    Result := MEDIASUBTYPE_ARGB4444;
    otArgb32:      Result := MEDIASUBTYPE_ARGB32;
//    otA2R10G10B10: Result := MEDIASUBTYPE_A2R10G10B10;
//    otA2B10G10R10: Result := MEDIASUBTYPE_A2B10G10R10;
    else {otAuto}  Result := GUID_NULL;
  end;
end;

procedure TFCamera.SetActive(Value: Boolean);
var
  Mux: IBaseFilter;
  FileSinkFilter: IFileSinkFilter;
  ParentForm: TCommonCustomForm;
  Handle: HWND;
  Point: TPointF;
  Rect: TRect;
  AspectRatioMode: TVMR9AspectRatioMode;
  RenderStreamResult: HResult;
  Compressor, AudioCompressor: IBaseFilter;
  MediaType: TAMMediaType;
begin
  if Active <> Value then
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        if Value then
        try
          {$ifdef TRIAL}
          ShowTrialMessage;
          {$endif}

          FGrabberUsed := False;
          CheckDeviceSelected;

          CheckNull(CaptureFilter, 'Capture IBaseFilter');
          CheckNull(CaptureGraphBuilder2, 'ICaptureGraphBuilder2');
          CheckNull(GraphBuilder, 'IGraphBuilder');
          CheckNull(MediaControl, 'IMediaControl');

          // capture to window using VMR-9
          RenderStreamResult := S_OK; // to avoid warning
          if (FCaptureType = ctVmr9) or (FCaptureType = ctAuto) then
          begin
            CheckNull(VideoMixingRenderer9Filter, 'VideoMixingRenderer9 IBaseFilter');
            CheckNull(VMRFilterConfig9, 'IVMRFilterConfig9');
            CheckNull(VMRWindowlessControl9, 'IVMRWindowlessControl9');

            if FPreviewControl <> nil then
              ParentForm := GetParentForm(FPreviewControl)
            else if Self.Owner is TCommonCustomForm then
              ParentForm := TCommonCustomForm(Self.Owner)
            else
              ParentForm := nil;
            Check(ParentForm <> nil, 'Cannot retrieve preview form');

            Handle := FormToHWND(ParentForm);
            CheckError(VMRWindowlessControl9.SetVideoClippingWindow(Handle));
            if FPreviewControl <> nil then
            begin
              Point := FPreviewControl.LocalToAbsolute(TPointF.Create(0.0, 0.0));
              Rect.Left := Trunc(Point.X);
              Rect.Top := Trunc(Point.Y);
              Point := PreviewControl.LocalToAbsolute(TPointF.Create(FPreviewControl.Width, FPreviewControl.Height));
              Rect.Right := Trunc(Point.X);
              Rect.Bottom := Trunc(Point.Y);
              CheckError(VMRWindowlessControl9.SetVideoPosition(nil, @Rect));
            end;

            if FAspectRatio then
              AspectRatioMode := VMR9ARMode_LetterBox
            else
              AspectRatioMode := VMR9ARMode_None;
            VMRWindowlessControl9.SetAspectRatioMode(AspectRatioMode); // ignore possible error
            VMRWindowlessControl9.SetBorderColor(FBorderColor); // ignore possible error

            CheckError(GraphBuilder.AddFilter(CaptureFilter, 'Video capture'));
            CheckError(GraphBuilder.AddFilter(VideoMixingRenderer9Filter, 'VMR-9'));

            RenderStreamResult := CaptureGraphBuilder2.RenderStream(@PIN_CATEGORY_PREVIEW, @MEDIATYPE_Video, CaptureFilter, nil, VideoMixingRenderer9Filter);
            if FCaptureType = ctVmr9 then
              CheckError(RenderStreamResult);
          end;

          // capture to memory using SampleGrabber
          if (FCaptureType = ctGrabber) or ((FCaptureType = ctAuto) and not Succeeded(RenderStreamResult)) then
          begin
            // try to use SampleGrabber instead of VMR-9
            FGrabberUsed := True;

            CheckNull(NullRenderer, 'NullRenderer IBaseFilter');
            CheckNull(SampleGrabber, 'ISampleGrabber');
            CheckNull(SampleGrabberFilter, 'SampleGrabber IBaseFilter');

            CheckError(SampleGrabber.SetBufferSamples(True));

            if FOutputType <> otAuto then
            begin
              FillChar(MediaType, SizeOf(MediaType), 0);
              MediaType.majortype := MEDIATYPE_Video;
              MediaType.subtype := Encode(FOutputType);
              CheckError(SampleGrabber.SetMediaType(MediaType));
            end;

            if Assigned(OnImageAvailable) then
            begin
              CheckNull(SampleGrabberCB, 'ISampleGrabberCB');
              CheckError(SampleGrabber.SetCallback(SampleGrabberCB, 0));
            end;

            if FCaptureType = ctAuto then
            begin
              CheckError(GraphBuilder.RemoveFilter(CaptureFilter));
              CheckError(GraphBuilder.RemoveFilter(VideoMixingRenderer9Filter));
            end;
            CheckError(GraphBuilder.AddFilter(CaptureFilter, 'Video capture'));
            CheckError(GraphBuilder.AddFilter(SampleGrabberFilter, 'Sample grabber'));
            CheckError(GraphBuilder.AddFilter(NullRenderer, 'Null renderer'));
            CheckError(CaptureGraphBuilder2.RenderStream(@PIN_CATEGORY_PREVIEW, @MEDIATYPE_Video, CaptureFilter, SampleGrabberFilter, NullRenderer));
          end;

          // capture to file
          if OutputFileName <> '' then
          begin
            CheckError(CaptureGraphBuilder2.SetOutputFileName(Encode(OutputFileType), @FOutputFileName[1], Mux, FileSinkFilter));
            CheckNull(Mux, 'Mux IBaseFilter');
//            CheckNull(FileSinkFilter, 'IFileSinkFilter');
            if CompressorName <> '' then
            begin
              CheckNull(CompressorFilter, 'Compressor IBaseFilter');
              CheckError(GraphBuilder.AddFilter(CompressorFilter, 'Compressor filter'));
              Compressor := CompressorFilter;
            end
            else
              Compressor := nil;
            CheckError(CaptureGraphBuilder2.RenderStream(@PIN_CATEGORY_CAPTURE, @MEDIATYPE_Video, CaptureFilter, Compressor, Mux));

            if AudioDeviceName <> '' then
            begin
              CheckNull(AudioCaptureFilter, 'IAudioCaptureFilter');
              CheckError(GraphBuilder.AddFilter(AudioCaptureFilter, 'Audio capture'));
              if AudioCompressorName <> '' then
              begin
                CheckNull(AudioCompressorFilter, 'AudioCompressor IBaseFilter');
                CheckError(GraphBuilder.AddFilter(AudioCompressorFilter, 'AudioCompressor filter'));
                AudioCompressor := AudioCompressorFilter;
              end
              else
                AudioCompressor := nil;
              CheckError(CaptureGraphBuilder2.RenderStream(@PIN_CATEGORY_CAPTURE, @MEDIATYPE_Audio, AudioCaptureFilter, AudioCompressor, Mux));
            end
          end;
        except
          on E: Exception do
          begin
            FActive := False;
            ReleaseInterfaces;
            raise;
          end
        end
        else
          ReleaseInterfaces;
  FActive := Value;
end;

procedure TFCamera.ReleaseInterfaces;
begin
  // switch off sample grabber
  if FSampleGrabber <> nil then
    FSampleGrabber.SetCallback(nil, 0);

  if FMediaControl <> nil then
    FMediaControl.StopWhenReady; // ignore error

{
  FBasicAudio := nil;
  FBasicVideo := nil;
  FBasicVideo2 := nil;
  FVideoWindow := nil;
}
  FAudioCaptureFilter := nil;
  FVideoMixingRenderer9Filter := nil;
  FVMRWindowlessControl9 := nil;
  FVMRFilterConfig9 := nil;
  FNullRenderer := nil;
  FSampleGrabber := nil;
  FSampleGrabberFilter := nil;
  FSampleGrabberCB := nil;
  FMediaControl := nil;
  FMediaEvent := nil;
  FAMCameraControl := nil;
  FAMStreamConfig := nil;
  FAMVideoControl := nil;
  FAMVideoProcAmp := nil;
  FCaptureGraphBuilder2 := nil;
  FGraphBuilder := nil;
  FCaptureFilter := nil;
  FCapturePin := nil;
  FAudioCompressorFilter := nil;
  FCompressorFilter := nil;

  // wait until ImageAvailable event completes
  while InterlockedCompareExchange(FInDoImageCount, 0, 0) <> 0 do
    Sleep(0);
end;

procedure TFCamera.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPreviewControl) then
  begin
    Active := False;
    FPreviewControl := nil;
  end;
end;

function TFCamera.GetAspectRatio: Boolean;
var AspectRatioMode: TVMR9AspectRatioMode;
begin
  if not (csDesigning in ComponentState) and Active then
  begin
    CheckVmr9Active;
    CheckError(VMRWindowlessControl9.GetAspectRatioMode(AspectRatioMode));
    Result := AspectRatioMode = VMR9ARMode_LetterBox;
  end
  else
    Result := FAspectRatio
end;

procedure TFCamera.SetAspectRatio(Value: Boolean);
var AspectRatioMode: TVMR9AspectRatioMode;
begin
  if Value <> AspectRatio then
    if not (csDesigning in ComponentState) and Active then
    begin
      if Value then
        AspectRatioMode := VMR9ARMode_LetterBox
      else
        AspectRatioMode := VMR9ARMode_None;
      CheckVmr9Active;
      CheckError(VMRWindowlessControl9.SetAspectRatioMode(AspectRatioMode));
    end;
  FAspectRatio := Value;
end;

function TFCamera.GetBorderColor: TAlphaColor;
var Color: COLORREF;
begin
  if not (csDesigning in ComponentState) and Active then
  begin
    CheckVmr9Active;
    CheckError(VMRWindowlessControl9.GetBorderColor(Color));
    Result := Color;
  end
  else
    Result := FBorderColor
end;

procedure TFCamera.SetBorderColor(Value: TAlphaColor);
begin
  if Value <> BorderColor then
    if not (csDesigning in ComponentState) and Active then
    begin
      CheckVmr9Active;
      CheckError(VMRWindowlessControl9.SetBorderColor(Value));
    end;
  FBorderColor := Value;
end;

function TFCamera.GetMaxIdealVideoSize: TPoint;
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.GetMaxIdealVideoSize(Result.X, Result.Y));
end;

function TFCamera.GetMinIdealVideoSize: TPoint;
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.GetMinIdealVideoSize(Result.X, Result.Y));
end;

function TFCamera.GetNativeAspectRatio: TPoint;
var VideoSize: TPoint;
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.GetNativeVideoSize(VideoSize.X, VideoSize.Y, Result.X, Result.Y));
end;

function TFCamera.GetNativeVideoSize: TPoint;
var AspectRatio: TPoint;
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.GetNativeVideoSize(Result.X, Result.Y, AspectRatio.X, AspectRatio.Y));
end;

function TFCamera.GetVideoPositionDest: TRect;
var VideoPositionSource: TRect;
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.GetVideoPosition(VideoPositionSource, Result));
end;

procedure TFCamera.SetVideoPositionDest(const Value: TRect);
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.SetVideoPosition(nil, @Value));
end;

function TFCamera.GetVideoPositionSource: TRect;
var VideoPositionDest: TRect;
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.GetVideoPosition(Result, VideoPositionDest));
end;

procedure TFCamera.SetVideoPositionSource(const Value: TRect);
begin
  CheckVmr9Active;
  CheckError(VMRWindowlessControl9.SetVideoPosition(@Value, nil));
end;

function TFCamera.GetCaptureType: TFCaptureType;
begin
  Result := FCaptureType;
  if not (csDesigning in ComponentState) then
    if not (csLoading in ComponentState) then
      if Active then
        if FGrabberUsed then
          Result := ctGrabber
        else
          Result := ctVmr9
end;

procedure TFCamera.SetCaptureType(Value: TFCaptureType);
begin
  if FCaptureType <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FCaptureType := Value;
  end;
end;

procedure TFCamera.SetOutputFileName(const Value: string);
begin
  if FOutputFileName <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FOutputFileName := Value;
  end;
end;

procedure TFCamera.SetOutputFileType(const Value: TFMediaType);
begin
  if FOutputFileType <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FOutputFileType := Value;
  end;
end;

procedure TFCamera.SetOutputType(Value: TFOutputType);
begin
  if FOutputType <> Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FOutputType := Value;
  end;
end;

procedure TFCamera.SetOnImageAvailable(Value: TFImageAvailableEvent);
begin
  if @FOnImageAvailable <> @Value then
  begin
    if not (csDesigning in ComponentState) then
      if not (csLoading in ComponentState) then
        CheckInactive;
    FOnImageAvailable := Value;
  end;
end;

procedure TFCamera.CheckVmr9Active;
begin
  CheckActive;
  Check(CaptureType = ctVmr9, 'VMR-9 capture type required');
end;

{
function TFCamera.GetBalance: Integer;
begin
  CheckActive;
  CheckNull(BasicAudio, 'IBasicAudio');
  CheckError(BasicAudio.get_Balance(Result));
end;

procedure TFCamera.SetBalance(Value: Integer);
begin
  CheckActive;
  CheckNull(BasicAudio, 'IBasicAudio');
  CheckError(BasicAudio.put_Balance(Value));
end;

function TFCamera.GetVolume: Integer;
begin
  CheckActive;
  CheckNull(BasicAudio, 'IBasicAudio');
  CheckError(BasicAudio.get_Volume(Result));
end;

procedure TFCamera.SetVolume(Value: Integer);
begin
  CheckActive;
  CheckNull(BasicAudio, 'IBasicAudio');
  CheckError(BasicAudio.put_Volume(Value));
end;
}

function TFCamera.DoImageAvailable(SampleTime: Double): HResult;
begin
  if Assigned(OnImageAvailable) then
  try
    InterlockedIncrement(FInDoImageCount);
    try
      OnImageAvailable(Self, SampleTime);
    except
      // ignore exceptions
    end;
  finally
    InterlockedDecrement(FInDoImageCount);
  end;
  Result := S_OK;
end;

function TFCamera.SampleCB(SampleTime: Double; MediaSample: IMediaSample): HResult;
begin
  Result := DoImageAvailable(SampleTime);
end;

// TFSampleGrabberCB

constructor TFSampleGrabberCB.Create(Camera: TFCamera);
begin
  inherited Create;
  FCamera := Camera;
end;

function TFSampleGrabberCB.SampleCB(SampleTime: Double; MediaSample: IMediaSample): HResult;
begin
  Result := FCamera.SampleCB(SampleTime, MediaSample);
end;

function TFSampleGrabberCB.BufferCB(SampleTime: Double; Buffer: PByte; BufferLen: LongInt): HResult;
begin
  Result := S_OK;
end;


end.
