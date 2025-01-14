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
  /// Конструктор класса TxtGmail. Инициализирует объект с указанными параметрами.
  /// Constructor of the TxtGmail class. Initializes the object with the specified parameters.
  /// </summary>
  /// <param name="UserName">Имя пользователя для аутентификации на SMTP-сервере. Username for authentication on the SMTP server.</param>
  /// <param name="Password">Пароль для аутентификации на SMTP-сервере. Password for authentication on the SMTP server.</param>
  /// <param name="FromName">Имя отправителя, которое будет отображаться в письме. Sender's name that will be displayed in the email.</param>
  /// <param name="FromAlias">Алиас отправителя (обычно email адрес). Sender's alias (usually the email address).</param>
  /// <param name="Host">Адрес SMTP-сервера. Address of the SMTP server.</param>
  /// <param name="Port">Порт SMTP-сервера. Port of the SMTP server.</param>
  constructor Create(const UserName, Password, FromName, FromAlias, Host: string; Port: Word);

  /// <summary>
  /// Деструктор класса TxtGmail. Освобождает ресурсы, занятые объектом.
  /// Destructor of the TxtGmail class. Frees the resources occupied by the object.
  /// </summary>
  destructor Destroy; override;

  /// <summary>
  /// Устанавливает соединение с SMTP-сервером и выполняет аутентификацию.
  /// Establishes a connection to the SMTP server and performs authentication.
  /// </summary>
  procedure Connect;

  /// <summary>
  /// Отправляет email на указанные адреса.
  /// Sends an email to the specified addresses.
  /// </summary>
  /// <param name="ToAddresses">Массив строк, содержащий адреса получателей. Array of strings containing the recipient addresses.</param>
  /// <param name="Subject">Тема письма. Subject of the email.</param>
  /// <param name="PlainBody">Текст письма в формате plain text. Text of the email in plain text format.</param>
  /// <param name="HTMLBody">Текст письма в формате HTML (необязательный параметр). Text of the email in HTML format (optional parameter).</param>
  /// <param name="AttachmentFile">Путь к файлу, который будет прикреплен к письму (необязательный параметр). Path to the file to be attached to the email (optional parameter).</param>
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
