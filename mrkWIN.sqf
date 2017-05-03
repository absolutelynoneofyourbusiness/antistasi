params ["_flag"];
private ["_player","_marker","_markerPos","_size","_hostiles","_antenna","_hostileMines"];

_player = objNull;
if (count _this > 1) then {_player = _this select 1};

if ((player != _player) and (!isServer)) exitWith {};

_marker = [marcadores,getPos _flag] call BIS_fnc_nearestPosition;
if (_marker in mrkFIA) exitWith {};
_markerPos = getMarkerPos _marker;
_size = [_marker] call sizeMarker;

if ((!isNull _player) and (captive _player)) exitWith {hint "You cannot Capture the Flag while in Undercover Mode"};

if (!isNull _player) then {
	if (_size > 300) then {_size = 300};
	_hostiles = [];
	{
		if (((side _x == side_green) OR (side _x == side_red)) AND (alive _x) AND !(fleeing _x) AND (_x distance _markerPos < _size)) then {_hostiles pushBack _x};
	} forEach allUnits;
	if (player == _player) then {
		_player playMove "MountSide";
		sleep 8;
		_player playMove "";
		{player reveal _x} forEach _hostiles;
	};
};

if (!isServer) exitWith {};

{
	if (isPlayer _x) then {
		[5,_x] remoteExec ["playerScoreAdd",_x];
		[[_marker], "intelFound.sqf"] remoteExec ["execVM",_x];
		if (captive _x) then {[_x,false] remoteExec ["setCaptive",_x]};
	}
} forEach ([_size,0,_markerPos,"BLUFORSpawn"] call distanceUnits);

spawner setVariable [_marker,false,true];

[_flag,"remove"] remoteExec ["AS_fnc_addActionMP"];
_flag setFlagTexture guer_flag_texture;

sleep 5;
[_flag,"unit"] remoteExec ["AS_fnc_addActionMP"];
[_flag,"vehicle"] remoteExec ["AS_fnc_addActionMP"];
[_flag,"garage"] remoteExec ["AS_fnc_addActionMP"];

_antenna = [antenas,_markerPos] call BIS_fnc_nearestPosition;
if (getPos _antenna distance _markerPos < 100) then {
	[_flag,"jam"] remoteExec ["AS_fnc_addActionMP"];
};

mrkAAF = mrkAAF - [_marker];
mrkFIA = mrkFIA + [_marker];
publicVariable "mrkAAF";
publicVariable "mrkFIA";

reducedGarrisons = reducedGarrisons - [_marker];
publicVariable "reducedGarrisons";

[_marker] call AS_fnc_markerUpdate;
[_marker] remoteExec ["patrolCA",HCattack];

call {
	if (_marker in aeropuertos) exitWith {
		[0,10,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		["TaskSucceeded", ["", "Airport Taken"]] remoteExec ["BIS_fnc_showNotification"];
		[20,10] remoteExec ["prestige",2];
		planesAAFmax = planesAAFmax - 1;
	    helisAAFmax = helisAAFmax - 2;
	   	if (activeBE) then {["con_bas"] remoteExec ["fnc_BE_XP", 2]};
	};

	if (_marker in bases) exitWith {
		[0,10,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		["TaskSucceeded", ["", "Base Taken"]] remoteExec ["BIS_fnc_showNotification"];
		[20,10] remoteExec ["prestige",2];
		APCAAFmax = APCAAFmax - 2;
	    tanksAAFmax = tanksAAFmax - 1;
		_hostileMines = allmines - (detectedMines side_blue);
		if (count _hostileMines > 0) then {
			{
				if (_x distance _pos < 1000) then {side_blue revealMine _x};
			} forEach _hostileMines;
		};
		if (activeBE) then {["con_bas"] remoteExec ["fnc_BE_XP", 2]};
	};

	if (_marker in power) exitWith {
		["TaskSucceeded", ["", "Powerplant Taken"]] remoteExec ["BIS_fnc_showNotification"];
		[0,5] remoteExec ["prestige",2];
		if (activeBE) then {["con_ter"] remoteExec ["fnc_BE_XP", 2]};
		[_marker] call AS_fnc_powerReorg;
	};

	if (_marker in puestos) exitWith {
		["TaskSucceeded", ["", "Outpost Taken"]] remoteExec ["BIS_fnc_showNotification"];
		if (activeBE) then {["con_ter"] remoteExec ["fnc_BE_XP", 2]};
	};

	if (_marker in puertos) exitWith {
		["TaskSucceeded", ["", "Seaport Taken"]] remoteExec ["BIS_fnc_showNotification"];
		[10,10] remoteExec ["prestige",2];
		if (activeBE) then {["con_ter"] remoteExec ["fnc_BE_XP", 2]};
		[_flag,"seaport"] remoteExec ["AS_fnc_addActionMP"];
	};

	if (_marker in (fabricas+recursos)) exitWith {
		if (_marker in fabricas) then {["TaskSucceeded", ["", "Factory Taken"]] remoteExec ["BIS_fnc_showNotification"]};
		if (_marker in recursos) then {["TaskSucceeded", ["", "Resource Taken"]] remoteExec ["BIS_fnc_showNotification"]};
		if (activeBE) then {["con_ter"] remoteExec ["fnc_BE_XP", 2]};
		[0,10] remoteExec ["prestige",2];
		if (([power, _markerPos] call BIS_fnc_nearestPosition) in mrkAAF) then {
			sleep 5;
			["TaskFailed", ["", "Resource out of Power"]] remoteExec ["BIS_fnc_showNotification"];
			[_marker, false] call AS_fnc_adjustLamps;
		} else {
			[_marker, true] call AS_fnc_adjustLamps;
		};
	};
};

{[_marker,_x] spawn AS_fnc_deleteRoadblock} forEach controles;
sleep 15;
[_marker] remoteExec ["autoGarrison",HCattack];

waitUntil {sleep 3; (({_x distance _markerPos < distanciaSPWN} count (allPlayers - hcArray) == 0) AND ({(alive _x)} count ([_size,0,_markerPos,"OPFORSpawn"] call distanceUnits) == 0)) OR (({!(vehicle _x isKindOf "Air") AND (alive _x) AND (!fleeing _x)} count ([_size,0,_markerPos,"OPFORSpawn"] call distanceUnits)) > 3*({(alive _x)} count ([_size,0,_markerPos,"BLUFORSpawn"] call distanceUnits)))};

call {
	// Clear to respawn zone
	if (({_x distance _markerPos < distanciaSPWN} count (allPlayers - hcArray) == 0) AND ({(alive _x)} count ([_size,0,_markerPos,"OPFORSpawn"] call distanceUnits) == 0)) then {
		[_marker] call AS_fnc_respawnZone;
	};

	// Zone lost
	if (({!(vehicle _x isKindOf "Air") AND (alive _x) AND (!fleeing _x)} count ([_size,0,_markerPos,"OPFORSpawn"] call distanceUnits)) > 3*({(alive _x)} count ([_size,0,_markerPos,"BLUFORSpawn"] call distanceUnits))) then {
		[_marker] spawn mrkLOOSE;
	};
};