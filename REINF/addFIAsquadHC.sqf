
if (player != Slowhand) exitWith {hint "Only Commander Slowhand has access to this function"};
if (!allowPlayerRecruit) exitWith {hint "Server is very loaded. \nWait one minute or change FPS settings in order to fulfill this request"};
if (markerAlpha guer_respawn == 0) exitWith {hint "You cant recruit a new squad while you are moving your HQ"};
if (!([player] call hasRadio)) exitWith {hint "You need a radio in your inventory to be able to give orders to other squads"};
_chequeo = false;
{
	if (((side _x == side_red) or (side _x == side_green)) and (_x distance petros < safeDistance_recruit) and (not(captive _x))) then {_chequeo = true};
} forEach allUnits;

if (_chequeo) exitWith {Hint "You cannot Recruit Squads with enemies near your HQ"};

private ["_tipogrupo","_esinf","_tipoVeh","_coste","_costeHR","_exit","_formato","_pos","_hr","_resourcesFIA","_grupo","_roads","_road","_grupo","_camion","_vehicle","_mortero","_morty"];


_tipogrupo = _this select 0;
_esinf = false;
_tipoVeh = "";
_coste = 0;
_costeHR = 0;
_exit = false;
_formato = "";

_hr = server getVariable "hr";
_resourcesFIA = server getVariable "resourcesFIA";

private ["_grupo","_roads","_camion"];

_check = false;
_check = ((_tipogrupo isEqualTo guer_grp_squad) or (_tipogrupo isEqualTo guer_grp_team) or (_tipogrupo isEqualTo guer_grp_AT) or (_tipogrupo isEqualTo guer_grp_sniper) or (_tipogrupo isEqualTo guer_grp_sentry));

if (_check) then
	{
	_formato = ([_tipogrupo, "guer"] call AS_fnc_pickGroup);
	if !(typeName _tipogrupo == "ARRAY") then {
		_tipogrupo = [_formato] call groupComposition;
	};
	{_coste = _coste + (server getVariable _x); _costeHR = _costeHR +1} forEach _tipogrupo;

	//if (_costeHR > 4) then {_tipoVeh = guer_veh_truck} else {_tipoVeh = guer_veh_offroad};
	//_coste = _coste + ([_tipoVeh] call vehiclePrice);
	_esinf = true;
	}
else
	{
	_coste = _coste + (2*(server getVariable guer_sol_R_L));
	_costeHR = 2;
	_coste = _coste + ([_tipogrupo] call vehiclePrice) + ([guer_veh_truck] call vehiclePrice);

	if ((activeAFRF) && (_tipogrupo == guer_stat_AA)) then {
		_coste = 3*(server getVariable guer_sol_R_L);
		_costeHR = 3;
		_coste = _coste + ([vehTruckAA] call vehiclePrice);
	};
};

if (_hr < _costeHR) then {_exit = true;hint format ["You do not have enough HR for this request (%1 required)",_costeHR]};

if (_resourcesFIA < _coste) then {_exit = true;hint format ["You do not have enough money for this request (%1 € required)",_coste]};

if (_exit) exitWith {};

[- _costeHR, - _coste] remoteExec ["resourcesFIA",2];

_pos = getMarkerPos guer_respawn;
_tam = 10;
while {true} do
	{
	_roads = _pos nearRoads _tam;
	if (count _roads < 1) then {_tam = _tam + 10};
	if (count _roads > 0) exitWith {};
	};
_road = _roads select 0;

if (activeAFRF) then {
	if (_esinf) then {
		_pos = [(getMarkerPos guer_respawn), 30, random 360] call BIS_Fnc_relPos;
		_grupo = [_pos, side_blue, ([_tipogrupo, "guer"] call AS_fnc_pickGroup)] call BIS_Fnc_spawnGroup;
		if (_tipogrupo isEqualTo guer_grp_squad) then {_formato = "Squd-"};
		if (_tipogrupo isEqualTo guer_grp_team) then {_formato = "Tm-"};
		if (_tipogrupo isEqualTo guer_grp_AT) then {_formato = "AT-"};
		if (_tipogrupo isEqualTo guer_grp_sniper) then {_formato = "Snpr-"};
		if (_tipogrupo isEqualTo guer_grp_sentry) then {_formato = "Stry-"};
		_formato = format ["%1%2",_formato,{side (leader _x) == side_blue} count allGroups];
		_grupo setGroupId [_formato];
		}
	else {
		_pos = position _road findEmptyPosition [1,30,guer_veh_truck];
		if (_tipogrupo == guer_stat_AA) then {
			_vehicle=[_pos, 0, vehTruckAA, side_blue] call bis_fnc_spawnvehicle;
			_veh = _vehicle select 0;
			_vehCrew = _vehicle select 1;
			{deleteVehicle _x} forEach crew _veh;
			_grupo = _vehicle select 2;
			[_veh] spawn VEHinit;
			_driv = _grupo createUnit [guer_sol_UN, _pos, [],0, "NONE"];
			_driv moveInDriver _veh;
			driver _veh action ["engineOn", vehicle driver _veh];
			_gun = _grupo createUnit [guer_sol_UN, _pos, [],0, "NONE"];
			_gun moveInGunner _veh;
			_com = _grupo createUnit [guer_sol_UN, _pos, [],0, "NONE"];
			_com moveInCommander _veh;
			_grupo setGroupId [format ["M.AA-%1",{side (leader _x) == side_blue} count allGroups]];
		}
		else {
			if (replaceFIA) then {
				if (_tipogrupo == guer_stat_AT) then {
					_vehicle = [_pos, 0, guer_veh_technical_AT, side_blue] call bis_fnc_spawnvehicle;
					_camion = _vehicle select 0;
					_grupo = _vehicle select 2;
				};
			} else {
				_vehicle=[_pos, 0,guer_veh_truck, side_blue] call bis_fnc_spawnvehicle;
				_camion = _vehicle select 0;
				_grupo = _vehicle select 2;
				_pos = _pos findEmptyPosition [1,30,guer_stat_mortar];
				_attachPos = [0,-1.5,0.2];
				if (_tipogrupo == guer_stat_AT) then {
					_mortero = "rhs_SPG9M_MSV" createVehicle _pos;
					_attachPos = [0,-2.4,-0.6];
				}
				else {
					_mortero = _tipogrupo createVehicle _pos;
				};

				//_mortero = "rhs_SPG9M_MSV" createVehicle _pos;
				[_mortero] spawn VEHinit;
				_morty = _grupo createUnit [guer_sol_UN, _pos, [],0, "NONE"];
				//_mortero attachTo [_camion,[0,-1.5,0.2]];
				//_mortero setDir (getDir _camion + 180);
				_grupo setVariable ["staticAutoT",false,true];
				if (_tipogrupo == guer_stat_mortar) then {
					_morty moveInGunner _mortero;
					[_morty,_camion,_mortero] spawn mortyAI;
					_grupo setGroupId [format ["Mort-%1",{side (leader _x) == side_blue} count allGroups]];
					}
				else {
					//_mortero attachTo [_camion,[0,-2.4,-0.6]];
					_mortero attachTo [_camion,_attachPos];
					_mortero setDir (getDir _camion + 180);
					_morty moveInGunner _mortero;
					/*
					_mortero attachTo [_camion,[0,-1.5,0.2]];
					_mortero setDir (getDir _camion + 180);
					_morty moveInGunner _mortero;
					*/
					if (_tipogrupo == guer_stat_AT) then {_grupo setGroupId [format ["M.AT-%1",{side (leader _x) == side_blue} count allGroups]]};
					//if (_tipogrupo == "B_static_AA_F") then {_grupo setGroupId [format ["M.AA-%1",{side (leader _x) == side_blue} count allGroups]]};
					};
			};

		driver _camion action ["engineOn", vehicle driver _camion];
		[_camion] spawn VEHinit;
		};

	};


}
else {

if (_esinf) then
	{
	//_camion = _tipoveh createVehicle _pos;
	_pos = [(getMarkerPos guer_respawn), 30, random 360] call BIS_Fnc_relPos;
	_grupo = [_pos, side_blue, (configfile >> "CfgGroups" >> "West" >> "Guerilla" >> "Infantry" >> _tipogrupo)] call BIS_Fnc_spawnGroup;
	if (_tipogrupo isEqualTo guer_grp_squad) then {_formato = "Squd-"};
	if (_tipogrupo isEqualTo guer_grp_team) then {_formato = "Tm-"};
	if (_tipogrupo isEqualTo guer_grp_AT) then {_formato = "AT-"};
	if (_tipogrupo isEqualTo guer_grp_sniper) then {_formato = "Snpr-"};
	if (_tipogrupo isEqualTo guer_grp_sentry) then {_formato = "Stry-"};
	_formato = format ["%1%2",_formato,{side (leader _x) == side_blue} count allGroups];
	_grupo setGroupId [_formato];
	//[_grupo] spawn dismountFIA;
	//_grupo addVehicle _camion;
	}
else
	{
	_pos = position _road findEmptyPosition [1,30,guer_veh_truck];
	_vehicle=[_pos, 0,guer_veh_truck, side_blue] call bis_fnc_spawnvehicle;
	_camion = _vehicle select 0;
	_grupo = _vehicle select 2;
	_pos = _pos findEmptyPosition [1,30,guer_stat_mortar];
	_mortero = _tipogrupo createVehicle _pos;
	[_mortero] spawn VEHinit;
	_morty = _grupo createUnit [guer_sol_UN, _pos, [],0, "NONE"];
	//_mortero attachTo [_camion,[0,-1.5,0.2]];
	//_mortero setDir (getDir _camion + 180);
	_grupo setVariable ["staticAutoT",false,true];
	if (_tipogrupo == guer_stat_mortar) then
		{
		_morty moveInGunner _mortero;
		[_morty,_camion,_mortero] spawn mortyAI;
		_grupo setGroupId [format ["Mort-%1",{side (leader _x) == side_blue} count allGroups]];
		//artyFIA synchronizeObjectsAdd [_morty];
		//_morty synchronizeObjectsAdd [artyFIA];
		//[player, apoyo, artyFIA] call BIS_fnc_addSupportLink;
		}
	else
		{
		_mortero attachTo [_camion,[0,-1.5,0.2]];
		_mortero setDir (getDir _camion + 180);
		_morty moveInGunner _mortero;
		if (_tipogrupo isEqualTo guer_stat_AT) then {_grupo setGroupId [format ["M.AT-%1",{side (leader _x) == side_blue} count allGroups]]};
		if (_tipogrupo isEqualTo guer_stat_AA) then {_grupo setGroupId [format ["M.AA-%1",{side (leader _x) == side_blue} count allGroups]]};
		};
	driver _camion action ["engineOn", vehicle driver _camion];
	[_camion] spawn VEHinit;
	};

};

{[_x] call AS_fnc_initialiseFIAUnit} forEach units _grupo;
leader _grupo setBehaviour "SAFE";
Slowhand hcSetGroup [_grupo];
_grupo setVariable ["isHCgroup", true, true];
petros directSay "SentGenReinforcementsArrived";
hint format ["Group %1 at your command.\n\nGroups are managed from the High Command bar (Default: CTRL+SPACE)\n\nIf the group gets stuck, use the AI Control feature to make them start moving. Mounted Static teams tend to get stuck (solving this is WiP)\n\nTo assign a vehicle for this group, look at some vehicle, and use Vehicle Squad Mngmt option in Y menu", groupID _grupo];

if (!_esinf) exitWith {};

if (_tipogrupo isEqualTo guer_grp_squad) then
	{
	_tipoVeh = guer_veh_truck;
	}
else
	{
	if ((_tipogrupo isEqualTo guer_grp_sniper) or (_tipogrupo isEqualTo guer_grp_sentry)) then
		{
		_tipoVeh = guer_veh_quad;
		}
	else
		{
		_tipoVeh = guer_veh_offroad;
		};
	};

_coste = [_tipoVeh] call vehiclePrice;
private ["_display","_childControl"];
if (_coste > server getVariable "resourcesFIA") exitWith {};

createDialog "veh_query";

sleep 1;
disableSerialization;

_display = findDisplay 100;

if (str (_display) != "no display") then
	{
	_ChildControl = _display displayCtrl 104;
	_ChildControl  ctrlSetTooltip format ["Buy a vehicle for this squad for %1 €",_coste];
	_ChildControl = _display displayCtrl 105;
	_ChildControl  ctrlSetTooltip "Barefoot Infantry";
	};

waitUntil {(!dialog) or (!isNil "vehQuery")};

if ((!dialog) and (isNil "vehQuery")) exitWith {};

//if (!vehQuery) exitWith {vehQuery = nil};

vehQuery = nil;
//_resourcesFIA = server getVariable "resourcesFIA";
//if (_resourcesFIA < _coste) exitWith {hint format ["You do not have enough money for this vehicle: %1 € required",_coste]};
_pos = position _road findEmptyPosition [1,30,guer_veh_truck];
_mortero = _tipoVeh createVehicle _pos;
[_mortero] spawn VEHinit;
_grupo addVehicle _mortero;
_mortero setVariable ["owner",_grupo,true];
[0, - _coste] remoteExec ["resourcesFIA",2];
leader _grupo assignAsDriver _mortero;
{[_x] orderGetIn true; [_x] allowGetIn true} forEach units _grupo;
hint "Vehicle Purchased";
petros directSay "SentGenBaseUnlockVehicle";
