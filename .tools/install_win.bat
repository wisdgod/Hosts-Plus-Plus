@ECHO OFF
CHCP 936 >NUL
SETLOCAL
SET "CERT_PATH=ca.pem"
SET "TITLE=��װ��֤�鵽Windows�����εĸ�֤��䷢����"

REM ��װ֤��
CERTUTIL -addstore "Root" "%CERT_PATH%"

IF %ERRORLEVEL% EQU 0 (
    ECHO ֤���ѳɹ���װ.
) ELSE (
    ECHO ֤�鰲װʧ��.
)
ENDLOCAL
