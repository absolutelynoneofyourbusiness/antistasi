params ["_Unit"];
private ["_enemies"];

if (side (group _Unit) == side_blue) then {
	_enemies = ((_Unit nearEntities [baseClasses_ENEMY, VCOM_HEARINGDISTANCE]) + ((_Unit nearEntities [baseClasses_VEHICLE, VCOM_HEARINGDISTANCE]) select {(side _x == side_green) OR {(side _x == side_red)}}));
} else {
	_enemies = (((_Unit nearEntities [baseClasses_VEHICLE, VCOM_HEARINGDISTANCE]) select {side _x == side_blue}) + (_Unit nearEntities [baseClasses_PLAYER, VCOM_HEARINGDISTANCE]));
};

_enemies