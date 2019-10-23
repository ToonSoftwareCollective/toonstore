import QtQuick 2.1
import qb.components 1.0

Screen {
	id: toonstoreDelegateChangelog
	screenTitle: "Nieuwe functies"
	property int screenshotSeq : 0
	property Popup imageGalleryPopup

	onCustomButtonClicked: {
		hide();
		if (app.toonstoreScreen) app.toonstoreScreen.show();
	}

	onShown: {
		addCustomTopRightButton("Terug");
		screenTitle = app.delegateChangelogTitle;
		btnScreenshots.visible = (app.delegateChangelogScreenshots !== 0);
	}

	StandardButton {
		id: btnScreenshots
		width: isNxt ? 200 : 150
		text: "Screenshots(" + app.delegateChangelogScreenshots + ")"
 		anchors {
			baseline: parent.top
			baselineOffset: isNxt ? 13 : 10
			left: parent.left
			leftMargin: isNxt ? 25 : 20
		}
		leftClickMargin: 3
		bottomClickMargin: 5
		onClicked: {
			app.toonstoreDelegateGalleryPopup.state = "dialogPopup";
			app.toonstoreDelegateGalleryPopup.show();
		}
	}

	Rectangle {
		id: changelogRect
		height: isNxt ? 482 : 385
		width: isNxt ? 998 : 780
		anchors {
			baseline: parent.top
			baselineOffset: isNxt ? 88 : 70
			left: parent.left
			leftMargin: isNxt ? 13 : 10
		}
		color: colors.addDeviceBackgroundRectangle

	       Flickable {
	            id: flickArea
	             anchors.fill: parent
	             contentWidth: changelogRect.width;
			contentHeight: changelogRect.height
	             flickableDirection: Flickable.VerticalFlick
	             clip: true

	             TextEdit{
	                  id: forecastText
	                   wrapMode: TextEdit.Wrap
	                   width:changelogRect.width;
	                   readOnly:true
				font {
					family: qfont.regular.name
					pixelSize: isNxt ? 18 : 15
				}

	                   text:  app.delegateChangelog
	            }
	      }
	}
}
