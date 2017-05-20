if (!isServer and hasInterface) exitWith {};

_tskTitle = localize "STR_TSK_FNDEXP";
_tskDesc = localize "STR_TSKDESC_FNDEXP";

#define DURATION 60

params [
	"_marker",
	["_break", false],
	["_patrolDispatched", false]
];

private ["_siteName", "_markerPos", "_roads", "_p1", "_posCmp", "_index", "_road", "_p2", "_direction", "_endTime", "_objs", "_groupDev", "_base", "_mrkDev"];

_allGroups = [];
_allVehicles = [];
_allSoldiers = [];

_siteName = [_marker] call AS_fnc_localizar;
_markerPos = getMarkerPos _marker;

_roads = carreteras getVariable _marker;

while {!(_break) AND {(count _roads > 0)}} do {
	_roads = _roads call BIS_fnc_arrayShuffle;
	_p1 = "";
	_posCmp = "";
	_index = 1;

	for "_i" from 0 to (count _roads - 1) do {
		if (((_roads select _i) distance _markerPos >150) && ((_roads select _i) distance _markerPos <300)) exitWith {_p1 = (_roads select _i); _index = _i;};
	};

	if (typeName _p1 != "ARRAY") exitWith {diag_log "no road found"};
	_road = (_p1 nearRoads 5) select 0;
	if (!isNil "_road") then {
		_roadcon = roadsConnectedto (_road);
		if (count _roadcon > 0) then {
			_p2 = getPos (_roadcon select 0);
			_direction = [_p1,_p2] call BIS_fnc_DirTo;
			_posCmp = [_p1, 8, _direction + 90] call BIS_Fnc_relPos;
			if (count (nearestObjects [_posCmp, [], 6]) < 1) exitWith {
				_break = true;
			};
			_roads set [_index,-1];
			_roads = _roads - [-1];
		};
	};
};

if !(_break) exitWith {
	[petros, "globalChat", "Sorry, I wasn't paying attention. What was it you requested of me?"] remoteExec ["commsMP", [0, -2] select isDedicated];
};

server setVariable ["expActive", true, true];

_endTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + DURATION];
_endTime = dateToNumber _endTime;

_tsk = ["FND_E",[side_blue,civilian],[format [_tskDesc,_siteName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4],_tskTitle,_marker],_posCmp,"CREATED",5,true,true,"Find"] call BIS_fnc_setTask;
misiones pushBack _tsk; publicVariable "misiones";

_objs = [_posCmp, ([_posCmp,_p1] call BIS_fnc_DirTo), call (compile (preprocessFileLineNumbers "Compositions\cmpExp.sqf"))] call BIS_fnc_ObjectsMapper;
sleep 3;

// Devin, as known from JA2 -- bow down to the masters at Sir-Tech!
_groupDev = createGroup Civilian;
_devin = _groupDev createUnit [CIV_specialUnits select 0, [8173.79,25308.9,0.00156975], [], 0.9, "NONE"];
[_devin] spawn AS_fnc_protectVehicle;
_devin setPos _posCmp;
_devin setDir ([_posCmp, _p1] call BIS_fnc_DirTo);
_devin removeWeaponGlobal (primaryWeapon _devin);
[_devin, {_this setIdentity "Devin"}] remoteExec ["call", [0, -2] select isDedicated, true];
_devin disableAI "move";
_devin setunitpos "up";

{
	call {
		if (str typeof _x find "Land_PlasticCase_01_medium_F" > -1) exitWith {expCrate = _x; [expCrate] call emptyCrate;};
		if (str typeof _x find "Box_Syndicate_Wps_F" > -1) exitWith { [_x] call emptyCrate;};
		if (str typeof _x find "Box_IED_Exp_F" > -1) exitWith { [_x] call emptyCrate;};
	};
} forEach _objs;

if (random 1 < 0.15) then {
	_patrolDispatched = true;
	_base = [_posCmp, "reinforcement"] call AS_fnc_findBase;
	_insertionPoint = [getMarkerPos _base, _posCmp, 150, 400] call AS_fnc_findDropoffPoint;
	([_base, _insertionPoint, enemyMotorpoolDef, infSquad, side_green, "none", 0, DURATION*60, "devin_patrol"] call AS_fnc_transportTroops) params ["_vehicle", "_vehicleCrew", "_vehicleGroup", "_group"];
	[_group, _posCmp] spawn {
		params ["_group", "_targetPosition"];
		waitUntil {sleep 3; (server getVariable ["devin_patrol", false]) OR {{alive _x AND !captive _x} count _group < 1}};
		if (server getVariable ["devin_patrol", false]) then {
			[_group, _targetPosition, 200] call bis_fnc_taskPatrol;
		};
	};

};

waitUntil {sleep 3; ({(_x getVariable ["BLUFORSpawn", false]) AND {(_x distance _devin < 200)}} count allPlayers > 0) OR {(dateToNumber date > _endTime)} OR {!(alive _devin)}};

{
	if (_x distance2d _devin < 200) then {
		[petros, "hint","Don't ask Devin about the Holy Handgrenade of Antioch. Just don't."] remoteExec ["commsMP", _x];
	};
} forEach (allPlayers - entities "HeadlessClient_F");

if !(_patrolDispatched) then {
	([spawnCSAT, _posCmp, opHeliFR, opGroup_Recon_Team, side_red, "fastrope", [300, 550], DURATION*60, [], "devin_patrol"] call AS_fnc_insertTroops) params ["_vehicle", "_vehicleCrew", "_vehicleGroup", "_group"];
	//["spawnCSAT", _posCmp, "transport", "small", DURATION*60, 250] remoteExec ["enemyQRF", HCattack]
};


waitUntil {sleep 1; ({(_x getVariable ["BLUFORSpawn", false]) AND {(_x distance _devin < 10)}} count allPlayers > 0) OR {(dateToNumber date > _endTime)} OR {!(alive _devin)}};

if ({(_x getVariable ["BLUFORSpawn", false]) AND {(_x distance _devin < 10)}} count allPlayers > 0) then {
	_tsk = ["FND_E",[side_blue,civilian],[format [_tskDesc,_siteName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4],_tskTitle,_marker],_posCmp,"SUCCEEDED",5,true,true,"Find"] call BIS_fnc_setTask;
	[_devin,"buy_exp"] remoteExec ["AS_fnc_addActionMP", [0, -2] select isDedicated, true];
	_mrkDev = createMarker ["_devin", _posCmp];
	_mrkDev setMarkerShape "ICON";
	_mrkDev setMarkerType "flag_Croatia";
    _devin allowDamage true;
	line1 = ["Devin", "Top of the day to ya. Haven't made yer acquaintance."];
    [[line1],"DIRECT",0.15] execVM "createConv.sqf";
} else {
	_tsk = ["FND_E",[side_blue,civilian],[format [_tskDesc,_siteName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4],_tskTitle,_marker],_posCmp,"FAILED",5,true,true,"Find"] call BIS_fnc_setTask;
};

waitUntil {sleep 10; (dateToNumber date > _endTime) OR {!(alive _devin)}};

[_devin,"remove"] remoteExec ["AS_fnc_addActionMP", [0, -2] select isDedicated, true];
if (alive _devin) then {
	_devin enableAI "ANIM";
	_devin enableAI "MOVE";
	_devin stop false;
	_devin doMove getMarkerPos "resource_7";
};

server setVariable ["expActive", false, true];

[1200,_tsk] spawn borrarTask;
sleep 30;
deleteMarker "_devin";
[(_vehicleGroup + [_groupDev]), (_vehicleCrew + (units _group) + [_devin]), [_vehicle] + _objs] spawn AS_fnc_despawnUnits;