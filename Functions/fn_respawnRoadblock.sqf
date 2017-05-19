/*
 	Description:
		Respawns a cleared roadblock after a certain period if the nearest zone is still under enemy control

	Parameters:
		0: STRING - Name of the roadblock
		1: INTEGER (optional) - specific delay in minutes

 	Returns:
		None

 	Example:
		["control_18", 71] spawn AS_fnc_respawnRoadblock;
*/

params [
	"_marker",
	["_remainingTime", 0, [1]]
];
private ["_markerPos", "_respawnTime", "_nearestLocation"];

#define DELAY 120

_markerPos = getMarkerPos (_marker);

if (_remainingTime == 0) then {
	_respawnTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + DELAY];
	_respawnTime = dateToNumber _respawnTime;
} else {
	_respawnTime = _remainingTime
};

{
	if ((_x select 0) == _marker) then {
		respawningRBs set [_forEachIndex, -1];
	};
} forEach respawningRBs;
respawningRBs = respawningRBs - [-1];
respawningRBs pushBack [_marker, _respawnTime];

diag_log format ["respawn marker set: %1", respawningRBs];

waitUntil {sleep 60; (dateToNumber date > _respawnTime)};
_nearestLocation = [marcadores,_markerPos] call BIS_fnc_nearestPosition;

if (_nearestLocation in mrkAAF) then {
	mrkAAF = mrkAAF + [_marker];
	mrkFIA = mrkFIA - [_marker];
	publicVariable "mrkAAF";
	publicVariable "mrkFIA";

	waitUntil {sleep 3; !([distanciaSPWN,1,_markerPos,"BLUFORSpawn"] call distanceUnits)};

	[_marker] call AS_fnc_respawnZone;
};

{
	if ((_x select 0) == _marker) then {
		respawningRBs set [_forEachIndex, -1];
	};
} forEach respawningRBs;
respawningRBs = respawningRBs - [-1];