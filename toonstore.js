function updateHour(strHHMM) {
	return parseInt(strHHMM.substring(0,2));
}

function updateMinute(strHHMM) {
	return parseInt(strHHMM.substring(2,4));
}
