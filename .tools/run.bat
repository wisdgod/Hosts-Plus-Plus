@ECHO OFF

REM ȷ����־Ŀ¼����
IF NOT EXIST "%~dp0temp\logs" (
    MKDIR "%~dp0temp\logs"
)

REM ����Go������ʱĿ¼
go build -a -o "%~dp0temp\hosts++.exe" "%~dp0..\cmd\."

REM ���������ļ�����ʱĿ¼
COPY "%~dp0..\config.yaml" "%~dp0temp\config.yaml"

REM �ڵ�ǰ����̨�������������򣬲��ȴ������
START /B /WAIT "%~dp0temp\hosts++.exe"