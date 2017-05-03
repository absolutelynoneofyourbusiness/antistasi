if (!isServer and hasInterface) exitWith {};

params ["_marker"];
private ["_markerPos","_targetName","_endTime","_fMarkers","_hMarkers","_base","_basePos","_baseName","_truckPos","_run","_spawnPosition","_direction","_truckMarkerPos","_truckMarker","_truck","_crate","_groupType","_group","_vehicleData","_dismountGroup","_wpV1_1","_wpInf1_1","_tsk","_loading","_nearbyFriendlies","_mrkTarget"];

[[],[],[],[],0,false] params ["_allGroups","_allSoldiers","_allVehicles","_allCrates","_counter","_loading"];

#define DURATION 60
#define MAXRUNS 50
#define VEHICLETYPE "C_Van_01_transport_F"
#define LOADTIME 120
#define UNLOADTIME 20

_tskTitle = localize "STR_TSK_LOGMEDICAL";
_tskDesc = localize "STR_TSKDESC_LOGMEDICAL";
_tskDesc_2 = localize "STR_TSKDESC_LOGMEDICAL_2";

_markerPos = getMarkerPos _marker;
_targetName = [_marker] call AS_fnc_localizar;

_endTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + DURATION];
_endTime = dateToNumber _endTime;

_fMarkers = mrkFIA + campsFIA;
_hMarkers = bases + aeropuertos + puestos - mrkFIA;

_base = [_markerPos] call AS_fnc_findBaseForConvoy;
if (_base isEqualTo "") exitWith {diag_log format ["Supply Recovery at %1 cancelled, no base available.",_marker]};
_basePos = getMarkerPos _base;
_baseName = [_base] call AS_fnc_localizar;

_run = 0;
while {(_run < MAXRUNS)} do {
	sleep 0.1;
	_truckPos = [_markerPos,2000,random 360] call BIS_fnc_relPos;
	_nfMarker = [_fMarkers,_truckPos] call BIS_fnc_nearestPosition;
	_nhMarker = [_hMarkers,_truckPos] call BIS_fnc_nearestPosition;
	if ((!surfaceIsWater _truckPos) AND (_truckPos distance (server getVariable ["posHQ", getMarkerPos guer_respawn]) < 4000) AND (getMarkerPos _nfMarker distance _truckPos > 500) AND (getMarkerPos _nhMarker distance _truckPos > 800)) exitWith {};
	_run = _run + 1;
};

if !(_run < MAXRUNS) exitWith {diag_log format ["Supply Recovery at %1 cancelled, position found.",_marker]};

([_basePos, _truckPos] call AS_fnc_findSpawnSpots) params ["_spawnPosition","_direction"];

_truckMarkerPos = [_truckPos,random 200,random 360] call BIS_fnc_relPos;
_truckPos = _truckPos findEmptyPosition [0,100,VEHICLETYPE];
_truckMarker = createMarker [format ["REC%1", random 100], _truckMarkerPos];
_truckMarker setMarkerShape "ICON";

_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_truckMarker],_truckMarkerPos,"CREATED",5,true,true,"Heal"] call BIS_fnc_setTask;

misiones pushBack _tsk; publicVariable "misiones";

_truck = createVehicle [VEHICLETYPE, _truckPos, [], 0, "CAN_COLLIDE"];
[_truck] spawn AS_fnc_protectVehicle;
[_truck,"Mission Vehicle"] spawn inmuneConvoy;
reportedVehs pushBack _truck; publicVariable "reportedVehs";
_allVehicles pushBack _truck;
_truck lockCargo true;
{_truck lockCargo [_x, false];} forEach [0 ,1];
[_truck, true] remoteExec ["AS_fnc_lockVehicle", [0,-2] select isDedicated, true];

_crate = "Box_IND_Support_F" createVehicle _truckPos;
_crate setPos ([getPos _truck, 6, 185] call BIS_Fnc_relPos);
_allCrates pushBack _crate;

_crate = "Box_IND_Support_F" createVehicle _truckPos;
_crate setPos ([getPos _truck, 4, 167] call BIS_Fnc_relPos);
_allCrates pushBack _crate;

_crate = "Box_NATO_WpsSpecial_F" createVehicle _truckPos;
_crate setPos ([getPos _truck, 8, 105] call BIS_Fnc_relPos);
_allCrates pushBack _crate;

_crate = "Box_NATO_WpsSpecial_F" createVehicle _truckPos;
_crate setPos ([getPos _truck, 5, 215] call BIS_Fnc_relPos);
_allCrates pushBack _crate;

{
	_x setDir (getDir _truck + (floor random 180));
	[_x] call emptyCrate;
	_x addItemCargoGlobal (selectRandom [["FirstAidKit", floor random [15,30,45]],["Medikit", floor random [5,10,20]]])
} forEach _allCrates;

_groupType = [infGarrisonSmall, side_green] call AS_fnc_pickGroup;
_group = [_truckPos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_allGroups pushBack _group;

sleep 30;

([_spawnPosition, _direction,selectRandom vehTrucks, side_green] call bis_fnc_spawnvehicle) params ["_vehicle","_vehicleCrew","_vehicleGroup"];
[_vehicle] spawn genVEHinit;
[_vehicle] spawn smokeCover;
[_vehicle,"AAF Escort"] spawn inmuneConvoy;
_allGroups pushBack _vehicleGroup;
_allVehicles pushBack _vehicle;


sleep 1;

_groupType = [infSquad, side_green] call AS_fnc_pickGroup;
_dismountGroup = [_basePos, side_green, _groupType] call BIS_Fnc_spawnGroup;
_allGroups pushBack _dismountGroup;

{
	_x assignAsCargo _vehicle;
	_x moveInCargo _vehicle;
} forEach units _dismountGroup;

{
	_group = _x;
	{
		[_x] spawn genInit;
		_allSoldiers pushBack _x;
	} forEach units _group;
} forEach _allGroups;

_wpV1_1 = _vehicleGroup addWaypoint [_truckPos, 30];
_wpV1_1 setWaypointBehaviour "CARELESS";
_wpV1_1 setWaypointSpeed "FULL";
_wpV1_1 setWaypointType "TR UNLOAD";
_wpV1_1 setWaypointStatements ["true", "(vehicle this) land 'GET OUT'; [vehicle this] call smokeCoverAuto"];

_wpInf1_1 = _dismountGroup addWaypoint [_truckPos, 30];
_wpInf1_1 setWaypointType "GETOUT";
_wpInf1_1 synchronizeWaypoint [_wpV1_1];

[_vehicleGroup,_vehicle,_spawnPosition] spawn {
	params ["_vehGroup","_veh","_pos"];
	waitUntil {sleep 5; (count (assignedCargo _veh) == 0) OR ({alive _x} count units _vehGroup == 0)};
	[_vehGroup, _pos] spawn AS_fnc_QRF_RTB;
};

waitUntil {sleep 1; (!alive _truck) OR (dateToNumber date > _endTime) OR (count ((_truckPos nearEntities ["Man", 50]) select {side _x == side_blue}) > 0)};

_truckMarker = createMarker [format ["REC%1", random 100], _truckPos];
_truckMarker setMarkerShape "ICON";

scopeName "main";
// Mission failure
if ((!alive _truck) OR (dateToNumber date > _endTime)) then {
	_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_truckMarker],_truckMarkerPos,"FAILED",5,true,true,"Heal"] call BIS_fnc_setTask;
	[5,-5,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
	[-10,Slowhand] call playerScoreAdd;
} else {
	_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc_2,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_truckMarker],_truckPos,"AUTOASSIGNED",5,true,true,"Heal"] call BIS_fnc_setTask;

	// Remove undercover status of nearby friendly units
	_nearbyFriendlies = [300,0,_truck,"BLUFORSpawn"] call distanceUnits;
	{
		if (captive _x) then {
			[_x,false] remoteExec ["setCaptive",_x];
		};
	} forEach _nearbyFriendlies;

	// Order nearby enemies to close in on the truck, reveal friendlies to them
	{
		_unit = _x;
		if (side _unit == side_green) then {
			if (_unit distance _truckPos < 300) then {
				_unit doMove _truckPos;
			} else {
				{
					_unit reveal [_x,4];
				} forEach _nearbyFriendlies;
			};
		};

		if ((side _unit == civilian) AND (_unit distance _truckPos < 300)) then {
			_unit doMove position _truck;
		};
	} forEach (_truckPos nearEntities ["Man", 1000]);

	while {(_counter < LOADTIME) AND (alive _truck) AND (dateToNumber date < _endTime)} do {

		while {(_counter < LOADTIME) AND (_truck distance _truckPos < 40) AND (alive _truck) AND ({(side _x == side_blue) AND !(_x getVariable ["inconsciente",false])} count (_truckPos nearEntities ["Man", 50]) > 0) AND ({(side _x == side_green)} count (_truckPos nearEntities ["Man", 50]) == 0) AND (dateToNumber date < _endTime)} do {

			if !(_loading) then {
				{
					if (_x distance2d _truck < 80) then {
						[(LOADTIME - _counter),false] remoteExec ["pBarMP",_x];
						"Guard the truck!" remoteExec ["hint",_x];
					};
				} forEach (allPlayers - entities "HeadlessClient_F");
				_loading = true;
			};

			_counter = _counter + 1;
  			sleep 1;
		};

		if !((alive _truck) AND (dateToNumber date < _endTime)) then {
			breakTo "main";
		};

		if (_counter < LOADTIME) then {
			_counter = 0;
			_loading = false;
			{
				if (_x distance2d _truck < 100) then {
					[0,true] remoteExec ["pBarMP",_x];
				};
			} forEach (allPlayers - entities "HeadlessClient_F");

			if ((_truck distance _truckPos > 40) OR !({(side _x == side_blue) AND !(_x getVariable ["inconsciente",false])} count (_truckPos nearEntities ["Man", 50]) > 0) OR ({(side _x == side_green)} count (_truckPos nearEntities ["Man", 50]) > 0) AND (alive _truck)) then {
				{
					if (_x distance2d _truck < 150) then {
						"Hold this position and keep the truck near the supplies while they are being loaded." remoteExec ["hint",_x];
					};
				} forEach (allPlayers - entities "HeadlessClient_F");
			};

			waitUntil {sleep 1; (!alive _truck) OR (dateToNumber date > _endTime) OR ((_truck distance _truckPos < 40) AND ({(side _x == side_blue) AND !(_x getVariable ["inconsciente",false])} count (_truckPos nearEntities ["Man", 80]) > 0) AND ({(side _x == side_green)} count (_truckPos nearEntities ["Man", 50]) == 0))};
		};

		if ((alive _truck) AND !(_counter < LOADTIME)) exitWith {
			{
				if (_x distance2d _truck < 80) then {
					[petros,"hint",format ["Good to go. Deliver these supplies to %1 on the double.",_targetName]] remoteExec ["commsMP",_x];
				};
			} forEach (allPlayers - entities "HeadlessClient_F");

			(_allCrates select 0) attachTo [_truck,[0.3,-1.0,-0.4]];
			(_allCrates select 1) attachTo [_truck,[-0.3,-1.0,-0.4]];
			(_allCrates select 2) attachTo [_truck,[0,-1.6,-0.4]];
			(_allCrates select 3) attachTo [_truck,[0,-2.0,-0.4]];

			[_truck, false] remoteExec ["AS_fnc_lockVehicle", [0,-2] select isDedicated, true];
		};
		sleep 3;
	};

	if !((alive _truck) AND (dateToNumber date < _endTime)) then {
		breakTo "main";
	};

	_mrkTarget = createMarker [format ["REC%1", random 100], _markerPos];
	_mrkTarget setMarkerShape "ICON";
	_loading = false;

	_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_mrkTarget],_markerPos,"AUTOASSIGNED",5,true,true,"Heal"] call BIS_fnc_setTask;

	waitUntil {sleep 3; (!alive _truck) OR (dateToNumber date > _endTime) OR (_truck distance2d _markerPos < 40)};

	if ((alive _truck) AND (dateToNumber date < _endTime)) then {
		_truck setFuel 0;
		{
			_x action ["eject", _truck];
		} forEach (crew (_truck));
		sleep 0.5;

		_counter = 0;
		while {(_counter < UNLOADTIME) AND (alive _truck) AND ({(side _x == side_blue) AND !(_x getVariable ["inconsciente",false])} count (_truck nearEntities ["Man", 80]) > 0) AND (dateToNumber date < _endTime)} do {
			if !(_loading) then {
				{
					if (_x distance2d _truck < 80) then {
						[(UNLOADTIME - _counter),false] remoteExec ["pBarMP",_x];
						"Leave the vehicle here, they'll come pick it up." remoteExec ["hint",_x];
					};
				} forEach (allPlayers - entities "HeadlessClient_F");
				_loading = true;
			};

			_counter = _counter + 1;
  			sleep 1;
		};

		{
			_x action ["eject", _truck];
		} forEach (crew (_truck));
		sleep 1;
		[_truck, true] remoteExec ["AS_fnc_lockVehicle", [0,-2] select isDedicated, true];

		if (alive _truck) then {
			[[petros,"hint","Supplies Delivered"],"commsMP"] call BIS_fnc_MP;
			_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_truckMarker],_truckMarkerPos,"SUCCEEDED",5,true,true,"Heal"] call BIS_fnc_setTask;
			[0,15,_marker] remoteExec ["AS_fnc_changeCitySupport",2];
			[5,0] remoteExec ["prestige",2];
			{if (_x distance _markerPos < 500) then {[10,_x] call playerScoreAdd}} forEach (allPlayers - hcArray);
			[5,Slowhand] call playerScoreAdd;
			// BE module
			if (activeBE) then {
				["mis"] remoteExec ["fnc_BE_XP", 2];
			};
			// BE module

			if (random 10 < 5) then {
				for "_i" from 1 to (1 + round random 2) do {
					cajaVeh addMagazineCargoGlobal [selectRandom genMines, 1 + (floor random 5)];
				};

				[[petros,"globalChat","Someone dropped off a crate near HQ while you were gone. Check the vehicle ammo box."],"commsMP"] call BIS_fnc_MP;
			};
		} else {
			_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_truckMarker],_truckMarkerPos,"FAILED",5,true,true,"Heal"] call BIS_fnc_setTask;
			[5,-5,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
			[-10,Slowhand] call playerScoreAdd;
		};
	} else {
		_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_truckMarker],_truckMarkerPos,"FAILED",5,true,true,"Heal"] call BIS_fnc_setTask;
		[5,-5,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
		[-10,Slowhand] call playerScoreAdd;
	};
};

// Mission failure
if ((!alive _truck) OR (dateToNumber date > _endTime)) then {
	_tsk = ["LOG",[side_blue,civilian],[format [_tskDesc,_targetName,numberToDate [2035,_endTime] select 3,numberToDate [2035,_endTime] select 4, _baseName, A3_Str_INDEP],_tskTitle,_truckMarker],_truckMarkerPos,"FAILED",5,true,true,"Heal"] call BIS_fnc_setTask;
	[5,-5,_markerPos] remoteExec ["AS_fnc_changeCitySupport",2];
	[-10,Slowhand] call playerScoreAdd;
};

[_allGroups, _allSoldiers, _allVehicles + _allCrates] spawn AS_fnc_despawnUnits;

[1200,_tsk] spawn borrarTask;
deleteMarker _truckMarker;
deleteMarker _mrkTarget;