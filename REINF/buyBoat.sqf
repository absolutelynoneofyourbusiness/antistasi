private ["_break","_spawnPos","_spawnposArray","_newPos","_cost","_vehicle"];

_break = false;
{
	if (((side _x == side_red) OR (side _x == side_green)) AND (_x distance player < safeDistance_fasttravel) AND !(captive _x)) then {_break = true};
} forEach allUnits;

if (_break) exitWith {Hint "You cannot buy vehicles with enemies nearby"};

_cost = server getVariable [guer_veh_dinghy,400];

if (server getVariable ["resourcesFIA",0] < _cost) exitWith {hint format ["You need %1€ to buy a boat.",_cost]};

_spawnPos = [];
_spawnposArray = selectBestPlaces [position player, 50, "sea", 1, 1];
{
	if ((_x select 1) > 0) exitWith {
		if (surfaceIsWater (_x select 0)) then {_spawnPos = (_x select 0)};
	};
} forEach _spawnposArray;

if !(count _spawnPos > 0) then {
	_spawnposArray = selectBestPlaces [position player, 100, "sea", 1, 1];
	{
		if ((_x select 1) > 0) exitWith {
			if (surfaceIsWater (_x select 0)) then {_spawnPos = (_x select 0)};
		};
	} forEach _spawnposArray;
};

if !(count _spawnPos > 0) exitWith {hint "No place for a boat."};

_vehicle = guer_veh_dinghy createVehicle _spawnPos;

[_vehicle] spawn VEHinit;
player reveal _vehicle;
[0,-_cost] remoteExec ["resourcesFIA",2];
hint "Boat purchased";