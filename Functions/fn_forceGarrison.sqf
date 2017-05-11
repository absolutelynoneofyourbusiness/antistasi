params ["_group",["_range",100],["_useMarkers",false], ["_PassFunction", false]];
[[],[],false] params ["_buildingPositions","_markerArray","_positionsTaken"];
private ["_GroupUnits","_BuildingLocation","_CurrentPos","_rnd","_dist","_dir","_positions","_markerPositions","_centerPos"];

#define OPTIONS ["Strategic","House"]

_centerPos = getPosATL (leader _group);
if (_useMarkers) then {
	_markerArray = nearestObjects [_centerPos, list_garMrks, _range];

	if (count _markerArray > 0) then {
		_markerPositions = _markerArray apply {getPosATL _x};
		_GroupUnits = units _group;
		{[_x] joinSilent grpNull; (group _x) enableDynamicSimulation true} forEach _GroupUnits;

		if !(_PassFunction) then {
			[_GroupUnits,side (leader _group)] spawn VCOMAI_ReGroup;
		};

		{
			if !((count _markerPositions) isEqualTo 0) then
			{
				_BuildingLocation = _markerPositions select 0;
				_markerPositions = _markerPositions - [_BuildingLocation];
				_GroupUnits = _GroupUnits - [_x];
				_x setPosATL _BuildingLocation;
				_x setUnitPosWeak "UP";
				_x setVariable ["VCOM_GARRISONED",true,false];
			};
		} foreach _GroupUnits;

		_positionsTaken = true;
	};
};

_buildings = nearestObjects [_centerPos, OPTIONS, _range];
if (count _buildings < 1) exitWith {diag_log format [" No %2 type of building found within a %3m radius around %1", _centerPos, OPTIONS, _range]};

{
	_buildingPositions = _buildingPositions + ([_x] call BIS_fnc_buildingPositions);
} forEach _buildings;

_buildingPositions = _buildingPositions call BIS_fnc_arrayShuffle;

if !(_positionsTaken) then {
	_GroupUnits = units _group;
	{[_x] joinSilent grpNull; (group _x) enableDynamicSimulation true} forEach _GroupUnits;

	if !(_PassFunction) then {
		[_GroupUnits,side (leader _group)] spawn VCOMAI_ReGroup;
	};
};

{
	if !((count _buildingPositions) isEqualTo 0) then
	{
		_BuildingLocation = _buildingPositions select 0;
		_buildingPositions = _buildingPositions - [_BuildingLocation];
		_GroupUnits = _GroupUnits - [_x];
		_x setPosATL _BuildingLocation;
		_x setUnitPosWeak "UP";
		_x setVariable ["VCOM_GARRISONED",true,false];
	};
} foreach _GroupUnits;


if ((count _GroupUnits) > 0) then
{
	{
		_CurrentPos = getPosASL _x;
		_rnd = random 25;
		_dist = (_rnd + 25);
		_dir = random 360;
		_positions = [(_CurrentPos select 0) + (sin _dir) * _dist, (_CurrentPos select 1) + (cos _dir) * _dist, 0];
		_x doMove _positions;
		sleep 15;
		[(group _x), _range, _useMarkers] spawn AS_fnc_forceGarrison;
	} foreach _GroupUnits;
};