if !(isServer) exitWith {};
if (settingUpZones) exitWith {};

settingUpZones = true;
allZonesSetup = false;

spawnDistanceOne = 1500;
spawnDistanceTwo = 3000;
spawnDistanceThree = 4500;
spawnDistanceFour = 6000;
spawnDistancePlayer = 1500;
frontierDistance = 9000;
bufferDistance = 6000;

tempSpawnedZones = [];
spawnedZonesExtra = [];

_zones = marcadores select {getMarkerPos _x distance2D posHQ < spawnDistanceTwo};
spawnedZones = +_zones;
bufferZones = (marcadores select {getMarkerPos _x distance2D posHQ < bufferDistance}) - spawnedZones;
frontierZones = (marcadores select {getMarkerPos _x distance2D posHQ < frontierDistance}) - bufferZones;
deadZones = marcadores - frontierZones - bufferZones - spawnedZones;
_zones = _zones apply {[getMarkerPos _x distance2d posHQ,_x]};
_zones sort true;

for "_i" from 0 to (count _zones - 1) do {
	_marker = _zones select _i select 1;
	spawner setVariable [_marker,true,true];
	[_marker] call AS_fnc_respawnZone;
	sleep 3;
};

{
	spawner setVariable [_x,false,true];
} forEach deadZones;

allZonesSetup = true;
settingUpZones = false;

if !(isNil "GarMon") then {
	terminate GarMon;
};

if !(isNil "ReinfMon") then {
	terminate ReinfMon;
};

//GarMon = [] spawn garrisonMonitor;
ReinfMon = [] spawn reinforcementMonitor;

"Perimeter established. Good to go." remoteExec ["hint", [0,-2] select isDedicated, true];