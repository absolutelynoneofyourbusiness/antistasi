params ["_location"];
private ["_zone"];

_zone = [mrkAAF, _location] call BIS_fnc_nearestPosition;

if (_location distance2D (getMarkerPos _zone) < VCOM_Unit_AIWarnDistance) then {
	distressCalls pushBack _zone;
	systemChat format ["Distress signal from %1 near %2 was sent at %3", _location, _zone, diag_tickTime];
};