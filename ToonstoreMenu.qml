import QtQuick 2.1

import qb.components 1.0
import qb.base 1.0

MenuItem {
	property ToonstoreApp app;
	label: "ToonStore"
	image: "qrc:/tsc/repo.png"
	weight: 200

	onClicked: {
		if (app) {
			if (app.toonstoreScreen) app.toonstoreScreen.show();
		}
	}
}