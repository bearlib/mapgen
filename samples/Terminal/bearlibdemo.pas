program BearlibDemo;

uses
  bearlibfov,
  BeaRLibTerminal,
  SysUtils,
  Math,
  bearlibmap,
  MyToken, bearlibMG in '../../include/bearlibmg.pas';

// Map layers:
const
  kOpacityLayer = 0;
  kFOVLayer = 1;
  kColorLayer = 2;
  kTileLayer = 3;

type
  TLight = record
    X, Y, Radius: integer;
    Enabled: boolean;
    Color: TColor;
  end;
  PLight = ^TLight;

var
  map_id: integer = -1;
  player_sight_radius: integer = 15;
  lights: array[0..9] of TLight;
  player: PLight = @lights[0];
  advanced: boolean = False;
  see_all: boolean = False;
  tweak_gen: boolean = False;
  SavedSeed: Cardinal;

  procedure DeleteMap;
  begin
    map_free(map_id);
  end;

  procedure GenerateMap(Width, Height: Integer; MapType: TMapGenerator);
  var
    plx, ply, I, J, rx, ry, h, w: Integer;
    params: TGeneratorParamsHandle;
    rooms: TRoomsDataHandle;
  begin
    plx := -1;
    map_id := map_alloc(Width, Height, 'flag, flag, integer, integer');

    if MapType = G_NICE_DUNGEON then
    begin
      params := mg_params_create(G_NICE_DUNGEON);
      //example of generator parameters tweaking.
      if tweak_gen then mg_params_set(params, 'RoomThreshold', 4);
      rooms := mg_roomsdata_create;
    end
    else
    begin
      params := nil;
      rooms := nil;
    end;

    SavedSeed := Random(MaxInt);
    mg_generate(map_id, kTileLayer, MapType, SavedSeed, params, rooms);

    for I := 0 to Width-1 do
      for J := 0 to Height-1 do
        case TCellType(map_get(map_id, I, J, kTileLayer)) of
          TILE_CAVE_WALL,TILE_TREE,
          TILE_ROOMWALL, TILE_MOUNTAIN,TILE_HOUSE_WALL:
            map_set(map_id,I, J,kOpacityLayer, 1);
          else
          begin
            if plx < 0 then
            begin
              plx := I;
              ply := J;
            end;
            map_set(map_id,I, J,kOpacityLayer, 0);
          end;
        end;
    player^.x := plx;
    player^.y := ply;

    if MapType = G_NICE_DUNGEON then
    begin
      if mg_roomsdata_count(rooms) < 1 then exit;
      mg_roomsdata_position(rooms, 0, rx, ry, w, h);
      player^.X := rx+1;
      player^.Y := ry+1;

      //place lights to first 9 rooms
      for I := 1 to 9 do
        with lights[I] do
        begin
          X := -1;
          Y := -1;
          Enabled := false;
        end;
      for I := 1 to min(9, mg_roomsdata_count(rooms)) do
      begin
        mg_roomsdata_position(rooms, I-1, rx, ry, w, h);
        with lights[I] do
        begin
          X := rx + w div 2;
          Y := ry + h div 2;
          Enabled := True;
        end;
      end;

    end;


  end;

  function LoadMap: boolean;
  var
    ff: TextFile;
    line: string;
    map_lines: array of string;
    aX, aY, Width, Height: integer;
    c: char;
    light, aradius: integer;

  begin
    Result := False;
    AssignFile(ff, 'map.txt');
    Reset(ff);
    Width := 0;
    Height := 0;
    while not EOF(ff) do
    begin
      ReadLn(ff, line);
      if line = '' then
        break;
      SetLength(map_lines, Height + 1);
      map_lines[Height] := line;
      Inc(Height);
      Width := max(Width, length(line));
    end;
    if Height = 0 then
      exit;
    map_id := map_alloc(Width, Height, 'integer, flag, integer, integer');
    map_clear(map_id);
    for ay := 0 to length(map_lines) - 1 do
    begin
      line := map_lines[ay];
      for ax := 0 to length(line) - 1 do
      begin
        c := line[ax + 1];
        map_set(map_id, ax, ay, kOpacityLayer, 0);
        map_set(map_id, ax, ay, kTileLayer, ord(TILE_HOUSE_FLOOR));
        if c = '#' then
        begin
          map_set(map_id, ax, ay, kOpacityLayer, 1);
          map_set(map_id, ax, ay, kTileLayer, ord(TILE_HOUSE_WALL));
        end
        else if c in ['@', '1'..'9'] then
        begin
          if c = '@' then
            light := 0
          else
            light := Ord(c) - Ord('0');
          with lights[light] do
          begin
            X := ax;
            Y := ay;
            //Enabled := True;
            //Radius := 5;
            //Color := color_from_argb(255, 255, 0, 0);
          end;
        end;
      end;
    end;

    while not EOF(ff) do
    begin
      ReadLn(ff, line);
      if (line = '') or (Pos('//', line) > 0) then
        continue;
      light := StrToInt(TokenStrS(line, ':'));
      line := trim(line);
      aradius := StrToInt(TokenStrS(line, ' '));
      if (light < 0) or (light > 9) then
        continue;
      with lights[light] do
      begin
        Radius := aradius;
        Color := color_from_name(Line);
        Enabled := True;
      end;
    end;
    Result := True;
    CloseFile(ff);
  end;

  procedure LightFOVCallback(map_id, x, y: integer; opaque: pointer); cdecl;
  var
    light: PLight;
    dx, dy, dist2, factor: single;
    radius2: integer;
    acolor: TColor;
    r, g, b, cr, cg, cb: Integer;
  begin
    light := PLight(opaque);
    dx := light^.x - x;
    dy := light^.y - y;
    dist2 := dx * dx + dy * dy;
    radius2 := light^.radius * light^.radius;
    factor := 1 - dist2 / radius2;
    if factor < 0 then
      factor := 0;

    acolor := TColor(map_get(map_id, x, y, kColorLayer));
    r := byte(acolor shr 16);
    g := byte(acolor shr 8);
    b := byte(acolor);
    cr := byte(light^.color shr 16);
    cg := byte(light^.color shr 8);
    cb := byte(light^.color);
    Inc(r, trunc(cr * factor));
    Inc(g, trunc(cg * factor));
    Inc(b, trunc(cb * factor));
    map_set(map_id, x, y, kColorLayer, color_from_argb(255, min(r,255), min(g,255), min(b,255)));
  end;


  procedure CalcLight(light: PLight);
  begin
    fov_calc_cb(map_id, kOpacityLayer, light^.x, light^.y, light^.radius,
      @LightFOVCallback, light);
  end;


  function AverageWallColor(x, y: integer): TColor;
  var
    Width, Height, Count: integer;
    r, g, b: integer;
    ax, ay: integer;
    acolor: integer;
  begin
    Width := map_width(map_id);
    Height := map_height(map_id);
    Count := 0;
    r := 0;
    g := 0;
    b := 0;
    for ax := x - 1 to x + 1  do
      for ay := y - 1 to y + 1 do
      begin
        if not InRange(ax, 0, Width - 1) or not InRange(y, 0, Height - 1) then
          continue; // OOB
        if map_get(map_id, ax, ay, kFOVLayer) <> 1 then
          continue; // Must be in player's FOV
        if map_get(map_id, ax, ay, kOpacityLayer) > 0 then
          continue; // Must be a floor cell
        acolor := map_get(map_id, ax, ay, kColorLayer);
        Inc(r, byte(acolor shr 16));
        Inc(g, byte(acolor shr 8));
        Inc(b, byte(acolor shr 0));
        Inc(Count);
      end;

    if Count > 0 then
      Result := color_from_argb(255, min(255, r div Count), min(255, g div Count), min(255, b div Count))
    else
      Result := color_from_argb(255,0,0,0);
  end;


  procedure CalcWalls;
  var
    x, y: integer;
  begin
    for y := 0 to map_height(map_id) - 1 do
      for x := 0 to map_width(map_id) - 1 do
      begin
        if map_get(map_id, x, y, kFOVLayer) <> 1 then
          continue; // Must be in player's FOV
        if map_get(map_id, x, y, kOpacityLayer) <> 1 then
          continue; // Must be a wall
        map_set(map_id, x, y, kColorLayer, AverageWallColor(x, y));
      end;
  end;

  procedure DrawSimple;
  var
    x, y, c: integer;
  begin
    // Wall colors
    CalcWalls();

    // Cells
    for y := 0 to map_height(map_id) - 1 do
      for x := 0 to map_width(map_id) - 1 do
      begin
        if (not see_all) and (map_get(map_id, x, y, kFOVLayer) <= 0) then continue; // // Must be in player's FOV
        case TCellType(map_get(map_id, x, y, kTileLayer)) of
          TILE_CAVE_WALL: c := ord('#');
          TILE_GROUND: c := ord('.');
          TILE_WATER: c := ord('~');
          TILE_TREE: c := ord('T');
          TILE_MOUNTAIN: c := ord('^');
          TILE_ROAD: c := ord('%');
          TILE_HOUSE_WALL: c := $2588;
          TILE_HOUSE_FLOOR: c := $E000+32+4;
          TILE_GRASS: c := ord(',');
          TILE_EMPTY: c := ord(' ');
          TILE_CORRIDOR: c := ord('.');
          TILE_SMALLROOM: c := ord(',');
          TILE_BIGROOM: c := $E000+32+4;
          TILE_ROOMWALL: c := $2588;
          TILE_DOOR: c := ord('+');

          else c := ord('?')
        end;
        terminal_color(map_get(map_id, x, y, kColorLayer));
        //terminal_color(color_from_name('gray'));
        terminal_put(x, y, c);
      end;
  end;

  procedure FillAmbient;
  var
    x, y: integer;
    ambient: TColor;
  begin
    ambient := color_from_name('darkest gray');
    for y := 0 to map_height(map_id) - 1 do
      for x := 0 to map_width(map_id) - 1 do
        map_set(map_id, x, y, kColorLayer, ambient);
  end;

  procedure MovePlayer(dx, dy: integer);
  var
    nx, ny: integer;
  begin
    nx := player^.x + dx;
    ny := player^.y + dy;

    if not InRange(nx, 0, map_width(map_id) - 1) or not
      InRange(ny, 0, map_height(map_id) - 1) then // OOB
      exit;

    if map_get(map_id, nx, ny, kOpacityLayer) > 0 then // Wall
      exit;

    player^.x := nx;
    player^.y := ny;
  end;

var
  key: integer;
  i: integer;
  map_generated: Boolean = false;
  gen_type: TMapGenerator = Low(TMapGenerator);
begin
  Randomize;

  terminal_open;
{  if not LoadMap then
  begin
    writeln('Couldn''t load a map from "map.txt" file');
    halt(-1);
  end;}


  terminal_set(Format('window: size=%dx%d', [80, 41]));
  terminal_set('title=Lighting');
  terminal_set('font.name=media/UbuntuMono-R.ttf; font.size=12');
  //0xE000: tileset.png, size=16x16, spacing=2x1;
  terminal_set('0xE000: media/supplement.png, size=8x16, spacing=0x0;');

  LoadMap;
  gen_type := G_NICE_DUNGEON;
  SavedSeed := 0;
  GenerateMap(80,40,G_NICE_DUNGEON);
  map_generated := True;
  see_all := True;


  while True do
  begin
    terminal_clear;
    FillAmbient;

    // Lights' and player's FOVs
    for i := 0 to 9 do
      if lights[i].Enabled then
        CalcLight(@lights[i]);
    map_clear_layer(map_id, kFOVLayer);
    fov_calc(map_id, kOpacityLayer, kFOVLayer, lights[0].x, lights[0].y,
      player_sight_radius);

    DrawSimple;

    for i := 0 to 9 do
      with lights[i] do
        if map_get(map_id, x, y, kFOVLayer) > 0 then
        begin
          if Enabled then
            terminal_color(Color)
          else
            terminal_color(color_from_name('gray'));
          if i = 0 then
            terminal_put(x, y, '@')
          else
            terminal_put(x, y, Ord('0') + i);
        end;

    terminal_color(color_from_name('white'));
    if map_generated then
      terminal_print(0, 38, 'map: '+GENERATOR_NAMES[ord(gen_type)]+', seed='+IntToStr(SavedSeed))
    else
      terminal_print(0, 38, 'map: from file');
    terminal_print(0, 39, '0-9: lights, L: toggle fov');
    terminal_print(0, 40, 'F1: from file, F2: cycle generators, F3: G_NICE_DUNGEON, F4: tweak example');
    terminal_refresh;
    key := terminal_read;
    case key of
      TK_CLOSE, TK_ESCAPE: break;
      TK_1..TK_9: lights[key - TK_1 + 1].Enabled := not lights[key - TK_1 + 1].Enabled;
      TK_LEFT: MovePlayer(-1, 0);
      TK_UP: MovePlayer(0, -1);
      TK_RIGHT: MovePlayer(+1, 0);
      TK_DOWN: MovePlayer(0, +1);
      TK_KP_1: MovePlayer(-1, +1);
      TK_KP_2: MovePlayer(0, +1);
      TK_KP_3: MovePlayer(+1, +1);
      TK_KP_4: MovePlayer(-1, 0);
      TK_KP_6: MovePlayer(+1, 0);
      TK_KP_7: MovePlayer(-1, -1);
      TK_KP_8: MovePlayer(0, -1);
      TK_KP_9: MovePlayer(+1, -1);
      TK_F1:
      begin
        DeleteMap;
        LoadMap;
        map_generated := False;
      end;
      TK_F2:
      begin
        DeleteMap;
        if gen_type = High(TMapGenerator) then
          gen_type := Low(TMapGenerator)
        else
          gen_type := TMapGenerator((Ord(gen_type)+1));
        GenerateMap(80,40,gen_type);
        map_generated := True;
      end;
      TK_F3:
      begin
        DeleteMap;
        gen_type := G_NICE_DUNGEON;
        tweak_gen := false;
        GenerateMap(80,40,G_NICE_DUNGEON);
        map_generated := True;
      end;
      TK_F4:
      begin
        DeleteMap;
        gen_type := G_NICE_DUNGEON;
        tweak_gen := true;
        GenerateMap(80,40,G_NICE_DUNGEON);
        map_generated := True;
      end;
      TK_L: see_all := not see_all;

    end;

  end;
  terminal_close;
end.
