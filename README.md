# Delphi-Gmail

**Delphi class for sending emails via Gmail**

## Usage Example:
```delphi
Gmail := TcfsGmail.Create('YourAccount@gmail.com', 'App password', 'From you/company', 'YourAccount@gmail.com', Host, Port);
try
  try
    Gmail.Connect;
    Gmail.Send(['useremail@gmail.com'], 'Subject', 'PlainBody', 'htmlBody', 'AttachmentFile');
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
finally
  Gmail.Free;
end;
```

Important Notes:
OpenSSL Libraries:
To ensure the application works correctly, make sure the following libraries are located in the same directory as the executable file:

- libeay32.dll
- ssleay32.dll
  
Gmail Account Configuration

Before using the class, ensure that your Gmail account is configured to work with external applications:

Go to Gmail settings -> "Security" tab.
Enable "2-Step Verification" and create an "App Password",
or enable the "Allow less secure apps" option.


**Класс Delphi для отправки электронной почты через Gmail**  

Важные примечания:
OpenSSL библиотеки:
Для корректной работы приложения, в папке с исполняемым файлом должны находиться библиотеки:

- libeay32.dll
- ssleay32.dll

Настройка аккаунта Gmail

Перед использованием убедитесь, что аккаунт Gmail настроен для работы с внешними приложениями:

Перейдите в настройки Gmail -> вкладка "Безопасность".
Активируйте "Двухэтапную аутентификацию" и создайте "Пароль для приложения".
или включите опцию "Разрешить небезопасные приложения".
