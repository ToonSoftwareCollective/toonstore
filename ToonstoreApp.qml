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
	property string autoUpdateTime
	property SystrayIcon toonstoreTray

	property bool toonstoreDataRead: false
	property bool testMode : false
	property string lanIp: "0.0.0.0"
	property int numberOfAppsSelectedToInstall : 0

	// Toonstore signals, used to update the listview and filter enabled button
	signal toonstoreUpdated()

	// user settings from config file
	property variant toonstoreSettingsJson : {
		'showTrayIcon': "",
		'autoUpdate': "",
		'autoUpdateTime': ""
	}

	FileIO {
		id: toonstoreSettingsFile
		source: "file:///mnt/data/tsc/toonstore.userSettings.json"
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

	// Read list of installed apps
	function readInstalledApps() {
		installedApps = qmlDir.dirEntries;
	}

	// Init the toonstore app by registering the widgets
	function init() {
		registry.registerWidget("screen", fullScreenUrl, this, "toonstoreScreen");
		registry.registerWidget("screen", fullSettingsUrl, this, "toonstoreSettings");
		registry.registerWidget("screen", fullChangelogUrl, this, "toonstoreDelegateChangelog");
		registry.registerWidget("menuItem", null, this, null, {objectName: "toonstoreMenuItem", label: qsTr("ToonStore"), image: toonstoreMenuIconUrl, screenUrl: fullScreenUrl, weight: 120});
		registry.registerWidget("systrayIcon", trayUrl, toonstoreApp);
		registry.registerWidget("popup", toonstoreDelegateGalleryPopupUrl, this, "toonstoreDelegateGalleryPopup");
	}

	function parseToonstoreMsg(msg) {

		toonstoreDataRead = true;
		repoDataAll = msg;
		toonstoreUpdated();
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
			datetimeTimerFiles.interval = targetTimer;
			datetimeTimerFiles.running = true;
		} else {
			datetimeTimerFiles.running = false;	
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
	
		var outputstr = "   ";
   		var doc2 = new XMLHttpRequest();
  		doc2.open("PUT", "file:///tmp/packages_to_delete.txt");
 	  	doc2.send(deletesToBeApplied);
		return true;
	}

	function applyUpdates(ActivateTimer) {
	

		//		1. first write packages to be downloaded and deleted
		// 		2. secondly edit host file
		//		3. thirdly call http request

		if (writeUpdatesToBeApplied() || writeDeletesToBeApplied()) {		
			writeTSCscriptCommand();		//valid from 4.16.8 onwards, but app is Firmware 5 compatible only
		}
	}
	
	function applyAutoUpdates() {
	

		//		1. first write packages to be downloaded
		// 		2. secondly edit host file
		//		3. thirdly call http request

  		if (writeAutoUpdatesToBeApplied()) {
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
		
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					parseToonstoreMsg(xmlhttp.responseText);
					var now = new Date().getTime();
					repoRefreshDateTime = "Bijgewerkt: " + i18n.dateTime(now,i18n.time_yes + i18n.mon_full);
				}
			}
		}
		if (testMode) {
			xmlhttp.open("GET", "http://files.domoticaforum.eu/uploads/Toon/apps/ToonRepo_test.xml", true);
		} else {
			xmlhttp.open("GET", "http://files.domoticaforum.eu/uploads/Toon/apps/ToonRepo.xml", true);
		}
		xmlhttp.send();
	}

	function updateRepoInfoAndUpdate() {
		updateRepoInfo();
		writeAutoUpdatesToBeApplied();
		applyAutoUpdates();
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
		} catch(e) {
		}

		updatesToBeApplied = "";
		autoUpdatesToBeApplied = "";
		deletesToBeApplied = "";
		readInstalledApps();
		updateRepoInfo();
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

 		toonstoreSettingsJson = {
			"showStoreIcon" : tmpTrayIcon,
			"autoUpdate" : tmpautoUpdate,
			"autopUpdateTime" : autoUpdateTime
		}

  		var doc3 = new XMLHttpRequest();
   		doc3.open("PUT", "file:///mnt/data/tsc/toonstore.userSettings.json");
   		doc3.send(JSON.stringify(toonstoreSettingsJson ));
	}

	Timer {
		id: datetimeTimerFiles
		interval: 86400000
		triggeredOnStart: false
		running: false
		repeat: true
		onTriggered: updateRepoInfoAndUpdate()
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
