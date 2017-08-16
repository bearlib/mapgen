library BeaRLibMG;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  uBeaRLibMG,
  uMapGenerator in 'uMapGenerator.pas',
  bearlibmap in 'bearlibmap.pas',
  uGeneral in 'ugeneral.pas',
  uDelaunay in 'uDelaunay.pas',
  uDungeonGen in 'uDungeonGen.pas';

exports mg_generate, mg_generate_cb,
  mg_params_create,
  mg_params_delete,
  mg_params_set,
  mg_params_setf,
  mg_params_get,
  mg_params_getf,
  mg_params_setstr,

  mg_roomsdata_create,
  mg_roomsdata_delete,
  mg_roomsdata_count,
  mg_roomsdata_position,
  mg_roomsdata_linkscount,
  mg_roomsdata_getlink

;

begin

end.
