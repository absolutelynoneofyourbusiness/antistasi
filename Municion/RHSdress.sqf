_unit = _this select 0;

_tipo = typeOf _unit;
_emptyUniform = false;

if ((_tipo == guer_sol_RFL) or (_tipo == guer_sol_GL) or (_tipo == guer_sol_LAT) or (_tipo == guer_sol_R_L) or (_tipo == guer_sol_MED) or (_tipo == guer_sol_ENG) or (_tipo == guer_sol_EXP) or (_tipo == guer_sol_AM)) then
	{
	if (_tipo == guer_sol_LAT) then
		{
		for "_i" from 1 to ({_x == "RPG32_F"} count magazines _unit) do
					{
					_unit removeMagazine "RPG32_F";
					};
				_unit removeMagazine "RPG32_HE_F";
				_unit removeWeaponGlobal "launch_RPG32_F";
				[_unit, "rhs_weap_rpg7", 4, 0] call BIS_fnc_addWeapon;
		};
	if (not(_tipo == guer_sol_GL)) then
		{
		for "_i" from 1 to ({_x == "30Rnd_556x45_Stanag"} count magazines _unit) do
			{
			_unit removeMagazine "30Rnd_556x45_Stanag";
			};
		_unit removeWeaponGlobal (primaryWeapon _unit);
		[_unit, unlockedRifles call BIS_fnc_selectRandom, 5, 0] call BIS_fnc_addWeapon;
		}
	else
		{
		if (activeAFRF) then
			{
			removeAllItemsWithMagazines _unit;
			for "_i" from 1 to 6 do {_unit addItemToVest "rhs_30Rnd_762x39mm"; _unit addItemToVest "rhs_VOG25";};
			_unit addWeapon "rhs_weap_akms_gp25";
			_emptyUniform = true;
			};
		};
	};

if ((_tipo == guer_sol_SL) or (_tipo == guer_sol_TL) or (_tipo == guer_sol_OFF)) then
	{
	removeAllItemsWithMagazines _unit;
	for "_i" from 1 to 6 do {_unit addItemToVest "rhs_30Rnd_545x39_AK"; _unit addItemToVest "rhs_VOG25";};
	_unit addWeapon "rhs_weap_ak74m_gp25";
	_unit addPrimaryWeaponItem "rhs_acc_1p29";
	_unit addItemToVest "SmokeShell";
	_unit addItemToVest "SmokeShell";
	_emptyUniform = true;
	};

if (_tipo == guer_sol_AR) then
	{
	removeAllItemsWithMagazines _unit;
	_unit removeWeaponGlobal (primaryWeapon _unit);
	_unit addMagazine ["rhs_100Rnd_762x54mmR", 100];
	_unit addWeaponGlobal "rhs_weap_pkm";
	_unit addMagazine ["rhs_100Rnd_762x54mmR", 100];
	_unit addMagazine ["rhs_100Rnd_762x54mmR", 100];
	_emptyUniform = true;
	};

if (_tipo == guer_sol_MRK) then
	{
	for "_i" from 1 to ({_x == "30Rnd_556x45_Stanag"} count magazines _unit) do
		{
		_unit removeMagazine "30Rnd_556x45_Stanag";
		};
	_unit removeWeaponGlobal (primaryWeapon _unit);
	[_unit, "rhs_weap_svdp_wd", 8, 0] call BIS_fnc_addWeapon;
	_unit addPrimaryWeaponItem "rhs_acc_pso1m2";
	};

if (_emptyUniform) then
	{
	_unit addItemToUniform "FirstAidKit";
	_unit addMagazine ["HandGrenade", 1];
	_unit addMagazine ["SmokeShell", 1];
	};

_unit selectWeapon (primaryWeapon _unit);
