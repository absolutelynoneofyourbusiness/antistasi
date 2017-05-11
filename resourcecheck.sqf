if (!isServer) exitWith{};

if (isMultiplayer) then {waitUntil {!isNil "switchCom"}};

private ["_incomeFIA","_incomeEnemy","_hrFIA","_popFIA","_popEnemy","_bonusFIA","_bonusEnemy","_city","_cityIncomeFIA","_cityIncomeEnemy","_cityIncomeHR","_data","_civilians","_supportFIA","_supportEnemy","_power","_coef","_mrkD","_base","_factory","_resource","_text","_updated","_resourcesAAF","_vehicle","_script", "_coefHR"];
scriptName "resourcecheck";

while {true} do {
	sleep 600;//600
	if (isMultiplayer) then {waitUntil {sleep 10; isPlayer Slowhand}};
	_incomeEnemy = 0;
	_incomeFIA = 25;//0
	_hrFIA = 0;//0
	_popFIA = 0;
	_popEnemy = 0;
	_bonusEnemy = 1;
	_bonusFIA = 1;

	_coefHR = 20000;
	if !(isNil "defaultPopulation") then {
		_coefHR = defaultPopulation * 3;
	};

	{
		_city = _x;
		_cityIncomeEnemy = 0;
		_cityIncomeFIA = 0;
		_cityIncomeHR = 0;
		_data = server getVariable [_city,[0,0,1,1]];
		_civilians = _data select 0;
		_supportEnemy = _data select 2;
		_supportFIA = _data select 3;
		_power = [_city] call AS_fnc_powerCheck;
		_coef = [0.5,1] select _power;
		_popFIA = _popFIA + (_civilians * (_supportFIA / 100));
		_popEnemy = _popEnemy + (_civilians * (_supportEnemy / 100));

		if (_city in destroyedCities) then {
			_cityIncomeEnemy = 0;
			_cityIncomeFIA = 0;
			_cityIncomeHR = 0;
		} else {
			_cityIncomeEnemy = ((_civilians * _coef*(_supportEnemy / 100)) /3);
			_cityIncomeFIA = ((_civilians * _coef*(_supportFIA / 100))/3);
			_cityIncomeHR = (_civilians * (_supportFIA / _coefHR));

			if (_city in mrkFIA) then {
				_cityIncomeEnemy = (_cityIncomeEnemy/2);
				if (_power) then {
					if (_supportFIA + _supportEnemy + 1 <= 100) then {[0,1,_city] spawn AS_fnc_changeCitySupport};
				} else {
					if (_supportFIA > 6) then {
						[0,-1,_city] spawn AS_fnc_changeCitySupport;
					} else {
						[1,0,_city] spawn AS_fnc_changeCitySupport;
					};
				};
			} else {
				_cityIncomeFIA = (_cityIncomeFIA/2);
				_cityIncomeHR = (_cityIncomeHR/2);
				if (_power) then {
					if (_supportEnemy + _supportFIA + 1 <= 100) then {[1,0,_city] call AS_fnc_changeCitySupport};
				} else {
					if (_supportEnemy > 6) then {
						[-1,0,_city] spawn AS_fnc_changeCitySupport;
					} else {
						[0,1,_city] spawn AS_fnc_changeCitySupport;
					};
				};
			};
		};

		_incomeEnemy = _incomeEnemy + _cityIncomeEnemy;
		_incomeFIA = _incomeFIA + _cityIncomeFIA;
		_hrFIA = _hrFIA + _cityIncomeHR;

		if ((_supportEnemy < _supportFIA) AND (_city in mrkAAF)) then {
			[["TaskSucceeded", ["", format ["%1 joined FIA",[_city, false] call AS_fnc_location]]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
			mrkAAF = mrkAAF - [_city];
			mrkFIA = mrkFIA + [_city];
			// Respawn city with new garrison
			[_city] spawn {
				params ["_city"];
				spawner setVariable [_city,false,true];
				sleep 30;
				waitUntil {sleep 3; !([distanciaSPWN,1,getMarkerPos _city,"BLUFORSpawn"] call distanceUnits) AND !([distanciaSPWN,1,getMarkerPos _city,"OPFORSpawn"] call distanceUnits)};
				[_city] call AS_fnc_respawnZone;
			};
			if (activeBE) then {["con_cit"] remoteExec ["fnc_BE_XP", 2]};
			publicVariable "mrkAAF";
			publicVariable "mrkFIA";
			[0,5] remoteExec ["prestige",2];
			_mrkD = format ["Dum%1",_city];
			_mrkD setMarkerColor guer_marker_colour;
			if (_power) then {_power = false} else {_power = true};
			[_city,_power] spawn AS_fnc_adjustLamps;
			sleep 5;
			{[_city,_x] spawn AS_fnc_deleteRoadblock} forEach controles;
			if !("CONVOY" in misiones) then {
				_base = [_city] call AS_fnc_findBaseForConvoy;
				if ((_base != "") AND (random 3 < 1)) then {
					[_city,_base,"city"] remoteExec ["CONVOY",HCattack];
				};
			};
		};

		if ((_supportEnemy > _supportFIA) AND (_city in mrkFIA)) then {
			[["TaskFailed", ["", format ["%1 joined AAF",[_city, false] call AS_fnc_location]]],"BIS_fnc_showNotification"] call BIS_fnc_MP;
			mrkAAF = mrkAAF + [_city];
			mrkFIA = mrkFIA - [_city];
			// Respawn city with new garrison
			[_city] spawn {
				params ["_city"];
				spawner setVariable [_city,false,true];
				sleep 30;
				waitUntil {sleep 3; !([distanciaSPWN,1,getMarkerPos _city,"BLUFORSpawn"] call distanceUnits) AND !([distanciaSPWN,1,getMarkerPos _city,"OPFORSpawn"] call distanceUnits)};
				[_city] call AS_fnc_respawnZone;
			};
			publicVariable "mrkAAF";
			publicVariable "mrkFIA";
			[0,-5] remoteExec ["prestige",2];
			_mrkD = format ["Dum%1",_city];
			_mrkD setMarkerColor IND_marker_colour;
			sleep 5;
			if (_power) then {_power = false} else {_power = true};
			[_city,_power] spawn AS_fnc_adjustLamps;
		};
	} forEach ciudades;

	if ((_popFIA > _popEnemy) AND ("airport_3" in mrkFIA)) then {["end1",true,true,true,true] remoteExec ["BIS_fnc_endMission",0]};

	{
		_factory = _x;
		_power = [_factory] call AS_fnc_powerCheck;
		if (_power AND !(_factory in destroyedCities)) then {
			if (_factory in mrkFIA) then {_bonusFIA = _bonusFIA + 0.25};
			if (_factory in mrkAAF) then {_bonusEnemy = _bonusEnemy + 0.25};
		};
	} forEach fabricas;

	{
		_resource = _x;
		_power = [_resource] call AS_fnc_powerCheck;

		if !(_resource in destroyedCities) then {
			if (_power) then {
				if (_resource in mrkFIA) then {_incomeFIA = _incomeFIA + (300 * _bonusFIA)};
				if (_resource in mrkAAF) then {_incomeEnemy = _incomeEnemy + (300 * _bonusEnemy)};
			} else {
				if (_resource in mrkFIA) then {_incomeFIA = _incomeFIA + (100 * _bonusFIA)};
				if (_resource in mrkAAF) then {_incomeEnemy = _incomeEnemy + (100 * _bonusEnemy)};
			};
		};
	} forEach recursos;

	if (server getVariable ["easyMode",false]) then {
		_hrFIA = _hrFIA * 2;
		_incomeFIA = _incomeFIA * 1.5;
	};

	_hrFIA = (round _hrFIA);
	_incomeFIA = (round _incomeFIA);

	// BE module
	if (activeBE) then {
		if (_hrFIA > 0) then {
			_hrFIA = _hrFIA min (["HR"] call fnc_BE_permission);
		};
	};
	// BE module

	_text = format ["<t size='0.6' color='#C1C0BB'>Taxes Income.<br/> <t size='0.5' color='#C1C0BB'><br/>Manpower: +%1<br/>Money: +%2 €",_hrFIA,_incomeFIA];
	if !(activeJNA) then {
		_updated = [] call AS_fnc_updateArsenal;
		if (count _updated > 0) then {_text = format ["%1<br/>Arsenal Updated<br/><br/>%2",_text,_updated]};
	};

	[[petros,"taxRep",_text],"commsMP"] call BIS_fnc_MP;

	_hrFIA = _hrFIA + (server getVariable ["hr",0]);
	_incomeFIA = _incomeFIA + (server getVariable ["resourcesFIA",0]);

	if !(activeBE) then {
		if (_hrFIA > 100) then {_hrFIA = 100}; // HR capped to 100
	};

	server setVariable ["hr",_hrFIA,true];
	server setVariable ["resourcesFIA",_incomeFIA,true];
	_resourcesAAF = server getVariable ["resourcesAAF",0];
	if (isMultiplayer) then {_resourcesAAF = _resourcesAAF + (round (_incomeEnemy + (_incomeEnemy * ((server getVariable "prestigeCSAT")/100))))} else {_resourcesAAF = _resourcesAAF + (round _incomeEnemy)};
	server setVariable ["resourcesAAF",_resourcesAAF,true];
	if (isMultiplayer) then {[] spawn assignStavros};
	if (!("AtaqueAAF" in misiones) AND (random 100 < 50)) then {[] call missionRequestAUTO};
	if (AAFpatrols < 3) then {[] remoteExec ["genRoadPatrol",hcAttack]};

	{
		_vehicle = _x;
		if ((_vehicle isKindOf "StaticWeapon") AND ({isPlayer _x} count crew _vehicle == 0) AND (alive _vehicle)) then {
			_vehicle setDamage 0;
			[_vehicle,1] remoteExec ["setVehicleAmmoDef",_vehicle];
		};
	} forEach vehicles;
	cuentaCA = cuentaCA - 600;
	publicVariable "cuentaCA";
	if ((cuentaCA < 1) AND (diag_fps > minimoFPS)) then {

		[1200] remoteExec ["AS_fnc_increaseAttackTimer",2];
		if ((count mrkFIA > 0) AND !("AtaqueAAF" in misiones) AND !(server getVariable ["waves_active",false])) then {
			_script = [] spawn AS_fnc_spawnAttack;
			waitUntil {sleep 5; scriptDone _script};
		};
	};

	sleep 3;
	call AAFeconomics;
	sleep 4;
	[] call AS_fnc_FIAradio;
};