@ECHO OFF  
chcp 65001
goto DefineRunDate
:DefineRunDate
	for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
		set dow=%%i
		set year=%%j
		set month=%%k
		set day=%%l
	)
 	SET WinSCP="C:\Program Files (x86)\WinSCP\WinSCP.exe"
	set RunDate=%year%_%month%_%day%
	set CommandPath=C:\Users\Administrator\Desktop\HISAutoBuild
	set LogPath=%CommandPath%\log
	set ConfigPath=%CommandPath%\config
	for /f "delims=" %%b in (%CommandPath%\batinfo\TFSWorkSpace.txt) do ( 
	if not defined WorkSpace set WorkSpace=%%b
	)
	set BuildClientPath=Mohw_His_Deploy\15.PCS_Compiler_Client\15.PCS_Compiler_Client.sln
	set ClientProjectRoot=%WorkSpace%\OPD_Developer\OPDAPP
	set ServerProjectRoot=%WorkSpace%\OPD_Developer\OPDServerWCFService 
	for /f "delims=" %%z in (%CommandPath%\deployInfo\PublishPath.txt) do set PublishPath=%%z
	for /f "delims=" %%b in (%CommandPath%\batinfo\TFSWorkSpace.txt) do ( 
	if not defined WorkSpace set WorkSpace=%%b
	)
	goto RemoveLogs
:RemoveLogs
	set PublishLog=%LogPath%\%RunDate%\PublishLog.log
	set PublishErrorLog=%LogPath%\%RunDate%\PublishErrorLog.log
	if exist %PublishLog% del %PublishLog%
	if exist %PublishErrorLog% del %PublishErrorLog%
	goto FindMSBuild
:FindMSBuild
	echo searching for .net framework
	set Framework=%WINDIR%\Microsoft.NET\Framework
	echo %WINDIR%
	for /f %%f in ('dir /b /a:D "%Framework%" ^| findstr v[0-9]') do set DotNetFramework=%Framework%\%%f
	for /f "delims=" %%x in (%CommandPath%\versionInfo.txt) do set ver=%%x
	if defined DotNetFramework goto Start
	goto DotNetNotFound
:DotNetNotFound
	echo Could not locate .Net Framework.  Please verify .Net Framework is installed.>>%PublishLog%	
	set ERRORLEVEL=-1
	goto END
 
:Start
	for /f "delims=" %%a in (%CommandPath%\DeployInfo\AppName.txt) do (  
		for /f "tokens=1-2 delims=," %%i in ("%%a") do ( 
			if exist %ClientProjectRoot%\App.config del %ClientProjectRoot%\App.config
			if exist %ClientProjectRoot%\NFCNotifyWindow\NFCNotifyWindow.exe.config del %ClientProjectRoot%\NFCNotifyWindow\NFCNotifyWindow.exe.config
			xcopy %ConfigPath%\%%i\App.config %ClientProjectRoot% /y
			xcopy %ConfigPath%\%%i\NFCNotifyWindow\NFCNotifyWindow.exe.config %ClientProjectRoot%\NFCNotifyWindow /y
			echo %DotNetFramework%\MSBuild.exe D:\HIS_Source\Mohw_Source\PLS_Developer\PLSAPP\PLSAPP /t:reBuild /p:Configuration=release /p:VisualStudioVersion=12.0 /fl /flp:LogFile=%PublishLog%
			%DotNetFramework%\MSBuild.exe D:\HIS_Source\Mohw_Source\PLS_Developer\PLSAPP\PLSAPP\PLSAPP.sln /t:publish /p:MapFileExtensions=false /p:Configuration=release /p:VisualStudioVersion=12.0 /p:ProductName="(開發機)無紙化系統";AssemblyName=PLSAPP_Dev /p:ApplicationVersion=1.0.0.58 /p:SuiteName=PLS_Dev /p:Platform="any cpu" /p:PublishDir=遠端位置 /p:PublishUrl=遠端位置 /p:InstallUrl=遠端位置 /fl /flp:LogFile=C:\Users\user\Desktop\SourceCode\HISAutoBuild\log\xxx.log
		 	if errorlevel 1 if not errorlevel 2 ( call echo %%j 前端發行失敗。 > %PublishErrorLog% ) 
		)
	)
 	 
	if exist %PublishErrorLog% goto PublishClientError
	goto PublishServer

:PublishServer 
for /f "delims=" %%a in (%CommandPath%\DeployInfo\AppName.txt) do (  
		for /f "tokens=1-2 delims=," %%i in ("%%a") do ( 
		if exist %PublishPath%\HISService\ del /S /Q %PublishPath%\%%i\%RunDate%\HISService\*.* || goto PublishIISError
		if exist %PublishPath%\HISService\ rmdir /S /Q %PublishPath%\%%i\%RunDate%\HISService  || goto PublishIISError 
		%DotNetFramework%\aspnet_compiler   -p "%ServerProjectRoot%"  -v -d  %PublishPath%\%%i\%RunDate%\HISService -f  -c -u > %PublishLog% || goto PublishIISError
		goto UpdateVersionInfo
		goto END
)
)
:UpdateVersionInfo
	for /f "tokens=1-4 delims=." %%i in ("%ver%") do (
		set first=%%i
		set second=%%j
		set third=%%k
		set fourth=%%l
	)
	set /a "c=%fourth%+1"
	echo %first%.%second%.%third%.%c%>%CommandPath%\versionInfo.txt
	GOTO Compression
 
:PublishClientError
	cmd /C %CommandPath%\SendMail.exe Fail Deploy - 前端發行失敗。 PublishLog
	GOTO END
 
:PublishIISError
	rem cmd /C %CommandPath%\SendMail.exe Fail Deploy - 後端發行失敗。 PublishLog
	GOTO END
:Compression
	if exist %LogPath%\%RunDate%\FTPLog.log del %LogPath%\%RunDate%\FTPLog.log
	for /f "delims=" %%a in (%CommandPath%\DeployInfo\AppName.txt) do (  
		for /f "tokens=1-6 delims=," %%i in ("%%a") do ( 
			if exist %PublishPath%\%%i\Server.7z del %PublishPath%\%%i\Server.7z
			if exist %PublishPath%\%%i\Client.7z del %PublishPath%\%%i\Client.7z
			if exist %PublishPath%\%RunDate%\HISService\Web.config del %PublishPath%\%RunDate%\HISService\Web.config
			xcopy %ConfigPath%\%%i\Web\Web.config %PublishPath%\%%i\%RunDate%\HISService\ /y
			echo F|xcopy "%ConfigPath%\%%i\App.config" "%PublishPath%\%%i\%RunDate%\Client\Application Files\OPDAPP_%%i_%first%_%second%_%third%_%fourth%\OPDAPP_%%i.exe.config"
pause >nul
			%CommandPath%\7z.exe a %PublishPath%\%%i\Server.7z %PublishPath%\%RunDate%\HISService\* >>%LogPath%\%RunDate%\ServerZipLog.log
			%CommandPath%\7z.exe a %PublishPath%\%%i\Client.7z "%PublishPath%\%%i\Client\Application Files\OPDAPP_%%i_%first%_%second%_%third%_%fourth%\*" >>%LogPath%\%RunDate%\ClientZipLog.log
 			rem 參數1:IP 參數2:FTP 目錄 參數3:Release位置

			if exist %CommandPath%\command.txt del %CommandPath%\command.txt
			ECHO option batch abort>>%CommandPath%\command.txt
			ECHO option confirm off>>%CommandPath%\command.txt
			ECHO open ftp://%%m:%%n@%%k>>%CommandPath%\command.txt
			ECHO cd %%l/%%i/>>%CommandPath%\command.txt
			ECHO put %PublishPath%\%%i\Client.7z >>%CommandPath%\command.txt
			ECHO put %PublishPath%\%%i\Server.7z >>%CommandPath%\command.txt
			ECHO put %LogPath%\%RunDate%\briefHistory.log >>%CommandPath%\command.txt
			ECHO put %LogPath%\%RunDate%\detailHistory.log >>%CommandPath%\command.txt
			ECHO close>>%CommandPath%\command.txt
			ECHO exit>>%CommandPath%\command.txt
			cmd /C %WinSCP% /log=%LogPath%\%RunDate%\FTPLog.log /script=%CommandPath%\command.txt
			find /I /C "Not connected" %LogPath%\%RunDate%\FTPLog.log
			IF NOT ERRORLEVEL 1 GOTO FTPERROR
			find /I /C "未連線" %LogPath%\%RunDate%\FTPLog.log
			IF NOT ERRORLEVEL 1 GOTO FTPERROR
			find /I /C "連線逾時" %LogPath%\%RunDate%\FTPLog.log
			IF NOT ERRORLEVEL 1 GOTO FTPERROR
			find /I /C "連線失敗" %LogPath%\%RunDate%\FTPLog.log
			IF NOT ERRORLEVEL 1 GOTO FTPERROR
			call echo %%j上傳成功>>%LogPath%\%RunDate%\FTPLog.log
			if exist %PublishPath%\%%i\Server.7z del %PublishPath%\%%i\Server.7z
			if exist %PublishPath%\%%i\Client.7z del %PublishPath%\%%i\Client.7z
		)
	)
 	GOTO END

:FTPERROR
	rem cmd /C %CommandPath%\SendMail.exe Fail Upload - 後端上傳FTP失敗。 FTPLog
	GOTO END 
:ZIPERROR
	ECHO "ZipFail">>%LogPath%\%RunDate%\ZipFailLog.log
	rem cmd /C %CommandPath%\SendMail.exe Fail Upload - 進行封裝失敗。 ZipFailLog 
	GOTO END
:END
