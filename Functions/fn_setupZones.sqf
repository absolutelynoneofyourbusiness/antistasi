if !(isServer) exitWith {};
if (settingUpZones) exitWith {};

settingUpZones = true;
allZonesSetup = false;

spawnDistanceOne = 1500;
spawnDistanceTwo = 3000;
spawnDistanceThree = 4500;
spawnDistanceFour = 6000;
spawnDistancePlayer = 2000;
frontierDistance = 9000;

frontierZones = [];
spawnedZones = [];
tempSpawnedZones = [];
deadZones =+ marcadores;

// Spawn first wave
{
	_marker = _x;
	_markerPos = getMarkerPos (_marker);

	if ((server getVariable ["posHQ", getMarkerPos guer_respawn]) distance2D _markerPos < spawnDistanceOne) then {
		spawnedZones pushBackUnique _marker;
		spawner setVariable [_marker,true,true];
		deadZones = deadZones - [_marker];

		[_marker] call AS_fnc_respawnZone;
		sleep 1;
	};
} forEach deadZones;

sleep 30;

// Spawn second wave
{
	_marker = _x;
	_markerPos = getMarkerPos (_marker);

	if ((server getVariable ["posHQ", getMarkerPos guer_respawn]) distance2D _markerPos < spawnDistanceTwo) then {
		spawnedZones pushBackUnique _marker;
		spawner setVariable [_marker,true,true];
		deadZones = deadZones - [_marker];

		[_marker] call AS_fnc_respawnZone;
		sleep 1;
	};
} forEach deadZones;

sleep 30;

// Spawn third wave
{
	_marker = _x;
	_markerPos = getMarkerPos (_marker);

	if ((server getVariable ["posHQ", getMarkerPos guer_respawn]) distance2D _markerPos < spawnDistanceThree) then {
		spawnedZones pushBackUnique _marker;
		spawner setVariable [_marker,true,true];
		deadZones = deadZones - [_marker];

		[_marker] call AS_fnc_respawnZone;
		sleep 1;
	};
} forEach deadZones;

sleep 30;

// Spawn fourth wave
{
	_marker = _x;
	_markerPos = getMarkerPos (_marker);

	if ((server getVariable ["posHQ", getMarkerPos guer_respawn]) distance2D _markerPos < spawnDistanceFour) then {
		spawnedZones pushBackUnique _marker;
		spawner setVariable [_marker,true,true];
		deadZones = deadZones - [_marker];

		[_marker] call AS_fnc_respawnZone;
		sleep 1;
	};
} forEach deadZones;

// Set frontier zones
{
	_marker = _x;
	_markerPos = getMarkerPos (_marker);

	if ((server getVariable ["posHQ", getMarkerPos guer_respawn]) distance2D _markerPos < frontierDistance) then {
		frontierZones pushBackUnique _marker;
		deadZones = deadZones - [_marker];
	};
} forEach deadZones;

allZonesSetup = true;
settingUpZones = false;