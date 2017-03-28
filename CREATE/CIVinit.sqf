private ["_unit","_enemigos"];

_unit = _this select 0;

_unit setSkill 0;
_unit setSpeedMode "LIMITED";

_EHkilledIdx = _unit addEventHandler ["killed", {
	_muerto = _this select 0;
	_killer = _this select 1;

	if (activeACE) then {
		if ((isNull _killer) || (_killer == _muerto)) then {
			_killer = _muerto getVariable ["ace_medical_lastDamageSource", _killer];
		};
	};

	if (_muerto == _killer) then {
		[-1,-1,getPos _muerto] remoteExec ["AS_fnc_changeCitySupport",2];
	} else {
		if (isPlayer _killer) then {
			if (!isMultiPlayer) then {
				[0,-20] remoteExec ["resourcesFIA",2];
				_killer addRating -500;
			} else {
				if (typeOf _muerto in CIV_workers) then {_killer addRating -1000};
				[-10,_killer] call playerScoreAdd;
			};
		};
		_multiplicador = 1;
		if (typeOf _muerto in CIV_journalists) then {_multiplicador = 10};
		if (side _killer == side_blue) then {
			[-1*_multiplicador,0] remoteExec ["prestige",2];
			[1,0,getPos _muerto] remoteExec ["AS_fnc_changeCitySupport",2];
		} else {
			if (side _killer == side_green) then {
				[1*_multiplicador,0] remoteExec ["prestige",2];
				[0,1,getPos _muerto] remoteExec ["AS_fnc_changeCitySupport",2];
			} else {
				if (side _killer == side_red) then {
					[2*_multiplicador,0] remoteExec ["prestige",2];
					[-1,1,getPos _muerto] remoteExec ["AS_fnc_changeCitySupport",2];
				};
			};
		};
	};
}];

_testEH = _unit addEventHandler ["HandleDamage", {
	_unit = _this select 0;
	_part = _this select 1;
	_damage = _this select 2;
	_source = _this select 3;
	_projectile = _this select 4;
	_damage
}];