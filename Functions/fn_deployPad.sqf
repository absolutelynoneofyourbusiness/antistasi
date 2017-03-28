params ["_obj", "_caller"];

private _pos = position _obj;
server setVariable ["AS_vehicleOrientation", [_caller, _obj] call BIS_fnc_dirTo, true];
if ((_pos distance fuego) > 30) exitWith {
	[petros,"hint","Too far from HQ."] remoteExec ["commsMP",Slowhand];
	deleteVehicle _obj;
};
if !(isNil "vehiclePad") exitWith {
	[petros,"hint","Pad already deployed."] remoteExec ["commsMP",Slowhand];
	deleteVehicle _obj;
};

deleteVehicle _obj;
vehiclePad = createVehicle ["Land_JumpTarget_F", _pos, [], 0, "CAN_COLLIDE"];