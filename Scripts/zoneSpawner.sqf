if !(isServer) exitWith {};

private ["_blueUnits", "_opforUnits", "_marker", "_markerPos","_lastPosHQ"];

"Group" setDynamicSimulationDistance distanciaSPWN;
"Vehicle" setDynamicSimulationDistance distanciaSPWN;
"IsMoving" setDynamicSimulationDistanceCoef 1;

waitUntil {allZonesSetup};

_lastPosHQ = posHQ;
// Checks of spawned-in zones and frontier zones
while {true} do {
	if (_lastPosHQ isEqualTo posHQ) then {
		// ### HQ was not moved ###

		// Player within spawn distance of frontier zones
		if ({(_x distance poshq > (spawnDistanceFour-spawnDistancePlayer))} count (allPlayers - entities "HeadlessClient_F") > 0) then {
			// Check frontier zones for player presence
			{
				_marker = _x;
				_markerPos = getMarkerPos (_marker);

				if ({(_x distance _markerPos < spawnDistancePlayer)} count (allPlayers - entities "HeadlessClient_F") > 0) then {
					tempSpawnedZones pushBackUnique _marker;
					spawner setVariable [_marker,true,true];
					frontierZones = frontierZones - [_marker];
					diag_log format ["################# Frontier zone spawned: %1 #################", _marker];

					[_marker] call AS_fnc_respawnZone;
				};
			} forEach frontierZones;

			// Player presence inside the frontier zones, check dead zones for player presence
			if (count tempSpawnedZones > 0) then {
				// Check dead zones for player proximity, spawn if neccessary
				{
					_marker = _x;
					_markerPos = getMarkerPos (_marker);

					if ({(_x distance _markerPos < spawnDistancePlayer)} count (allPlayers - entities "HeadlessClient_F") > 0) then {
						tempSpawnedZones pushBackUnique _marker;
						spawner setVariable [_marker,true,true];
						deadZones = deadZones - [_marker];
						diag_log format ["################# Dead zone spawned: %1 #################", _marker];

						[_marker] call AS_fnc_respawnZone;
					};
				} forEach deadZones;
			};
		};

		// Check spawned zones for player proximity and HQ distance, despawn if possible
		{
			_marker = _x;
			_markerPos = getMarkerPos (_marker);

			if ({(_x distance _markerPos < spawnDistancePlayer)} count (allPlayers - entities "HeadlessClient_F") < 1) then {
				tempSpawnedZones = tempSpawnedZones - [_marker];
				spawner setVariable [_marker,false,true];
				if (posHQ distance2D _markerPos < frontierDistance) then {
					frontierZones pushBackUnique _marker;
					diag_log format ["################# Frontier zone despawned: %1 #################", _marker];
				} else {
					deadZones pushBackUnique _marker;
					diag_log format ["################# Dead zone despawned: %1 #################", _marker];
				};
			};
		} forEach tempSpawnedZones;

		sleep 10;
	} else {
		// ### HQ was moved ###

		// Check frontier zones for HQ proximity, remove zones if possible
		{
			_marker = _x;
			_markerPos = getMarkerPos (_marker);

			call {
				if (posHQ distance2D _markerPos > frontierDistance) exitWith {
					deadZones pushBackUnique _marker;
					frontierZones = frontierZones - [_marker];
					diag_log format ["################# Frontier zone became dead zone: %1 #################", _marker];
				};
				if (posHQ distance2D _markerPos < spawnDistanceFour) exitWith {
					spawnedZones pushBackUnique _marker;
					spawner setVariable [_marker,true,true];
					frontierZones = frontierZones - [_marker];
					diag_log format ["################# Frontier zone became active zone: %1 #################", _marker];
				};
			};
		} forEach frontierZones;

		// Check dead zones for HQ proximity, adjust frontier zones if neccessary
		{
			_marker = _x;
			_markerPos = getMarkerPos (_marker);

			if (posHQ distance2D _markerPos < frontierDistance) then {
				frontierZones pushBackUnique _marker;
				deadZones = deadZones - [_marker];
				diag_log format ["################# Dead zone became frontier zone: %1 #################", _marker];
			};
		} forEach deadZones;

		sleep 5;
	};

	_lastPosHQ = posHQ;
};