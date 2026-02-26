program ScrcpyFrontend;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Spin, Buttons, Process, Clipbrd, Interfaces;

type

  { TMainForm }

  TMainForm = class(TForm)
  private
    FScrcpyMajor: Integer;  // 1 = v1.x, 2 = v2.x+
    // Top Panel
    pnlTop:         TPanel;
    pnlTopLeft:     TPanel;   // holds listbox
    pnlTopRight:    TPanel;   // holds buttons
    lblTitle:       TLabel;
    lblDevices:     TLabel;
    lbDevices:      TListBox;
    btnScan:        TBitBtn;
    btnDisconnect:  TBitBtn;
    pnlTcpRow:      TPanel;
    lblConnectIP:   TLabel;
    edtConnectIP:   TEdit;
    btnConnect:     TBitBtn;

    // PageControl
    pgOptions:  TPageControl;
    tsDisplay:  TTabSheet;
    tsInput:    TTabSheet;
    tsAudio:    TTabSheet;
    tsAdvanced: TTabSheet;

    // Display Tab
    spnBitrate:           TSpinEdit;
    spnMaxFPS:            TSpinEdit;
    spnMaxSize:           TSpinEdit;
    cmbRotation:          TComboBox;
    cmbOrientation:       TComboBox;
    chkFullscreen:        TCheckBox;
    chkAlwaysOnTop:       TCheckBox;
    chkBorderless:        TCheckBox;
    chkShowTouches:       TCheckBox;
    chkStayAwake:         TCheckBox;
    chkDisableScreensaver:TCheckBox;

    // Input Tab
    chkNoControl:           TCheckBox;
    chkForwardAllClicks:    TCheckBox;
    chkLegacyPaste:         TCheckBox;
    chkKeyboardHID:         TCheckBox;
    chkMouseHID:            TCheckBox;
    chkGamepadHID:          TCheckBox;
    chkNoClipboardAutosync: TCheckBox;
    chkPhysicalKeyboard:    TCheckBox;

    // Audio Tab
    chkNoAudio:         TCheckBox;
    chkNoAudioPlayback: TCheckBox;
    spnAudioBitrate:    TSpinEdit;
    cmbAudioCodec:      TComboBox;
    cmbAudioSource:     TComboBox;

    // Advanced Tab
    cmbVideoCodec:      TComboBox;
    chkPowerOffOnClose: TCheckBox;
    chkNoPowerOn:       TCheckBox;
    edtRecordFile:      TEdit;
    btnBrowseRecord:    TButton;
    edtCrop:            TEdit;
    edtWindowTitle:     TEdit;
    chkPrintFPS:        TCheckBox;
    chkVerbose:         TCheckBox;
    edtExtraArgs:       TEdit;

    // Bottom Panel
    pnlBottom:    TPanel;
    pnlMemo:      TPanel;
    pnlBtns:      TPanel;
    lblCmdPreview:TLabel;
    memoCmd:      TMemo;
    btnLaunch:    TBitBtn;
    btnCopy:      TBitBtn;
    lblStatus:    TLabel;

  public
    constructor Create(AOwner: TComponent); override;

  private
    procedure btnScanClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnLaunchClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnBrowseRecordClick(Sender: TObject);
    procedure OptionChanged(Sender: TObject);
    procedure lbDevicesClick(Sender: TObject);

    procedure BuildTopPanel;
    procedure BuildBottomPanel;
    procedure BuildPageControl;
    procedure BuildDisplayTab;
    procedure BuildInputTab;
    procedure BuildAudioTab;
    procedure BuildAdvancedTab;

    // Factory helpers
    function  MakeDarkLabel(AParent: TWinControl; const ACaption: string): TLabel;
    function  MakeRow(AParent: TWinControl; AHeight: Integer): TPanel;
    function  MakeRowLabel(ARow: TPanel; const ACaption: string): TLabel;
    function  MakeCheck(AParent: TWinControl; const ACaption: string): TCheckBox;

    procedure BuildParams(P: TProcess);
    function  BuildCommand: string;
    function  GetSelectedDevice: string;
    procedure SetStatus(const Msg: string; IsError: Boolean = False);
    function  RunADB(const Args: string; out Output: string): Boolean;
    function  DetectScrcpyVersion: Integer;
  end;

const
  CLR_PANEL_BG   = TColor($003A3A3A);
  CLR_PANEL_FG   = clWhite;
  CLR_EDIT_BG    = TColor($00333333);
  CLR_LIST_BG    = TColor($00222222);
  CLR_TITLE      = TColor($0033BBFF);
  CLR_STATUS_OK  = TColor($0088CCFF);
  CLR_STATUS_ERR = TColor($006666FF);
  CLR_MEMO_BG    = TColor($00111111);
  CLR_MEMO_FG    = TColor($0033FF99);
  LBL_WIDTH      = 200;  // fixed label column width in tab rows

var
  MainForm: TMainForm;

{ ── Factories ────────────────────────────────────────── }

function TMainForm.MakeDarkLabel(AParent: TWinControl;
  const ACaption: string): TLabel;
begin
  Result            := TLabel.Create(Self);
  Result.Parent     := AParent;
  Result.Caption    := ACaption;
  Result.ParentFont := False;
  Result.Font.Color := CLR_PANEL_FG;
  Result.Layout     := tlCenter;
end;

// A thin horizontal row panel — children use alLeft / alClient
function TMainForm.MakeRow(AParent: TWinControl; AHeight: Integer): TPanel;
begin
  Result            := TPanel.Create(Self);
  Result.Parent     := AParent;
  Result.Align      := alTop;
  Result.Height     := AHeight;
  Result.BevelOuter := bvNone;
  Result.Caption    := '';
end;

// Label in the left column of a row
function TMainForm.MakeRowLabel(ARow: TPanel; const ACaption: string): TLabel;
begin
  Result            := TLabel.Create(Self);
  Result.Parent     := ARow;
  Result.Caption    := ACaption;
  Result.Align      := alLeft;
  Result.Width      := LBL_WIDTH;
  Result.Layout     := tlCenter;
  Result.ParentFont := False;
  Result.Font.Color := clWindowText;
end;

function TMainForm.MakeCheck(AParent: TWinControl;
  const ACaption: string): TCheckBox;
begin
  Result            := TCheckBox.Create(Self);
  Result.Parent     := AParent;
  Result.Caption    := ACaption;
  Result.Align      := alTop;
  Result.Height     := 28;
  Result.ParentFont := False;
  Result.Font.Color := clWindowText;
  Result.OnChange   := @OptionChanged;
end;

{ ── Constructor ──────────────────────────────────────── }

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption  := 'Scrcpy Frontend';
  Width    := 1020;
  Height   := 760;
  Position := poScreenCenter;
  BuildTopPanel;
  BuildBottomPanel;   // alBottom before alClient
  BuildPageControl;   // alClient last
  FScrcpyMajor := DetectScrcpyVersion;
  if FScrcpyMajor > 0 then
    Caption := 'Scrcpy Frontend  [scrcpy v' + IntToStr(FScrcpyMajor) + '.x detected]'
  else
    Caption := 'Scrcpy Frontend  [scrcpy not found in PATH]';
  OptionChanged(nil);
end;

{ ── Top Panel ────────────────────────────────────────── }

procedure TMainForm.BuildTopPanel;
begin
  pnlTop                  := TPanel.Create(Self);
  pnlTop.Parent           := Self;
  pnlTop.Align            := alTop;
  pnlTop.Height           := 220;
  pnlTop.BevelOuter       := bvNone;
  pnlTop.Color            := CLR_PANEL_BG;
  pnlTop.ParentBackground := False;

  // Title bar across the top
  lblTitle            := MakeDarkLabel(pnlTop, 'Scrcpy Frontend');
  lblTitle.Align      := alTop;
  lblTitle.Height     := 38;
  lblTitle.Font.Size  := 14;
  lblTitle.Font.Style := [fsBold];
  lblTitle.Font.Color := CLR_TITLE;
  lblTitle.Alignment  := taCenter;

  // Below title: left panel (listbox) + right panel (buttons)
  pnlTopLeft              := TPanel.Create(Self);
  pnlTopLeft.Parent       := pnlTop;
  pnlTopLeft.Align        := alLeft;
  pnlTopLeft.Width        := 440;
  pnlTopLeft.BevelOuter   := bvNone;
  pnlTopLeft.Color        := CLR_PANEL_BG;
  pnlTopLeft.ParentBackground := False;

  lblDevices            := MakeDarkLabel(pnlTopLeft, 'Detected Devices:');
  lblDevices.Align      := alTop;
  lblDevices.Height     := 22;

  lbDevices             := TListBox.Create(Self);
  lbDevices.Parent      := pnlTopLeft;
  lbDevices.Align       := alClient;
  lbDevices.Color       := CLR_LIST_BG;
  lbDevices.ParentColor := False;
  lbDevices.ParentFont  := False;
  lbDevices.Font.Color  := CLR_PANEL_FG;
  lbDevices.OnClick     := @lbDevicesClick;

  pnlTopRight             := TPanel.Create(Self);
  pnlTopRight.Parent      := pnlTop;
  pnlTopRight.Align       := alClient;
  pnlTopRight.BevelOuter  := bvNone;
  pnlTopRight.Color       := CLR_PANEL_BG;
  pnlTopRight.ParentBackground := False;

  // Scan button
  // GTK2 alTop stacks in reverse insertion order, so add Disconnect first
  // so Scan appears at top visually
  btnDisconnect         := TBitBtn.Create(Self);
  btnDisconnect.Parent  := pnlTopRight;
  btnDisconnect.Align   := alTop;
  btnDisconnect.Height  := 36;
  btnDisconnect.Caption := 'Disconnect Selected';
  btnDisconnect.OnClick := @btnDisconnectClick;

  with TPanel.Create(Self) do begin
    Parent := pnlTopRight; Align := alTop;
    Height := 6; BevelOuter := bvNone; Color := CLR_PANEL_BG;
    ParentBackground := False;
  end;

  btnScan         := TBitBtn.Create(Self);
  btnScan.Parent  := pnlTopRight;
  btnScan.Align   := alTop;
  btnScan.Height  := 36;
  btnScan.Caption := 'Scan Devices';
  btnScan.OnClick := @btnScanClick;

  // Spacer below TCP row so it doesn't sit flush at the bottom edge
  with TPanel.Create(Self) do begin
    Parent := pnlTopRight; Align := alBottom;
    Height := 10; BevelOuter := bvNone; Color := CLR_PANEL_BG;
    ParentBackground := False;
  end;

  // TCP row: label / edit / button
  pnlTcpRow             := TPanel.Create(Self);
  pnlTcpRow.Parent      := pnlTopRight;
  pnlTcpRow.Align       := alBottom;
  pnlTcpRow.Height      := 76;
  pnlTcpRow.BevelOuter  := bvNone;
  pnlTcpRow.Color       := CLR_PANEL_BG;
  pnlTcpRow.ParentBackground := False;

  lblConnectIP            := MakeDarkLabel(pnlTcpRow, 'TCP Connect  IP:Port');
  lblConnectIP.Align      := alTop;
  lblConnectIP.Height     := 20;

  // Edit + Connect button row — button docked right, edit fills rest
  btnConnect         := TBitBtn.Create(Self);
  btnConnect.Parent  := pnlTcpRow;
  btnConnect.Align   := alRight;
  btnConnect.Width   := 120;
  btnConnect.Caption := 'Connect';
  btnConnect.OnClick := @btnConnectClick;

  edtConnectIP             := TEdit.Create(Self);
  edtConnectIP.Parent      := pnlTcpRow;
  edtConnectIP.Align       := alClient;
  edtConnectIP.Text        := '192.168.1.100:5555';
  edtConnectIP.Color       := CLR_EDIT_BG;
  edtConnectIP.ParentColor := False;
  edtConnectIP.ParentFont  := False;
  edtConnectIP.Font.Color  := CLR_PANEL_FG;
end;

{ ── Bottom Panel ─────────────────────────────────────── }

procedure TMainForm.BuildBottomPanel;
begin
  pnlBottom                  := TPanel.Create(Self);
  pnlBottom.Parent           := Self;
  pnlBottom.Align            := alBottom;
  pnlBottom.Height           := 150;
  pnlBottom.BevelOuter       := bvNone;
  pnlBottom.Color            := CLR_PANEL_BG;
  pnlBottom.ParentBackground := False;

  // Status bar at very bottom
  lblStatus             := TLabel.Create(Self);
  lblStatus.Parent      := pnlBottom;
  lblStatus.Align       := alBottom;
  lblStatus.Height      := 22;
  lblStatus.Caption     := 'Ready.';
  lblStatus.ParentFont  := False;
  lblStatus.Font.Color  := CLR_STATUS_OK;

  // Header label
  lblCmdPreview         := MakeDarkLabel(pnlBottom, 'Command Preview:');
  lblCmdPreview.Align   := alTop;
  lblCmdPreview.Height  := 20;

  // Middle: memo on left, buttons on right
  pnlMemo             := TPanel.Create(Self);
  pnlMemo.Parent      := pnlBottom;
  pnlMemo.Align       := alClient;
  pnlMemo.BevelOuter  := bvNone;
  pnlMemo.Color       := CLR_PANEL_BG;
  pnlMemo.ParentBackground := False;

  pnlBtns            := TPanel.Create(Self);
  pnlBtns.Parent     := pnlMemo;
  pnlBtns.Align      := alRight;
  pnlBtns.Width      := 230;
  pnlBtns.BevelOuter := bvNone;
  pnlBtns.Color      := CLR_PANEL_BG;
  pnlBtns.ParentBackground := False;

  // Reversed for GTK2 alTop: Copy first so Launch appears on top
  btnCopy         := TBitBtn.Create(Self);
  btnCopy.Parent  := pnlBtns;
  btnCopy.Align   := alTop;
  btnCopy.Height  := 34;
  btnCopy.Caption := 'Copy Command';
  btnCopy.OnClick := @btnCopyClick;

  with TPanel.Create(Self) do begin
    Parent := pnlBtns; Align := alTop; Height := 4;
    BevelOuter := bvNone; Color := CLR_PANEL_BG;
    ParentBackground := False;
  end;

  btnLaunch           := TBitBtn.Create(Self);
  btnLaunch.Parent    := pnlBtns;
  btnLaunch.Align     := alTop;
  btnLaunch.Height    := 44;
  btnLaunch.Caption   := 'Launch';
  btnLaunch.Font.Size := 11;
  btnLaunch.OnClick   := @btnLaunchClick;

  memoCmd             := TMemo.Create(Self);
  memoCmd.Parent      := pnlMemo;
  memoCmd.Align       := alClient;
  memoCmd.ReadOnly    := True;
  memoCmd.Color       := CLR_MEMO_BG;
  memoCmd.ParentColor := False;
  memoCmd.ParentFont  := False;
  memoCmd.Font.Color  := CLR_MEMO_FG;
  memoCmd.Font.Name   := 'Monospace';
  memoCmd.ScrollBars  := ssVertical;
  memoCmd.WordWrap    := True;
end;

{ ── PageControl ──────────────────────────────────────── }

procedure TMainForm.BuildPageControl;
begin
  pgOptions            := TPageControl.Create(Self);
  pgOptions.Parent     := Self;
  pgOptions.Align      := alClient;
  pgOptions.ParentFont := False;
  pgOptions.Font.Color := clWindowText;

  tsDisplay  := pgOptions.AddTabSheet; tsDisplay.Caption  := '  Display  ';
  tsInput    := pgOptions.AddTabSheet; tsInput.Caption    := '  Input  ';
  tsAudio    := pgOptions.AddTabSheet; tsAudio.Caption    := '  Audio  ';
  tsAdvanced := pgOptions.AddTabSheet; tsAdvanced.Caption := '  Advanced  ';
  // Ensure tab sheets use system colours, not inherited dark panel colours
  tsDisplay.Font.Color  := clWindowText; tsDisplay.ParentFont  := False;
  tsInput.Font.Color    := clWindowText; tsInput.ParentFont    := False;
  tsAudio.Font.Color    := clWindowText; tsAudio.ParentFont    := False;
  tsAdvanced.Font.Color := clWindowText; tsAdvanced.ParentFont := False;

  BuildDisplayTab;
  BuildInputTab;
  BuildAudioTab;
  BuildAdvancedTab;
end;

{ ── Display Tab ──────────────────────────────────────── }

procedure TMainForm.BuildDisplayTab;
var
  Row: TPanel;
  pnlLeft, pnlRight: TPanel;

  function MakeTabRow(AHeight: Integer = 36): TPanel;
  begin
    Result            := TPanel.Create(Self);
    Result.Parent     := tsDisplay;
    Result.Align      := alTop;
    Result.Height     := AHeight;
    Result.BevelOuter := bvNone;
    Result.Caption    := '';
  end;

begin
  // NOTE: GTK2 reverses alTop insertion order, so we add rows
  // BOTTOM-to-TOP here so they appear top-to-bottom on screen.

  // Checkboxes row (visually last = added first)
  Row := MakeTabRow(114);
  pnlLeft            := TPanel.Create(Self);
  pnlLeft.Parent     := Row;
  pnlLeft.Align      := alLeft;
  pnlLeft.Width      := 260;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.Caption    := '';
  pnlRight            := TPanel.Create(Self);
  pnlRight.Parent     := Row;
  pnlRight.Align      := alClient;
  pnlRight.BevelOuter := bvNone;
  pnlRight.Caption    := '';
  // Checkboxes also reverse within their column
  chkBorderless         := MakeCheck(pnlLeft,  'Borderless Window');
  chkAlwaysOnTop        := MakeCheck(pnlLeft,  'Always on Top');
  chkFullscreen         := MakeCheck(pnlLeft,  'Fullscreen (-f)');
  chkDisableScreensaver := MakeCheck(pnlRight, 'Disable Screensaver');
  chkStayAwake          := MakeCheck(pnlRight, 'Stay Awake');
  chkShowTouches        := MakeCheck(pnlRight, 'Show Touches');

  MakeTabRow(8);  // spacer

  // Orientation row
  Row := MakeTabRow;
  MakeRowLabel(Row, 'Orientation Lock:');
  cmbOrientation            := TComboBox.Create(Self);
  cmbOrientation.Parent     := Row;
  cmbOrientation.Align      := alLeft;
  cmbOrientation.Width      := 220;
  cmbOrientation.Style      := csDropDownList;
  cmbOrientation.Items.Text := 'Unlocked'#13'Portrait'#13'Landscape'#13'Portrait (flipped)'#13'Landscape (flipped)';
  cmbOrientation.ItemIndex  := 0;
  cmbOrientation.OnChange   := @OptionChanged;

  // Rotation row
  Row := MakeTabRow;
  MakeRowLabel(Row, 'Rotation:');
  cmbRotation            := TComboBox.Create(Self);
  cmbRotation.Parent     := Row;
  cmbRotation.Align      := alLeft;
  cmbRotation.Width      := 140;
  cmbRotation.Style      := csDropDownList;
  cmbRotation.Items.Text := 'None'#13'90'#176#13'180'#176#13'270'#176;
  cmbRotation.ItemIndex  := 0;
  cmbRotation.OnChange   := @OptionChanged;

  // Max size row
  Row := MakeTabRow;
  MakeRowLabel(Row, 'Max Size px  (0 = auto):');
  spnMaxSize          := TSpinEdit.Create(Self);
  spnMaxSize.Parent   := Row;
  spnMaxSize.Align    := alLeft;
  spnMaxSize.Width    := 100;
  spnMaxSize.MinValue := 0; spnMaxSize.MaxValue := 4096; spnMaxSize.Value := 0;
  spnMaxSize.OnChange := @OptionChanged;

  // Max FPS row
  Row := MakeTabRow;
  MakeRowLabel(Row, 'Max FPS  (0 = default):');
  spnMaxFPS          := TSpinEdit.Create(Self);
  spnMaxFPS.Parent   := Row;
  spnMaxFPS.Align    := alLeft;
  spnMaxFPS.Width    := 100;
  spnMaxFPS.MinValue := 0; spnMaxFPS.MaxValue := 240; spnMaxFPS.Value := 0;
  spnMaxFPS.OnChange := @OptionChanged;

  // Bitrate row (visually first = added last)
  Row := MakeTabRow;
  MakeRowLabel(Row, 'Video Bitrate (Mbps):');
  spnBitrate          := TSpinEdit.Create(Self);
  spnBitrate.Parent   := Row;
  spnBitrate.Align    := alLeft;
  spnBitrate.Width    := 100;
  spnBitrate.MinValue := 1; spnBitrate.MaxValue := 100; spnBitrate.Value := 8;
  spnBitrate.OnChange := @OptionChanged;

  // Top padding (visually first, added absolutely last)
  MakeTabRow(8);
end;

{ ── Input Tab ────────────────────────────────────────── }

procedure TMainForm.BuildInputTab;
var
  Pad: TPanel;
begin
  Pad := TPanel.Create(Self); Pad.Parent := tsInput;
  Pad.Align := alTop; Pad.Height := 8; Pad.BevelOuter := bvNone; Pad.Caption := '';

  // Reversed insertion order for GTK2 alTop
  chkPhysicalKeyboard    := MakeCheck(tsInput, 'Physical Keyboard  (--keyboard=uhid)');
  chkNoClipboardAutosync := MakeCheck(tsInput, 'Disable Clipboard Autosync');
  chkGamepadHID          := MakeCheck(tsInput, 'Gamepad HID  (--gamepad=aoa)');
  chkMouseHID            := MakeCheck(tsInput, 'Mouse HID  (--mouse=aoa)');
  chkKeyboardHID         := MakeCheck(tsInput, 'Keyboard HID  (--keyboard=aoa)');
  chkLegacyPaste         := MakeCheck(tsInput, 'Legacy Paste');
  chkForwardAllClicks    := MakeCheck(tsInput, 'Forward All Clicks');
  chkNoControl           := MakeCheck(tsInput, 'No Control  (view only)');
end;

{ ── Audio Tab ────────────────────────────────────────── }

procedure TMainForm.BuildAudioTab;
var
  Row: TPanel;
  Pad: TPanel;

  function MakeTabRow(AHeight: Integer = 36): TPanel;
  begin
    Result            := TPanel.Create(Self);
    Result.Parent     := tsAudio;
    Result.Align      := alTop;
    Result.Height     := AHeight;
    Result.BevelOuter := bvNone;
    Result.Caption    := '';
  end;

begin
  // Reversed for GTK2 alTop

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Audio Source:');
  cmbAudioSource            := TComboBox.Create(Self);
  cmbAudioSource.Parent     := Row;
  cmbAudioSource.Align      := alLeft;
  cmbAudioSource.Width      := 140;
  cmbAudioSource.Style      := csDropDownList;
  cmbAudioSource.Items.Text := 'output'#13'mic';
  cmbAudioSource.ItemIndex  := 0;
  cmbAudioSource.OnChange   := @OptionChanged;

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Audio Codec:');
  cmbAudioCodec            := TComboBox.Create(Self);
  cmbAudioCodec.Parent     := Row;
  cmbAudioCodec.Align      := alLeft;
  cmbAudioCodec.Width      := 140;
  cmbAudioCodec.Style      := csDropDownList;
  cmbAudioCodec.Items.Text := 'opus'#13'aac'#13'flac'#13'raw';
  cmbAudioCodec.ItemIndex  := 0;
  cmbAudioCodec.OnChange   := @OptionChanged;

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Audio Bitrate (kbps):');
  spnAudioBitrate          := TSpinEdit.Create(Self);
  spnAudioBitrate.Parent   := Row;
  spnAudioBitrate.Align    := alLeft;
  spnAudioBitrate.Width    := 100;
  spnAudioBitrate.MinValue := 16; spnAudioBitrate.MaxValue := 512; spnAudioBitrate.Value := 128;
  spnAudioBitrate.OnChange := @OptionChanged;

  MakeTabRow(6);

  chkNoAudioPlayback := MakeCheck(tsAudio, 'No Audio Playback  (--no-audio-playback)');
  chkNoAudio         := MakeCheck(tsAudio, 'Disable Audio  (--no-audio)');

  MakeTabRow(8);
end;

{ ── Advanced Tab ─────────────────────────────────────── }

procedure TMainForm.BuildAdvancedTab;
var
  Row: TPanel;
  Pad: TPanel;
  pnlLeft, pnlRight: TPanel;

  function MakeTabRow(AHeight: Integer = 36): TPanel;
  begin
    Result            := TPanel.Create(Self);
    Result.Parent     := tsAdvanced;
    Result.Align      := alTop;
    Result.Height     := AHeight;
    Result.BevelOuter := bvNone;
    Result.Caption    := '';
  end;

begin
  // Reversed for GTK2 alTop

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Extra Arguments:');
  edtExtraArgs          := TEdit.Create(Self);
  edtExtraArgs.Parent   := Row;
  edtExtraArgs.Align    := alClient;
  edtExtraArgs.OnChange := @OptionChanged;

  MakeTabRow(6);

  Row := MakeTabRow(80);
  pnlLeft            := TPanel.Create(Self);
  pnlLeft.Parent     := Row;
  pnlLeft.Align      := alLeft;
  pnlLeft.Width      := 240;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.Caption    := '';
  pnlRight            := TPanel.Create(Self);
  pnlRight.Parent     := Row;
  pnlRight.Align      := alClient;
  pnlRight.BevelOuter := bvNone;
  pnlRight.Caption    := '';
  chkNoPowerOn       := MakeCheck(pnlLeft,  'No Power On');
  chkPowerOffOnClose := MakeCheck(pnlLeft,  'Power Off on Close');
  chkVerbose         := MakeCheck(pnlRight, 'Verbose Logging');
  chkPrintFPS        := MakeCheck(pnlRight, 'Print FPS');

  MakeTabRow(6);

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Record to file:');
  btnBrowseRecord         := TButton.Create(Self);
  btnBrowseRecord.Parent  := Row;
  btnBrowseRecord.Align   := alRight;
  btnBrowseRecord.Width   := 40;
  btnBrowseRecord.Caption := '...';
  btnBrowseRecord.OnClick := @btnBrowseRecordClick;
  edtRecordFile          := TEdit.Create(Self);
  edtRecordFile.Parent   := Row;
  edtRecordFile.Align    := alClient;
  edtRecordFile.OnChange := @OptionChanged;

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Window Title:');
  edtWindowTitle          := TEdit.Create(Self);
  edtWindowTitle.Parent   := Row;
  edtWindowTitle.Align    := alLeft;
  edtWindowTitle.Width    := 280;
  edtWindowTitle.OnChange := @OptionChanged;

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Crop  W:H:X:Y:');
  edtCrop          := TEdit.Create(Self);
  edtCrop.Parent   := Row;
  edtCrop.Align    := alLeft;
  edtCrop.Width    := 180;
  edtCrop.OnChange := @OptionChanged;

  Row := MakeTabRow;
  MakeRowLabel(Row, 'Video Codec:');
  cmbVideoCodec            := TComboBox.Create(Self);
  cmbVideoCodec.Parent     := Row;
  cmbVideoCodec.Align      := alLeft;
  cmbVideoCodec.Width      := 140;
  cmbVideoCodec.Style      := csDropDownList;
  cmbVideoCodec.Items.Text := 'h264'#13'h265'#13'av1';
  cmbVideoCodec.ItemIndex  := 0;
  cmbVideoCodec.OnChange   := @OptionChanged;

  MakeTabRow(8);
end;

{ ── ADB runner ───────────────────────────────────────── }

function TMainForm.RunADB(const Args: string; out Output: string): Boolean;
var
  P: TProcess;
  S: TStringList;
begin
  Result := False; Output := '';
  P := TProcess.Create(nil);
  S := TStringList.Create;
  try
    P.Executable  := 'adb';
    P.Parameters.Text := StringReplace(Args, ' ', LineEnding, [rfReplaceAll]);
    P.Options     := [poUsePipes, poWaitOnExit, poStderrToOutPut];
    try
      P.Execute;
      S.LoadFromStream(P.Output);
      Output := S.Text;
      Result := True;
    except on E: Exception do Output := 'Error: ' + E.Message; end;
  finally S.Free; P.Free; end;
end;

{ ── Scan / Connect / Disconnect ──────────────────────── }

procedure TMainForm.btnScanClick(Sender: TObject);
var
  Output, Line, Serial, State: string;
  Lines: TStringList;
  i: Integer;
  Parts: TStringArray;
  PastHeader: Boolean;
begin
  lbDevices.Clear;
  SetStatus('Scanning...');
  if not RunADB('devices', Output) then
  begin SetStatus('adb not found in PATH.', True); Exit; end;
  Lines := TStringList.Create;
  try
    Lines.Text := Output;
    PastHeader := False;
    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);

      // The real device list starts after "List of devices attached"
      if Pos('List of devices attached', Line) > 0 then
      begin
        PastHeader := True;
        Continue;
      end;

      // Skip everything before the header and skip blank / daemon lines
      if not PastHeader then Continue;
      if Line = '' then Continue;
      // Skip adb daemon info lines (start with '*')
      if (Length(Line) > 0) and (Line[1] = '*') then Continue;

      // A valid device line is: <serial> <TAB> <state>
      // Split on tab first, then fall back to spaces
      Parts := Line.Split([#9], TStringSplitOptions.ExcludeEmpty);
      if Length(Parts) < 2 then
        Parts := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
      if Length(Parts) < 2 then Continue;

      Serial := Trim(Parts[0]);
      State  := Trim(Parts[1]);

      // Skip if serial looks like an adb message word
      if (Serial = 'List') or (Serial = '*') or (Serial = '') then Continue;

      if State = 'device' then
        lbDevices.Items.Add(Serial)
      else
        lbDevices.Items.Add(Serial + '  [' + State + ']');
    end;
  finally Lines.Free; end;
  if lbDevices.Count = 0 then
    SetStatus('No devices found.', True)
  else begin
    lbDevices.ItemIndex := 0;
    SetStatus(IntToStr(lbDevices.Count) + ' device(s) found.');
    OptionChanged(nil);
  end;
end;

procedure TMainForm.btnConnectClick(Sender: TObject);
var Output: string;
begin
  if Trim(edtConnectIP.Text) = '' then Exit;
  SetStatus('Connecting...');
  RunADB('connect ' + edtConnectIP.Text, Output);
  SetStatus(Trim(Output));
  btnScanClick(nil);
end;

procedure TMainForm.btnDisconnectClick(Sender: TObject);
var Dev, Output: string;
begin
  Dev := GetSelectedDevice;
  if Dev = '' then begin SetStatus('No device selected.', True); Exit; end;
  RunADB('disconnect ' + Dev, Output);
  SetStatus(Trim(Output));
  btnScanClick(nil);
end;

procedure TMainForm.lbDevicesClick(Sender: TObject);
begin OptionChanged(nil); end;

function TMainForm.GetSelectedDevice: string;
var S: string;
begin
  Result := '';
  if lbDevices.ItemIndex < 0 then Exit;
  S := lbDevices.Items[lbDevices.ItemIndex];
  if Pos('  [', S) > 0 then S := Copy(S, 1, Pos('  [', S) - 1);
  Result := Trim(S);
end;

{ ── Version detection ────────────────────────────────── }

function TMainForm.DetectScrcpyVersion: Integer;
{ Returns the major version number of scrcpy, e.g. 1 or 2. Returns 0 on failure. }
var
  P: TProcess;
  S: TStringList;
  Line, VerStr: string;
  i, DotPos: Integer;
begin
  Result := 0;
  P := TProcess.Create(nil);
  S := TStringList.Create;
  try
    P.Executable := 'scrcpy';
    P.Parameters.Add('--version');
    P.Options := [poUsePipes, poWaitOnExit, poStderrToOutPut];
    try
      P.Execute;
      S.LoadFromStream(P.Output);
      // First line is typically "scrcpy x.y" or "scrcpy x.y.z <url>"
      for i := 0 to S.Count - 1 do
      begin
        Line := Trim(S[i]);
        if Pos('scrcpy', LowerCase(Line)) = 1 then
        begin
          // Extract version token after "scrcpy "
          VerStr := Trim(Copy(Line, 8, Length(Line)));
          // Take only up to first space (drop URL etc)
          if Pos(' ', VerStr) > 0 then
            VerStr := Copy(VerStr, 1, Pos(' ', VerStr) - 1);
          // Major version is before first dot
          DotPos := Pos('.', VerStr);
          if DotPos > 1 then
            Result := StrToIntDef(Copy(VerStr, 1, DotPos - 1), 0)
          else if VerStr <> '' then
            Result := StrToIntDef(VerStr, 0);
          Break;
        end;
      end;
    except
      Result := 0;
    end;
  finally
    S.Free; P.Free;
  end;
end;

{ ── BuildParams ──────────────────────────────────────── }
{ Flag reference:
    v1.x: --bit-rate (-b), no audio flags, no --video-codec
    v2.x: --video-bit-rate, --audio-bit-rate, --audio-codec,
           --video-codec, --no-audio, --keyboard=, --mouse=  }

procedure TMainForm.BuildParams(P: TProcess);
var
  Dev: string;
  ExtraList: TStringList;
  j: Integer;
  IsV2: Boolean;
begin
  IsV2 := FScrcpyMajor >= 2;

  Dev := GetSelectedDevice;
  if Dev <> '' then begin P.Parameters.Add('-s'); P.Parameters.Add(Dev); end;

  // Bitrate: flag name differs between v1 and v2
  if spnBitrate.Value > 0 then
  begin
    if IsV2 then
      P.Parameters.Add('--video-bit-rate=' + IntToStr(spnBitrate.Value) + 'M')
    else
      P.Parameters.Add('--bit-rate=' + IntToStr(spnBitrate.Value) + 'M');
  end;

  if spnMaxFPS.Value  > 0 then P.Parameters.Add('--max-fps='  + IntToStr(spnMaxFPS.Value));
  if spnMaxSize.Value > 0 then P.Parameters.Add('--max-size=' + IntToStr(spnMaxSize.Value));

  if cmbRotation.ItemIndex > 0 then
    P.Parameters.Add('--rotation=' + IntToStr(cmbRotation.ItemIndex));
  case cmbOrientation.ItemIndex of
    1: P.Parameters.Add('--lock-video-orientation=0');
    2: P.Parameters.Add('--lock-video-orientation=1');
    3: P.Parameters.Add('--lock-video-orientation=2');
    4: P.Parameters.Add('--lock-video-orientation=3');
  end;

  if chkFullscreen.Checked         then P.Parameters.Add('--fullscreen');
  if chkAlwaysOnTop.Checked        then P.Parameters.Add('--always-on-top');
  if chkBorderless.Checked         then P.Parameters.Add('--window-borderless');
  if chkShowTouches.Checked        then P.Parameters.Add('--show-touches');
  if chkStayAwake.Checked          then P.Parameters.Add('--stay-awake');
  if chkDisableScreensaver.Checked then P.Parameters.Add('--disable-screensaver');
  if chkNoControl.Checked          then P.Parameters.Add('--no-control');
  if chkForwardAllClicks.Checked   then P.Parameters.Add('--forward-all-clicks');
  if chkLegacyPaste.Checked        then P.Parameters.Add('--legacy-paste');

  // HID/UHID keyboard/mouse/gamepad — v2.0+ only
  if IsV2 then
  begin
    if chkKeyboardHID.Checked         then P.Parameters.Add('--keyboard=aoa');
    if chkMouseHID.Checked            then P.Parameters.Add('--mouse=aoa');
    if chkGamepadHID.Checked          then P.Parameters.Add('--gamepad=aoa');
    if chkPhysicalKeyboard.Checked    then P.Parameters.Add('--keyboard=uhid');
    if chkNoClipboardAutosync.Checked then P.Parameters.Add('--no-clipboard-autosync');
  end;

  // Audio — v2.0+ only
  if IsV2 then
  begin
    if chkNoAudio.Checked then
      P.Parameters.Add('--no-audio')
    else begin
      if chkNoAudioPlayback.Checked then P.Parameters.Add('--no-audio-playback');
      P.Parameters.Add('--audio-bit-rate=' + IntToStr(spnAudioBitrate.Value) + 'k');
      P.Parameters.Add('--audio-codec=' + cmbAudioCodec.Items[cmbAudioCodec.ItemIndex]);
      if cmbAudioSource.ItemIndex > 0 then
        P.Parameters.Add('--audio-source=' + cmbAudioSource.Items[cmbAudioSource.ItemIndex]);
    end;
    // Video codec — v2.0+ only
    P.Parameters.Add('--video-codec=' + cmbVideoCodec.Items[cmbVideoCodec.ItemIndex]);
  end;

  if Trim(edtCrop.Text)        <> '' then P.Parameters.Add('--crop='         + Trim(edtCrop.Text));
  if Trim(edtWindowTitle.Text) <> '' then P.Parameters.Add('--window-title=' + Trim(edtWindowTitle.Text));
  if Trim(edtRecordFile.Text)  <> '' then P.Parameters.Add('--record='       + Trim(edtRecordFile.Text));
  if chkPowerOffOnClose.Checked then P.Parameters.Add('--power-off-on-close');
  if chkNoPowerOn.Checked       then P.Parameters.Add('--no-power-on');
  if chkPrintFPS.Checked        then P.Parameters.Add('--print-fps');
  if chkVerbose.Checked         then P.Parameters.Add('--verbose');

  if Trim(edtExtraArgs.Text) <> '' then begin
    ExtraList := TStringList.Create;
    try
      ExtraList.Delimiter       := ' ';
      ExtraList.StrictDelimiter := True;
      ExtraList.DelimitedText   := Trim(edtExtraArgs.Text);
      for j := 0 to ExtraList.Count - 1 do
        if Trim(ExtraList[j]) <> '' then P.Parameters.Add(Trim(ExtraList[j]));
    finally ExtraList.Free; end;
  end;
end;

{ ── BuildCommand (for preview) ───────────────────────── }

function TMainForm.BuildCommand: string;
var
  P: TProcess;
  i: Integer;
  Cmd: string;
begin
  P := TProcess.Create(nil);
  try
    P.Executable := 'scrcpy';
    BuildParams(P);
    Cmd := 'scrcpy';
    for i := 0 to P.Parameters.Count - 1 do
      Cmd := Cmd + ' ' + P.Parameters[i];
    Result := Cmd;
  finally P.Free; end;
end;

procedure TMainForm.OptionChanged(Sender: TObject);
begin
  if Assigned(memoCmd) then
    memoCmd.Text := BuildCommand;
end;

{ ── Launch ───────────────────────────────────────────── }

procedure TMainForm.btnLaunchClick(Sender: TObject);
var P: TProcess;
begin
  SetStatus('Launching scrcpy...');
  Application.ProcessMessages;
  P := TProcess.Create(nil);
  try
    P.Executable := 'scrcpy';
    BuildParams(P);
    P.Options := [poNoConsole];
    try
      P.Execute;
      SetStatus('scrcpy launched (PID ' + IntToStr(P.Handle) + ').');
    except on E: Exception do begin
      SetStatus('Launch failed: ' + E.Message, True);
      MessageDlg('Launch Error',
        'Could not start scrcpy:'#13#10 + E.Message + #13#10#13#10 +
        'Make sure scrcpy is installed and in your PATH.',
        mtError, [mbOK], 0);
    end; end;
  finally P.Free; end;
end;

{ ── Copy / Browse / Status ───────────────────────────── }

procedure TMainForm.btnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := memoCmd.Text;
  SetStatus('Command copied to clipboard.');
end;

procedure TMainForm.btnBrowseRecordClick(Sender: TObject);
var SD: TSaveDialog;
begin
  SD := TSaveDialog.Create(nil);
  try
    SD.Filter := 'MP4|*.mp4|MKV|*.mkv|All|*.*';
    SD.DefaultExt := 'mp4';
    if SD.Execute then begin edtRecordFile.Text := SD.FileName; OptionChanged(nil); end;
  finally SD.Free; end;
end;

procedure TMainForm.SetStatus(const Msg: string; IsError: Boolean);
begin
  lblStatus.Caption := Msg;
  if IsError then lblStatus.Font.Color := CLR_STATUS_ERR
  else            lblStatus.Font.Color := CLR_STATUS_OK;
  Application.ProcessMessages;
end;

{ ── Main ─────────────────────────────────────────────── }

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
