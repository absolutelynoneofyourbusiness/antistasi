/*
    Description:
        Puts all of a unit's essential gear into a specified container

    Parameters:
        0: OBJECT - Unit
        1: OBJECT - Container to use for storage
        2: BOOLEAN - Save the unit's loadout to be restored later -- gear will NOT be put into the container, only deleted

    Returns:
        Nothing

    Example:
        [(groupSelectedUnits player) select 0, vehicle player, true] spawn AS_fnc_dropAllGear
*/

params [
	"_unit",
	["_container", objNull],
	["_ownEquipment", false, [true]],

	["_weapons", []],
	["_magazines", []],
	["_items", []]
];

if !(_ownEquipment) then {
	_weapons = weapons _unit;
	_magazines = magazines _unit + [currentMagazine _unit];
	_items = (items _unit) + (primaryWeaponItems _unit) + (secondaryWeaponItems _unit) + (assignedItems _unit) + [vest _unit,headgear _unit];

	_container addBackpackCargoGlobal [backpack _unit,1];
	{_container addWeaponCargoGlobal [_x,1]} forEach _weapons;
	{_container addMagazineCargoGlobal [_x,1]} forEach _magazines;
	{_container addItemCargoGlobal [_x,1]} forEach _items;
} else {
	_unit setVariable ["gearStored", true, false];
	[_unit, [_unit, "scav_inventory"]] call BIS_fnc_saveInventory;
};

removeAllWeapons _unit;
removeVest _unit;
removeHeadgear _unit;
removeBackpack _unit;
removeAllAssignedItems _unit;