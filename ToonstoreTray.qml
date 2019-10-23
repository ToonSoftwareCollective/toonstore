import QtQuick 2.1

import qb.components 1.0
import qb.base 1.0

SystrayIcon {
	id: toonstoreSystrayIcon
	
	property string objectName: "toonstoreSystrayIcon"

	visible: app.showStoreIcon
	posIndex: 9000

	onClicked: {
		if (app.toonstoreScreen) app.toonstoreScreen.show();
	}

	Image {
		id: imgtoonstore
		anchors.centerIn: parent
		source: "qrc:/tsc/repo.png"
	}
}
