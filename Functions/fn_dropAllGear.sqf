params ["_unit", "_container",["_ownEquipment",false]];
private ["_weapons","_magazines"];

if !(_ownEquipment) then {
	_weapons = weapons _unit;
	_magazines = magazines _unit + [currentMagazine _unit];
	_items = (items _unit) + (primaryWeaponItems _unit) + (secondaryWeaponItems _unit) + (assignedItems _unit) + [vest _unit,headgear _unit];

	_container addBackpackCargoGlobal [backpack _unit,1];
	{_container addWeaponCargoGlobal [_x,1]} forEach _weapons;
	{_container addMagazineCargoGlobal [_x,1]} forEach _magazines;
	{_container addItemCargoGlobal [_x,1]} forEach _items;
} else {
	_unit setVariable ["gearStored",true,true];
	[_unit, [_unit, "scav_inventory"]] call BIS_fnc_saveInventory;
};

removeAllWeapons _unit;
removeVest _unit;
removeHeadgear _unit;
removeBackpack _unit;
removeAllAssignedItems _unit;