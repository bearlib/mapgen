unit BearLibMap;

{$mode objfpc}{$H+}

interface

const
  BearLibMapLib = 'bearlibmap.dll';


function map_alloc(width, height: integer; description: PChar): Integer; cdecl; external BearLibMapLib;
procedure map_free(map_id: integer); cdecl; external BearLibMapLib;
function map_copy(map_id: integer): Integer; cdecl; external BearLibMapLib;
function map_assign(dst_map_id, src_map_id: integer): Integer; cdecl; external BearLibMapLib;
procedure map_clear(map_id: integer); cdecl; external BearLibMapLib;
procedure map_clear_layer(map_id, layer: integer); cdecl; external BearLibMapLib;
procedure map_set(map_id, x, y, layer, value: integer); cdecl; external BearLibMapLib;
procedure map_setf(map_id, x, y, layer: integer; value: single); cdecl; external BearLibMapLib;
function map_get(map_id, x, y, layer: integer): Integer; cdecl; external BearLibMapLib;
function map_getf(map_id, x, y, layer: integer): Single; cdecl; external BearLibMapLib;
function map_width(map_id: integer): Integer; cdecl; external BearLibMapLib;
function map_height(map_id: integer): Integer; cdecl; external BearLibMapLib;

implementation

end.

