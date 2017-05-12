params [
	"_unit",
	"_name",
	"_uid",
	["_refundCash", 0, [0]],
	["_refundHR", 0, [0]]
];

private ["_units","_vehicle","_vehicleType","_object","_weapons","_magazines","_items","_wpnHolder"];

if (_unit == Slowhand) then {
	{
		if !(_x getVariable ["esNATO",false]) then {
			_units = units _x;
			{
				if (alive _x) then {
					_refundCash = _refundCash + (server getVariable (typeOf _x));
					_refundHR = _refundHR + 1;
				};

				if !(isNull (assignedVehicle _x)) then {
					_vehicle = assignedVehicle _x;
					_vehicleType = typeOf _vehicle;

					if ((_vehicle isKindOf "StaticWeapon") AND {!(_vehicle in staticsToSave)}) then {
						_refundCash = _refundCash + ([_vehicleType] call vehiclePrice) + ([typeOf (vehicle leader _x)] call vehiclePrice);
					} else {
						call {
							if (_vehicleType in guer_vehicleArray) exitWith {_refundCash = _refundCash + ([_vehicleType] call vehiclePrice)};
							if (_vehicleType in (vehTrucks + vehPatrol + vehSupply)) exitWith {_refundCash = _refundCash + 300};
							if (_vehicleType in vehAPC) exitWith {_refundCash = _refundCash + 1000};
							if (_vehicleType in vehIFV) exitWith {_refundCash = _refundCash + 2000};
							if (_vehicleType in vehTank) exitWith {_refundCash = _refundCash + 5000};
						};

						if (count attachedObjects _vehicle > 0) then {
							_object = (attachedObjects _vehicle) select 0;
							_refundCash = _refundCash + ([(typeOf _object)] call vehiclePrice);
							deleteVehicle _object;
						};
					};

					if !(_vehicle in staticsToSave) then {deleteVehicle _vehicle};
				};

				deleteVehicle _x;
			} forEach _units;
		};
	} forEach (hcAllGroups Slowhand);

	if (((count playableUnits > 0) AND {(count miembros == 0)}) OR {({(getPlayerUID _x) in miembros} count playableUnits > 0)}) then {
		[] spawn assignStavros;
	};

	if (group petros == group _unit) then {[] spawn buildHQ};
};

if ((_refundHR > 0) OR {(_refundCash > 0)}) then {[_refundHR,_refundCash] remoteExec ["resourcesFIA", 2]};

diag_log format ["Log: %1 (%2) disconnected", _name, _uid];

_weapons = weapons _unit;
_magazines = magazines _unit + [currentMagazine _unit];
_items = (items _unit) + (primaryWeaponItems _unit) + (assignedItems _unit);

{caja addWeaponCargoGlobal [_x,1]} forEach _weapons;
{caja addMagazineCargoGlobal [_x,1]} forEach _magazines;
{caja addItemCargoGlobal [_x,1]} forEach _items;
caja addBackpackCargoGlobal [(backpack _unit) call BIS_fnc_basicBackpack,1];

_wpnHolder = nearestObjects [_unit, ["weaponHolderSimulated", "weaponHolder"], 2];
{deleteVehicle _x} forEach (_wpnHolder + [_unit]);
if (alive _unit) then {
	_unit setVariable ["owner",_unit,true];
	_unit setDamage 1;
};