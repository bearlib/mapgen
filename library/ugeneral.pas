unit uGeneral;

interface

type
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

  TMapGenerator = (
    G_ANT_NEST=1,
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


  TRoomInfo = record
    X0, Y0, Width, Height: Integer;
    Links: array of Integer;
  end;

  TRoomsData = class
    data: array of TRoomInfo;
  end;

  TGeneratorParams = class
    procedure SetField(s: string; x: single); virtual; abstract;
    function GetField(s: string): single; virtual; abstract;
  end;

function UpperCase(s: string): string;
implementation

function UpperCase(s: string): string;
var
  I: Integer;
begin
  SetLength(Result, length(s));
  for I := 1 to length(s) do
    Result[i] := UpCase(s[i]);
end;



end.
