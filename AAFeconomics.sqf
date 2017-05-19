private ["_enemyFunds", "_enemySupport", "_coefficient", "_progressFIA", "_destroyedCities", "_zone", "_price", "_minefieldDone"];

// prices for each action
#define 	PRICE_REPAIR		5000
#define 	PRICE_PLANE			17500
#define 	PRICE_TANK			10000
#define 	PRICE_GUNSHIP		8000
#define 	PRICE_APC			5000
#define 	PRICE_MINEFIELD		2000
#define 	PRICE_SKILL_BASE	1000
#define 	PRICE_SKILL_COEF	750
#define 	PRICE_SKILL_SOL		1/280

// minimum number of territories held by FIA to enable AAF to acquire specific vehicle types
#define 	THRES_PLANE			6
#define 	THRES_TANK			5
#define 	THRES_GUNSHIP		3
#define 	THRES_APC			2

_enemyFunds = server getVariable ["resourcesAAF", 0];
_enemySupport = server getVariable ["prestigeCSAT", 0];

waitUntil {sleep 1; !resourcesIsChanging};
resourcesIsChanging = true;

_coefficient = [2, 1] select isMultiplayer;
_progressFIA = count (mrkFIA - puestosFIA - ["FIA_HQ"] - ciudades - controles);

// repair cities/radio towers/power plants
if (_enemyFunds > (PRICE_REPAIR*_coefficient)) then {
	_destroyedCities = destroyedCities - mrkFIA - ciudades;

	if (count _destroyedCities > 0) then {
		{
			if ((_enemyFunds > (PRICE_REPAIR*_coefficient)) AND {!(spawner getVariable _x)}) then {
				_enemyFunds = _enemyFunds - (PRICE_REPAIR*_coefficient);
				destroyedCities = destroyedCities - [_x];
				publicVariable "destroyedCities";
				[10, 0, getMarkerPos _x] remoteExec ["AS_fnc_changeCitySupport", 2];
				[-5, 0] remoteExec ["prestige", 2];
				if (_x in power) then {[_x] call AS_fnc_powerReorg};
				["TaskFailed", ["", format ["%1 has been rebuilt by %2", [_x] call AS_fnc_localizar, A3_Str_INDEP]]] remoteExec ["BIS_fnc_showNotification", [0,-2] select isDedicated];
			};
		} forEach _destroyedCities;
	} else {
		if ((count antenasMuertas > 0) AND {!("REP" in misiones)}) then {
			{
				if ((_enemyFunds > (PRICE_REPAIR*_coefficient)) and {!("REP" in misiones)}) then{
					_zone = [marcadores, _x] call BIS_fnc_nearestPosition;
					if ((_zone in mrkAAF) AND {!(spawner getVariable _zone)}) then {
						diag_log format ["Repairing antenna near %1", _zone];
						[_zone, _x] remoteExec ["REP_Antena", HCattack];
						_enemyFunds = _enemyFunds - (PRICE_REPAIR*_coefficient);
					};
				};
			} forEach antenasMuertas;
		};
	};
};

// break if FIA haven't made any territorial progress yet
if (_progressFIA == 0) exitWith {resourcesIsChanging = false};

// buy planes
if ((planesAAFcurrent < planesAAFmax) AND {helisAAFcurrent > 3} AND {_progressFIA > THRES_PLANES}) then {
	if (_enemyFunds > (PRICE_PLANE*_coefficient)) then {
		indAirForce = indAirForce + planes;
		indAirForce = indAirForce arrayIntersect indAirForce;
		publicVariable "indAirForce";

		planesAAFcurrent = planesAAFcurrent + 1;
		publicVariable "planesAAFcurrent";
		_enemyFunds = _enemyFunds - (PRICE_PLANE*_coefficient);
		diag_log format ["Econ report: airplanes acquired. Current number: %1; remaining resources: %2", planesAAFcurrent, _enemyFunds];
	};
};

// buy tanks
if ((tanksAAFcurrent < tanksAAFmax) AND {APCAAFcurrent > 3} AND {_progressFIA > THRES_TANKS} AND {planesAAFcurrent != 0}) then {
	if (_enemyFunds > (PRICE_TANK*_coefficient)) then {
		enemyMotorpool = enemyMotorpool + vehTank;
		enemyMotorpool = enemyMotorpool arrayIntersect enemyMotorpool;
		publicVariable "enemyMotorpool";

		tanksAAFcurrent = tanksAAFcurrent + 1;
		publicVariable "tanksAAFcurrent";
	    _enemyFunds = _enemyFunds - (PRICE_TANK*_coefficient);
	    diag_log format ["Econ report: tanks acquired. Current number: %1; remaining resources: %2", tanksAAFcurrent, _enemyFunds];
	};
};

// buy gunships
if ((helisAAFcurrent < helisAAFmax) AND {_progressFIA > THRES_GUNSHIP} AND {(helisAAFcurrent < 4) OR {planesAAFcurrent > 3}}) then {
	if (_enemyFunds > (PRICE_GUNSHIP*_coefficient)) then {
		indAirForce = indAirForce + heli_armed;
		indAirForce = indAirForce arrayIntersect indAirForce;
		publicVariable "indAirForce";

		helisAAFcurrent = helisAAFcurrent + 1;
		publicVariable "helisAAFcurrent";
		_enemyFunds = _enemyFunds - (PRICE_GUNSHIP*_coefficient);
		diag_log format ["Econ report: helicopters acquired. Current number: %1; remaining resources: %2", helisAAFcurrent, _enemyFunds];
	};
};

// buy APCs/IFVs
if ((APCAAFcurrent < APCAAFmax) AND {_progressFIA > THRES_APC} AND {(tanksAAFcurrent > 2) or {APCAAFcurrent < 4}}) then {
	if (_enemyFunds > (PRICE_APC*_coefficient)) then {
		enemyMotorpool = enemyMotorpool + vehAPC + vehIFV;
		enemyMotorpool = enemyMotorpool arrayIntersect enemyMotorpool;
		publicVariable "enemyMotorpool";

	    APCAAFcurrent = APCAAFcurrent + 1;
	    publicVariable "APCAAFcurrent";
	    _enemyFunds = _enemyFunds - (PRICE_APC*_coefficient);
	    diag_log format ["Econ report: APCs/IFVs acquired. Current number: %1; remaining resources: %2", APCAAFcurrent, _enemyFunds];
	};
};

// buy skill levels
if ((skillAAF < ((server getVariable ["skillFIA", 1]) + 2)) AND {skillAAF < 17}) then {
	diag_log format ["Econ report: AAF skill. Current level: %1; current cost: %2; current resources: %3", skillAAF, PRICE_SKILL_BASE + (skillAAF * _coefficient * PRICE_SKILL_COEF), _enemyFunds];
	if ((PRICE_SKILL_BASE + (skillAAF * _coefficient * PRICE_SKILL_COEF)) < _enemyFunds) then {
		skillAAF = skillAAF + 1;
		publicVariable "skillAAF";
		_enemyFunds = _enemyFunds - (PRICE_SKILL_BASE + (skillAAF * _coefficient * PRICE_SKILL_COEF));
		{
			_price = server getVariable [_x, 100];
			_price = round (_price + (_price * skillAAF * PRICE_SKILL_SOL));
			server setVariable [_x, _price, true];
		} forEach units_enemySoldiers;
	};
};

// deploy minefield
if (_enemyFunds > (PRICE_MINEFIELD*_coefficient)) then{
	{
		if (_enemyFunds < (PRICE_MINEFIELD*_coefficient)) exitWith {};
		if ([_x] call AS_fnc_isFrontline) then {
			_zone = [mrkFIA,getMarkerPos _x] call BIS_fnc_nearestPosition;
			_minefieldDone = false;
			_minefieldDone = [_zone,_x] call minefieldAAF;
			if (_minefieldDone) then {_enemyFunds = _enemyFunds - (PRICE_MINEFIELD*_coefficient)};
			diag_log format ["Econ report: minefield deployed. Location: %1; current resources: %2", _x, _enemyFunds];
		};
	} forEach (bases - mrkFIA);
};

server setVariable ["resourcesAAF", round _enemyFunds, true];

resourcesIsChanging = false;