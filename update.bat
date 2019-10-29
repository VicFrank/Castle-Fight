@echo off

rem No parameters will deploy repo in dota folder
rem Possible parameters are 'content' 'game' 'scripts' 'fetch'
rem Parameter order doesn't matter
rem Each parameter updates corresponding folder
rem Parameter 'fetch' reverses direction of update - instead of copying local files to dota folder
rem     it copies files from dota folder to repo folder




rem Reset vars just in case
set dotapath=steamapps\common\dota 2 beta
set librarydatapath=steamapps\libraryfolders.vdf
set contenttarget=\content\dota_addons\castle_fight
set gametarget=\game\dota_addons\castle_fight
set scriptstarget=\game\dota_addons\castle_fight\scripts
rem Reg key contains dota installation path, yes, BUT, it's not updated if dota is moved somewhere
rem So it can point in a nonexistent place, empty or damaged folder
rem Thus, asking steam is much more reliable



echo Checking registry for a sign of dota
set steamfolder=""

rem A saint guy: https://stackoverflow.com/questions/7516064/escaping-double-quote-in-delims-option-of-for-f
FOR /F delims^=^"^ tokens^=2 %%i ^
IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\uninstall\Steam App 570" /v UninstallString')^
DO set steamfolder=%%i

if "%steamfolder%"=="" (echo Couldn't find an active installation of dota & pause & exit /b)
set steamfolder=%steamfolder:~0,-9%
Echo Detected dota is present





Echo Checking self location
set missing=0
if not exist %~dp0game echo Missing 'game' folder & set missing=1
if not exist %~dp0content echo Missing 'content' folder & set missing=1
if %missing%==1 echo Are you sure I'm in castle-fight repo folder? & pause & exit /b
echo Location is fine, i'm in repo





echo Steam location is %steamfolder%
echo Looking for dota in steam folder
set dotafolder=%steamfolder%%dotapath%
if exist "%dotafolder%" goto work
echo Didn't find dota in steam folder, looking for library folders
if not exist "%steamfolder%%librarydatapath%" (echo Couldn't find steam library data & pause & exit /b)

FOR /F %%i IN ('type "%steamfolder%%librarydatapath%"') DO^
if exist "%%~i%dotapath%" set dotafolder=%%~i%dotapath% & goto work

echo Couldn't find library, containing dota ):
pause
exit /b




:proceed_parameter
if %parameter%=="content" set content=1
if %parameter%=="game" set game=1
if %parameter%=="scripts" set scripts=1
if %parameter%=="fetch" set fetch=1
goto %next_param%



:update
if %fetch%==0 (xcopy %adr1% %adr2% /y /e /q) else (xcopy %adr2% %adr1% /y /e /q)
goto %next_operation%



rem Possible parameters are 'content' 'game' 'scripts' 'fetch'
:work
echo Found dota in %dotafolder%
set content=0
set game=0
set scripts=0
set fetch=0
:param1
set parameter="%1"
set next_param=param2
goto proceed_parameter
:param2
set parameter="%2"
set next_param=param3
goto proceed_parameter
:param3
set parameter="%3"
set next_param=param4
goto proceed_parameter
:param4
set parameter="%4"
set next_param=params_done
goto proceed_parameter
:params_done
if %content%==0 if %game%==0 if %scripts%==0 (set content=1) & set game=1
if %fetch%==0 (echo COPYING LOCAL files to dota folder) else (echo REPLACING LOCAL FILES with the ones in dota folder)
:update_content
if %content%==1 (set adr1="%~dp0content\castle_fight\*") & (set adr2="%dotafolder%%contenttarget%\*")^
& (set next_operation=update_game) & (echo Updating content) & (goto update)
:update_game
if %game%==1 (set adr1="%~dp0game\castle_fight\*") & (set adr2="%dotafolder%%gametarget%\*")^
& (set next_operation=end) & (echo Updating game) & (goto update)
rem Don't update 'scripts' if allready updated 'game'
:update_scripts
if %scripts%==1 (set adr1="%~dp0game\castle_fight\scripts\*") & (set adr2="%dotafolder%%scriptstarget%\*")^
& (set next_operation=end) & (echo Updating scripts) & (goto update)


:end
echo Done
timeout /t 3