import QtQuick 2.1

import qb.base 1.0
import qb.components 1.0

Popup {
	id: imageGallery

	state: "dialogPopup"

	states: [
		State {
			name: "dialogPopup"
			PropertyChanges { target: closeBtn; overlayWhenUp: false}
			PropertyChanges { target: closeBtn; colorDown: "#ffffff"}
			PropertyChanges { target: closeBtn; overlayColorDown: "#565656"}
		},
		State {
			name: "transparentPopup"
			PropertyChanges { target: closeBtn; overlayWhenUp: true}
			PropertyChanges { target: closeBtn; overlayColorUp: "#ffffff"}
			PropertyChanges { target: imageSelector;  dotColor: "#ffffff"}
			PropertyChanges { target: imageSelector;  arrowOverlayWhenUp: true}
			PropertyChanges { target: imageSelector;  arrowOverlayColorUp: "#ffffff"}
			PropertyChanges { target: imageSelector;  arrowColorDown: "#565656"}
			PropertyChanges { target: imageSelector;  arrowOverlayColorDown: "#ffffff"}
		}
	]

	QtObject {
		id: p
		property int pageOffsetNavigator: 0
		property int currentPage: 0
		property int numberOfImages: app.delegateChangelogScreenshots 
	}

	onShown: {
		imageSelector.currentPage = 0;
		imageSelector.navigate(0);
		navigatePage(0);
	}

	onHidden: {
		state = "dialogPopup";
		gallery.source = "";
	}


	function navigatePage(page) {
		p.currentPage = page;
		if (app.testMode) {
			gallery.source = "https://raw.githubusercontent.com/ToonSoftwareCollective/toonstore_AppRepository/test/" + app.screenshotURLchunk + (p.currentPage + 1) + ".png";
		} else {
			gallery.source = "https://raw.githubusercontent.com/ToonSoftwareCollective/toonstore_AppRepository/main/" + app.screenshotURLchunk + (p.currentPage + 1) + ".png";
		}
		if (page < p.pageOffsetNavigator) {
			imageSelector.visible = false;
		} else {
			imageSelector.visible = imageSelector.pageCount > 1 ? true : false;
			imageSelector.leftArrowVisible = page > p.pageOffsetNavigator;
			imageSelector.rightArrowVisible = page < p.numberOfImages - 1;
		}
	}

	MouseArea {
		anchors.fill: parent
		property string kpiPostfix: "greyArea"
	}

	Item {
		anchors.fill: parent
		Image {
			id: gallery
			anchors.fill: parent
			cache: false
		}
	}

	Rectangle {
		id: selectorBackgroundRect
		height: 40
		width: 530

		anchors {
			bottom: parent.bottom
			left: imageSelector.left
			leftMargin: -5
		}
		color: "#999999"
	}

	DottedSelector {
		id: imageSelector
		width: 488

		anchors {
			horizontalCenter: parent.horizontalCenter
			bottom: parent.bottom
		}

		arrowColorUp: "transparent"
		pageCount: p.numberOfImages - p.pageOffsetNavigator
		onNavigate: navigatePage(page + p.pageOffsetNavigator)
	}

	IconButton {
		id: closeBtn
		width: 45
		height: 45

		anchors.left: selectorBackgroundRect.right
		anchors.leftMargin: -45
		anchors.top: selectorBackgroundRect.top
		anchors.topMargin: -5
		iconSource: "qrc:/tsc/DialogCross.png"

		leftClickMargin: 5
		rightClickMargin: 5
		topClickMargin: 5
		bottomClickMargin: 5

//		useShadow: false
		colorUp: "transparent"

		onClicked: {
			hide();
		}
	}
}
