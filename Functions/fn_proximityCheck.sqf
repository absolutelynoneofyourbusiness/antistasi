/*
 	Description:
		Check for presence of hostile units within a specified distance around a specified position

	Parameters:
		0: ARRAY - Position
		1: SIDE - Side of units to look for
		2: INTEGER - (optional) - Distance

 	Returns:
		0: BOOLEAN - Area clear?

 	Example:
		_blueNearby = [getMarkerPos "Neri", side_blue] call AS_fnc_proximityCheck;
*/

params [
	"_position",
	["_side", side_blue, [side_green]],
	["_distance", distanciaSPWN, [0]],

	["_return", false, [true]]
];

if (_side isEqualTo side_blue) then {
	_return = ((count ((_position nearEntities ["LandVehicle", _distance]) select {_x getVariable ["BLUFORSpawn", false]}) < 1) AND
 		{(count ((_position nearEntities ["AirVehicle", _distance]) select {_x getVariable ["BLUFORSpawn", false]}) < 1)} AND
 		{(count ((_position nearEntities [baseClasses_PLAYER, _distance]) select {_x getVariable ["BLUFORSpawn", false]}) < 1)});
} else {
	_return = ((count ((_position nearEntities [baseClasses_VEHICLE, _distance]) select {(side _x == side_green) OR {side _x == side_red}}) < 1) AND
 		{(count ((_position nearEntities [baseClasses_ENEMY, _distance]) select {_x getVariable ["OPFORSpawn", false]}) < 1)});
};

_return