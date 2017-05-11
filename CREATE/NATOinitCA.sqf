params ["_unit"];

_unit setVariable ["BLUFORSpawn",true,true];
_unit triggerDynamicSimulation true;
_unit allowFleeing 0;
_unit setSkill 0.7;

if (sunOrMoon < 1) then {
	if (bluIR in primaryWeaponItems _unit) then {_unit action ["IRLaserOn", _unit]};
};

_EHkilledIdx = _unit addEventHandler ["killed", {
	params ["_corpse"];
	_corpse setVariable ["BLUFORSpawn",nil,true];
	[_corpse] spawn postmortem;
	[0.25,0,getPos _corpse] remoteExec ["AS_fnc_changeCitySupport",2];
}];

VcomAI_UnitQueue pushback _unit;