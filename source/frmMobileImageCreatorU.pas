unit frmMobileImageCreatorU;
// === File Prolog ============================================================
// This code was developed by RiverSoftAVG.
//
// --- Notes ------------------------------------------------------------------
//
// --- Development History  ---------------------------------------------------
//
// 11/2018 Tristan Marlow
// - Ability to load and save profiles
// - File paths are saved relative
// - FrameRatio SelectedRect would not load correctly
// - New splash images (iOs Xs) 2688x1242, 1242x2688,	1125x2436, 2436x1125
// 02/2015 T. Grubb
// - Fixed optset bugs for iPhone larger sizes
// - Added 750x1334 iPhone Launch image
// - Added 2208x1242 iPhone Launch image
// - Added Android Splash images that were added in XE7 (does not work
// in optset though :-( )
// 02/2015 Thanks to Graham Murt for his updates:
// - Added extra icons required in XE7 (87x87, 180x180, 75-x1334, 1242x2208, 2208x1242)
// 02/2014 T. Grubb
// Initial version.
//
// File Contents:
//
//
// === End File Prolog ========================================================

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Memo, FMX.TabControl, FMX.Edit, FMX.Objects, FrameRatio,
  FMX.ListBox, System.Actions, FMX.ActnList, AndroidOptset, iOSOptset, XMLIntf,
  FMX.ComboEdit, FMX.Controls.Presentation, FMX.ScrollBox, IniFiles;

type
  TSizeInfo = record
    Width, Height: Integer;
    AndroidName: String;
    iPhoneName: String;
    iPadName: String;
    constructor Create(const X, Y: Integer; aiPhoneName: String = '';
      aiPadName: String = ''; aAndroidName: String = '');
  end;

  TSizeInfos = Array of TSizeInfo;
  TRatio = (r1to1, r1_77to1, r1_47to1, r1_37to1, r1_33to1, r0_76to1, r0_75to1,
    r0_66to1, r0_56to1, r2_16to1, r0_46tol);
  TRatioOutputs = Array [TRatio] of TSizeInfos;

  TfrmMobileImageCreator = class(TForm)
    TabControl1: TTabControl;
    tiSetup: TTabItem;
    tiGraphics: TTabItem;
    tiOutput: TTabItem;
    tiGenerate: TTabItem;
    Layout1: TLayout;
    ListBox1: TListBox;
    ListBoxGroupHeader1: TListBoxGroupHeader;
    lbiiPhone: TListBoxItem;
    lbiiPad: TListBoxItem;
    lbiAndroid: TListBoxItem;
    cbOptset: TCheckBox;
    Button1: TButton;
    OpenDialog: TOpenDialog;
    mmOutput: TMemo;
    ActionList: TActionList;
    actGenerate: TAction;
    ceBaseName: TComboEdit;
    Label1: TLabel;
    Button2: TButton;
    SaveDialog: TSaveDialog;
    ceSettingsFilename: TEdit;
    Label2: TLabel;
    EditButton1: TEditButton;
    EditButton2: TEditButton;
    Label3: TLabel;
    btnClearSettings: TEditButton;
    lblModified: TLabel;
    EditButton4: TEditButton;
    actLoad: TAction;
    actSave: TAction;
    actSaveAs: TAction;
    actClear: TAction;
    imgLogo: TImageControl;
    procedure actClearUpdate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure actGenerateExecute(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure actSaveExecute(Sender: TObject);
    procedure actSaveUpdate(Sender: TObject);
    procedure btnSettingsLoadClick(Sender: TObject);
    procedure btnSettingsSaveClick(Sender: TObject);
    procedure cbOptsetChange(Sender: TObject);
    procedure ceBaseNameChange(Sender: TObject);
    procedure btnClearSettingsClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ListBox1ChangeCheck(Sender: TObject);
  private
    { Private declarations }
    FVertScrollBoxRatios: TVertScrollBox;
    FINIFile: TMemIniFile;
    procedure InitializeRatios;
    procedure InitializeRatioFrames;
    procedure InitializeOutput;
    procedure FilenameChange(Sender: TObject);
    function GetFrame(Ratio: TRatio): TRatioFrame;
    procedure InitializeOptsets;
    function GetSetting(AName: string): string;
    procedure SetSetting(AName: string; const Value: string);
    function GetINIFileName: string;
    function GetDefaultINIFileName: string;
    procedure LoadSettings(AFileName: TFileName);
    procedure SaveSettings(AFileName: TFileName);
    procedure ClearSettings;
    function IsModified: Boolean;
    procedure ExpandFilePaths(AINIFile: TMemIniFile; ABaseDir: string);
    function PathFullToRelative(APath: string; ABaseDir: string = ''): string;
    function PathRelativeToFull(APath: string; ABaseDir: string = ''): string;
    procedure RelativeFilePaths(AINIFile: TMemIniFile; ABaseDir: string);
  public
    { Public declarations }
    AndroidOptions: IXMLAndroidProjectType;
    iOSOptions: IXMLiOSProjectType;
    function Validate: Boolean;
    procedure GenerateImage(aBitmap: TBitmap; Width, Height: Integer;
      aRect: TRectF; AFileName: String);
    procedure GenerateImages;
    procedure Log(const Msg: String); virtual;
    property Setting[AName: string]: string read GetSetting write SetSetting;
    property INIFileName: string read GetINIFileName;
  end;

var
  frmMobileImageCreator: TfrmMobileImageCreator;
  RatioOutputs: TRatioOutputs;

implementation

uses
  IOUtils;

{$R *.fmx}

procedure TfrmMobileImageCreator.actClearUpdate(Sender: TObject);
begin
  actClear.Enabled := Trim(ceSettingsFilename.Text) <> '';
end;

procedure TfrmMobileImageCreator.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FINIFile);
end;

procedure TfrmMobileImageCreator.actGenerateExecute(Sender: TObject);
begin
  GenerateImages;
end;

function TfrmMobileImageCreator.IsModified: Boolean;
begin
  Result := Assigned(FINIFile) and (FINIFile.Modified);
end;

procedure TfrmMobileImageCreator.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  lblModified.Visible := IsModified;
end;

procedure TfrmMobileImageCreator.actSaveExecute(Sender: TObject);
begin
  SaveSettings(ceSettingsFilename.Text);
end;

procedure TfrmMobileImageCreator.actSaveUpdate(Sender: TObject);
begin
  actSave.Enabled := FileExists(ceSettingsFilename.Text);
end;

procedure TfrmMobileImageCreator.Button1Click(Sender: TObject);
begin
  OpenDialog.FileName := ceBaseName.Text;
  OpenDialog.Filter := 'All Files|*.*';
  OpenDialog.Options := [TOpenOption.ofHideReadOnly,
    TOpenOption.ofPathMustExist, TOpenOption.ofEnableSizing];
  OpenDialog.DefaultExt := '';
  if OpenDialog.Execute then
  begin
    ceBaseName.Text := ChangeFileExt(OpenDialog.FileName, '.png');
  end;
end;

procedure TfrmMobileImageCreator.btnSettingsLoadClick(Sender: TObject);
begin
  OpenDialog.FileName := ceSettingsFilename.Text;
  OpenDialog.DefaultExt := '.fmxmic';
  OpenDialog.Filter := 'Mobile Image Creator files|*.fmxmic|All Files|*.*';
  OpenDialog.Options := [TOpenOption.ofFileMustExist,
    TOpenOption.ofPathMustExist, TOpenOption.ofEnableSizing];
  if OpenDialog.Execute then
  begin
    LoadSettings(OpenDialog.FileName);
  end;
end;

procedure TfrmMobileImageCreator.btnSettingsSaveClick(Sender: TObject);
begin
  SaveDialog.FileName := ceSettingsFilename.Text;
  SaveDialog.DefaultExt := '.fmxmic';
  SaveDialog.Filter := 'Mobile Image Creator files|*.fmxmic|All Files|*.*';
  if SaveDialog.Execute then
  begin
    SaveSettings(SaveDialog.FileName);
  end;
end;

procedure TfrmMobileImageCreator.cbOptsetChange(Sender: TObject);
begin
  Setting['output_optset'] := BoolToStr(cbOptset.IsChecked);
end;

procedure TfrmMobileImageCreator.ceBaseNameChange(Sender: TObject);
begin
  Setting['base_filename'] := ceBaseName.Text;
end;

procedure TfrmMobileImageCreator.ClearSettings;
begin
  LoadSettings('');
end;

procedure TfrmMobileImageCreator.btnClearSettingsClick(Sender: TObject);
begin
  ClearSettings;
end;

procedure TfrmMobileImageCreator.FilenameChange(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to ComponentCount - 1 do
    if (Components[i] is TRatioFrame) and
      (TRatioFrame(Components[i]).ceFilename.Items.IndexOf
      ((Sender as TRatioFrame).FileName) = -1) then
      TRatioFrame(Components[i]).ceFilename.Items.Add((Sender as TRatioFrame)
        .FileName);
  if ceBaseName.Items.IndexOf((Sender as TRatioFrame).FileName) = -1 then
    ceBaseName.Items.Add((Sender as TRatioFrame).FileName);
end;

procedure TfrmMobileImageCreator.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not IsModified;
  if not CanClose then
  begin
    case MessageDlg('Save changes?', TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel], 0) of
      idYes:
        begin
          if actSave.Enabled then
          begin
            actSave.Execute;
          end
          else
          begin
            actSaveAs.Execute;
          end;
          CanClose := not IsModified;
        end;
      idCancel:
        begin
          CanClose := false;
        end
    else
      begin
        CanClose := True;
      end;
    end;
  end;
end;

procedure TfrmMobileImageCreator.FormCreate(Sender: TObject);
begin
  FINIFile := TMemIniFile.Create('');
  FINIFile.AutoSave := false;
  TabControl1.TabIndex := 0;
  LoadSettings(GetDefaultINIFileName);
end;

procedure TfrmMobileImageCreator.GenerateImage(aBitmap: TBitmap;
  Width, Height: Integer; aRect: TRectF; AFileName: String);
var
  NewBitmap: TBitmap;
  SrcRect: TRectF;
begin
  NewBitmap := TBitmap.Create(Width, Height);
  try
    // aRect contains percentages of bitmap
    NewBitmap.Canvas.BeginScene;
    try
      NewBitmap.Canvas.Clear(TAlphaColorRec.Null);
      SrcRect := RectF(aBitmap.Width * aRect.Left, aBitmap.Height * aRect.Top,
        aBitmap.Width * aRect.Right, aBitmap.Height * aRect.Bottom);
      NewBitmap.Canvas.DrawBitmap(aBitmap, SrcRect,
        RectF(0, 0, Width, Height), 1);
    finally
      NewBitmap.Canvas.EndScene;
    end;
    NewBitmap.SaveToFile(AFileName);
  finally
    NewBitmap.Free;
  end;
end;

procedure TfrmMobileImageCreator.GenerateImages;
var
  i: TRatio;
  rf: TRatioFrame;
  j: Integer;
  AFileName: String;
  Overwrite: Integer;
begin
  InitializeOptsets;
  Log('Generating images...');
  Overwrite := mrYes;
  for i := Low(TRatio) to High(TRatio) do
  begin
    rf := GetFrame(i);
    Log('   Generating ' + rf.Caption + ' images...');
    for j := 0 to Length(RatioOutputs[i]) - 1 do
    begin
      // first, see if we are generating this file
      if not(((RatioOutputs[i][j].AndroidName <> '') and lbiAndroid.IsChecked)
        or ((RatioOutputs[i][j].iPhoneName <> '') and lbiiPhone.IsChecked) or
        ((RatioOutputs[i][j].iPadName <> '') and lbiiPad.IsChecked)) then
        Continue;
      // generate filename: basename + WidthXHeight.png
      AFileName := TPath.Combine(TPath.GetDirectoryName(ceBaseName.Text),
        TPath.ChangeExtension(TPath.GetFileNameWithoutExtension(ceBaseName.Text)
        + RatioOutputs[i][j].Width.ToString + 'x' + RatioOutputs[i][j]
        .Height.ToString, '.png'));
      // save into optsets
      if (RatioOutputs[i][j].AndroidName <> '') and lbiAndroid.IsChecked then
        AndroidOptions.PropertyGroup.ChildValues[RatioOutputs[i][j].AndroidName]
          := AFileName;
      if (RatioOutputs[i][j].iPhoneName <> '') and lbiiPhone.IsChecked then
        iOSOptions.PropertyGroup.ChildValues[RatioOutputs[i][j].iPhoneName] :=
          AFileName;
      if (RatioOutputs[i][j].iPadName <> '') and lbiiPad.IsChecked then
        iOSOptions.PropertyGroup.ChildValues[RatioOutputs[i][j].iPadName] :=
          AFileName;
      // generate file
      if FileExists(AFileName) then
      begin
        case Overwrite of
          mrYesToAll:
            ;
          mrNoToAll:
            begin
              Log('      ' + AFileName + ' exists.  Skipping.');
              Continue;
            end;
        else
          Overwrite := MessageDlg(AFileName + ' exists.  Overwrite?',
            TMsgDlgType.mtWarning, [TMsgDlgBtn.mbYesToAll, TMsgDlgBtn.mbYes,
            TMsgDlgBtn.mbNo, TMsgDlgBtn.mbNoToAll, TMsgDlgBtn.mbCancel], 0);
          case Overwrite of
            mrYes, mrYesToAll:
              ;
            mrNo, mrNoToAll:
              begin
                Log('      ' + AFileName + ' exists.  Skipping.');
                Continue;
              end;
            mrCancel:
              Exit;
          end;
        end;
      end;
      Log('      ' + AFileName);

      GenerateImage(rf.imPreview.Bitmap, RatioOutputs[i][j].Width,
        RatioOutputs[i][j].Height, rf.ZoomRect, AFileName);
    end;
  end;
  if cbOptset.IsChecked then
  begin
    if lbiAndroid.IsChecked then
    begin
      AFileName := TPath.Combine(TPath.GetDirectoryName(ceBaseName.Text),
        TPath.ChangeExtension(ceBaseName.Text, '.android.optset'));
      AndroidOptions.OwnerDocument.SaveToFile(AFileName);
    end;
    if lbiiPhone.IsChecked or lbiiPad.IsChecked then
    begin
      AFileName := TPath.Combine(TPath.GetDirectoryName(ceBaseName.Text),
        TPath.ChangeExtension(ceBaseName.Text, '.ios.optset'));
      iOSOptions.OwnerDocument.SaveToFile(AFileName);
    end;
  end;
  Log('Operation complete.');
end;

function TfrmMobileImageCreator.GetFrame(Ratio: TRatio): TRatioFrame;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to ComponentCount - 1 do
    if (Components[i] is TRatioFrame) and (Components[i].Tag = Ord(Ratio)) then
    begin
      Result := TRatioFrame(Components[i]);
      Break;
    end;
end;

function TfrmMobileImageCreator.GetDefaultINIFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'default.fmxmic';
end;

function TfrmMobileImageCreator.GetINIFileName: string;
begin
  Result := ceSettingsFilename.Text;
  if Trim(Result) = '' then
  begin
    Result := GetDefaultINIFileName;
  end;
end;

function TfrmMobileImageCreator.GetSetting(AName: string): string;
begin
  Result := FINIFile.ReadString('settings', AName, '');
end;

procedure TfrmMobileImageCreator.InitializeRatioFrames;
var
  i: TRatio;
begin
  if Assigned(FVertScrollBoxRatios) then
  begin
    try
      FVertScrollBoxRatios.Visible := false;
      FVertScrollBoxRatios.Free;
    finally
      FVertScrollBoxRatios := nil;
    end;
  end;

  FVertScrollBoxRatios := TVertScrollBox.Create(Self);
  FVertScrollBoxRatios.Parent := tiGraphics;
  FVertScrollBoxRatios.Align := TAlignLayout.client;
  FVertScrollBoxRatios.BeginUpdate;
  try
    for i := Low(TRatio) to High(TRatio) do
    begin
      with TRatioFrame.Create(Self, RatioOutputs[i][0].Width,
        RatioOutputs[i][0].Height, FINIFile) do
      begin
        Parent := FVertScrollBoxRatios;
        Align := TAlignLayout.Top;
        OnChange := Self.FilenameChange;
        Tag := Ord(i);
      end;
    end;
  finally
    FVertScrollBoxRatios.EndUpdate;
  end;
end;

procedure TfrmMobileImageCreator.InitializeRatios;
begin
  SetLength(RatioOutputs[r1to1], 19);
  RatioOutputs[r1to1][0] := TSizeInfo.Create(152, 152, '', 'iPad_AppIcon152');
  RatioOutputs[r1to1][1] := TSizeInfo.Create(76, 76, '', 'iPad_AppIcon76');
  RatioOutputs[r1to1][2] := TSizeInfo.Create(120, 120, 'iPhone_AppIcon120');
  RatioOutputs[r1to1][3] := TSizeInfo.Create(57, 57, 'iPhone_AppIcon57');
  RatioOutputs[r1to1][4] := TSizeInfo.Create(60, 60, 'iPhone_AppIcon60');
  RatioOutputs[r1to1][5] := TSizeInfo.Create(29, 29, 'iPhone_Spotlight29',
    'iPad_Setting29');
  RatioOutputs[r1to1][6] := TSizeInfo.Create(80, 80, 'iPhone_Spotlight80',
    'iPad_SpotLight80');
  RatioOutputs[r1to1][7] := TSizeInfo.Create(58, 58, 'iPhone_Spotlight58',
    'iPad_Setting58');
  RatioOutputs[r1to1][8] := TSizeInfo.Create(40, 40, 'iPhone_Spotlight40',
    'iPad_SpotLight40');
  RatioOutputs[r1to1][9] := TSizeInfo.Create(114, 114, 'iPhone_AppIcon114');
  RatioOutputs[r1to1][10] := TSizeInfo.Create(100, 100, '',
    'iPad_SpotLight100');
  RatioOutputs[r1to1][11] := TSizeInfo.Create(144, 144, '', 'iPad_AppIcon144',
    'Android_LauncherIcon144');
  RatioOutputs[r1to1][12] := TSizeInfo.Create(50, 50, '', 'iPad_SpotLight50');
  RatioOutputs[r1to1][13] := TSizeInfo.Create(72, 72, '', 'iPad_AppIcon72',
    'Android_LauncherIcon72');
  RatioOutputs[r1to1][14] := TSizeInfo.Create(96, 96, '', '',
    'Android_LauncherIcon96');
  RatioOutputs[r1to1][15] := TSizeInfo.Create(48, 48, '', '',
    'Android_LauncherIcon48');
  RatioOutputs[r1to1][16] := TSizeInfo.Create(36, 36, '', '',
    'Android_LauncherIcon36');
  RatioOutputs[r1to1][17] := TSizeInfo.Create(87, 87, 'iPhone_AppIcon87');
  RatioOutputs[r1to1][18] := TSizeInfo.Create(180, 180, 'iPhone_AppIcon180');

  SetLength(RatioOutputs[r1_47to1], 1);
  RatioOutputs[r1_47to1][0] := TSizeInfo.Create(470, 320, '', '',
    'Android_SplashImage470');

  SetLength(RatioOutputs[r1_37to1], 2);
  RatioOutputs[r1_37to1][0] := TSizeInfo.Create(2048, 1496, '',
    'iPad_Launch2048');
  RatioOutputs[r1_37to1][1] := TSizeInfo.Create(1024, 748, '',
    'iPad_Launch1024');

  SetLength(RatioOutputs[r1_33to1], 5);
  RatioOutputs[r1_33to1][0] := TSizeInfo.Create(2048, 1536, '',
    'iPad_Launch2048x1536');
  RatioOutputs[r1_33to1][1] := TSizeInfo.Create(1024, 768, '',
    'iPad_Launch1024x768');
  RatioOutputs[r1_33to1][2] := TSizeInfo.Create(640, 480, '', '',
    'Android_SplashImage640');
  RatioOutputs[r1_33to1][3] := TSizeInfo.Create(960, 720, '', '',
    'Android_SplashImage960');
  RatioOutputs[r1_33to1][4] := TSizeInfo.Create(426, 320, '', '',
    'Android_SplashImage426'); // 1.33125

  SetLength(RatioOutputs[r1_77to1], 1);
  RatioOutputs[r1_77to1][0] := TSizeInfo.Create(2208, 1242,
    'iPhone_Launch2208x1242');

  SetLength(RatioOutputs[r0_76to1], 2);
  RatioOutputs[r0_76to1][0] := TSizeInfo.Create(1536, 2008, '',
    'iPad_Launch1536');
  RatioOutputs[r0_76to1][1] := TSizeInfo.Create(768, 1004, '',
    'iPad_Launch768');

  SetLength(RatioOutputs[r0_75to1], 2);
  RatioOutputs[r0_75to1][0] := TSizeInfo.Create(1536, 2048, '',
    'iPad_Launch1536x2048');
  RatioOutputs[r0_75to1][1] := TSizeInfo.Create(768, 1024, '',
    'iPad_Launch768x1024');

  SetLength(RatioOutputs[r0_66to1], 2);
  RatioOutputs[r0_66to1][0] := TSizeInfo.Create(640, 960, 'iPhone_Launch640');
  RatioOutputs[r0_66to1][1] := TSizeInfo.Create(320, 480, 'iPhone_Launch320');

  SetLength(RatioOutputs[r0_56to1], 3);
  RatioOutputs[r0_56to1][0] := TSizeInfo.Create(640, 1136,
    'iPhone_Launch640x1136');
  RatioOutputs[r0_56to1][1] := TSizeInfo.Create(750, 1334,
    'iPhone_Launch750x1134');
  RatioOutputs[r0_56to1][2] := TSizeInfo.Create(1242, 2208,
    'iPhone_Launch1242x2208');

  SetLength(RatioOutputs[r2_16to1], 2);
  RatioOutputs[r2_16to1][0] := TSizeInfo.Create(2688, 1242,
    'iPhone_Launch2688x1142');
  RatioOutputs[r2_16to1][1] := TSizeInfo.Create(2436, 1125,
    'iPhone_Launch2436x1125');

  SetLength(RatioOutputs[r0_46tol], 2);
  RatioOutputs[r0_46tol][0] := TSizeInfo.Create(1242, 2688,
    'iPhone_Launch1242x2688');

  RatioOutputs[r0_46tol][1] := TSizeInfo.Create(1125, 2436,
    'iPhone_Launch1125x2436');

end;

function TfrmMobileImageCreator.PathRelativeToFull(APath,
  ABaseDir: string): string;
var
  xDir: string;
begin
  xDir := GetCurrentDir;
  try
    if ABaseDir = '' then
      ABaseDir := IncludeTrailingPathDelimiter(ExtractFilePath(INIFileName));
    SetCurrentDir(ABaseDir);
    Result := ExpandFileName(APath);
  finally
    SetCurrentDir(xDir);
  end
end;

function TfrmMobileImageCreator.PathFullToRelative(APath,
  ABaseDir: string): string;
begin
  if ABaseDir = '' then
    ABaseDir := IncludeTrailingPathDelimiter(ExtractFilePath(INIFileName));
  Result := ExtractRelativePath(ABaseDir, APath);
end;

procedure TfrmMobileImageCreator.ExpandFilePaths(AINIFile: TMemIniFile;
  ABaseDir: string);
var
  LSection: TStringList;
  LSectionName, LFileName: string;
begin
  LSection := TStringList.Create;
  try
    FINIFile.ReadSection('images', LSection);
    for LSectionName in LSection do
    begin
      LFileName := FINIFile.ReadString('images', LSectionName, '');
      if LFileName <> '' then
      begin
        LFileName := PathRelativeToFull(LFileName, ABaseDir);
        FINIFile.WriteString('images', LSectionName, LFileName);
      end;
    end;
    LFileName := FINIFile.ReadString('settings', 'base_filename', '');

    if Trim(LFileName) = '' then
    begin
      LFileName := IncludeTrailingPathDelimiter(ABaseDir);
    end
    else
    begin
      LFileName := PathRelativeToFull
        (IncludeTrailingPathDelimiter(ExtractFilePath(LFileName)), ABaseDir) +
        ExtractFileName(LFileName);
    end;

    FINIFile.WriteString('settings', 'base_filename', LFileName);

  finally
    FreeAndNil(LSection);
  end;
end;

procedure TfrmMobileImageCreator.RelativeFilePaths(AINIFile: TMemIniFile;
  ABaseDir: string);
var
  LSection: TStringList;
  LSectionName, LFileName: string;
begin
  LSection := TStringList.Create;
  try
    FINIFile.ReadSection('images', LSection);
    for LSectionName in LSection do
    begin
      LFileName := FINIFile.ReadString('images', LSectionName, '');
      if LFileName <> '' then
      begin
        LFileName := PathFullToRelative(LFileName, ABaseDir);
        FINIFile.WriteString('images', LSectionName, LFileName);
      end;
    end;
    LFileName := FINIFile.ReadString('settings', 'base_filename', '');
    if LFileName <> '' then
    begin
      LFileName := PathFullToRelative
        (IncludeTrailingPathDelimiter(ExtractFilePath(LFileName)), ABaseDir) +
        ExtractFileName(LFileName);
      FINIFile.WriteString('settings', 'base_filename', LFileName);
    end;
  finally
    FreeAndNil(LSection);
  end;
end;

procedure TfrmMobileImageCreator.LoadSettings(AFileName: TFileName);
var
  LSettings: TStringList;
begin
  FINIFile.Clear;
  LSettings := TStringList.Create;
  try
    if FileExists(AFileName) then
    begin
      LSettings.LoadFromFile(AFileName);
      FINIFile.SetStrings(LSettings);
      ExpandFilePaths(FINIFile, ExtractFilePath(AFileName));
    end;
  finally
    LSettings.Free;
  end;
  ceSettingsFilename.Text := AFileName;
  InitializeRatios;
  InitializeRatioFrames;
  InitializeOutput;
  FINIFile.Modified := false;
end;

procedure TfrmMobileImageCreator.Log(const Msg: String);
begin
  mmOutput.Lines.Add(Msg);
end;

procedure TfrmMobileImageCreator.SaveSettings(AFileName: TFileName);
var
  LSettings: TStringList;
begin
  LSettings := TStringList.Create;
  try
    RelativeFilePaths(FINIFile, ExtractFilePath(AFileName));
    FINIFile.GetStrings(LSettings);
    LSettings.SaveToFile(AFileName);
  finally
    LSettings.Free;
  end;
  ceSettingsFilename.Text := AFileName;
  FINIFile.Modified := false;
end;

procedure TfrmMobileImageCreator.SetSetting(AName: string; const Value: string);
begin
  FINIFile.WriteString('settings', AName, Value);
end;

procedure TfrmMobileImageCreator.InitializeOptsets;
begin
  AndroidOptions := NewAndroidOptset;
  AndroidOptions.ProjectExtensions.BorlandPersonality :=
    'Delphi.Personality.12';
  AndroidOptions.ProjectExtensions.BorlandProjectType := 'OptionSet';
  AndroidOptions.ProjectExtensions.BorlandProject.DelphiPersonality := '';
  AndroidOptions.ProjectExtensions.ProjectFileVersion := 12;
  AndroidOptions.OwnerDocument.Options := AndroidOptions.OwnerDocument.Options +
    [doNodeAutoIndent];

  iOSOptions := NewiOSOptset;
  iOSOptions.ProjectExtensions.BorlandPersonality := 'Delphi.Personality.12';
  iOSOptions.ProjectExtensions.BorlandProjectType := 'OptionSet';
  iOSOptions.ProjectExtensions.BorlandProject.DelphiPersonality := '';
  iOSOptions.ProjectExtensions.ProjectFileVersion := 12;
  iOSOptions.OwnerDocument.Options := iOSOptions.OwnerDocument.Options +
    [doNodeAutoIndent];
end;

procedure TfrmMobileImageCreator.InitializeOutput;
begin
  ceBaseName.Text := Setting['base_filename'];
  lbiiPhone.IsChecked := StrToBoolDef(Setting['output_iphone'], True);
  lbiiPad.IsChecked := StrToBoolDef(Setting['output_ipad'], True);
  lbiAndroid.IsChecked := StrToBoolDef(Setting['output_android'], True);
  cbOptset.IsChecked := StrToBoolDef(Setting['output_optset'], True);
end;

procedure TfrmMobileImageCreator.ListBox1ChangeCheck(Sender: TObject);
begin
  Setting['output_iphone'] := BoolToStr(lbiiPhone.IsChecked);
  Setting['output_ipad'] := BoolToStr(lbiiPad.IsChecked);
  Setting['output_android'] := BoolToStr(lbiAndroid.IsChecked);
end;

procedure TfrmMobileImageCreator.TabControl1Change(Sender: TObject);
begin
  if (Sender as TTabControl).TabIndex = tiGenerate.Index then
  begin
    // validate the inputs
    mmOutput.Lines.Clear;
    if not Validate then
      raise Exception.Create('Errors were found in setup.  Please correct.');
    Log('Ready to generate images');
    actGenerate.Enabled := True;
  end
  else
    actGenerate.Enabled := false;
end;

function TfrmMobileImageCreator.Validate: Boolean;
var
  i: Integer;
  rf: TRatioFrame;
  LDirectoryName: String;
begin
  if not(lbiiPhone.IsChecked or lbiiPad.IsChecked or lbiAndroid.IsChecked) then
    raise Exception.Create('An output device must be checked');
  Result := True;
  Log('Validating Ratio Inputs...');
  for i := 0 to ComponentCount - 1 do
    if (Components[i] is TRatioFrame) then
    begin
      rf := TRatioFrame(Components[i]);
      Log('   Validating ' + rf.Caption + '...');
      if rf.imPreview.Bitmap.IsEmpty then
      begin
        Result := false;
        Log('      INVALID Bitmap (Empty)');
      end
      else
        Log('      Bitmap Ok');
      if rf.SelectRect.IsEmpty then
      begin
        Result := false;
        Log('      INVALID Selection rectangle (Empty)');
      end
      else
        Log('      Selection rectangle Ok');
    end;
  Log('Validating Outputs...');
  try
    LDirectoryName := TPath.GetDirectoryName(ceBaseName.Text);
    if LDirectoryName = '' then
    begin
      Result := false;
      Log('   No directory found at specified path for base name: ' +
        ceBaseName.Text);
    end;
  except
    Result := false;
    Log('   Incorrect path for base name: ' + ceBaseName.Text);
  end;
end;

{ TSizeInfoInfo }

constructor TSizeInfo.Create(const X, Y: Integer;
  aiPhoneName, aiPadName, aAndroidName: String);
begin
  Width := X;
  Height := Y;
  iPhoneName := aiPhoneName;
  iPadName := aiPadName;
  AndroidName := aAndroidName;
end;

end.
