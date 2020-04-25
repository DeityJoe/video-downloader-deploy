@rem - Encoding:utf-8; Mode:Batch; Language:en; LineEndings:CRLF -
:: Used for "Deploy.bat" in :InitDeploy-* & :Upgrade-*
:: Please make sure that: only call this batch when %cd% is "res\"; call "res\scripts\lang_*.bat" before calling this batch.
:: e.g.
:: call scripts\DoDeploy.bat Setup youget
:: call scripts\DoDeploy.bat Upgrade youtubedl

@echo off
set "dd_Type=%~1"
set "dd_Tool=%~2"
call :DoDeploy-%dd_Type%
goto :eof


rem ================= Deploy Types =================


:DoDeploy-Setup
cd download
call :Setup_%dd_Tool%
cd ..
goto :eof


:DoDeploy-Upgrade
call :Upgrade_%dd_Tool%
goto :eof


rem ================= FUNCTIONS =================


:Setup_python
:: Get the full name of "python-3.x.x-embed*.zip" -> %pyZip%
for /f "delims=" %%i in ('dir /b /a:a /o:d python*embed*.zip') do ( set "pyZip=%%i" )
echo %str_unzipping% %pyZip%...
:: https://superuser.com/questions/331148/7-zip-command-line-extract-silently-quietly
7za x %pyZip% -o"%pyBin%" > NUL
echo Python-embed %str_already-deploy%
goto :eof


:Setup_youget
for /f "delims=" %%i in ('dir /b /a:a /o:d you-get*.tar.gz') do ( set "ygZip=%%i" )
if NOT "%~1"=="" ( set "ygZip=%~1" )
echo %str_unzipping% %ygZip%...
:: https://superuser.com/questions/80019/how-can-i-unzip-a-tar-gz-in-one-step-using-7-zip
7za x %ygZip% -so | 7za x -aoa -si -ttar > NUL
ping -n 3 127.0.0.1 > NUL
set ygDir=%ygZip:~0,-7%
move %ygDir% "%ygBin%" > NUL
echo You-Get %str_already-deploy%
goto :eof


:Setup_youtubedl
for /f "delims=" %%i in ('dir /b /a:a /o:d youtube-dl*.tar.gz') do ( set "ydZip=%%i" )
if NOT "%~1"=="" ( set "ydZip=%~1" )
echo %str_unzipping% %ydZip%...
7za x %ydZip% -so | 7za x -aoa -si -ttar > NUL
:: In order to avoid access denied, wait for the decompression to complete.
ping -n 5 127.0.0.1 > NUL
set ydDir=youtube-dl
move %ydDir% "%ydBin%" > NUL
echo Youtube-dl %str_already-deploy%
goto :eof


:Setup_annie
for /f "delims=" %%i in ('dir /b /a:a /o:d annie*Windows*.zip') do ( set "anZip=%%i" )
if NOT "%~1"=="" ( set "anZip=%~1" )
echo %str_unzipping% %anZip%...
7za x %anZip% -o"%anBin%" > NUL
echo Annie %str_already-deploy%
goto :eof


:Setup_ffmpeg
for /f "delims=" %%i in ('dir /b /a:a /o:d ffmpeg*.zip') do ( set "ffZip=%%i" )
echo %str_unzipping% %ffZip% ...
7za x %ffZip% > NUL
set "ffDir=%ffZip:~0,-4%"
move %ffDir% "%root%\usr\ffmpeg" > NUL
goto :eof


:Upgrade_youget
echo %str_upgrading% you-get...
:: %ygCurrentVersion% was set in res\scripts\CheckUpdate.bat :CheckUpdate_youget
del /Q download\you-get-%ygCurrentVersion%.tar.gz >NUL 2>NUL
if exist deploy.settings (
    for /f "tokens=2 delims= " %%i in ('findstr /i "UpgradeOnlyViaGitHub" deploy.settings') do ( set "state_upgradeOnlyViaGitHub=%%i" )
) else ( set "state_upgradeOnlyViaGitHub=disable" )
setlocal EnableDelayedExpansion
if "%state_upgradeOnlyViaGitHub%"=="enable" (
    set "ygLatestVersion_Url=https://github.com/soimort/you-get/releases/download/v%ygLatestVersion%/you-get-%ygLatestVersion%.tar.gz"
    echo !ygLatestVersion_Url!>> download\to-be-downloaded.txt
    wget %_WgetOptions_% !ygLatestVersion_Url! -P download
) else (
    del /Q sources.txt >NUL 2>NUL
    wget %_WgetOptions_% %_RemoteRes_%/sources.txt
    call scripts\SourcesSelector.bat sources.txt youget %_Region_% %_SystemType_% download\to-be-downloaded.txt
    wget %_WgetOptions_% -i download\to-be-downloaded.txt -P download
    REM If the file fails to download because of mirror index not syncing timelier, set %_Region_% as "origin" to fetch from original source.
    if NOT exist download\you-get-%ygLatestVersion%.tar.gz (
        call scripts\SourcesSelector.bat sources.txt youget origin %_SystemType_% download\to-be-downloaded.txt
        wget %_WgetOptions_% -i download\to-be-downloaded.txt -P download
    )
    REM If %_RemoteRes_%/sources.txt is not updated timely after the new release of you-get, download it from GitHub
    if NOT exist download\you-get-%ygLatestVersion%.tar.gz (
        set "ygLatestVersion_Url=https://github.com/soimort/you-get/releases/download/v%ygLatestVersion%/you-get-%ygLatestVersion%.tar.gz"
        ( echo # RemoteRes is not updated timely after the new release of you-get, download it from GitHub:
        echo !ygLatestVersion_Url!) >> download\to-be-downloaded.txt
        wget %_WgetOptions_% !ygLatestVersion_Url! -P download
    )
)
endlocal
rd /S /Q "%ygBin%" >NUL 2>NUL
cd download && call :Setup_youget "you-get-%ygLatestVersion%.tar.gz"
cd .. && echo You-Get %str_already-upgrade%
goto :eof


:Upgrade_youtubedl
echo %str_upgrading% youtube-dl...
:: %ydCurrentVersion% and %ydLatestVersion% were set in res\scripts\CheckUpdate.bat :CheckUpdate_youtubedl
del /Q download\youtube-dl-%ydCurrentVersion%.tar.gz >NUL 2>NUL
set "ydLatestVersion_Url=https://github.com/ytdl-org/youtube-dl/releases/download/%ydLatestVersion%/youtube-dl-%ydLatestVersion%.tar.gz"
echo %ydLatestVersion_Url%>> download\to-be-downloaded.txt
wget %_WgetOptions_% %ydLatestVersion_Url% -P download
rd /S /Q "%ydBin%" >NUL 2>NUL
cd download && call :Setup_youtubedl "youtube-dl-%ydLatestVersion%.tar.gz"
cd .. && echo Youtube-dl %str_already-upgrade%
goto :eof


:Upgrade_annie
echo %str_upgrading% annie...
:: %anCurrentVersion% and %anLatestVersion% were set in res\scripts\CheckUpdate.bat :CheckUpdate_annie
del /Q download\annie_%anCurrentVersion%_Windows*.zip >NUL 2>NUL
set "anLatestVersion_Url=https://github.com/iawia002/annie/releases/download/%anLatestVersion%/annie_%anLatestVersion%_Windows_%_SystemType_%-bit.zip"
echo %anLatestVersion_Url%>> download\to-be-downloaded.txt
wget %_WgetOptions_% %anLatestVersion_Url% -P download
del /Q "%anBin%\annie.exe" >NUL 2>NUL
cd download && call :Setup_annie "annie_%anLatestVersion%_Windows_%_SystemType_%-bit.zip"
cd .. && echo Annie %str_already-upgrade%
goto :eof


rem ================= End of File =================
