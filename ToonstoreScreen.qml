import QtQuick 2.1
import SimpleXmlListModel 1.0
import qb.components 1.0
import BasicUIControls 1.0
import FileIO 1.0

Screen {
	property bool toonstoreLoaded: false
	property string searchFilter: ""
	property bool updatesOnlyFilter: false

	FileIO { id: filterVersionIO }
	ListModel { id: filteredModel }

	function rebuildFilteredModel() {
		filteredModel.clear();

		var items = [];
		for (var i = 0; i < toonstoreModel.count; i++) {
			var e = toonstoreModel.get(i);
			items.push({
				name: e.name,
				version: e.version,
				folder: e.folder,
				description: e.description,
				author: e.author,
				skipautoupdate: e.skipautoupdate,
				firmwareminimum: e.firmwareminimum,
				firmwaremaximum: e.firmwaremaximum,
				screenshots: e.screenshots,
				toon2only: e.toon2only,
				allowdeletion: e.allowdeletion
			});
		}

		items.sort(function(a, b) {
			var na = a.name.toLowerCase();
			var nb = b.name.toLowerCase();
			return na < nb ? -1 : na > nb ? 1 : 0;
		});

		var search = searchFilter.toLowerCase();

		for (var j = 0; j < items.length; j++) {
			var item = items[j];

			if (search !== "" && item.name.toLowerCase().indexOf(search) < 0) continue;

			if (updatesOnlyFilter) {
				if (app.installedApps.indexOf(item.folder) <= 0) continue;
				filterVersionIO.source = "file:///qmf/qml/apps/" + item.folder + "/version.txt";
				var installedVer = filterVersionIO.read().trim();
				if (installedVer === item.version) continue;
			}

			filteredModel.append(item);
		}
	}

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
			rebuildFilteredModel();
			toonstoreSimpleList.initialView();

			if (app.activeRepoBranch == "main" ) {
				checkNewApps();
				saveCurrentRepoInfo();
			}

		} else {
			noJamsText.visible = true;
			noJamsText.text = "Geen apps in ToonStore";
		}
		toonstoreLoaded = true;

		// Update the header text
		headerText.text = getHeaderText();
	}

	onSearchFilterChanged: {
		rebuildFilteredModel();
		toonstoreSimpleList.initialView();
		headerText.text = getHeaderText();
	}

	onUpdatesOnlyFilterChanged: {
		rebuildFilteredModel();
		toonstoreSimpleList.initialView();
		headerText.text = getHeaderText();
	}

	// Function creates the header text using the correct XML nodes
	function getHeaderText() {
		var str = filteredModel.count + " Apps in de ToonStore. ";
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

	function checkNewApps() {

		for (var i = 0; i < toonstoreModel.count; i++) {
			var j = app.namesOldRepo.indexOf(toonstoreModel.get(i).folder);
			if (j < 0) {
				if (app.sendNotificationOfNewApps) app.sendNotification("Er is een nieuwe app beschikbaar in de ToonStore: " + toonstoreModel.get(i).name);
			} else {
				if (app.versionsOldRepo[j] !== toonstoreModel.get(i).version) {
					if (app.installedApps.indexOf(toonstoreModel.get(i).folder) > 0) {
						if (!app.autoUpdate) {
							if (app.sendNotificationOfNewAppVersions) app.sendNotification("Er is een update van de app " + toonstoreModel.get(i).name + " beschikbaar in de ToonStore.");
						}
					}
				}
			}
		}
	}

	function saveCurrentRepoInfo() {

		var tmpRepoInfoNames = "";
		var tmpRepoInfoVersions = "";
		var j = toonstoreModel.count - 1;
		for (var i = 0; i < toonstoreModel.count; i++) {
			if ( i == j) {
				tmpRepoInfoNames = tmpRepoInfoNames + '"' + toonstoreModel.get(i).folder + '"';
				tmpRepoInfoVersions = tmpRepoInfoVersions + '"' + toonstoreModel.get(i).version + '"';
			} else {
				tmpRepoInfoNames = tmpRepoInfoNames + '"' + toonstoreModel.get(i).folder + '",';
				tmpRepoInfoVersions = tmpRepoInfoVersions + '"' + toonstoreModel.get(i).version + '",';
			}
		}
		var tmpRepoInfo = '{"names":[' + tmpRepoInfoNames + '],';
		var tmpRepoInfo = tmpRepoInfo + '"versions":[' + tmpRepoInfoVersions + ']}';
  		var doc3 = new XMLHttpRequest();
   		doc3.open("PUT", "file:///mnt/data/tsc/toonstore.oldRepoInfo.json");
		doc3.onreadystatechange=function() {
			if (doc3.readyState == 4) {
				app.readOldRepoInfo();
			}
		}

   		doc3.send(tmpRepoInfo);

	}

	function footerText() {
		if (app.activeRepoBranch == "main" ) {
			return "Bron: github.com/ToonSoftwareCollective";
		}
		if (app.activeRepoBranch == "test" ) {
			return "Bron: test repository !!";
		}
		if (app.activeRepoBranch == "dev" ) {
			return "Bron: dev repository !!";
		}
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

	function toggleBranch() {
		if (app.activeRepoBranch == "main") {
			app.activeRepoBranch = "test"
		} else {
			if (app.activeRepoBranch == "test") {
				app.activeRepoBranch = "dev"
			} else {
				app.activeRepoBranch = "main"
			}
		}
		app.updateRepoInfo();
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

	Item {
		id: filterRow
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76
		height: isNxt ? 36 : 28
		y: isNxt ? 64 : 51

		Text {
			id: searchLabel
			text: "Zoek:"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 20 : 16
			anchors {
				left: parent.left
				verticalCenter: parent.verticalCenter
			}
		}

		Rectangle {
			id: searchBox
			height: isNxt ? 30 : 24
			width: isNxt ? 320 : 250
			border.color: "#999999"
			border.width: 1
			radius: 3
			anchors {
				left: searchLabel.right
				leftMargin: isNxt ? 8 : 6
				verticalCenter: parent.verticalCenter
			}

			MouseArea {
				anchors.fill: parent
				onClicked: searchInput.forceActiveFocus()
			}

			TextInput {
				id: searchInput
				anchors {
					fill: parent
					leftMargin: 6
					rightMargin: 6
				}
				verticalAlignment: TextInput.AlignVCenter
				font.family: qfont.italic.name
				font.pixelSize: isNxt ? 18 : 14
				onTextChanged: searchFilter = text
			}
		}

		Rectangle {
			id: btnUpdatesOnly
			width: isNxt ? 210 : 170
			height: isNxt ? 30 : 24
			border.color: "#666666"
			border.width: 1
			radius: 3
			color: updatesOnlyFilter ? "#689F38" : "#e0e0e0"
			anchors {
				right: parent.right
				verticalCenter: parent.verticalCenter
			}

			Text {
				anchors.centerIn: parent
				text: "Alleen updates"
				font.family: qfont.semiBold.name
				font.pixelSize: isNxt ? 16 : 13
				color: updatesOnlyFilter ? "white" : "#333333"
			}

			MouseArea {
				anchors.fill: parent
				onClicked: updatesOnlyFilter = !updatesOnlyFilter
			}
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
			toon2only: "string",
			allowdeletion: "string"
		})
	}

	Rectangle {
		id: content
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76
		height: isNxt ? parent.height - 135 : parent.height - 107
		y: isNxt ? 104 : 83
		radius: 3

		ToonstoreSimpleList {
			id: toonstoreSimpleList
			delegate: ToonstoreDelegate{}
			dataModel: filteredModel
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
		text: footerText()
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
		id: btnToggleBranch;
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
		onClicked: toggleBranch();
	}
}
