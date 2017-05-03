params [
	["_vehicles", []],
	["_duration", 5, [1]]
];

if !(typeName _vehicles == "ARRAY") then {_vehicles = [_vehicles]};

{
	_x allowDamage false;
	_x setDamage 0;
} forEach _vehicles;

sleep _duration;

{
	_x allowDamage true;
} forEach _vehicles;

{
	if !(alive _x) then {
		_x hideObjectGlobal true;
		deleteVehicle _x;
		diag_log format ["Error in protectVehicle: a %1 died and was removed.", typeOf _x];
	};
};