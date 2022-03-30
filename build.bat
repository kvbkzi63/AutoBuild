@echo off

rem change the code page to UTF-8
rem chcp 65001

rem change the code page to Big5
chcp 950
goto DefineRunDate


:DefineRunDate
	for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
		set dow=%%i
		set year=%%j
		set month=%%k
		set day=%%l
	)
	set RunDate=%year%_%month%_%day%
	goto DefinePathInfo
 
:DefinePathInfo
	set CommandPath=C:\Users\Administrator\Desktop\HISAutoBuild
	set BuildLogPath=%CommandPath%\log\%RunDate%
	set BatInfoPath=%CommandPath%\BatInfo
	
	rd /S /Q %BuildLogPath% 
	mkdir %BuildLogPath%
	
	REM if not exist %BuildLogPath% (
		REM mkdir %BuildLogPath%
	REM ) 

	goto DefineLogFiles	
:DefineLogFiles	
	set SuccessLog=%BuildLogPath%\BuildSuccess.log
	set ErrorLog=%BuildLogPath%\BuildError.log
	goto GetTFSLoginInfo
	
:GetTFSLoginInfo
	for /f "delims=" %%a in (%BatInfoPath%\TFSLoginInfo.txt) do ( 
	if not defined LoginInfo set LoginInfo=%%a
	)
	for /f "delims=" %%b in (%BatInfoPath%\TFSWorkSpace.txt) do ( 
	if not defined WorkSpace set WorkSpace=%%b
	)
	goto RemoveLogs
:RemoveLogs	
	if exist %SuccessLog% del %SuccessLog%
	if exist %ErrorLog% del %ErrorLog%
	goto FindMSBuild
	
:FindMSBuild
	echo searching for .net framework
	set Framework=%WINDIR%\Microsoft.NET\Framework
	for /f %%f in ('dir /b /a:D "%Framework%" ^| findstr v[0-9]') do set DotNetFramework=%Framework%\%%f
	if defined DotNetFramework goto TFSGetSource
	goto DotNetNotFound
:DotNetNotFound
	echo Could not locate .Net Framework.  Please verify .Net Framework is installed.>>%ErrorLog%	
	set ERRORLEVEL=-1
	goto BuildError

:TFSGetSource
	time/T > %BuildLogPath%\00.source.log
 	rem cmd /C ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" undo %WorkSpace% /recursive /login:%LoginInfo%">>%BuildLogPath%\UndoList.log
	rem cmd /C ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" get %WorkSpace% /recursive /login:%LoginInfo%">>%BuildLogPath%\00.source.log
	cmd /C %CommandPath%\changeSet.bat
	time/T >> %BuildLogPath%\00.source.log
	goto RunBuildScript
	
:RunBuildScript		
	set /A i=0	
	for /F "delims=" %%a in (%BatInfoPath%\buildInfo.txt) do (
		set /A i+=1
		call echo %%i%%
		call set solutionname[%%i%%]=%%a

		rem get the solution file name for log name.
		for /f "tokens=1-2 delims=\" %%d in ("%%a") do (
			set kind=%%d
			set filename=%%e
		)		
		call set logname[%%i%%]=%%filename%%
		call set n=%%i%%		
	)
	
	for /L %%i in (1,1,%n%) do (
		call %DotNetFramework%\MSBuild.exe %WorkSpace%\%%solutionname[%%i]%% /t:Build /p:Configuration=release /p:VisualStudioVersion=12.0 /fl /flp:LogFile=%BuildLogPath%\%%logname[%%i]%%.log
		if errorlevel 1 if not errorlevel 2 (
			call echo %%logname[%%i]%% >> %ErrorLog%
		)
	)
	if exist %ErrorLog% goto BuildError
	goto BuildSuccess

:BuildSuccess
chcp 950
	echo 全部建置成功，標上此版本標籤：MOHW_%RunDate%>%SuccessLog%
 	rem cmd /C ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" checkin %WorkSpace% /comment:"Build" /override:"done by script" /noprompt /r /login:%LoginInfo%">>%BuildLogPath%\ReBuildRecord.log
	cmd /C %CommandPath%\Publish
	goto End

:BuildError
	echo 建置失敗。>> %ErrorLog%
	rem cmd /C %CommandPath%\SendMail.exe Fail Build - 建置失敗。
	goto End

:End
