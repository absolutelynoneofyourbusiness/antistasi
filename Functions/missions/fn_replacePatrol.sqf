params [
	"_group",
	["_homeZone", "", [""]],
	["_groupType", infTeam],
	["_maxSpread", 400, [0]],
	["_forceRTB", false, [true]],
	["_maxDistance", 1000, [0]],
	["_markerPos", []],
	["_endTime", diag_tickTime],
	["_base", ""],
	["_transportData", []]
];

if (_homeZone isEqualTo "") exitWith {format ["Error in replacePatrol, group %1 did not have a zone attached to it.", _group]};

_markerPos = getMarkerPos _homeZone;
_endTime = diag_tickTime + 3600;
waitUntil {sleep 10; (count ((_markerPos nearEntities [baseClasses_PLAYER, 2000]) select {_x getVariable ["BLUFORSpawn", false]}) < 1) OR {diag_tickTime > _endTime}};

if (diag_tickTime > _endTime) then {
	_base = [_homeZone, "replacement"] call AS_fnc_findBase;
	if !(_base isEqualTo "") then {
		_transportData = [_base, getMarkerPos _homeZone, enemyMotorpoolDef, infSquad, side_green, "patrol", 200, 0, format ["rep_", _homeZone]] call AS_fnc_transportTroops;
		_endTime = diag_tickTime + 1200;
		waitUntil {sleep 5; (missionNamespace getVariable [format ["rep_", _homeZone], false]) OR {(!alive (_transportData select 0))} OR {diag_tickTime > _endTime}};
		if (missionNamespace getVariable [format ["rep_", _homeZone], false]) then {
			[_transportData select 3, _homeZone, _groupType, _maxSpread, _forceRTB, _maxDistance] spawn AS_fnc_monitorGroup;
		};
	};
};