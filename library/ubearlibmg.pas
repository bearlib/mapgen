unit uBeaRLibMG;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses uGeneral, uMapGenerator;

type
  map_callback = procedure(x, y: Integer; Value: TCellType; opaque: Pointer); cdecl;
  TGeneratorParamsHandle = Pointer;
  TRoomsDataHandle = Pointer;

procedure mg_generate(map_id, layer: Integer; Typ: TMapGenerator; Seed: Integer; GeneratorParams: TGeneratorParamsHandle; RoomsData: TRoomsDatahandle); cdecl;
procedure mg_generate_cb(SizeX, SizeY: Integer; Typ: TMapGenerator; Seed: Integer; callback: map_callback; opaque: Pointer; GeneratorParams: TGeneratorParamsHandle; RoomsData: TRoomsDatahandle); cdecl;

function mg_params_create(Typ: TMapGenerator): TGeneratorParamsHandle;cdecl;
procedure mg_params_delete(GeneratorParams: TGeneratorParamsHandle);cdecl;
procedure mg_params_set(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar; value: Integer);cdecl;
procedure mg_params_setf(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar; value: Single);cdecl;
function mg_params_get(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar): Integer;cdecl;
function mg_params_getf(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar): Single;cdecl;
procedure mg_params_setstr(GeneratorParams: TGeneratorParamsHandle; somestring: PAnsiChar);cdecl;

function mg_roomsdata_create: TRoomsDataHandle;cdecl;
procedure mg_roomsdata_delete(RoomsData: TRoomsDataHandle);cdecl;
function mg_roomsdata_count(RoomsData: TRoomsDataHandle): Integer;cdecl;
procedure mg_roomsdata_position(RoomsData: TRoomsDataHandle; RoomIndex: Integer; var ax0, ay0, awidth, aheight: Integer);cdecl;
function mg_roomsdata_linkscount(RoomsData: TRoomsDataHandle; RoomIndex: Integer): Integer;cdecl;
function mg_roomsdata_getlink(RoomsData: TRoomsDataHandle; RoomIndex, LinkIndex: Integer): Integer;cdecl;

//procedure mg_get

implementation

uses bearlibmap, uDungeonGen, Math;

{var
  RoomsDataList: array of TRoomInfo;
  GeneratorParamsList: array of TGeneratorParams;}


function GetParams(H: TGeneratorParamsHandle): TGeneratorParams;
begin
  Result := TGeneratorParams(H);
end;

function GetRoomsData(H: TRoomsDataHandle): TRoomsData;
begin
  Result := TRoomsData(H);
end;


procedure mg_generate(map_id, layer: Integer; Typ: TMapGenerator; Seed: Integer; GeneratorParams: TGeneratorParamsHandle; RoomsData: TRoomsDatahandle); cdecl;
var
  SizeX, SizeY,I,J: Integer;
begin
  SizeX := map_width(map_id);
  SizeY := map_height(map_id);
  CreateMap(SizeX, SizeY, Typ, Seed, GetParams(GeneratorParams), GetRoomsData(RoomsData));
  for I := 0 to SizeX - 1 do
    for J := 0 to SizeY - 1 do
      map_set(map_id, I, J, layer, Ord(Map[I+1][J+1]));
end;

procedure mg_generate_cb(SizeX, SizeY: Integer; Typ: TMapGenerator; Seed: Integer; callback: map_callback; opaque: Pointer; GeneratorParams: TGeneratorParamsHandle; RoomsData: TRoomsDatahandle); cdecl;
var
  I,J: Integer;
begin
  CreateMap(SizeX, SizeY, Typ, Seed, GetParams(GeneratorParams), GetRoomsData(RoomsData));
  for I := 0 to SizeX - 1 do
    for J := 0 to SizeY - 1 do
      callback(I, J, Map[I+1][J+1], opaque);
end;


function mg_params_create(Typ: TMapGenerator): TGeneratorParamsHandle;cdecl;
begin
  case typ of
    G_NICE_DUNGEON: Result := TNiceDungeonGeneratorParams.Create;
    else Result := nil;
  end;
end;

procedure mg_params_delete(GeneratorParams: TGeneratorParamsHandle);cdecl;
begin
  GetParams(GeneratorParams).Free;
end;

procedure mg_params_set(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar; value: Integer);
begin
  GetParams(GeneratorParams).SetField(param, value);
end;

procedure mg_params_setf(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar; value: Single);
begin
  GetParams(GeneratorParams).SetField(param, value);
end;

function mg_params_get(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar): Integer;
begin
  Result := Trunc(GetParams(GeneratorParams).GetField(param));
end;

function mg_params_getf(GeneratorParams: TGeneratorParamsHandle; param: PAnsiChar): Single;
begin
  Result := GetParams(GeneratorParams).GetField(param);
end;

procedure mg_params_setstr(GeneratorParams: TGeneratorParamsHandle; somestring: PAnsiChar);
begin
//TODO
end;


function mg_roomsdata_create: TRoomsDataHandle;cdecl;
begin
  Result := TRoomsData.Create;
end;

procedure mg_roomsdata_delete(RoomsData: TRoomsDataHandle);cdecl;
begin
  GetRoomsData(RoomsData).Free;
end;

function mg_roomsdata_count(RoomsData: TRoomsDataHandle): Integer;cdecl;
begin
  Result := Length(GetRoomsData(RoomsData).data);
end;

procedure mg_roomsdata_position(RoomsData: TRoomsDataHandle; RoomIndex: Integer; var ax0, ay0, awidth, aheight: Integer);cdecl;
begin
  if not InRange(RoomIndex, 0, Length(GetRoomsData(RoomsData).data)-1) then
  begin
    ax0 := -1;
    ay0 := -1;
    awidth := -1;
    aheight := -1;
    exit;
  end;
  with GetRoomsData(RoomsData).data[RoomIndex] do
  begin
    ax0 := X0;
    ay0 := Y0;
    awidth := Width;
    aheight := Height;
  end;
end;

function mg_roomsdata_linkscount(RoomsData: TRoomsDataHandle; RoomIndex: Integer): Integer;cdecl;
begin
  if not InRange(RoomIndex, 0, Length(GetRoomsData(RoomsData).data)-1) then
    Result := -1
  else
    Result := Length(GetRoomsData(RoomsData).data[RoomIndex].Links)
end;

function mg_roomsdata_getlink(RoomsData: TRoomsDataHandle; RoomIndex, LinkIndex: Integer): Integer;cdecl;
begin
  if not InRange(RoomIndex, 0, Length(GetRoomsData(RoomsData).data)-1) then
    Result := -1
  else if not InRange(LinkIndex, 0, Length(GetRoomsData(RoomsData).data[RoomIndex].Links)-1) then
    Result := -1
  else
    Result := GetRoomsData(RoomsData).data[RoomIndex].Links[LinkIndex];
end;



end.

