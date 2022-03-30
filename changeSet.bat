@echo off

rem change the code page to UTF-8
chcp 65001 

goto DefineRunDate

:DefineRunDate
	for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
		set dow=%%i
		set year=%%j
		set month=%%k
		set day=%%l
	)
	set RunDate=%year%_%month%_%day%
	set GetDate=%year%/%month%/%day%
	goto DefinePathInfo

:DefinePathInfo
	set CommandPath=C:\Users\Administrator\Desktop\HISAutoBuild
	set LogPath=%CommandPath%\log\%RunDate%
	if not exist %LogPath% (
		mkdir %LogPath%
	)
	for /f "delims=" %%b in (%CommandPath%\BatInfo\TFSWorkSpace.txt) do ( 
	if not defined WorkSpace set WorkSpace=%%b
	)
	goto DefineLogFiles
	
:DefineLogFiles	
	set ChangeSetLog=%LogPath%\briefHistory.log
	set ChangeSetLogD=%LogPath%\detailHistory.log
	goto RemoveLogs
	
:RemoveLogs	
	if exist %ChangeSetLog% del %ChangeSetLog%
	if exist %ChangeSetLogD% del %ChangeSetLogD%
	goto GetChangeSet
	
:GetChangeSet
	for /F "delims=" %%a in (%CommandPath%\PreGetDate.txt) do (
		call set PreDate=%%a
	)
	cmd /C ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" history /server:遠端工作區 %WorkSpace% /login:帳號,密碼 /recursive /v:D%PreDate%T00:00~D%GetDate%T00:00 /format:brief /user:* /noprompt">%ChangeSetLog%
	if errorlevel 1 (
		call echo 發生錯誤 >> %ChangeSetLog%
		goto End
	)
	cmd /C ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe" history /server:遠端工作區 %WorkSpace% /login:帳號,密碼 /recursive /v:D%PreDate%T00:00~D%GetDate%T00:00 /format:detailed /user:* /noprompt">%ChangeSetLogD%
	if errorlevel 1 (
		call echo 發生錯誤 >> %ChangeSetLogD%
		goto End
	)	
	goto WritePreGetDate
	
:WritePreGetDate
	call echo %GetDate%>%CommandPath%/PreGetDate.txt
	goto End
	
:End