params ["_Unit"];
private ["_friendlies"];

if (side (group _Unit) != side_blue) then {
	_friendlies = ((_Unit nearEntities [baseClasses_ENEMY, VCOM_Unit_AIWarnDistance]) + ((_Unit nearEntities [baseClasses_VEHICLE, VCOM_Unit_AIWarnDistance]) select {(side _x == side_green) OR {(side _x == side_red)}}));
} else {
	_friendlies = (((_Unit nearEntities [baseClasses_VEHICLE, VCOM_Unit_AIWarnDistance]) select {_x getVariable ["BLUFORSpawn",false]}) + (_Unit nearEntities [baseClasses_PLAYER, VCOM_Unit_AIWarnDistance]));
};

_friendlies