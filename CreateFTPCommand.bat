
SET ip=%1
SET ShareFolder=%2
SET ReleasePath=%3
SET ChangeSet=%4
SET UserId=%5
SET Password=%6
if exist command.txt del command.txt

@ECHO OFF 
ECHO option batch abort>>command.txt
ECHO option confirm off>>command.txt
ECHO open ftp://%UserId%:%Password%@%ip%>>command.txt
ECHO cd "%ShareFolder%"/>>command.txt
ECHO put %ReleasePath%\Client.7z >>command.txt
ECHO put %ReleasePath%\Server.7z >>command.txt
ECHO put %ChangeSet%\briefHistory.log >>command.txt
ECHO put %ChangeSet%\detailHistory.log >>command.txt
ECHO close>>command.txt 
ECHO exit>>command.txt 