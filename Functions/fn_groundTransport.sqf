params ["_vehicleType","_groupType",["_groupCounter",1],"_originPosition","_targetMarker"];
private ["_isArmed","_targetPosition","_spawnpositionData","_spawnPosition","_direction","_allVehicles","_allGroups","_allSoldiers","_vehicle","_vehicleGroup","_dismountPosition","_threatEvaluationLand","_group","_wpV1_1","_wpV1_2","_wpInf1_1","_wpInf2_1","_infGroupOne","_infGroupTwo","_tempInfo"];

_targetPosition = getMarkerPos _targetMarker;
_isArmed = !(_vehicleType in vehTrucks);

_spawnpositionData = [_originPosition, _targetPosition] call AS_fnc_findSpawnSpots;
_spawnPosition = _spawnpositionData select 0;
_direction = _spawnpositionData select 1;

_initData = [_spawnPosition, _vehicleType,_direction, side_green, [], [], [], true] call AS_fnc_initialiseVehicle;
_allVehicles = _initData select 0;
_allGroups = _initData select 1;
_allSoldiers = _initData select 2;
_vehicle = _initData select 3;
_vehicleGroup = _initData select 4;

_threatEvaluationLand = [_targetMarker] call landThreatEval;
_dismountPosition = [_targetPosition, _spawnPosition, _threatEvaluationLand] call findSafeRoadToUnload;

for "_i" from 1 to _groupCounter do {
	_group = [_originPosition, side_green, _groupType] call BIS_Fnc_spawnGroup;
	{_x assignAsCargo _vehicle;_x moveInCargo _vehicle} forEach units _group;
	_allGroups pushBack _group;
};

_infGroupOne = _allGroups select 1;
_infGroupTwo = ["", _allGroups select 2] select (_groupCounter > 1);

if !(_isArmed) then {
	_tempInfo = [_vehicle, _infGroupOne, [], _originPosition] call AS_fnc_fillCargo;
	_allSoldiers = _allSoldiers + (_tempInfo select 2);

	[_vehicle,"Inf Truck."] spawn inmuneConvoy;
};

_wpV1_1 = _vehicleGroup addWaypoint [_dismountPosition, 0];
_wpV1_1 setWaypointBehaviour "CARELESS";
_wpV1_1 setWaypointSpeed "FULL";
_wpV1_1 setWaypointType "TR UNLOAD";
_wpV1_1 setWaypointStatements ["true", "(vehicle this) land 'GET OUT'; [vehicle this] call smokeCoverAuto"];

if (_isArmed) then {
	_wpV1_2 = _vehicleGroup addWaypoint [_targetPosition, 1];
	_wpV1_2 setWaypointType "SAD";
	_wpV1_2 setWaypointBehaviour "COMBAT";

	[_vehicle] spawn smokeCover;
	_vehicle allowCrewInImmobile true;
	[_vehicle,"APC"] spawn inmuneConvoy;
};

_wpInf1_1 = _infGroupOne addWaypoint [_dismountPosition, 0];
_wpInf1_1 setWaypointType "GETOUT";
_wpInf1_1 synchronizeWaypoint [_wpV1_1];
if (_groupCounter > 1) then {
	_wpInf2_1 = _infGroupTwo addWaypoint [_dismountPosition, 0];
	_wpInf2_1 setWaypointType "GETOUT";
	_wpInf2_1 synchronizeWaypoint [_wpV1_1];
};

if !(_isArmed) then {
	[_vehicleGroup, _infGroupOne, _targetPosition, _originPosition] spawn {
		params ["_vg","_ig","_tp","_op"];
		waitUntil {sleep 5; (((units _ig select 0) distance _tp < 100) AND (count assignedCargo (vehicle _vg) < 1)) OR ({alive _x} count units _vg == 0)};
		[_vg, _op] spawn AS_fnc_QRF_RTB;
	};
};

[_allVehicles, _allGroups, _allSoldiers]