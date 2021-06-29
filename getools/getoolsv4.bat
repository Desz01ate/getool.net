@echo off 
color 1f
setlocal enableextensions enabledelayedexpansion
REM http://www.dostips.com/DtTipsMenu.php
title Granado Espada Tools v4

REM check for admin rights
net session >nul 2>&1
if not %errorlevel%==0 (
	echo You do not have administrator privilege. 
	echo Attempting privilege elevation...
	echo Alternatively, right-click on %~nx0 and run as administrator.
	timeout 1
	bin\nircmd.exe elevate %0 %1 %2
	exit
) 
cd /d %~dp0..
set clientdir=%cd%
cd /d %~dp0
REM check for file integrity
echo.
if not exist bin\getools_fc.txt (
	echo ERROR: File not found - getools_fc.txt
	pause
	exit
)
for /f "tokens=* delims= " %%a in (bin\getools_fc.txt) do (
	if not exist %%a (
		echo ERROR: File not found - %%a
		set filecheck=fail
	) 
)
echo.
REM if "%filecheck%"=="fail" (
if defined filecheck (
	echo Failed file integrity check. Some files are missing.
	echo Do NOT rename or move the files and folders.
	pause
	exit
)


set /p rev=<..\updater.revision.txt
REM find and get string from within double quotes
REM https://stackoverflow.com/questions/7516064/escaping-double-quote-in-delims-option-of-for-f
for /f delims^=^"^ tokens^=2 %%a in ('type ..\release\client.xml^|find "ServiceNation"') do (set nation=%%a)

REM call getools.bat ui.ipf 1 - http://stackoverflow.com/questions/11576270
REM https://ss64.com/nt/syntax-dequote.html
set drop=%~1
set choice=%2
if not "%2"=="" (goto menu_%2)
cls

:menuLOOP
echo.
echo.= GRANADO ESPADA TOOLS =================================================
echo Current Client = %clientdir%
echo Current Region = %nation%
echo Current Patch = %rev%
if not "%drop%"=="" (echo Selected File/Folder = %drop%)
echo.
REM http://marsbox.com/blog/howtos/batch-file-programfiles-x86-parenthesis-anomaly/
REM for /f "tokens=1,2,* delims=_ " %%A in ('"findstr /b /c:":menu_" "%~f0""') do echo.  %%B  %%C
for /f "tokens=1,2,* delims=_ " %%A in ('"findstr /b /c:":menu_" "getoolsv4.bat""') do echo.  %%B  %%C
set choice=
set backup=
echo.&set /p choice=Make a choice or hit ENTER to quit: ||GOTO:EOF
echo.&call:menu_%choice%
GOTO:menuLOOP

:: menu functions follow below here------------------------------------------

:menu_0   Extract All IPFs
echo.= EXTRACT ALL IPFS ==========================================================
echo Starting extraction for all IPFs
bin\getool.net.exe
echo.
echo COMPLETED: Extracted All IPFs successfully.
echo.
bin\speak.exe -t "extract all ipf process completed"
goto:eof

:menu_1   Extract IPF
echo.= EXTRACT IPF ==========================================================
if not exist "%drop%" (
	echo Use the dialog window to choose a file to extract.
REM	bin\filebrowse.exe "Select File to Extract" "..\ge\*.ipf" "IPF or BAK (*.ipf, *.bak)|*.ipf;*.bak" > browse.tmp
	bin\filebrowse.exe "Select File to Extract" "..\ge\*.ipf" "IPF (*.ipf)|*.ipf" > browse.tmp
	set /p drop=<browse.tmp
	del browse.tmp
)
set reqtype=file
set reqext=.ipf
call :testtype
if not "%testerror%"=="" (
	echo !testerror!
	echo.
	set drop=
	goto:eof
)

echo Starting extraction of %drop%...
echo This may take a while, depending on file size. Please wait.
echo Converting to .zip...
bin\iz.exe "%drop%" > NUL
if "%ipfrev%"=="" (
	echo Extracting .zip...
	bin\ez.exe "%dropdir%%dropname%.zip" > NUL
	echo Deleting .zip...
	del "%dropdir%%dropname%.zip"
) else (
	echo Removing backup tags from file name...
	ren "%dropdir%%dropname%.zip" "%ipfname%.zip"
	echo Moving .zip from backup folder...
	move /-y "%dropdir%%ipfname%.zip" ..\ge
	echo Extracting .zip...
	bin\ez.exe "..\ge\%ipfname%.zip" > NUL
	echo Deleting .zip...
	del "..\ge\%ipfname%.zip"
)
echo.
echo COMPLETED: Extracted %dropname%%dropext% into %clientdir%\ge\%ipfname% folder.
echo.
bin\speak.exe -t "extract ipf process completed"
set drop=
goto:eof


:menu_2   Create IPF From Folder
echo.= CREATE IPF FROM FOLDER ===============================================
call :checkgeexe
if not exist "%drop%" (
	echo Use the dialog window to choose a folder from which to create the IPF file.
	bin\folderbrowse.exe "Select a folder from which to create the IPF file" "%cd%" > browse.tmp
	set /p drop=<browse.tmp
	set drop=!drop:~0,-1!
	del browse.tmp
)
set reqtype=folder
set reqext=
call :testtype
if not "%testerror%"=="" (
	echo !testerror!
	echo.
	set drop=
	goto:eof
)

echo WARNING: This process modifies the game client files. Backup recommended.
bin\choice.exe Create a backup copy of %dropname%.ipf 
if %errorlevel%==1 (set backup=yes)
echo.
echo Starting creation of %dropname%.ipf from %drop%...
echo This may take a while, depending on file size. Please wait.
echo.
echo Creating .zip from %dropname% folder...
bin\cz.exe "%drop%" > NUL
echo Converting .zip to .ipf...
bin\zi.exe "%drop%.zip" > NUL
echo Deleting .zip...
del "%drop%.zip"
if exist "%drop%.ipf" (
	call :makebackup
	del "%drop%.ipf"
)
echo Fixing filename of new .ipf...
ren "%drop%.zip.ipf" %dropname%.ipf
echo Removing %drop% folder...
rd /s "%drop%"
echo.
echo COMPLETED: Created %dropname%.ipf from %drop% folder.
echo.
bin\speak.exe -t "create ipf process completed"
set drop=
goto:eof


:menu_3   Optimize IPF
echo.= OPTIMIZE IPF =========================================================
call :checkgeexe
if not exist "%drop%" (
	echo Use the dialog window to choose one or more files to optimize.
	echo Tip: Hold Ctrl or Shift key to select multiple files.
	bin\filebrowse.exe -m "Select Files to Optimize" "..\ge\*.ipf" "IPF (*.ipf)|*.ipf" > browse.tmp
	echo.
)
set reqtype=file
set reqext=.ipf

echo WARNING: This process modifies the game client files. Backup recommended.
bin\choice.exe Create a backup copy of the affected files 
if %errorlevel%==1 (set backup=yes)
echo.
for /f "tokens=* delims= " %%a in (browse.tmp) do (
	set drop=%%a
	call :testtype
	if not "!testerror!"=="" (
		echo !testerror!
		echo.
		set drop=
		goto:eof
	)
	if exist "!drop!" (call :makebackup)
	echo Optimizing !drop!... 
	echo This may takes a few minutes... Please wait.
	bin\oz.exe "!drop!"
	echo OPTIMIZED !drop!	
REM	bin\iz.exe "!drop!" > NUL
REM	bin\oz.exe "!dropdir!!dropname!.zip" > NUL
REM	bin\zi.exe "!dropdir!!dropname!.zip" > NUL
REM	if exist "!dropdir!!dropname!.zip.ipf" (
REM		del !drop!
REM		ren "!dropdir!!dropname!.zip.ipf" !dropname!.ipf
REM		echo OPTIMIZED !drop!
REM	) else (
REM		echo ERROR: !dropname!.zip.ipf is missing.
REM		echo Original !dropname!.ipf file retained.
REM	)
	echo.
)
echo COMPLETED: All selected files have been optimized.
echo.
bin\speak.exe -t "optimize ipf process completed"
del browse.tmp
set drop=
goto:eof


:menu_4   Add Folder To IPF
echo.= ADD FOLDER TO IPF ====================================================
call :checkgeexe
REM folder must be named ipfname_region_description.af, such as ui_usa_wideinventory.af
if "%drop%"=="" (
	echo Use the dialog window to choose a folder to add to IPF file.
	bin\folderbrowse.exe "Select a folder to add to IPF" "%cd%" > browse.tmp
	set /p drop=<browse.tmp
	set drop=!drop:~0,-1!
	del browse.tmp
)
set reqtype=folder
set reqext=.af
call :testtype
if not "%testerror%"=="" (
	echo !testerror!
	echo.
	set drop=
	goto:eof
)
if "%ipfexe%"=="" (set ipfexe=UNDEFINED)
if not "%ipfexe%"=="%nation%" (
	if not "%ipfexe%"=="ANY" (
		echo ERROR: Mismatched region.
		echo The selected folder is for %ipfexe% region, but your client region is %nation%.
		echo.
		set drop=
		goto:eof
	)
)
set dropname=%ipfname%
if not exist "..\ge\%dropname%.ipf" (
	echo ERROR: File %dropname%.ipf is missing in this game client.
	set drop=
	goto:eof
)
echo WARNING: This process modifies the game client files. Backup recommended.
bin\choice.exe Create a backup copy of %dropname%.ipf file 
if %errorlevel%==1 (set backup=yes)
call :makebackup
echo Adding %drop% to %dropname%.ipf...
bin\af.exe "..\ge\%dropname%.ipf" "%drop%"
echo.
echo COMPLETED: Added %drop% to %dropname%.ipf.
echo.
bin\speak.exe -t "add folder to ipf process completed"
set drop=
goto:eof
REM bin\7z.exe x "%drop%" -o%now% -t7z -part
REM dir /b /ad %now%>%now%\af.tmp
REM set /p dropname=<%now%\af.tmp


:menu_5   Convert IES To XML/PRN
echo.= CONVERT IES FILE TO XML/PRN ==========================================
if not exist "%drop%" (
	echo Use the dialog window to choose one or more files to convert.
	echo Tip: Hold Ctrl or Shift key to select multiple files.
	bin\filebrowse.exe -m "Select Files to Convert" "..\ge\ies\*.ies" "IES (*.ies)|*.ies" > browse.tmp
	echo.
)
set reqtype=file
set reqext=.ies
for /f "tokens=* delims= " %%a in (browse.tmp) do (
	set drop=%%a
	call :testtype
	if not "!testerror!"=="" (
		echo !testerror!
		echo.
		set drop=
		goto:eof
	)
	echo Converting !drop!... 
	echo This may takes a few minutes... Please wait.
	bin\ix3.exe "!drop!"
	ren "!dropdir!!dropname!.csv" !dropname!.prn
	echo CONVERTED !drop!
	echo.
)
echo COMPLETED: Converted the selected IES files.
echo XML files can be opened with Microsoft Excel as an XML table.
echo PRN files can be opened with Microsoft Excel as a tab-delimited table.
echo.
bin\speak.exe -t "convert ies process completed"
del browse.tmp
set drop=
goto:eof


:menu_6   Restore Backup IPF
echo.= RESTORE BACKUP IPF ===================================================
call :checkgeexe
if not exist "%drop%" (
	echo Use the dialog window to choose a backup file to restore.
	bin\filebrowse.exe "Select File to Restore" "..\ge\backup\*.ipf" "IPF (*.ipf)|*.ipf" > browse.tmp
	set /p drop=<browse.tmp
	del browse.tmp
)
set reqtype=file
set reqext=.ipf
call :testtype
if not "%testerror%"=="" (
	echo !testerror!
	echo.
	set drop=
	goto:eof
)

if not "%ipfexe%"=="" (
	if not "%ipfrev%"=="" (goto:skip6)
)
echo ERROR: File %dropname%%dropext% is not created by GE Tools.
set drop=
goto:eof
:skip6
echo Client File = %clientdir%\ge\%ipfname%.ipf
echo Client Patch = %rev%
echo Backup File = %drop%
echo Backup Patch = %ipfrev%
if "%ipfexe%"=="2" (echo Backup Process = Create IPF from Folder)
if "%ipfexe%"=="3" (echo Backup Process = Optimize IPF)
if "%ipfexe%"=="4" (echo Backup Process = Add Folder To IPF)
echo.
if not "%ipfrev%"=="%rev%" (
	echo WARNING: Backup Patch is different from Client Patch.
	echo If you restore this backup file, you must re-update the game client.
	bin\choice.exe Do you wish to re-update the client to the latest patch  
	if !errorlevel!==2 (
		echo Process aborted. Backup file has NOT been restored.
		goto :eof
	)
)
echo.
echo To restore backup, you must overwrite the existing file if it exists.
move /-y "%drop%" "..\ge\%ipfname%.ipf"
echo %date% %time% - Restored %drop% when latest patch is %rev% >> ..\ge\backup\backup.log
echo.
if not "%ipfrev%"=="%rev%" (
REM	copy /y "%clientdir%\updater.revision.txt" "%clientdir%\updater.revision.bak" > NUL
	echo %ipfrev%>"..\updater.revision.txt"
	echo Starting game client to re-update...
	echo Wait for patch to complete, then close the game client.
	..\ge.exe
	pause
)
echo.
bin\speak.exe -t "restore backup process completed"
set drop=
goto :eof

:menu_7   Check For Updates Online 
echo See the console window title for this version number.
echo Starting your default browser...
start https://starstorm-ge.blogspot.com/2017/09/ge-tools.html
goto :eof


:menu_


:menu_C   Clear Screen
cls
goto:eof


:testtype
REM http://stackoverflow.com/questions/8666225
if not exist "%drop%" (
	set droptype=
) else (
	dir /ad /b "%drop%" 1> NUL 2> NUL
	if !errorlevel!==0 (
		set droptype=folder
	) else (
		set droptype=file
	)
)
REM http://stackoverflow.com/questions/9252980
for %%a in ("%drop%") do (
    set dropdir=%%~dpa
    set dropname=%%~na
	set dropext=%%~xa
)
for /f "tokens=1,2* delims=-" %%c in ("%dropname%") do (
	set ipfname=%%c
	set ipfexe=%%d
	set ipfrev=%%e
)
echo Target = %drop%
echo Path = %dropdir%
echo Type = %droptype%
echo Name = %dropname%
echo Extension = %dropext%
echo IPF Name = %ipfname%
echo Process = %ipfexe%
echo Revision = %ipfrev%
echo.
set testerror=
if not "%dropext%"=="%reqext%" (set "testerror=ERROR: Selected item must have [!reqext!] extension.")
if not "%droptype%"=="%reqtype%" (set "testerror=ERROR: Selected item must be a !reqtype!.")
if not exist "%drop%" (set "testerror=ERROR: Selected item is missing - !drop!")
goto:eof


:makebackup
if not exist ..\ge\backup (md ..\ge\backup)
if "%backup%"=="yes" (
	echo Creating backup copy of %dropname%.ipf...
	copy /-y "..\ge\%dropname%.ipf" "..\ge\backup\%dropname%-%choice%-%rev%.ipf"
	echo Created %dropname%-%choice%-%rev%.ipf in ..\ge\backup folder.
	echo Manually delete %dropname%-%choice%-%rev%.ipf if it is no longer desired.
	echo %date% %time% - Created %dropname%-%choice%-%rev%.ipf >> ..\ge\backup\backup.log
) else (
	echo Backup process skipped.
)
echo.
goto:eof

	
:checkgeexe
tasklist /FI "IMAGENAME eq ge.exe" 2>NUL | find /I /N "ge.exe">NUL
if %errorlevel%==0 (
 	echo WARNING: Found process ge.exe.
 	echo Close the game client first before continuing.
 	pause&echo.
	goto:checkgeexe
)
goto:eof