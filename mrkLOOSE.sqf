if (!isServer) exitWith {};

params ["_marker"];
private ["_markerPos","_flag","_distance","_mrk","_staticsToSave"];

if (_marker in mrkAAF) exitWith {};
_markerPos = getMarkerPos _marker;

mrkAAF = mrkAAF + [_marker];
mrkFIA = mrkFIA - [_marker];
publicVariable "mrkAAF";
publicVariable "mrkFIA";

// BE module
if (activeBE) then {
	["territory", -1] remoteExec ["fnc_BE_update", 2];
};
// BE module

garrison setVariable [_marker,[],true];

_flag = objNull;
_distance = 10;
while {isNull _flag} do {
	_distance = _distance + 10;
	_flag = (nearestObjects [_markerPos, ["FlagCarrier"], _distance]) select 0;
};

[_flag,"take"] remoteExec ["AS_fnc_addActionMP"];

_mrk = format ["Dum%1",_marker];
_mrk setMarkerColor IND_marker_colour;

call {
	if (_marker in puestos) exitWith {
		_mrk setMarkerText "AAF Outpost";
		[10,-10,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		["TaskFailed", ["", "Outpost Lost"]] remoteExec ["BIS_fnc_showNotification"];
	};

	if (_marker in puertos) exitWith {
		_mrk setMarkerText "Sea Port";
		[10,-10,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		["TaskFailed", ["", "Sea Port Lost"]] remoteExec ["BIS_fnc_showNotification"];
	};

	if (_marker in power) exitWith {
		[0,-5] remoteExec ["prestige",2];
		_mrk setMarkerText "Power Plant";
		["TaskFailed", ["", "Powerplant Lost"]] remoteExec ["BIS_fnc_showNotification"];
		[_marker] spawn AS_fnc_powerReorg;
	};

	if (_marker in recursos) exitWith {
		[10,-10,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		[0,-10] remoteExec ["prestige",2];
		_mrk setMarkerText "Resource";
		["TaskFailed", ["", "Resource Lost"]] remoteExec ["BIS_fnc_showNotification"];
	};

	if (_marker in fabricas) exitWith {
		[10,-10,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		[0,-10] remoteExec ["prestige",2];
		_mrk setMarkerText "Factory";
		["TaskFailed", ["", "Factory Lost"]] remoteExec ["BIS_fnc_showNotification"];
	};

	if (_marker in (bases+aeropuertos)) exitWith {
		[20,-20,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		_mrk setMarkerType IND_marker_type;
		[0,-10] remoteExec ["prestige",2];
		server setVariable [_marker,dateToNumber date,true];
		[_marker,60] spawn AS_fnc_addTimeForIdle;

		if (_marker in bases) then {
			["TaskFailed", ["", "Base Lost"]] remoteExec ["BIS_fnc_showNotification"];
			_mrk setMarkerText "AAF Base";
			APCAAFmax = APCAAFmax + 2;
	        tanksAAFmax = tanksAAFmax + 1;
		} else {
			["TaskFailed", ["", "Airport Lost"]] remoteExec ["BIS_fnc_showNotification"];
			_mrk setMarkerText "AAF Airport";
			server setVariable [_marker,dateToNumber date,true];
			planesAAFmax = planesAAFmax + 1;
	        helisAAFmax = helisAAFmax + 2;
	    };
	};
};

_size = [_marker] call sizeMarker;

_staticsToSave = staticsToSave;
{
	if ((position _x) distance _markerPos < _size) then {
		_staticsToSave = _staticsToSave - [_x];
		deleteVehicle _x;
	};
} forEach staticsToSave;

if !(_staticsToSave isEqualTo staticsToSave) then {
	staticsToSave = _staticsToSave;
	publicVariable "staticsToSave";
};

waitUntil {sleep 3; (({_x distance _markerPos < distanciaSPWN} count (allPlayers - hcArray) == 0) AND ({(alive _x)} count ([_size,0,_markerPos,"BLUFORSpawn"] call distanceUnits) == 0)) OR (({!(vehicle _x isKindOf "Air") AND (alive _x) AND (!fleeing _x)} count ([_size,0,_markerPos,"BLUFORSpawn"] call distanceUnits)) > 3*({(alive _x)} count ([_size,0,_markerPos,"OPFORSpawn"] call distanceUnits)))};

call {
	// Clear to respawn zone
	if (({_x distance _markerPos < distanciaSPWN} count (allPlayers - hcArray) == 0) AND ({(alive _x)} count ([_size,0,_markerPos,"BLUFORSpawn"] call distanceUnits) == 0)) then {
		[_marker] call AS_fnc_respawnZone;
	};

	// Zone lost
	if (({!(vehicle _x isKindOf "Air") AND (alive _x) AND (!fleeing _x)} count ([_size,0,_markerPos,"BLUFORSpawn"] call distanceUnits)) > 3*({(alive _x)} count ([_size,0,_markerPos,"OPFORSpawn"] call distanceUnits))) then {
		[_flag] spawn mrkWIN;
	};
};