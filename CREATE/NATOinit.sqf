params ["_unit"];

_unit triggerDynamicSimulation false;
_unit allowFleeing 0;
_unit setSkill 0.7;

_unit addEventHandler ["killed", {
	params ["_corpse"];
	[0.25,0,getPos _corpse] remoteExec ["AS_fnc_changeCitySupport",2];
	[_corpse] spawn postmortem;
}];

if (sunOrMoon < 1) then {
	if (bluIR in primaryWeaponItems _unit) then {_unit action ["IRLaserOn", _unit]};
};

VcomAI_UnitQueue pushback _unit;