import QtQuick 2.1
import qb.components 1.0
import FileIO 1.0

Rectangle {


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

	function showDialogToonstore2(text) {
			qdialog.showDialog(qdialog.SizeLarge, "ToonStore mededeling", text , "Sluiten");
	}

	FileIO {
		id: appVersionTxt
	}

	function showChangelog() {
	
		app.delegateChangelog = "\n\n\n\n\n\n\n          Ophalen changelog ......";
		app.delegateChangelogTitle = "Nieuwe functies " + name;
		app.delegateChangelogScreenshots = parseInt(screenshots);
		app.screenshotURLchunk = folder + "_screenshot_";
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
		xmlhttp.open("GET", "https://raw.githubusercontent.com/ToonSoftwareCollective/" + folder + "/main/Changelog.txt", true);
		xmlhttp.send();
	}

	function getInstalledStatus() {
		return (app.installedApps.indexOf(folder) > 0 );
	}

	function getInstalledVersion() {
		appVersionTxt.source = "file:///qmf/qml/apps/" + folder + "/version.txt";
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
		if (app.autoUpdatesToBeApplied.indexOf(searchStr) > 0) {
			// should not happen
			console.log("*********** Error in toonstore - package to add (AutoUpdates) already present in string")
		} else {
			if (skipautoupdate == "no") {
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
				addToAutoUpdates(folder + "-" + version);
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

			// check Toon model compatibility

		if (!isNxt && toon2only == "yes") {
			return false;
		}

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
	color: validateVersion(firmwareminimum, firmwaremaximum, app.toonSoftwareVersion, "yes") ? "white" : "transparent"

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
		text: getToBeDownloaded(folder + "-" + version)
		anchors.baseline: parent.top
		anchors.baselineOffset: isNxt ? 38 : 30
		anchors.right: parent.right
		visible: false
	}

	Text {
		id:tobeDeleted
		text: getToBeDeleted(folder + "-" + version)
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
		state: getDeleteButtonStatus(folder + "-" + version)
		onClicked: {
			if (tobeDeleted.text === "0") {
				deleteButton.state = "up";
				addToDeletes(folder + "-" + version);
				downloadButton.state = "down";
				removeFromUpdates(folder + "-" + version);
			} else {			
				deleteButton.state = "down";
				removeFromDeletes(folder + "-" + version);
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
		state: getUpdateButtonStatus(folder + "-" + version)
		onClicked: {
			if (validateVersion(firmwareminimum, firmwaremaximum, app.toonSoftwareVersion, "yes")) {
				if (tobeDownloaded.text === "0") {
					downloadButton.state = "up";
					addToUpdates(folder + "-" + version);
					deleteButton.state = "down";
					removeFromDeletes(folder + "-" + version);
				} else {			
					downloadButton.state = "down";
					removeFromUpdates(folder + "-" + version);
				}
			} else {
				downloadButton.state = "down";
				if (!isNxt && toon2only == "yes") {
					showDialogToonstore2("Deze applicatie " + name + " is niet geschikt voor het oude model Toon.");
				} else {
					showDialogToonstore2("Deze applicatie " + name + " is niet geschikt voor de software versie " + app.toonSoftwareVersion + " van uw Toon.");
				}
			}			
		}
	}
}
