/*
 	Description:
		Add the nearest enemy zone to a list of locations from which potential targets for reinforcements will be picked

	Parameters:
		0: ARRAY - Location, in most cases from the corpse of a deceased soldier

 	Returns:
		Nothing

 	Example:
		[getPos _corpse] call AS_fnc_signalDistress;
*/

params ["_location"];
private ["_zone"];

_zone = [mrkAAF, _location] call BIS_fnc_nearestPosition;

if (_location distance2D (getMarkerPos _zone) < VCOM_Unit_AIWarnDistance) then {
	distressCalls pushBack _zone;
	diag_log format ["Distress signal from %1 near %2 was sent at %3", _location, _zone, diag_tickTime];
};