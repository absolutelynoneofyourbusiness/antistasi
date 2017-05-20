params [
	["_groups", []],
	["_soldiers", []],
	["_vehicles", []],
	["_isFriendly", false, [true]]
];

if (count _vehicles > 0) then {
	{
		if !(_x in staticsToSave) then {
			[_x, _isFriendly] spawn {
				params ["_unit", "_isFriendly"];
				if (_isFriendly) then {
					//waitUntil {sleep 1; count ((_unit nearEntities [baseClasses_ENEMY, distanciaSPWN - 100]) select {_x getVariable ["OPFORSpawn",false]}) < 1};
				} else {
					waitUntil {sleep 1; !([distanciaSPWN, 1, _unit, "BLUFORSpawn"] call distanceUnits)};
				};
				deleteVehicle _unit;
			};
		};

		if (_x in reportedVehs) then {
			reportedVehs = reportedVehs - [_x];
			publicVariable "reportedVehs";
		};
	} forEach _vehicles;
};

if (count _soldiers > 0) then {
	{
		[_x, _isFriendly] spawn {
			params ["_unit", "_isFriendly"];
			if (_isFriendly) then {
				//waitUntil {sleep 1; count ((_unit nearEntities [baseClasses_ENEMY, distanciaSPWN - 100]) select {_x getVariable ["OPFORSpawn",false]}) < 1};
			} else {
				waitUntil {sleep 1; !([distanciaSPWN, 1, _unit, "BLUFORSpawn"] call distanceUnits)};
			};
			deleteVehicle _unit;
		};
	} forEach _soldiers;
};

if (count _groups > 0) then {
	{
		_x deleteGroupWhenEmpty true;
		grps_VCOM = grps_VCOM - [(_x call BIS_fnc_netId)];
	} forEach _groups;
};

publicVariable "grps_VCOM";