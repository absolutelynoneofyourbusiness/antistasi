private ["_veh","_tipo"];

_veh = _this select 0;

if ((_veh isKindOf "FlagCarrier") or (_veh isKindOf "Building")) exitWith {};
if (_veh isKindOf "ReammoBox_F") exitWith {[_veh] call cajaAAF};
if ((activeACE) && !(random 3 > 2)) then {_veh setVariable ["ace_cookoff_enable", false, true]};

_tipo = typeOf _veh;

if ((activeACE) && (random 8 < 7)) then {_veh setVariable ["ace_cookoff_enable", false, true]};

if ((_tipo in vehTrucks) or (_tipo in vehPatrol) or (_tipo in vehSupply) or (_tipo in enemyMotorpool) or (_tipo in vehPatrolBoat)) then
	{
	if !(_tipo in enemyMotorpool) then
		{
		if (_tipo == vehAmmo) then
			{
			if (_veh distance getMarkerPos guer_respawn > 50) then {[_veh] call cajaAAF};
			};
		_veh addEventHandler ["killed",{
			[-1000] remoteExec ["resourcesAAF",2];
			if (activeBE) then {["des_veh"] remoteExec ["fnc_BE_XP", 2]};
		}];
		if (_veh isKindOf "Car") then
			{
			_veh addEventHandler ["HandleDamage",{if (((_this select 1) find "wheel" != -1) and (_this select 4=="") and (!isPlayer driver (_this select 0))) then {0;} else {(_this select 2);};}];
			};
		}
	else
		{
		if ((_tipo in vehAPC) or (_tipo in vehIFV)) then
			{
			_veh addEventHandler ["killed",{
				if (side (_this select 1) == side_blue) then {
					[_this select 0] call AS_fnc_AAFassets;
					[-2,2,position (_this select 0)] remoteExec ["AS_fnc_changeCitySupport",2];
					if (activeBE) then {["des_arm"] remoteExec ["fnc_BE_XP", 2]};
				}
			}];
			_veh addEventHandler ["HandleDamage",{private ["_veh"]; _veh = _this select 0; if (!canFire _veh) then {[_veh] call smokeCoverAuto}}];
			}
		else
			{
			if (_tipo in vehTank) then
				{
				_veh addEventHandler ["killed",{
					if (side (_this select 1) == side_blue) then {
						[_this select 0] call AS_fnc_AAFassets; call AS_fnc_AAFassets;
						[-5,5,position (_this select 0)] remoteExec ["AS_fnc_changeCitySupport",2];
						if (activeBE) then {["des_arm"] remoteExec ["fnc_BE_XP", 2]};
					}
				}];
				_veh addEventHandler ["HandleDamage",{private ["_veh"]; _veh = _this select 0; if (!canFire _veh) then {[_veh] call smokeCoverAuto}}];
				};
			};
		};
	}
else
	{
	if (_tipo in indAirForce) then
		{
		_veh addEventHandler ["GetIn",
			{
			_posicion = _this select 1;
			if (_posicion == "driver") then
				{
				_unit = _this select 2;
				if ((!isPlayer _unit) and (_unit getVariable ["BLUFORSpawn",false])) then
					{
					moveOut _unit;
					hint "Only Humans can pilot an air vehicle";
					};
				};
			}];
		if (_tipo in heli_unarmed) then
			{
			_veh addEventHandler ["killed",{
				[-4000] remoteExec ["resourcesAAF",2];
				if (activeBE) then {["des_veh"] remoteExec ["fnc_BE_XP", 2]};
			}];
			}
		else
			{
			if (_veh isKindOf "Helicopter") then {_veh addEventHandler ["killed",{[_this select 0] call AS_fnc_AAFassets;[1,1] remoteExec ["prestige",2]; [-2,2,position (_this select 0)] remoteExec ["AS_fnc_changeCitySupport",2]}]};
			if (_veh isKindOf "Plane") then {_veh addEventHandler ["killed",{[_this select 0] call AS_fnc_AAFassets; call AS_fnc_AAFassets;[2,1] remoteExec ["prestige",2]; [-5,5,position (_this select 0)] remoteExec ["AS_fnc_changeCitySupport",2]}]};
			};
		}
	else
		{
		if (_tipo == indUAV_large) then
			{
			_veh addEventHandler ["killed",{[-2500] remoteExec ["resourcesAAF",2]}];
			}
		else
			{
			if (_veh isKindOf "StaticWeapon") then
				{
				[[_veh,"steal"],"AS_fnc_addActionMP"] call BIS_fnc_MP;
				}
			};
		};
	};
[_veh] spawn vehicleRemover;

//_veh addEventHandler ["Killed",{[_this select 0] spawn postmortem}];

if ((count crew _veh) > 0) then
	{
	[_veh] spawn VEHdespawner
	}
else
	{
	_veh addEventHandler ["GetIn",
		{
		_veh = _this select 0;
		[_veh] spawn VEHdespawner;
		}
		];
	};