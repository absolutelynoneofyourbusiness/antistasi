params ["_Unit"];
private ["_friendlies"];

if (side (group _Unit) != side_blue) then {
	_friendlies = ((_Unit nearEntities [enemyCat, VCOM_Unit_AIWarnDistance]) + ((_Unit nearEntities [vehCat, VCOM_Unit_AIWarnDistance]) select {(side _x == side_green) OR {(side _x == side_red)}}));
} else {
	_friendlies = (((_Unit nearEntities [vehCat, VCOM_Unit_AIWarnDistance]) select {_x getVariable ["BLUFORSpawn",false]}) + (_Unit nearEntities [solCat, VCOM_Unit_AIWarnDistance]));
};

_friendlies