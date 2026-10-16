@echo off
echo ==============================================
echo ==== USB TUNELI ACICI (XAMPP - TELEFON) ======
echo ==============================================
echo Eger telefon uzerinden giris yapamazsaniz
echo bu dosyaya cift tiklayin.
echo.
set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
%ADB% devices
echo.
FOR /F "skip=1 tokens=1" %%A IN ('%ADB% devices') DO (
    if "%%A" NEQ "" (
        echo Cihaz/Emulator [%%A] icin tunel aciliyor...
        %ADB% -s %%A reverse tcp:8080 tcp:80
    )
)
echo.
echo Tunnel tum cihazlar icin basariyla acildi.
pause
