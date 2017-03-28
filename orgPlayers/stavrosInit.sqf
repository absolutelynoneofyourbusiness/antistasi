private ["_unit","_grupos","_oldUnit","_oldProviders","_HQ","_providerModule","_used"];
_unit = _this select 0;
_grupos = hcAllGroups Slowhand;
_oldUnit = Slowhand;

if (!isNil "_grupos") then {
  {
  	_oldUnit hcRemoveGroup _x;
  } forEach _grupos;
};

_oldUnit synchronizeObjectsRemove [HC_comandante];
//apoyo synchronizeObjectsRemove [_oldUnit];
HC_comandante synchronizeObjectsRemove [_oldUnit];
Slowhand = _unit;
publicVariable "Slowhand";
[group _unit, _unit] remoteExec ["selectLeader",_unit];
Slowhand synchronizeObjectsAdd [HC_comandante];
HC_comandante synchronizeObjectsAdd [Slowhand];
//apoyo synchronizeObjectsAdd [Slowhand];
if (!isNil "_grupos") then {
  	{_unit hcSetGroup [_x]} forEach _grupos;
}
else {
	{
		if (_x getVariable ["isHCgroup",false]) then {
			_unit hcSetGroup [_x];
		};
		/*
	if (_x getVariable ["esNATO",false]) then
		{
		diag_log format ["NATO group: %1", _x];
		_unit hcSetGroup [_x];
		};
	if ((leader _x getVariable ["BLUFORSpawn",false]) and (!isPlayer leader _x)) then
		{
		_unit hcSetGroup [_x];
		diag_log format ["BLUFOR group: %1", _x];
		};
		*/
	} forEach allGroups;
};

if (isNull _oldUnit) then {
	[_oldUnit,[group _oldUnit]] remoteExec ["hcSetGroup",_oldUnit];
};