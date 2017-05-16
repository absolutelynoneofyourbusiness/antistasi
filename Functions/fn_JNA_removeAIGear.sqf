/*
 	Description:
		Remove weapons/ammo taken by AI from the arsenal

	Parameters:
		0: OBJECT - AI unit

 	Returns:
		Nothing

 	Example:
		[_unit] call AS_fnc_JNA_removeAIGear;
*/

params [
	["_unit", objNull],

	["_addToArray", {}, [{}]],
	["_itemsToRemove", [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]], [[]]]
];

if (isNull _unit) exitWith {diag_log "Error in removeAIGear, no unit specified"};

_addToArray = {
	params ["_array","_index","_item","_amount"];

	if !((_index == -1) OR {_item isEqualTo ""} OR {_amount == 0}) then {
		_array set [_index, [_array select _index, [_item,_amount]] call jna_fnc_addToArray];
	};
};

{
	if ((_x select 3) != 1) then {
		[_itemsToRemove, 26, _x select 0, _x select 1] call _addToArray;
	};
} forEach magazinesAmmoFull _unit;

{
	[_itemsToRemove, _foreachindex, _x, 1] call _addToArray;
} forEach [primaryWeapon _unit, secondaryWeapon _unit];

_itemsToRemove call jna_fnc_removeItems_Arsanal;