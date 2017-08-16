unit bearlibMG;

{$IFDEF FPC}
{$MODE OBJFPC}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils;

const
{$ifdef win32}
  bearlibmgLIB = 'bearlibmg.dll';
{$else}
  {$ifdef darwin}
    bearlibmgLIB = 'bearlibmg.dylib';
  {$else}
    bearlibmgLIB = 'bearlibmg.so';
  {$endif}
{$endif}

type
    TMapGenerator = (
      G_ANT_NEST = 1,
      G_CAVES = 2,
      G_VILLAGE = 3,
      G_LAKES = 4,
      G_LAKES2 = 5,
      G_TOWER = 6,
      G_HIVE = 7,
      G_CITY = 8,
      G_MOUNTAIN=9,
      G_FOREST = 10,
      G_SWAMP = 11,
      G_RIFT=12,
      G_TUNDRA=13,
      G_BROKEN_CITY=14,
      G_BROKEN_VILLAGE=15,
      G_MAZE=16,
      G_CASTLE = 17,
      G_WILDERNESS = 18,
      G_NICE_DUNGEON = 19
    );

    TCellType = (
      TILE_CAVE_WALL=0,
      TILE_GROUND=1,
      TILE_WATER = 2,
      TILE_TREE = 3,
      TILE_MOUNTAIN = 4,
      TILE_ROAD=6,
      TILE_HOUSE_WALL = 7,
      TILE_HOUSE_FLOOR = 8,
      TILE_GRASS = 9,
      TILE_EMPTY = 10,

      TILE_CORRIDOR = 11,
      TILE_SMALLROOM = 12,
      TILE_BIGROOM = 13,
      TILE_ROOMWALL = 14,
      TILE_DOOR=15
  );

const
    N_MAP_GENERATORS = 19;

  GENERATOR_NAMES: array[1..N_MAP_GENERATORS] of string =
    (
    'G_ANT_NEST',
    'G_CAVES',
    'G_VILLAGE',
    'G_LAKES',
    'G_LAKES2',
    'G_TOWER',
    'G_HIVE',
    'G_CITY',
    'G_MOUNTAIN',
    'G_FOREST',
    'G_SWAMP',
    'G_RIFT',
    'G_TUNDRA',
    'G_BROKEN_CITY',
    'G_BROKEN_VILLAGE',
    'G_MAZE',
    'G_CASTLE',
    'G_WILDERNESS',
    'G_NICE_DUNGEON'
    );

type
    map_callback = procedure(x, y: Integer; Value: TCellType; opaque: Pointer); cdecl;
    TGeneratorParamsHandle = Pointer;
    TRoomsDataHandle = Pointer;

  procedure mg_generate(map_id, layer: Integer; Typ: TMapGenerator; Seed: Integer; GeneratorParams: TGeneratorParamsHandle; RoomsData: TRoomsDatahandle); cdecl;external bearlibmgLIB;
  procedure mg_generate_cb(SizeX, SizeY: Integer; Typ: TMapGenerator; Seed: Integer; callback: map_callback; opaque: Pointer; GeneratorParams: TGeneratorParamsHandle; RoomsData: TRoomsDatahandle); cdecl;external bearlibmgLIB;

  function mg_params_create(Typ: TMapGenerator): TGeneratorParamsHandle;cdecl;external bearlibmgLIB;
  procedure mg_params_delete(GeneratorParams: TGeneratorParamsHandle);cdecl;external bearlibmgLIB;
  procedure mg_params_set(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar; value: Integer);external bearlibmgLIB;
  procedure mg_params_setf(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar; value: Single);external bearlibmgLIB;
  function mg_params_get(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar): Integer;external bearlibmgLIB;
  function mg_params_getf(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar): Single;external bearlibmgLIB;
  procedure mg_params_setstr(GeneratorParams: TGeneratorParamsHandle; somestring: PAnsiChar);external bearlibmgLIB;

  function mg_roomsdata_create: TRoomsDataHandle;cdecl;external bearlibmgLIB;
  procedure mg_roomsdata_delete(RoomsData: TRoomsDataHandle);cdecl;external bearlibmgLIB;
  function mg_roomsdata_count(RoomsData: TRoomsDataHandle): Integer;cdecl;external bearlibmgLIB;
  procedure mg_roomsdata_position(RoomsData: TRoomsDataHandle; RoomIndex: Integer; var ax0, ay0, awidth, aheight: Integer);cdecl;external bearlibmgLIB;
  function mg_roomsdata_linkscount(RoomsData: TRoomsDataHandle; RoomIndex: Integer): Integer;cdecl;external bearlibmgLIB;
  function mg_roomsdata_getlink(RoomsData: TRoomsDataHandle; RoomIndex, LinkIndex: Integer): Integer;cdecl;external bearlibmgLIB;


implementation

end.
