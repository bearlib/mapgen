unit BearLibMap;

{$ifdef fpc}{$mode delphi}{$endif}
{$DEFINE BEARLIBMAP_DYNAMIC}

interface

const
{$ifdef win32}
  BearLibMapLib = 'bearlibmap.dll';
{$else}
  {$ifdef darwin}
    BearLibMapLib = 'bearlibmap.dylib';
  {$else}
    BearLibMapLib = 'bearlibmap.so';
  {$endif}
{$endif}

{$IFDEF BEARLIBMAP_DYNAMIC}
var
  map_alloc: function (width, height: integer; description: PChar): Integer; cdecl;
  map_free: procedure (map_id: integer); cdecl;
  map_copy: function (map_id: integer): Integer; cdecl;
  map_assign: function (dst_map_id, src_map_id: integer): Integer; cdecl;
  map_clear: procedure (map_id: integer); cdecl;
  map_clear_layer: procedure (map_id, layer: integer); cdecl;
  map_set: procedure (map_id, x, y, layer, value: integer); cdecl;
  map_setf: procedure (map_id, x, y, layer: integer; value: single); cdecl;
  map_get: function (map_id, x, y, layer: integer): Integer; cdecl;
  map_getf: function (map_id, x, y, layer: integer): Single; cdecl;
  map_width: function (map_id: integer): Integer; cdecl;
  map_height: function (map_id: integer): Integer; cdecl;
{$ELSE}
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
{$ENDIF}
implementation


{$IFDEF BEARLIBMAP_DYNAMIC}

{$ifdef fpc}
uses dynlibs;
var
  h: TLibHandle;
begin
  h := LoadLibrary(BearLibMapLib);
  if h = NilHandle then exit;
  map_alloc := GetProcedureAddress(h, 'map_alloc');
  map_free := GetProcedureAddress(h, 'map_free');
  map_copy := GetProcedureAddress(h, 'map_copy');
  map_assign := GetProcedureAddress(h, 'map_assign');
  map_clear := GetProcedureAddress(h, 'map_clear');
  map_clear_layer := GetProcedureAddress(h, 'map_clear_layer');
  map_set := GetProcedureAddress(h, 'map_set');
  map_setf := GetProcedureAddress(h, 'map_setf');
  map_get := GetProcedureAddress(h, 'map_get');
  map_getf := GetProcedureAddress(h, 'map_getf');
  map_width := GetProcedureAddress(h, 'map_width');
  map_height := GetProcedureAddress(h, 'map_height');
{$else}
uses Windows;
var
  h: THandle;
begin
  h := LoadLibrary(BearLibMapLib);
  if h = 0 then exit;
  map_alloc := GetProcAddress(h, 'map_alloc');
  map_free := GetProcAddress(h, 'map_free');
  map_copy := GetProcAddress(h, 'map_copy');
  map_assign := GetProcAddress(h, 'map_assign');
  map_clear := GetProcAddress(h, 'map_clear');
  map_clear_layer := GetProcAddress(h, 'map_clear_layer');
  map_set := GetProcAddress(h, 'map_set');
  map_setf := GetProcAddress(h, 'map_setf');
  map_get := GetProcAddress(h, 'map_get');
  map_getf := GetProcAddress(h, 'map_getf');
  map_width := GetProcAddress(h, 'map_width');
  map_height := GetProcAddress(h, 'map_height');
{$endif}
{$ENDIF}
end.

