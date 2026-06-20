[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{8A196191-E623-4554-8B61-6E9D58E02341}
AppName=PAPs n POPs
AppVersion=1.0.0
;AppVerName=PAPs n POPs 1.0.0
AppPublisher=PAPs n POPs
AppPublisherURL=https://papsnpops.com/
AppSupportURL=https://papsnpops.com/
AppUpdatesURL=https://papsnpops.com/
DefaultDirName={autopf}\PAPs n POPs
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=..\build\windows\installer
OutputBaseFilename=PAPs_n_POPs_Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; Self-update support: the running app is closed (Restart Manager) so its exe can
; be replaced. We relaunch it ourselves from [Run] (see below), so disable Inno's
; own restart to avoid launching it twice.
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\paps_n_pops.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\PAPs n POPs"; Filename: "{app}\paps_n_pops.exe"
Name: "{autodesktop}\PAPs n POPs"; Filename: "{app}\paps_n_pops.exe"; Tasks: desktopicon

[Run]
; Interactive install: offer to launch at the end of the wizard.
; runasoriginaluser keeps the app de-elevated even though setup ran elevated.
Filename: "{app}\paps_n_pops.exe"; Description: "{cm:LaunchProgram,PAPs n POPs}"; Flags: nowait postinstall skipifsilent runasoriginaluser
; Silent (auto-update) install: relaunch the app automatically once files are replaced.
Filename: "{app}\paps_n_pops.exe"; Flags: nowait runasoriginaluser; Check: WizardSilent
