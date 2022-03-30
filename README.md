# 自動取版/發佈腳本(.NET + TFS)

## 功能描述

可設定排程做自動取版/發佈

結合 TFS MSBuild 7z FTP...等相關指令來實現CI/CD
 
 
### 設定介紹

* BatInfo.txt
 - 設定要建置的專案有哪些，可設定多個
  
  
* TFSLoginInfo.txt/TFSWorkSpace.txt
 - 設定版控相關資訊如 工作區/專案目錄
 
* AppName.txt
 - 設定發布的遠端主機相關資訊
 
* PublishPath
 - 檔案發布的路徑目錄
 
### 工作流程

 1 . build.bat 初始化變數設定 
 
 2 . changeSet.bat 取Server上最新版本
 
 3 . publish.bat 發佈到遠端伺服器(透過FTP方式將壓縮檔上傳)

 4. SendMail.exe 通知相關人員本次自動發版結果