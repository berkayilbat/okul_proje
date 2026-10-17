@echo off
chcp 65001 >nul
echo =======================================================
echo ==== CANLI DEMO AĞ VE BAĞLANTI YARDIMCISI (XAMPP) =====
echo =======================================================
echo.
echo [1] BILGISAYARINIZIN YEREL AĞ IP ADRESLERI:
ipconfig | findstr /i "IPv4"
echo.
echo [!] IKI TELEFONLA CANLI DEMO TALIMATI:
echo - Bilgisayar ve her iki telefon da AYNI Wi-Fi veya Telefon Hotspot agina bagli olmalidir.
echo - Uygulamanin giris ekranindaki 'Sunucu' kutusuna bilgisayarinizin IPv4 adresini yazin.
echo   (Ornegin: 192.168.1.7)
echo.
echo [2] EGER TELEFON USB KABLOSU ILE BAGLI ISE TUNEL ACILIYOR...
set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if exist %ADB% (
    %ADB% devices
    FOR /F "skip=1 tokens=1" %%A IN ('%ADB% devices') DO (
        if "%%A" NEQ "" (
            echo Cihaz [%%A] icin port 80 ve 8080 yonlendiriliyor...
            %ADB% -s %%A reverse tcp:80 tcp:80
            %ADB% -s %%A reverse tcp:8080 tcp:80
        )
    )
    echo USB Tuneli basariyla yonlendirildi.
) else (
    echo Android ADB bulunamadi, kablosuz Wi-Fi IP uzerinden baglanti saglayabilirsiniz.
)
echo.
echo Apache ve MySQL servislerinin calistigindan emin olun.
echo Test icin tarayicidan: http://localhost/backend/ping.php
echo.
pause
