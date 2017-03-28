private ["_targetLocations", "_isHC", "_group", "_groupLeader", "_check", "_enemy", "_targetPosition", "_tam", "_position", "_distance", "_force", "_roads", "_road", "_pos"];

_targetLocations = campsFIA + [guer_respawn];
_isHC = false;

if (count hcSelected player > 1) exitWith {hintSilent "You can fast-travel only one group at a time."};
if (count hcSelected player == 1) then {_group = hcSelected player select 0; _isHC = true} else {_group = group player};

_groupLeader = leader _group;

if (!(_groupLeader == player) and !(_isHC)) exitWith {hintSilent "Only a group leader can ask for fast-travel."};
if (player != player getVariable ["owner",player]) exitWith {hint "You cannot fast-travel while you are controlling AI."};

_enemiesNearGroup = false;
{
	_enemy = _x;
	{
		if (((side _enemy == side_red) or (side _enemy == side_green)) and (_enemy distance _x < safeDistance_fasttravel) and !(captive _enemy)) exitWith {_enemiesNearGroup = true};
	} forEach units _group;
	if (_enemiesNearGroup) exitWith {};
} forEach allUnits;

if ((_isHC) && (_enemiesNearGroup)) exitWith {hintSilent "This group cannot fast-travel with enemies nearby."};

_check = false;
{
	if (((side _x == side_red) or (side _x == side_green)) and (player distance _x < safeDistance_fasttravel) and !(captive _x)) exitWith {_check = true};
} foreach allUnits;

if (_check) exitWith {hintSilent "You cannot fast-travel with enemies nearby."};

{
	if (!(vehicle _x == _x) and ((isNull (driver vehicle _x)) or !(canMove vehicle _x))) then {
		if !(vehicle _x isKindOf "StaticWeapon") then {_check = true};
	}
} forEach units _group;

if (_check) exitWith {hintSilent "You cannot fast-travel if one of your vehicles is damaged or doesn't have a driver."};

targetPosition = [];

if (_isHC) then {hcShowBar false};
hint "Click on the zone you want to travel to";
openMap true;
onMapSingleClick "targetPosition = _pos;";

waitUntil {sleep 1; (count targetPosition > 0) or !(visiblemap)};
onMapSingleClick "";

_targetPosition = targetPosition;

if (count _targetPosition > 0) then {
	_marker = [_targetLocations, _targetPosition] call BIS_Fnc_nearestPosition;

	if (_marker in mrkAAF) exitWith {hintSilent "You cannot fast-travel to an enemy-controlled zone."; openMap [false, false]};

	{
		if (((side _x == side_red) or (side _x == side_green)) and (_x distance (getMarkerPos _marker) < safeDistance_fasttravel) and !(captive _x)) then {_check = true};
	} forEach allUnits;

	if (_check) exitWith {Hint "You cannot fast-travel to an area under attack or with enemies in the surrounding."; openMap [false,false]};

	if (_targetPosition distance getMarkerPos _marker < 50) then {
		_position = [getMarkerPos _marker, 10, random 360] call BIS_Fnc_relPos;
		_distance = round (((position _groupLeader) distance _position)/200);
		if (!_isHC) then {
			disableUserInput true;
			cutText ["Fast traveling, please wait","BLACK",2];
			sleep 2;
		} else {
			hcShowBar false;
			hcShowBar true;
			hint format ["Moving group %1 to destination",groupID _group];
			sleep _distance;
		};
		_force = false;
		if !(isMultiplayer) then {
			if !(_marker in forcedSpawn) then {
				_force = true;
				forcedSpawn = forcedSpawn + [_marker];
				};
			};
		if (!_isHC) then {
			sleep _distance;
		};

		// have a chance to launch a QRF to the target camp
		if ((_marker in campsFIA) && (random 10 < 1) && !(captive player)) then {
			[_marker] remoteExec ["DEF_Camp",HCattack];
			[format ["Camp under attack: %1", _marker]] remoteExec ["AS_fnc_logOutput", 2];
		};

		if (_enemiesNearGroup) then {
			player allowDamage false;
			if !(player == vehicle player) then {
				if (driver vehicle player == player) then {
					sleep 3;
					_tam = 10;
					while {true} do {
						_roads = _position nearRoads _tam;
						if (count _roads < 1) then {_tam = _tam + 10};
						if (count _roads > 0) exitWith {};
					};
					_road = _roads select 0;
					_pos = position _road findEmptyPosition [1, 50, typeOf (vehicle player)];
					vehicle player setPosATL _pos;
				};
				if ((vehicle player isKindOf "StaticWeapon") and !(isPlayer (leader player))) then {
					_pos = _position findEmptyPosition [1, 50, typeOf (vehicle player)];
					vehicle player setPosATL _pos;
				};
			}
			else {
				if !(isNil {player getVariable "inconsciente"}) then {
					if !(player getVariable "inconsciente") then {
						_position = _position findEmptyPosition [1, 50, typeOf player];
						player setPosATL _position;
					};
				} else {
					_position = _position findEmptyPosition [1, 50, typeOf player];
					player setPosATL _position;
				};
			};
		} else {
			{
				_unit = _x;
				_unit allowDamage false;
				if !(_unit == vehicle _unit) then {
					if (driver vehicle _unit == _unit) then {
						sleep 3;
						_tam = 10;
						while {true} do {
							_roads = _position nearRoads _tam;
							if (count _roads < 1) then {_tam = _tam + 10};
							if (count _roads > 0) exitWith {};
						};
						_road = _roads select 0;
						_pos = position _road findEmptyPosition [1, 50, typeOf (vehicle _unit)];
						vehicle _unit setPosATL _pos;
					};
					if ((vehicle _unit isKindOf "StaticWeapon") and !(isPlayer (leader _unit))) then {
						_pos = _position findEmptyPosition [1, 50, typeOf (vehicle _unit)];
						vehicle _unit setPosATL _pos;
					};
				} else {
					if (!isNil {_unit getVariable "inconsciente"}) then {
						if (!(_unit getVariable "inconsciente")) then {
							_position = _position findEmptyPosition [1, 50, typeOf _unit];
							_unit setPosATL _position;
							if (isPlayer leader _unit) then {_unit setVariable ["rearming",false]};
							_unit doWatch objNull;
							_unit doFollow leader _unit;
						};
					} else {
						_position = _position findEmptyPosition [1, 50, typeOf _unit];
						_unit setPosATL _position;
					};
				};
			} forEach units _group;
		};

		if (!_isHC) then {
			disableUserInput false;
			cutText ["You arrived at your destination.","BLACK IN",3];
		} else {
			hint format ["Group %1 arrived at their destination.", groupID _group]};
		if (_force) then {
			forcedSpawn = forcedSpawn - [_marker];
		};
		sleep 5;
		{_x allowDamage true} forEach units _group;
	} else {
		Hint "You must click near a camp or HQ";
	};
};
openMap false;