import QtQuick 2.1
import BxtClient 1.0
import FileIO 1.0
import qb.components 1.0
import qb.base 1.0;
import "toonstore.js" as ToonstoreJS

App {
	id: toonstoreApp
	property url fullScreenUrl : "ToonstoreScreen.qml"
	property url fullSettingsUrl : "ToonstoreSettings.qml"
	property url fullChangelogUrl : "ToonstoreDelegateChangelog.qml"
	property url thumbnailIcon: "qrc:/tsc/repo.png"
	property url toonstoreMenuIconUrl: "qrc:/tsc/repo.png"
	property url trayUrl: "ToonstoreTray.qml"
	property url toonstoreDelegateGalleryPopupUrl : "ToonstoreDelegateGalleryPopup.qml"

	property Popup toonstoreDelegateGalleryPopup
	property string configMsgUuid

	property ToonstoreScreen toonstoreScreen
	property ToonstoreDelegateChangelog toonstoreDelegateChangelog
	property ToonstoreSettings toonstoreSettings
	property bool dialogShown : false  //shown when changes have been made in the list of apps. Shown only once.
	property string toonSoftwareVersion  //actual firmware version

	// Toonstore data in XML string format
	property string repoDataAll
	property variant installedApps
	property int updatesCount : 0

	property string repoRefreshDateTime	
	property string updatesToBeApplied	
	property string autoUpdatesToBeApplied
	property string deletesToBeApplied
	property string delegateChangelog : "Leeg...."
	property string delegateChangelogTitle : "Nieuwe functies"
	property int delegateChangelogScreenshots 
	property string screenshotURLchunk 

	property bool showStoreIcon : true
	property bool updateViaTSCscripts : false
	property bool autoUpdate : false
	property bool sendNotificationOfNewApps : false
	property bool sendNotificationOfNewAppVersions : false
	property string autoUpdateTime
	property SystrayIcon toonstoreTray
	property variant namesOldRepo : []
	property variant versionsOldRepo : []

	property bool toonstoreDataRead: false
	property string activeRepoBranch : "main"
	property string lanIp: "0.0.0.0"
	property int numberOfAppsSelectedToInstall : 0

	// Toonstore signals, used to update the listview and filter enabled button
	signal toonstoreUpdated()

	// user settings from config file
	property variant toonstoreSettingsJson

	FileIO {
		id: toonstoreSettingsFile
		source: "file:///mnt/data/tsc/toonstore.userSettings.json"
 	}

	FileIO {
		id: toonstoreOldRepoInfoFile
		source: "file:///mnt/data/tsc/toonstore.oldRepoInfo.json"
		onError: { sendNotificationOfNewApps = false; }
	}

	FileIO {
		id: qmlDir
		source: "file:///qmf/qml/apps"
	}

	FileIO {
		id: toonConfig
		source: "file:///usr/lib/opkg/info/base-qb2-ene.control"
	}

	FileIO {
		id: toonConfigUni
		source: "file:///usr/lib/opkg/info/base-qb2-uni.control"
	}

	FileIO {
		id: toonConfigNxt
		source: "file:///var/lib/opkg/info/base-nxt-uni.control"
	}

	// Init the toonstore app by registering the widgets
	function init() {
		registry.registerWidget("screen", fullScreenUrl, this, "toonstoreScreen");
		registry.registerWidget("screen", fullSettingsUrl, this, "toonstoreSettings");
		registry.registerWidget("screen", fullChangelogUrl, this, "toonstoreDelegateChangelog");
		registry.registerWidget("menuItem", null, this, null, {objectName: "toonstoreMenuItem", label: qsTr("ToonStore"), image: toonstoreMenuIconUrl, screenUrl: fullScreenUrl, weight: 120});
		registry.registerWidget("systrayIcon", trayUrl, toonstoreApp);
		registry.registerWidget("popup", toonstoreDelegateGalleryPopupUrl, this, "toonstoreDelegateGalleryPopup");
		notifications.registerType("toonstore", notifications.prio_HIGHEST, Qt.resolvedUrl("qrc:/tsc/notification-update.svg"), fullScreenUrl , {"categoryUrl": fullScreenUrl }, "ToonStore mededelingen");
		notifications.registerSubtype("toonstore", "mededeling", fullScreenUrl , {"categoryUrl": fullScreenUrl});
	}

	function sendNotification(text) {
		notifications.send("toonstore", "mededeling", false, text, "category=mededeling");
	}


	function saveUpdateTime(text) {

		autoUpdateTime = text;
   		saveSettings();
		if (autoUpdate) {
			activateUpdateTimer();
		}
	}

	function saveShowStoreIcon(text) {

		showStoreIcon = (text == "Yes");
   		saveSettings();
	}

	function saveShowNotifications(text) {

		sendNotificationOfNewApps = (text == "Yes");
   		saveSettings();
	}

	function saveShowNotificationsVersions(text) {

		sendNotificationOfNewAppVersions = (text == "Yes");
   		saveSettings();
	}

	function saveAutoUpdate(text) {

		autoUpdate = (text == "Yes");
   		saveSettings();
		if (autoUpdate) {
			activateUpdateTimer();
		}
	}

	function activateUpdateTimer() {
			/// calculates miliseconds till next scheduled update time and starts timer
		var now = new Date();
		var nowUtc = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), now.getSeconds(),now.getMilliseconds());
		var addaday = 0;
		var targetHour = ToonstoreJS.updateHour(autoUpdateTime);
		var targetMinute = ToonstoreJS.updateMinute(autoUpdateTime);

		if (now.getHours() > targetHour) {
			addaday = 1;
		} else {
			if (now.getHours() == targetHour) {
				if (now.getMinutes() >= targetMinute) {
					addaday = 1;
				}
			}
		}
		var targetTimer = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() + addaday, targetHour, targetMinute, 0, 0);
		targetTimer = targetTimer - nowUtc;
		if (autoUpdate) {
			autoUpdateTimer.interval = targetTimer;
			autoUpdateTimer.running = true;
			console.log("ToonStore auto update timer set for " + targetTimer + " from " + now);
		} else {
			autoUpdateTimer.running = false;	
		}
	}

	function writeUpdatesToBeApplied() {
	
		var outputstr = updatesToBeApplied.trim();
		if (outputstr.length > 2) {
 	  		var doc2 = new XMLHttpRequest();
  			doc2.open("PUT", "file:///tmp/packages_to_install.txt");
 	  		doc2.send(updatesToBeApplied);
			return true;
		} else {
			return false;
		}
	}


	function writeAutoUpdatesToBeApplied() {
	
		var outputstr = autoUpdatesToBeApplied.trim();
		if (outputstr.length > 2) {
 	  		var doc2 = new XMLHttpRequest();
  			doc2.open("PUT", "file:///tmp/packages_to_install.txt");
 	  		doc2.send(autoUpdatesToBeApplied);
			return true;
		} else {
			return false;
		}
	}

	function writeTSCscriptCommand() {
	
 		var doc4 = new XMLHttpRequest();
  		doc4.open("PUT", "file:///tmp/tsc.command");
   		doc4.send("toonstore");
	}

	function writeDeletesToBeApplied() {
	
		var outputstr = deletesToBeApplied.trim();
		if (outputstr.length > 2) {
 	  		var doc2 = new XMLHttpRequest();
  			doc2.open("PUT", "file:///tmp/packages_to_delete.txt");
 	  		doc2.send(deletesToBeApplied);
			return true;
		} else {
			return false;
		}
	}

	function clearDeletesToBeApplied() {
	
		var outputstr = " ";
   		var doc2 = new XMLHttpRequest();
  		doc2.open("PUT", "file:///tmp/packages_to_delete.txt");
 	  	doc2.send(deletesToBeApplied);
		return true;
	}

	function applyUpdates(ActivateTimer) {
	
		var check1 = writeUpdatesToBeApplied();
		var check2 = writeDeletesToBeApplied();
		if (check1 || check2) {		
			writeTSCscriptCommand();
		}
	}
	

	function readToonSoftwareVersion() {
	    	var resultTekst = toonConfig.read();
	    	if (resultTekst.search( "Version:" ) == -1 ) {
			resultTekst = toonConfigUni.read();
			if (resultTekst.search( "Version:" ) == -1 ) {
				resultTekst = toonConfigNxt.read();
	    		}
	    	}
		var i = resultTekst.indexOf("Version:");
		var j = resultTekst.indexOf("-", i);
		toonSoftwareVersion = resultTekst.substring(i+9, j);
	}

	function updateRepoInfo() {
		
		readOldRepoInfo();

		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					toonstoreDataRead = true;
					repoDataAll = xmlhttp.responseText;
					toonstoreUpdated();
					var now = new Date().getTime();
					repoRefreshDateTime = "Bijgewerkt: " + i18n.dateTime(now,i18n.time_yes + i18n.mon_full);
				}
			}
		}
		xmlhttp.open("GET", "https://raw.githubusercontent.com/ToonSoftwareCollective/toonstore_AppRepository/" + activeRepoBranch + "/ToonRepo.xml", true);
		xmlhttp.send();
	}

	function updateRepoInfoAndUpdate() {
		updateRepoInfo();
  		if (writeAutoUpdatesToBeApplied()) {
			writeTSCscriptCommand();
		}
	}

	Component.onCompleted: {
		initToonstore();
	}

	function initToonstore() {

		readToonSoftwareVersion();

		// read user settings

		try {
			toonstoreSettingsJson = JSON.parse(toonstoreSettingsFile.read());
			showStoreIcon = (toonstoreSettingsJson['showStoreIcon'] == "true");
			autoUpdate = (toonstoreSettingsJson['autoUpdate'] == "true");		
			autoUpdateTime = toonstoreSettingsJson['autoUpdateTime'];
			if (autoUpdate) {
				activateUpdateTimer();
			}
			if (toonstoreSettingsJson['sendNotificationOfNewApps']) sendNotificationOfNewApps = (toonstoreSettingsJson['sendNotificationOfNewApps'] == "true");
			if (toonstoreSettingsJson['sendNotificationOfNewAppVersions']) sendNotificationOfNewAppVersions = (toonstoreSettingsJson['sendNotificationOfNewAppVersions'] == "true");
		} catch(e) {
		}

		readOldRepoInfo();

		updatesToBeApplied = "";
		autoUpdatesToBeApplied = "";
		deletesToBeApplied = "";
		installedApps = qmlDir.dirEntries;
		updateRepoInfo();
	}
	
	function readOldRepoInfo() {

		// read old RepoInfo

		try {
			var toonstoreOldRepoInfoJson = JSON.parse(toonstoreOldRepoInfoFile.read());
			namesOldRepo = toonstoreOldRepoInfoJson['names'];
			versionsOldRepo = toonstoreOldRepoInfoJson['versions'];
		} catch(e) {
		}
	}

	function saveSettings() {
		
		// save user settings

		var tmpTrayIcon = "";
		if (showStoreIcon == true) {
			tmpTrayIcon = "true";
		} else {
			tmpTrayIcon = "false";
		}

		var tmpautoUpdate = "";
		if (autoUpdate == true) {
			tmpautoUpdate = "true";
		} else {
			tmpautoUpdate = "false";
		}

		var tmpNotifications = "";
		if (sendNotificationOfNewApps) {
			tmpNotifications = "true";
		} else {
			tmpNotifications = "false";
		}

		var tmpNotificationsVersions = "";
		if (sendNotificationOfNewAppVersions) {
			tmpNotificationsVersions = "true";
		} else {
			tmpNotificationsVersions = "false";
		}

 		toonstoreSettingsJson = {
			"showStoreIcon" : tmpTrayIcon,
			"autoUpdate" : tmpautoUpdate,
			"autoUpdateTime" : autoUpdateTime,
			"sendNotificationOfNewApps" : tmpNotifications,
			"sendNotificationOfNewAppVersions" : tmpNotificationsVersions
		}

  		var doc3 = new XMLHttpRequest();
   		doc3.open("PUT", "file:///mnt/data/tsc/toonstore.userSettings.json");
   		doc3.send(JSON.stringify(toonstoreSettingsJson ));
	}

	Timer {
		id: autoUpdateTimer
		interval: 999999999
		triggeredOnStart: false
		running: false
		repeat: true
		onTriggered: updateRepoInfoAndUpdate()
	}

	Timer {
		id: updateRepoTimer
		interval: 10800000  //every three hours
		triggeredOnStart: false
		running: true
		repeat: true
		onTriggered: updateRepoInfo()
	}
	
	BxtDiscoveryHandler {
		id : netconDiscoHandler
		deviceType: "hcb_netcon"
		onDiscoReceived: {
			statusNotifyHandler.sourceUuid = deviceUuid;
		}
	}

	BxtNotifyHandler {
		id: statusNotifyHandler
		serviceId: "gwif"
		onNotificationReceived : {
			var address = message.getArgument("ipaddress");
			if (address) {
				lanIp = address;
			}
		}
	}
}
