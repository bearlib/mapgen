unit uDungeonGen;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


{$IFDEF BEARLIB}
uses uGeneral;
{$ELSE}
uses SysUtils;
{$ENDIF}


type

{$IFNDEF BEARLIB}
  TCellType = (TILE_CAVE_Wall = 0, TILE_Corridor, TILE_SmallRoom, TILE_BigRoom, TILE_RoomWall, TILE_Door);
  TGeneratorParams = class
    procedure SetField(s: string; x: single); virtual; abstract;
    function GetField(s: string): single; virtual; abstract;
  end;
  TRoomInfo = record
    X0, Y0, Width, Height: Integer;
    Links: array of Integer;
  end;

  TRoomsData = class
    data: array of TRoomInfo;
  end;

{$ENDIF}

  TRoomIndex = Integer;
  TDungeon = class;

  //Node type
  TNodeLink = record
    Removed: Boolean;
    Target: TRoomIndex;
    //Distance: Integer;
  end;


  TDirection = (N,S,W,E);

  //Rooms type
  TRoom = record
    X,Y,W,H: integer;
    RoomType: TCellType;
    Links: array of TNodeLink;
    TraverseId: Integer;
    CachedDoorPos: array[TDirection] of integer;  
    function CenterX: Integer;
    function CenterY: Integer;
    function RandomX: Integer;
    function RandomY: Integer;
    function Intersects(const WithRoom: TRoom): Boolean;
    function CloseByX(const WithRoom: TRoom): Boolean;
    function CloseByY(const WithRoom: TRoom): Boolean;
    procedure Draw(Context: TDungeon; Index: integer=-1);
  end;
  PRoom = ^TRoom;

  TNiceDungeonGeneratorParams = class(TGeneratorParams)
    NRooms: Integer;
    RoomMinSize, RoomMaxSize, RoomThreshold: Integer;//in cells
    MaxSizeRatio: Single;
    InitialRadius: Single;// 0..1 (Scaled by MapX/MapY)
    AdditionalLinks: Single;//0..1 (percent of total links number)
    procedure SetField(s: string; x: single); override;
    function GetField(s: string): single; override;
    constructor Create;
  end;

  TCells = array of array of TCellType;
  TRoomCache = array of array of TRoomIndex;

  TDungeon = class
    MapX, MapY, NRooms: Integer;
    Params: TNiceDungeonGeneratorParams;
    Rooms: array of TRoom;
    MainRooms: array of TRoomIndex;
    Cells: TCells;
    RoomCache: TRoomCache;

    constructor Create(aMapX, aMapY: Integer; aParams: TNiceDungeonGeneratorParams);
    //Step 1
    procedure GenerateRooms;
    //Step 2
    procedure OffsetRooms;
    //Step 3
    procedure PickMainRooms;
    //Step 4
    procedure DelaunayTriangulation;
    //Step 5
    procedure MinimalTree;
    //Step 6
    procedure DrawHallways;

    procedure DumpRooms(ToRooms: TRoomsData);
  end;


implementation

uses Math, uDelaunay;

{ TDungeon }

constructor TDungeon.Create(aMapX, aMapY: Integer;
  aParams: TNiceDungeonGeneratorParams);
begin
  MapX := aMapX;
  MapY := aMapY;
  if aParams = nil then
    aParams := TNiceDungeonGeneratorParams.Create;
  Params := aParams;
  NRooms := Params.NRooms;
  SetLength(Rooms, NRooms);
  SetLength(Cells, MapX,MapY);
  SetLength(RoomCache, MapX,MapY);
end;

procedure TDungeon.DelaunayTriangulation;

procedure AddLink(p1, p2: TRoomIndex);
var
  N: Integer;
  P: PRoom;
begin
  if p1 >= length(MainRooms) then exit;
  if p2 >= length(MainRooms) then exit;
  P := @Rooms[MainRooms[p1]];
  for N := 0 to Length(P.Links) - 1 do
    if P.Links[N].Target = p2 then
      exit;
  N := Length(P.Links);
  SetLength(P.Links, N+1);
  P.Links[N].Target := p2;
  P := @Rooms[MainRooms[p2]];
  N := Length(P.Links);
  SetLength(P.Links, N+1);
  P.Links[N].Target := p1;
end;

var
  I, n1, n2, n3: Integer;
  TRI: TDelaunay;
begin

  if Length(MainRooms) < 4 then
  begin
    for n1 := 0 to Length(MainRooms) - 2 do
      for n2 := n1+1 to Length(MainRooms) - 1 do
        AddLink(n1, n2);
    exit;    
  end;

  //Initialize graph
  TRI := TDelaunay.Create;

  for I := 0 to Length(MainRooms) - 1 do
    TRI.AddPoint(Rooms[MainRooms[I]].CenterX+random, Rooms[MainRooms[I]].CenterY+random);
  TRI.Mesh;
  for I := 1 to TRI.HowMany do
    with TRI.Triangle.Items[I] do
    begin
      n1 := TRI.Vertex.Items[vv0].Original-1;
      n2 := TRI.Vertex.Items[vv1].Original-1;
      n3 := TRI.Vertex.Items[vv2].Original-1;
      AddLink(n1, n2);
      AddLink(n2, n3);
      AddLink(n3, n1);
    end;
  TRI.Free;
end;

procedure TDungeon.DrawHallways;

var
  CurPass, FromRoom, ToRoom: Integer;
  prevx, prevy: integer;
  prevroom: Integer;
  

  procedure OneCell(x,y: integer; Central: boolean = false);
  var
    FoundRoom, I, N: Integer;
  begin
    if not InRange(x, 1, MapX) then exit;
    if not InRange(y, 1, MapY) then exit;
    if (Cells[x,y] in [TILE_RoomWall, TILE_Door])  then
    begin
      if not Central then exit;
      FoundRoom := RoomCache[x,y]-1;
      if Rooms[RoomCache[x,y]-1].TraverseId = CurPass then
      begin
        //only one door in starting andd ending room
        {if FoundRoom = FromRoom then exit;
        if FoundRoom = ToRoom then exit;}
        //if its another room - set a door
        if (prevroom >= 0) and (FoundRoom <> prevroom) then
          Cells[prevx,prevy] := TILE_Door;
        //otherwise - save position to set door at last visited
        prevroom := FoundRoom;
        prevx := X;
        prevy := Y;
        exit;
      end;
      Cells[x,y] := TILE_Door;
      Rooms[RoomCache[x,y]-1].TraverseId := CurPass;
      if (FoundRoom <> FromRoom) and (FoundRoom <> ToRoom) then
      begin
        prevroom := FoundRoom;
        prevx := X;
        prevy := Y;
      end;
      exit;
    end;
    if Cells[x,y] <> TILE_CAVE_Wall then exit;
    if central and (prevroom >= 0) then
    begin
      Cells[prevx,prevy] := TILE_Door;
      prevroom := -1;
    end;

    N := RoomCache[x,y];
    if (N > 0) and (Rooms[N-1].RoomType <> TILE_BigRoom) then
    begin
      Rooms[N-1].RoomType := TILE_SmallRoom;
      Rooms[N-1].Draw(Self);
      exit;
    end;
    Cells[x,y] := TILE_Corridor;
  end;

  procedure DrawHoriz(y, x1, x2: Integer);
  var
    ax, dx, i, n: integer;
  begin
    n := abs(x1 - x2)+3;
    ax := x1;
    if x1 < x2 then
      dx := 1
    else
      dx := -1;
    dec(ax, dx);
    for i := 1 to n do
    begin
      OneCell(ax, y-1);
      OneCell(ax, y, true);
      OneCell(ax, y+1);
      inc(ax, dx);
    end;
  end;

  procedure DrawVertical(x, y1, y2: Integer);
  var
    ay, dy, i, n: integer;
  begin
    n := abs(y1 - y2)+3;
    ay := y1;
    if y1 < y2 then
      dy := 1
    else
      dy := -1;
    for i := 1 to n do
    begin
      inc(ay, dy);
      OneCell(x-1, ay);
      OneCell(x, ay, true);
      OneCell(x+1, ay);
    end;
  end;

var
  I, J, basex, basey, tmpi: Integer;
  Room, Target, tmp: PRoom;
  swapped: boolean;
begin
  SetLength(Cells, 0, 0);
  SetLength(Cells, MapX, MapY);
  for I := 0 to Length(Rooms) - 1 do
    if Rooms[I].RoomType = TILE_SmallRoom then
      Rooms[I].RoomType := TILE_CAVE_Wall
    else
      Rooms[I].Draw(Self);
  CurPass := 0;
  for I := 0 to Length(MainRooms) - 1 do
  begin
    Room := @Rooms[MainRooms[I]];
    Room.CachedDoorPos[N] := Room.RandomX;
    Room.CachedDoorPos[S] := Room.RandomX;
    Room.CachedDoorPos[W] := Room.RandomY;
    Room.CachedDoorPos[E] := Room.RandomY;
    Room.TraverseId := -1;
  end;
  for I := 0 to Length(MainRooms) - 1 do
  begin
    Room := @Rooms[MainRooms[I]];
    for J := 0 to Length(Room.Links) - 1 do
    begin
      if Room.Links[J].Removed or(Room.Links[J].Target < I) then continue;
      Target := @Rooms[MainRooms[Room.Links[J].Target]];
      inc(CurPass);
      prevroom := -1;
      FromRoom := MainRooms[Room.Links[J].Target];
      ToRoom := MainRooms[I];

      {if Room.CloseByX(Target^) then
        DrawVertical((Room.CenterX+Target.CenterX) div 2, Room.CenterY, Target.CenterY)
      else if Room.CloseByY(Target^) then
        DrawHoriz((Room.CenterY+Target.CenterY) div 2, Room.CenterX, Target.CenterX)
      else}
      //-1005289332
      swapped := random > 0.5;
      if swapped then
      begin
        tmp := Room;
        Room := Target;
        Target := tmp;
        tmpi := FromRoom;
        FromRoom := ToRoom;
        ToRoom := tmpi;
      end;
      //Vertical from first room
      if Target.CenterY > Room.CenterY then
        basex := Room.CachedDoorPos[N]
      else
        basex := Room.CachedDoorPos[S];
      //Horizontal from second room
      if Room.CenterX > Target.CenterX then
        basey := Target.CachedDoorPos[W]
      else
        basey := Target.CachedDoorPos[E];

        DrawVertical(basex, Room.CenterY, basey);
        DrawHoriz(basey, basex, Target.CenterX);
      if swapped then
        Room := Target;

    end;
  end;
end;


procedure TDungeon.DumpRooms(ToRooms: TRoomsData);
var
  I, J, N: Integer;
  P: PRoom;
begin
  SetLength(ToRooms.data, length(MainRooms));
  for I := 0 to length(MainRooms) - 1 do
  begin
    P := @Rooms[MainRooms[I]];
    with ToRooms.data[I] do
    begin
      X0 := P.X+1;
      Y0 := P.Y+1;
      Width := P.W-2;
      Height := P.H-2;
      N := 0;
      for J := 0 to Length(P.Links) - 1 do
        if not P.Links[J].Removed then inc(N);
      SetLength(Links, N);
      N := 0;
      for J := 0 to Length(P.Links) - 1 do
        if not P.Links[J].Removed then
        begin
          Links[N] := P.Links[J].Target;
          inc(N);
        end;
    end;
  end;
end;

function RandMinMax(a,b: Double): Double;
begin
  Result := EnsureRange( Abs(RandG(0, 1/3)), 0, 1 ) * (b-a)  + a;
end;

procedure TDungeon.GenerateRooms;
var
  I: Integer;
  rx,ry,rw,rh, t,u,r, amin, amax: Single;
begin
  for I := 0 to NRooms - 1 do
  begin
    t := 2*Pi*Random;
    u := Random+Random;
    if u > 1 then
      r := 2-u
    else
      r := u;
    rX := MapX*Params.InitialRadius*r*cos(t) + MapX/2;
    ry := MapY*Params.InitialRadius*r*sin(t) + MapY/2;
    rw := RandMinMax(Params.RoomMinSize, Params.RoomMaxSize);
    rh := RandMinMax(max(Params.RoomMinSize, rw/Params.MaxSizeRatio) , min(Params.RoomMaxSize, rw*Params.MaxSizeRatio));
    Rooms[I].X := Round(rx);
    Rooms[I].Y := Round(ry);
    Rooms[I].H := Round(rw);
    Rooms[I].W := Round(rh);
    Rooms[I].RoomType := TILE_SmallRoom;
  end;
end;

procedure TDungeon.MinimalTree;
//using https://ru.wikipedia.org/wiki/Алгоритм_Крускала
//and https://ru.wikipedia.org/wiki/Система_непересекающихся_множеств

type
  TLine = record
    Length, A,B: Integer;
    Active: Boolean;
  end;

var
  NRoots, NLines: Integer;
  Roots: array of Integer;
  Lines: array of TLine;

{procedure makeset(x:integer);
begin
  Roots[x] := x;
  inc(NRoots);
end;}

function find(x:integer):integer;
begin
  if Roots[x] <> x then
    Roots[x] := find(Roots[x]);
  Result := Roots[x];
end;

function union(x,y:integer): Boolean;
begin
  x := find(x);
  y := find(y);
  Result := x <> y;
  if Result then
  begin
    Dec(NRoots);
    if random <= 0.5 then
      Roots[x] := y
    else
      Roots[y] := x;
  end;
end;

  procedure DoQuickSort(iLo, iHi: Integer);
  var
    Lo, Hi: Integer;
    Mid: Double;
    T: TLine;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := Lines[(Lo + Hi) div 2].Length;
    repeat
      while Lines[Lo].Length < Mid do Inc(Lo);
      while Lines[Hi].Length > Mid do Dec(Hi);
      if Lo <= Hi then
      begin
        T := Lines[Lo];
        Lines[Lo] := Lines[Hi];
        Lines[Hi] := T;
        Inc(Lo);
        Dec(Hi);
      end;
    until Lo > Hi;
    if Hi > iLo then DoQuickSort(iLo, Hi);
    if Lo < iHi then DoQuickSort(Lo, iHi);
  end;


var
  I, J, K, A, B: Integer;
  Ra, Rb: PRoom;
  MaxLine: Integer;
begin
  NRoots := length(MainRooms);
  SetLength(Roots, NRoots);
  for I := 0 to NRoots - 1 do
    Roots[I] := I;

  NLines := 0;
  for I := 0 to NRoots - 1 do
    inc(NLines, Length(Rooms[MainRooms[I]].Links));
  SetLength(Lines, NLines);
  NLines := 0;
  for I := 0 to NRoots - 1 do
    for J := 0 to Length(Rooms[MainRooms[I]].Links) - 1 do
    begin
      A := I;
      B := Rooms[MainRooms[I]].Links[J].Target;
      if A < B then
      begin
        Lines[NLines].A := A;
        Lines[NLines].B := B;
      end;
      Ra := @Rooms[MainRooms[A]];
      Rb := @Rooms[MainRooms[B]];
      Lines[NLines].Length := Sqr(Ra.CenterX-Rb.CenterX)+Sqr(Ra.CenterY-Rb.CenterY);
      inc(NLines);
    end;
  if NLines = 0 then exit;
  //TODO: sort
  DoQuickSort(0, NLines-1);  
  //Actually, process lines
  MaxLine := 0;
  while NRoots > 1 do
  begin
    Lines[MaxLine].Active := union(Lines[MaxLine].A, Lines[MaxLine].B);
    inc(MaxLine);
  end;
  //Now, extract data back to our structure
  for I := 0 to NLines-1 do
  begin
    if (I < MaxLine) and Lines[I].Active then continue;
    //also, add some more links
    if random < Params.AdditionalLinks then continue;

    A := Lines[I].A;
    B := Lines[I].B;
    Ra := @Rooms[MainRooms[A]];
    Rb := @Rooms[MainRooms[B]];
    for K := 0 to Length(Ra.Links) - 1 do
      if Ra.Links[K].Target = B then
      begin
        Ra.Links[K].Removed := True;
        break;
      end;
    for K := 0 to Length(Rb.Links) - 1 do
      if Rb.Links[K].Target = A then
      begin
        Rb.Links[K].Removed := True;
        break;
      end;
  end;
end;

procedure TDungeon.OffsetRooms;
var
  I, J: Integer;
  NoIntersections: boolean;
  vx, vy, dx, dy, r: Single;
const
  SMALL_DELTA = 1.5;

begin
  repeat
    NoIntersections := True;
    for I := 0 to NRooms - 1 do
    begin
      vx := 0;
      vy := 0;
      for J := 0 to NRooms - 1 do
        if (I<>J) and Rooms[I].Intersects(Rooms[J]) then
        begin
          NoIntersections := False;
          dx := Rooms[I].CenterX - Rooms[J].CenterX;
          dy := Rooms[I].CenterY - Rooms[J].CenterY;
          r := Hypot(dx, dy);
          if r < 1 then //Centers are identical
          begin
            r := 2*pi*random;
            dx := cos(r);
            dy := sin(r);
            r := 1;
          end;
          vx := vx+dx/r;
          vy := vy+dy/r;
        end;
      r := Hypot(vx, vy);
      if r > 0.001 then
      begin
        Inc(Rooms[I].X, Round(SMALL_DELTA*vx/r));
        Inc(Rooms[I].Y, Round(SMALL_DELTA*vy/r));
      end;
    end;
  until NoIntersections;
end;

procedure TDungeon.PickMainRooms;
var
  I, ax, ay: Integer;
  Square, aRoom, NMain: Integer;

begin
  NMain := 0;
  for I := NRooms - 1 downto 0 do
    with Rooms[I] do
    begin
      //fix rooms that is partially in
      if (X < 0) and (X+W > 0) then
      begin
        Inc(W, X);
        X := 0;
      end;
      if (Y < 0) and (Y+H > 0) then
      begin
        Inc(H, Y);
        Y := 0;
      end;
      if (Y < MapY-1) and (Y+H > MapY-1) then
        H := MapY-1-Y;
      if (X < MapX-1) and (X+W > MapX-1) then
        W := MapX-1-X;
      //drop that still outside
      if (X < 0) or (X+W > MapX-1) or (Y < 0) or (Y+H > MapY-1) or (W < 1) or (H < 1) then
      begin
        Rooms[I] := Rooms[NRooms-1];
        Dec(NRooms);
        SetLength(Rooms, NRooms);
        continue;
      end
      else if (W >= Params.RoomThreshold) and (H >= Params.RoomThreshold) then
      begin
        RoomType := TILE_BigRoom;
        Inc(NMain);
      end;
      Draw(Self, I);
    end;
  SetLength(MainRooms, NMain);
  NMain := 0;
  for I := 0 to NRooms - 1 do
    if Rooms[I].RoomType = TILE_BigRoom then
    begin
      MainRooms[NMain] := I;
      Inc(NMain);
    end;
  //Bad case!
  if NMain = 0 then
  begin
    //totally bad!
    if length(Rooms) = 0 then exit;

    Square := Rooms[0].W*Rooms[0].H;
    aRoom := 0;
    for I := 1 to NRooms - 1 do
      if Rooms[I].W*Rooms[I].H > Square then
      begin
        Square := Rooms[I].W*Rooms[I].H;
        aRoom := I;
      end;
    SetLength(MainRooms, 1);
    MainRooms[0] := aRoom;
    Rooms[aRoom].RoomType := TILE_BigRoom;
    Rooms[aRoom].Draw(Self, aRoom);
  end;
end;

{ TRoom }

function TRoom.CenterX: Integer;
begin
  Result := X+W div 2;
end;

function TRoom.CenterY: Integer;
begin
  Result := Y+H div 2;
end;

procedure TRoom.Draw(Context: TDungeon; Index: integer=-1);
var
  ax, ay: Integer;
begin
  for ax := X to X+W-1 do
    for ay := Y to Y+H-1 do
    begin
      context.Cells[ax, ay] := RoomType;
      if Index >= 0 then
        context.RoomCache[ax, ay] := Index+1;
    end;
  //Draw more for a big rooms
  if RoomType = TILE_BigRoom then
  begin
    for ax := X to X+W-1 do
    begin
      Context.Cells[ax, Y] := TILE_RoomWall;
      Context.Cells[ax, Y+H-1] := TILE_RoomWall;
    end;
    for ay := Y to Y+H-1 do
    begin
      Context.Cells[X, ay] := TILE_RoomWall;
      Context.Cells[X+W-1, ay] := TILE_RoomWall;
    end;
  end; 
end;

function TRoom.Intersects(const WithRoom: TRoom): Boolean;
begin
  Result :=
    (W div 2 + WithRoom.W div 2 >= abs(CenterX - WithRoom.CenterX))
      and
    (H div 2 + WithRoom.H div 2 >= abs(CenterY - WithRoom.CenterY));
end;

// X=0,W=6
// |    |
// +-??-+
// X
// |   |
// +-!-+

function TRoom.RandomX: Integer;
begin
  if W < 6 then
    Result := CenterX
  else
    Result := X+2+random(W-4);
end;

function TRoom.RandomY: Integer;
begin
  if H < 6 then
    Result := CenterY
  else
    Result := Y+2+random(H-4);
end;

function TRoom.CloseByX(const WithRoom: TRoom): Boolean;
begin
  Result :=
    (W div 4 + WithRoom.W div 4 >= abs(CenterX - WithRoom.CenterX));
end;

function TRoom.CloseByY(const WithRoom: TRoom): Boolean;
begin
  Result :=
    (H div 4 + WithRoom.H div 4 >= abs(CenterY - WithRoom.CenterY));
end;

{ TNiceDungeonGeneratorParams }

constructor TNiceDungeonGeneratorParams.Create;
begin
  NRooms := 150;
  RoomMinSize := 3;
  RoomMaxSize := 11;
  RoomThreshold := 6;
  MaxSizeRatio := 1.8;
  InitialRadius := 0.3;
  AdditionalLinks := 0.15;
end;

function TNiceDungeonGeneratorParams.GetField(s: string): single;

function tryint(name: string; val: integer): boolean;
begin
  Result := name = s;
  if Result then GetField := trunc(val);
end;

function tryf(name: string; val: Single): boolean;
begin
  Result := name = s;
  if Result then GetField := val;
end;

begin
  s := UpperCase(s);
  Result := 0;
  if tryint('NROOMS', NRooms) then exit;
  if tryint('ROOMMINSIZE', RoomMinSize) then exit;
  if tryint('ROOMMAXSIZE', RoomMaxSize) then exit;
  if tryint('ROOMTHRESHOLD', RoomThreshold) then exit;
  if tryf('MAXSIZERATIO', MaxSizeRatio) then exit;
  if tryf('INITIALRADIUS', InitialRadius) then exit;
  if tryf('ADDITIONALLINKS', AdditionalLinks) then exit;
end;


procedure TNiceDungeonGeneratorParams.SetField(s: string; x: single);

function tryint(name: string; var val: integer): boolean;
begin
  Result := name = s;
  if Result then val := trunc(x);
end;

function tryf(name: string; var val: Single): boolean;
begin
  Result := name = s;
  if Result then val := x;
end;

begin
  s := UpperCase(s);
  if tryint('NROOMS', NRooms) then exit;
  if tryint('ROOMMINSIZE', RoomMinSize) then exit;
  if tryint('ROOMMAXSIZE', RoomMaxSize) then exit;
  if tryint('ROOMTHRESHOLD', RoomThreshold) then exit;
  if tryf('MAXSIZERATIO', MaxSizeRatio) then exit;
  if tryf('INITIALRADIUS', InitialRadius) then exit;
  if tryf('ADDITIONALLINKS', AdditionalLinks) then exit;
end;

end.
