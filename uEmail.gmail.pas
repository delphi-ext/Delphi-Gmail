unit uEmail.gmail;

interface

uses
  System.SysUtils, System.Classes, IdTCPConnection, IdExplicitTLSClientServerBase, IdMessageClient,  IdSMTP, IdMessage, IdIOHandler,
  IdBaseComponent, IdComponent, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdText, IdAttachmentFile;

type
  TxtGmail = class
  private
    FFromName: string;
    FFromAlias: string;

    FIdSSLIOHandlerSocket: TIdSSLIOHandlerSocketOpenSSL;
    FIdSMTP: TIdSMTP;
  public
    /// <summary>
    /// Create
    /// </summary>
    /// <param name="FromAlias">Почта отправителя</param>
    constructor Create(const UserName, Password, FromName, FromAlias, Host: string; Port: Word);
    destructor Destroy; override;
    procedure Connect;

    procedure Send(ToAddresses: array of string; const Subject, PlainBody: string; const HTMLBody: string = ''; const AttachmentFile: string = '');
 end;

implementation

constructor TxtGmail.Create(const UserName, Password, FromName, FromAlias, Host: string; Port: Word);
begin
  FFromName := FromName;
  FFromAlias:= FromAlias;

  FIdSSLIOHandlerSocket := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  FIdSSLIOHandlerSocket.SSLOptions.Method := sslvSSLv23;
  FIdSSLIOHandlerSocket.SSLOptions.Mode := sslmClient;
  FIdSSLIOHandlerSocket.SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];

  FIdSMTP := TIdSMTP.Create(nil);
  FIdSMTP.IOHandler := FIdSSLIOHandlerSocket;
  FIdSMTP.UseTLS := utUseImplicitTLS;
  FIdSMTP.AuthType := satDefault;

  FIdSMTP.Host := Host;
  FIdSMTP.Port := Port;
  FIdSMTP.Username := UserName;
  FIdSMTP.Password := Password;
end;

destructor TxtGmail.Destroy;
begin
  if Assigned(FIdSMTP) then
  begin
    try
      FIdSMTP.Disconnect;
    except
    end;
    UnLoadOpenSSLLibrary;
    FreeAndNil(FIdSMTP);
  end;

  if Assigned(FIdSSLIOHandlerSocket) then FreeAndNil(FIdSSLIOHandlerSocket);

  inherited;
end;

procedure TxtGmail.Connect;
begin
  FIdSMTP.Connect;
  FIdSMTP.Authenticate;
end;

procedure TxtGmail.Send(ToAddresses: array of string; const Subject, PlainBody: string; const HTMLBody: string = ''; const AttachmentFile: string = '');
var
  IdMessage: TIdMessage;
  IdText: TIdText;
  Address: string;
  AttachFileExist: Boolean;
  MultipartAlternative: Boolean;
begin
  if not FIdSMTP.Connected then
    Connect;

  IdMessage := TIdMessage.Create(nil);
  try
    IdMessage.From.Address := FIdSMTP.Username;
    IdMessage.From.Name := FFromName;
    IdMessage.From.User := FFromAlias;

    for Address in ToAddresses do
    begin
      if Address <> '' then
        IdMessage.Recipients.Add.Text := Address;
    end;

    IdMessage.Subject := Subject;

    AttachFileExist := False;
    if AttachmentFile <> '' then
      AttachFileExist := FileExists(AttachmentFile);

    MultipartAlternative := False;
    if (PlainBody <> '') and (HTMLBody <> '')  then
      MultipartAlternative := True;

    IdMessage.ContentType := 'multipart/alternative';
    if AttachFileExist then
    begin
      if MultipartAlternative then
        IdMessage.ContentType := 'multipart/related; type="multipart/alternative"'
      else
        IdMessage.ContentType := 'multipart/mixed';
    end;

    if MultipartAlternative and AttachFileExist then
    begin
      IdText := TIdText.Create(IdMessage.MessageParts);
      IdText.ContentType := 'multipart/alternative';
    end;

    // plain body
    if PlainBody <> '' then
    begin
      IdText := TIdText.Create(IdMessage.MessageParts);
      IdText.ContentType := 'text/plain; charset="UTF-8"';
      IdText.Body.Text := PlainBody;
      if MultipartAlternative and AttachFileExist then
        IdText.ParentPart := 0;
    end;

    // html body
    if HTMLBody <> '' then
    begin
      IdText := TIdText.Create(IdMessage.MessageParts);
      IdText.ContentType := 'text/html; charset="UTF-8"';
      IdText.Body.Text := HTMLBody;
      if MultipartAlternative and AttachFileExist then
        IdText.ParentPart := 0;
    end;

    if AttachFileExist then
      TIdAttachmentFile.Create(IdMessage.MessageParts, AttachmentFile);

    FIdSMTP.Send(IdMessage);
  finally
    IdMessage.Free;
  end;
end;

end.
