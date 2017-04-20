/*
    By: Jeroen Notenbomer

    Add amounts of same namee togetter
    Also removes all empty names
    Use amount -1 to remove unlimited items

    Inputs:
        1: list         [["name1",amount1],["name2",amount2]]
        2: item         "name1" or ["name1",amount1] or [["name1",amount1],["name2",amount2]]

    Outputs
        list = Input1-Input2
*/


private["_remove","_list","_removeName","_removeAmount","_newAmount","_listName","_listAmount"];

_list = +(_this select 0);
_remove = _this select 1;

if(typeName _remove isEqualTo "STRING")then{_remove = [_remove,1];};
if(typeName (_remove select 0) isEqualTo "STRING")then{_remove = [_remove]};

_remove = +_remove;

//remove empty
{
    _listName = _x select 0;
    if(_listName isEqualTo "")then{
        _list set [_forEachIndex,-1];
    };
} forEach _list;
_list = _list - [-1];

{
    _removeName = _x select 0;
    _removeAmount = _x select 1;
    if!(_removeName isEqualTo "")then{//remove "" in remove
        scopename "foundIt";
        {
            _listName = _x select 0;
            _listAmount = _x select 1;
            if(_listName isEqualTo "")then{
                _list set [_forEachIndex,-1];
            }else{
                if(_listName isEqualTo _removeName)then{
                    //found update amount

                    if(_listAmount != -1)then{
                        _newAmount = _listAmount - _removeAmount;
                        if(_newAmount > 0)then{
                            _list set [_forEachIndex, [_listName, _newAmount]];
                        }else{
                            _list set [_forEachIndex, -1];
                        };
                    }else{
                        //item is unlimited
                        if(_removeAmount == -1)then{
                            //remove unlimited when -1 was used
                             _list set [_forEachIndex, -1];
                        }
                    }
                    breakout "foundIt";
                };
            };
        }forEach _list;
    };
}forEach _remove;

_list = _list - [-1];
_list; //return this
