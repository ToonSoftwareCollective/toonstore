import QtQuick 2.1
import SimpleXmlListModel 1.0
import qb.components 1.0
import BasicUIControls 1.0

Screen {
	// toonstore loading indicator
	property bool toonstoreLoaded: false

	// Function (triggerd by a signal) updates the toonstore list model and the header text
	function updateToonstoreList() {
		if (!app.toonstoreDataRead) {
			noJamsText.visible = true;
			noJamsText.text = "Verbinding met de ToonStore mislukt. Geen Internet verbinding.";
		}
		else if (app.repoDataAll.length > 0) {
			// Update the toonstore list model
			noJamsText.visible = false;
			toonstoreModel.xml = app.repoDataAll;
			toonstoreSimpleList.initialView();
		} else {
			noJamsText.visible = true;
			noJamsText.text = "Geen apps in ToonStore";
		}
		toonstoreLoaded = true;

		// Update the header text
		headerText.text = getHeaderText();
	}

	// Function creates the header text using the correct XML nodes
	function getHeaderText() {
		var str = toonstoreSimpleList.count + " Apps in de ToonStore. ";
		return str;
	}

	anchors.fill: parent
	screenTitleIconUrl: "qrc:/tsc/repo.png"
	screenTitle: "ToonStore"

	Component.onCompleted: {
		app.toonstoreUpdated.connect(updateToonstoreList)
	}

	onShown: {
		updateInstallButton();
		hasBackButton = false;
	}

	function updateInstallButton() {
		if (anythingToUpdate()) {
			addCustomTopRightButton("Toon Bijwerken (" + app.numberOfAppsSelectedToInstall + ")");
		} else {
			addCustomTopRightButton("Terug");
		}	
	}

	onCustomButtonClicked: {
		if (app.numberOfAppsSelectedToInstall > 3) {
			qdialog.showDialog(qdialog.SizeLarge, "ToonStore mededeling", "U kunt niet meer dan drie apps tegelijkertijd installeren", "Sluiten");
		} else {
			if (anythingToUpdate()) {
				qdialog.showDialog(qdialog.SizeLarge, "ToonStore mededeling", "De geselekteerde apps zullen in de achtergrond worden opgehaald en geinstalleerd danwel verwijderd.\nAls alle wijzigingen zijn doorgevoerd zal de Toon automatisch herstarten.", "Sluiten");
				app.applyUpdates("yes");
			}
			hide();	
		}
	}

	function anythingToUpdate() {
		var updates = app.updatesToBeApplied.trim();
		var deletes = app.deletesToBeApplied.trim();
		if ((updates.length > 2) || (deletes.length > 2)) {
			return true;
		} else {
			return false;
		}
	}

	function toggleTestMode() {
		var testMode = app.testMode;
		app.testMode = !testMode;
		app.updateRepoInfo();
		app.readLatestFirmwareVersion();			
	}

	Item {
		id: header
		height: isNxt ? 55 : 45
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76

		Text {
			id: headerText
			text: getHeaderText()
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: header.left
				bottom: parent.bottom
			}
		}

		StandardButton {
			id: btnConfigScreen
			width: isNxt ? 190 : 150
			text: "Instellingen"
			anchors.right: refreshButton.left
			anchors.bottom: parent.bottom
			anchors.rightMargin: 10
			leftClickMargin: 3
			bottomClickMargin: 5
			onClicked: {
				if (app.toonstoreSettings) {
					app.toonstoreSettings.show();
				}
			}
		}

		IconButton {
			id: refreshButton
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			leftClickMargin: 3
			bottomClickMargin: 5
			iconSource: "qrc:/tsc/refresh.svg"
			onClicked: app.updateRepoInfo()
		}
	}


	SimpleXmlListModel {
		id: toonstoreModel
		query: "/repository/app"
		roles: ({
			name: "string",
			version: "string",
			folder: "string",
			description: "string",
			author: "string",
			skipautoupdate : "string",
			firmwareminimum : "string",
			firmwaremaximum : "string",
			screenshots: "string",
			allowdeletion: "string"
		})
	}

	Rectangle {
		id: content
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76
		height: isNxt ? parent.height - 95 : parent.height - 75
		y: isNxt ? 64 : 51
		radius: 3

		ToonstoreSimpleList {
			id: toonstoreSimpleList
			delegate: ToonstoreDelegate{}
			dataModel: toonstoreModel
			itemHeight: isNxt ? 92 : 73
			itemsPerPage: 4
			anchors.top: parent.top
			downIcon: "qrc:/tsc/arrowScrolldown.png"
			buttonsHeight: isNxt ? 180 : 144
			buttonsVisible: true
			scrollbarVisible: true
		}

		Text {
			id: noJamsText
			visible: false
			anchors.centerIn: parent
			font.family: qfont.italic.name
			font.pixelSize: isNxt ? 18 : 15
		}
	}

	Text {
		id: footerleft
		text: app.repoRefreshDateTime
		anchors {
			baseline: parent.bottom
			baselineOffset: -5
			left: parent.left
			leftMargin: 5
		}
		font {
			pixelSize: isNxt ? 18 : 15
			family: qfont.italic.name
		}
	}

	Text {
		id: firmwareText
		text: "Firmware: " + app.toonSoftwareVersion + " / IP:" + app.lanIp
		anchors {
			baseline: parent.bottom
			baselineOffset: -5
			horizontalCenter: parent.horizontalCenter
		}
		font {
			pixelSize: isNxt ? 18 : 15
			family: qfont.italic.name
		}
	}

	Text {
		id: footerRight
		text: app.testMode ? "Bron: test xml !!!!!" : "Bron: github.com/ToonSoftwareCollective"
		anchors {
			baseline: parent.bottom
			baselineOffset: -5
			right: parent.right
			rightMargin: 5
		}
		font {
			pixelSize: isNxt ? 18 : 15
			family: qfont.italic.name
		}
	}

	IconButton {
		id: btnTestMode;
		width: isNxt ? 48 : 38
		height: isNxt ? 63 : 50
		iconSource: ""
		anchors {
			left: parent.left
			top: parent.top
			topMargin: 150
		}
		colorUp : "transparent"
		colorDown : "transparent"
		onClicked: toggleTestMode();
	}
}
