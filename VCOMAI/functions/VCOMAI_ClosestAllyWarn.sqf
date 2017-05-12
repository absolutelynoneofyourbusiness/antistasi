//Created on ???
// Modified on : 9/7/14 - Added radio check.   9/10/14 - Added PRIVATE commandArtilleryFire

private ["_Unit","_Wall","_Direction","_Killer","_UnitSide","_NoFlanking","_GrabVariable","_CheckStatus","_Array1","_NoFlanking2","_CheckStatus2","_GrabVariable2","_CombatStance","_group","_index","_WaypointIs","_waypoint0"];

params ["_Unit", "_Killer"];

_UnitGroup = (group _Unit);
_DeathPosition = getpos _Unit;

if !((side _UnitGroup) in VCOM_SideBasedMovement) exitWith {if (VCOM_AIDEBUG isEqualTo 1) then {systemChat format ["Exited ClosestAllyWarn1..: %1",_UnitGroup];};};

//If this gets attached to a player, then exit before doing anything
if (isPlayer _Unit) exitWith {if (VCOM_AIDEBUG isEqualTo 1) then {systemChat format ["Exited ClosestAllyWarn1a..: %1",_UnitGroup];};};


//If the unit is in the ArtilleryArray, then remove it
if (_Unit in ArtilleryArray) then {ArtilleryArray = ArtilleryArray - [_Unit];};

//Check to see if this unit should be moving to support others or not
//Check to see if this unit is garrisoned. If so, don't do anything
//Check to see if unit has radio. If the unit does not have a radio, then it will not move to support
_NoFlanking = _Unit getVariable ["VCOM_NOPATHING_Unit",false];
_NoAI = _Unit getVariable ["NOAI",false];
_GrabVariable = _Unit getVariable ["VCOM_GARRISONED",false];;

if (_NoFlanking || {_GrabVariable} || {_NoAI} || {!([_unit] call hasRadio)}) exitWith {if (VCOM_AIDEBUG isEqualTo 1) then {systemChat format ["Exited ClosestAllyWarn2..: %1",_UnitGroup];};}; //todo modified

_Array1 = _Unit call VCOMAI_FriendlyArray;
_Array1 = _Array1 - ArtilleryArray;

if (VCOM_AIDEBUG isEqualTo 1) then {
	systemChat format ["Man Down...: %1",_UnitGroup];
};

sleep (30 + (random 30));

if (VCOM_AIDEBUG isEqualTo 1) then {
	systemChat format ["Group is attempting to call for help...: %1",_UnitGroup];
};

_aliveCount = {alive _x} count (units _UnitGroup);

if (_aliveCount > 0) then {
	if (VCOM_AIDEBUG isEqualTo 1) then {
		systemChat format ["Group successfully called for help: %1",_UnitGroup];
	};

	{
		_NoFlanking2 = _x getVariable ["VCOM_NOPATHING_Unit",false];

		if !(_NoFlanking2) then {

			if ([_x] call hasRadio) then { //todo modified
					_GrabVariable2 = _x getVariable ["VCOM_GARRISONED",false];

					if !(_GrabVariable2) then {
						_group	= group _x;

						if (((count (waypoints _group)) < 2) OR {((_group call BIS_fnc_netId) in grps_VCOM)}) then {//todo modified
							_WaypointCheck = _group call VCOMAI_Waypointcheck;

							if (count _WaypointCheck < 1) then {

								if ((_x distance _Unit) <= (_x getVariable ["VCOM_Unit_AIWarnDistance", VCOM_Unit_AIWarnDistance]) ) then {
										_x setbehaviour "AWARE";
										_x setVariable ["VCOM_MOVINGTOSUPPORT",true,false];

										if (leader _x isEqualTo _x) then {
											[_group] call AS_fnc_clearWaypoints;
											_waypoint2 = _group addwaypoint [_DeathPosition,15];
											_waypoint2 setwaypointtype "MOVE";
											_waypoint2 setWaypointSpeed "NORMAL";
											_waypoint2 setWaypointBehaviour "AWARE";
										};

										_x spawn {
											sleep 30;
											_this setVariable ["VCOM_MOVINGTOSUPPORT",false,false];
										};

									if (VCOM_AIDEBUG isEqualTo 1) then {
										[_x,"Warned of Combat!",120,20000] remoteExec ["3DText",0];
									};
								};
							};
						};
					};
				};
			};
	} forEach _Array1;
};