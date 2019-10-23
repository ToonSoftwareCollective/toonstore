import QtQuick 2.1
import qb.components 1.0
import FileIO 1.0

Rectangle {

	property string folderStripped

	// Create the app description with the corrosponding XML nodes. Nodes are named in the ToonstoreScreen.qml
	function getDescription() {
		var str = "App: " + name;
		if (getInstalledStatus()) {
			str = str + ". Ge\u00EFnstalleerde versie: " + getInstalledVersion();
			str = str + ". " + description + ", door " + author + ".";
		} else {
			str = str + ". " + description + ", door " + author + ".";
		}
		return str;
	}

	function showDialogToonstore() {
		if (!app.dialogShown) {
			qdialog.showDialog(qdialog.SizeLarge, "ToonStore mededeling", "Alle wijzigingen in applicaties (toevoegen en/of verwijderen) worden pas geactiveerd als U op de knop 'Toon Bijwerken' heeft gedrukt, rechtsboven op het scherm.\nHierna zullen de gevraagde applicaties worden gedownload waarna de Toon zal herstarten om de wijzigingen te activeren. Hiervoor hoeft U zelf niets meer te doen.", "Sluiten");
			app.dialogShown = true;
		}
	}

	function showDialogToonstore2() {
			qdialog.showDialog(qdialog.SizeLarge, "ToonStore mededeling", "Deze applicatie " + name + " is niet geschikt voor de software versie " + app.toonSoftwareVersion + " van uw Toon.", "Sluiten");
	}

	FileIO {
		id: appVersionTxt
	}

	function showChangelog(foldername) {
	
		app.delegateChangelog = "\n\n\n\n\n\n\n          Ophalen changelog ......";
		app.delegateChangelogTitle = "Nieuwe functies " + name;
		app.delegateChangelogScreenshots = parseInt(screenshots);
		app.screenshotURLchunk = folder + "/" + folderStripped + "_screenshot_";
		stage.navigateHome();
		app.toonstoreDelegateChangelog.show();

		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var tmpTxt = xmlhttp.responseText;
					app.delegateChangelog = tmpTxt.replace("\r\n","\n");
				}
			}
		}
		xmlhttp.open("GET", "http://files.domoticaforum.eu/uploads/Toon/apps/" + foldername + "/Changelog.txt", true);
		xmlhttp.send();
	}

	function getInstalledStatus() {
		var findMinus = folder.indexOf("-");
		if (findMinus > 0) {
			folderStripped = folder.substring(0, findMinus);
		} else {
			folderStripped = folder;
		}
		return (app.installedApps.indexOf(folderStripped) > 0 );
	}

	function getInstalledVersion() {
		var findMinus = folder.indexOf("-");
		if (findMinus > 0) {
			folderStripped = folder.substring(0, findMinus);
		} else {
			folderStripped = folder;
		}
//		var temp = "file:///qmf/qml/apps/" + folderStripped + "/version.txt"
		appVersionTxt.source = "file:///qmf/qml/apps/" + folderStripped + "/version.txt";
		var versionStr = appVersionTxt.read();
		return versionStr.trim();
	}

	function addToUpdates(packageName) {
		showDialogToonstore();
		var searchStr = packageName;
		if (app.updatesToBeApplied.indexOf(searchStr) > 0) {
			// should not happen
			console.log("*********** Error in toonstore - package to add (Updates) already present in string")
		} else {
			app.updatesToBeApplied = packageName + " " +  app.updatesToBeApplied;
			app.numberOfAppsSelectedToInstall = app.numberOfAppsSelectedToInstall + 1;
			app.toonstoreScreen.updateInstallButton();
		}
	}

	function addToAutoUpdates(packageName) {
		var searchStr = packageName;
		console.log("**********" + skipautoupdate + "-" + packageName + "-" + app.autoUpdatesToBeApplied.indexOf(searchStr));
		if (app.autoUpdatesToBeApplied.indexOf(searchStr) > 0) {
			// should not happen
			console.log("*********** Error in toonstore - package to add (AutoUpdates) already present in string")
		} else {
			if (skipautoupdate == "no") {
				console.log("********** adding:" + packageName + " to autoUpdates");
				app.autoUpdatesToBeApplied = packageName + " " +  app.autoUpdatesToBeApplied;
			}
		}
	}

	function addToDeletes(packageName) {
		showDialogToonstore();
		var searchStr = packageName.substring(1,100);
		if (app.deletesToBeApplied.indexOf(searchStr) > 0) {
			// should not happen
			console.log("*********** Error in toonstore - package to add (Deletes) already present in string")
		} else {
			app.deletesToBeApplied = packageName + " " +  app.deletesToBeApplied;
			app.numberOfAppsSelectedToInstall = app.numberOfAppsSelectedToInstall -1;
			app.toonstoreScreen.updateInstallButton();

		}
	}

	function removeFromUpdates(packageName) {
		if (app.updatesToBeApplied.indexOf(packageName) < 0) {
			// should not happen
			console.log("*********** Error in toonstore - package to remove (from Updates) not present in string")
		} else {
			var newList = app.updatesToBeApplied.replace(packageName, "");
			app.updatesToBeApplied = newList;
			app.numberOfAppsSelectedToInstall = app.numberOfAppsSelectedToInstall - 1;
			app.toonstoreScreen.updateInstallButton();
		}
	}

	function removeFromDeletes(packageName) {
		if (app.deletesToBeApplied.indexOf(packageName) < 0) {
			// should not happen
			console.log("*********** Error in toonstore - package to remove (from Deletes) not present in string")
		} else {
			var newList = app.deletesToBeApplied.replace(packageName, "");
			app.deletesToBeApplied = newList;
			app.numberOfAppsSelectedToInstall = app.numberOfAppsSelectedToInstall + 1;
			app.toonstoreScreen.updateInstallButton();

		}
	}

	function getToBeDownloaded(packageName) {
		if (app.updatesToBeApplied.indexOf(packageName) < 0) {
			return "0";
		} else {
			return "1";
		}
	}

	function getToBeDeleted(packageName) {
		if (app.deletesToBeApplied.indexOf(packageName) < 0) {
			return "0";
		} else {
			return "1";
		}
	}

	function getUpdateButtonStatus(packageName) {
		if (app.updatesToBeApplied.indexOf(packageName) < 0) {
			return "down";
		} else {
			return "up";
		}
	}


	function getDeleteButtonStatus(packageName) {
		if (app.deletesToBeApplied.indexOf(packageName) < 0) {
			return "down";
		} else {
			return "up";
		}
	}


	function getInstalledLabel() {
		if (getInstalledStatus()) {
			if (!validateVersion("0.0.0", getInstalledVersion(), version, "no")) {
				deleteButton.visible = true;
				if (allowdeletion == "no") {
					deleteButton.visible = false;
				}
				downloadButton.visible = true;
				addToAutoUpdates(packagename);
				return "Nieuwe versie:";
			} else {
				deleteButton.visible = true;
				if (folder.substring(0,9) == "toonstore") {
					deleteButton.visible = false;
				}
				downloadButton.visible = false;
				return "Ge\u00EFnstalleerd:";
			}
		} else {
			deleteButton.visible = false;
			downloadButton.visible = true;
			return "Beschikbaar:";
		}
	}

	function getInstalledColor() {
		if (getInstalledStatus()) {
			if (!validateVersion("0.0.0", getInstalledVersion(), version, "no")) {
				return "#CC3300";
			} else {
				return "#689F38";
			}
		} else {
			return "#CC3300";
		}
	}	

	function validateVersion(minstr, maxstr, compstr, newonly) {
		var minfw = minstr.split(".");
		var maxfw = maxstr.split(".");
		var actfw = compstr.split(".");
		var result = true;

			//Check minimum version		

		if (parseInt(minfw[0]) > parseInt(actfw[0])) {
			result = false;
		} else {
			if (parseInt(minfw[0]) == parseInt(actfw[0])) {
				if (parseInt(minfw[1]) > parseInt(actfw[1])) {
					result = false;
				} else {
					if (parseInt(minfw[1]) == parseInt(actfw[1])) {
						if (parseInt(minfw[2]) > parseInt(actfw[2])) {
							result = false;
						}
					}
				}
			}
		}

		if (result) {

			//Check maximum version		

			if (parseInt(maxfw[0]) < parseInt(actfw[0])) {
				result = false;
			} else {
				if (parseInt(maxfw[0]) == parseInt(actfw[0])) {
					if (parseInt(maxfw[1]) < parseInt(actfw[1])) {
						result = false;
					} else {
						if (parseInt(maxfw[1]) == parseInt(actfw[1])) {
							if (parseInt(maxfw[2]) < parseInt(actfw[2])) {
								result = false;
							} else {
								if (newonly == "yes") {
									if (parseInt(maxfw[2]) == parseInt(actfw[2])) {
										result = false;
									}
								}
							}
						}
					}
				}
			}
		}

		return result;
	}


	width: isNxt ? 870 : 646
	height: isNxt ? 94 : 73
//	color: colors.background

	Text {
		id: roadLabel
		x: isNxt ? 13 : 10
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 30 : 24
		text: getInstalledLabel()
		color: getInstalledColor()
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 23 : 18
	}

	Text {
		anchors.left: roadLabel.right
		anchors.leftMargin: isNxt ? 6 : 5
		anchors.bottom: roadLabel.bottom
		text: name
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 23 : 18	}

	Text {
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 30 : 24
		anchors.right: btnChangelog.left
		anchors.rightMargin: 10
		text: version
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 23 : 18
	}

	Text {
		id:descriptionLabel
		x: isNxt ? 13 : 10
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 54 : 43
		width: isNxt ? parent.width - 137 : parent.width - 110
		text: getDescription()
		wrapMode: Text.WordWrap
		maximumLineCount: 2
		elide: Text.ElideRight
		lineHeight: 0.8
		font.family: qfont.italic.name
		font.pixelSize: isNxt ? 18 : 15
	}

	Text {
		id:tobeDownloaded
		text: getToBeDownloaded(packagename)
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 38 : 30
		anchors.right: parent.right
		visible: false
	}

	Text {
		id:tobeDeleted
		text: getToBeDeleted(packagename)
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 38 : 30
		anchors.right: parent.right
		visible: false
	}

	StandardButton {
		id: btnChangelog
		width: isNxt ? 45 : 36
		height: isNxt ? 38 : 30
		text: "?"
		anchors.right: parent.right
		anchors.bottom: deleteButton.top
		anchors.bottomMargin : 3
		anchors.rightMargin: 10
		leftClickMargin: 3
		bottomClickMargin: 5
		onClicked: {
			showChangelog(folder);
		}
	}

	IconButton {
		id: deleteButton
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 45 : 36
		anchors.right: parent.right
		anchors.rightMargin: 10
		leftClickMargin: 3
		bottomClickMargin: 5
		iconSource: "qrc:/tsc/minus.png"
		state: getDeleteButtonStatus(packagename)
		onClicked: {
			if (tobeDeleted.text === "0") {
				deleteButton.state = "up";
				addToDeletes(packagename);
				downloadButton.state = "down";
				removeFromUpdates(packagename);
			} else {			
				deleteButton.state = "down";
				removeFromDeletes(packagename);
			}
		}
	}

	IconButton {
		id: downloadButton
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 45 : 36
		anchors.right: parent.right
		anchors.rightMargin: isNxt ? 63 : 50
		leftClickMargin: 3
		bottomClickMargin: 5
		iconSource: validateVersion(firmwareminimum, firmwaremaximum, app.toonSoftwareVersion, "yes") ? "qrc:/tsc/plus.png" : "qrc:/tsc/bad_small.png"
		state: getUpdateButtonStatus(packagename)
		onClicked: {
			if (validateVersion(firmwareminimum, firmwaremaximum, app.toonSoftwareVersion, "yes")) {
				if (tobeDownloaded.text === "0") {
					downloadButton.state = "up";
					addToUpdates(packagename);
					deleteButton.state = "down";
					removeFromDeletes(packagename);
				} else {			
					downloadButton.state = "down";
					removeFromUpdates(packagename);
				}
			} else {
				downloadButton.state = "down";
				showDialogToonstore2();
			}			
		}
	}
}
