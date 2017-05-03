params ["_Unit"];
private ["_enemies"];

if (side (group _Unit) == side_blue) then {
	_enemies = ((_Unit nearEntities [enemyCat, VCOM_HEARINGDISTANCE]) + ((_Unit nearEntities [vehCat, VCOM_HEARINGDISTANCE]) select {(side _x == side_green) OR {(side _x == side_red)}}));
} else {
	_enemies = (((_Unit nearEntities [vehCat, VCOM_HEARINGDISTANCE]) select {side _x == side_blue}) + (_Unit nearEntities [solCat, VCOM_HEARINGDISTANCE]));
};

_enemies