/* ----------------------------------------------------------------------------
Function: CBA_fnc_clearWaypoints

Description:
    A function used to correctly clear all waypoints from a group.

Parameters:
    - Group (Group or Object)

Example:
    (begin example)
    [group player] call CBA_fnc_clearWaypoints
    (end)

Returns:
    None

Author:
    SilentSpike

---------------------------------------------------------------------------- */

params ["_group"];
if (typeName _group isEqualTo "GROUP") exitWith {};

private _waypoints = waypoints _group;
{
    deleteWaypoint [_group, 0];
} forEach _waypoints;

private _wp = _group addWaypoint [getPosATL (leader _group), 0];
_wp setWaypointStatements ["true", "deleteWaypoint [group this,currentWaypoint (group this)]"];