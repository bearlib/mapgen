unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, uDungeonGen, Grids, ValEdit;

type
  TForm2 = class(TForm)
    Image1: TImage;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    leMapX: TLabeledEdit;
    leMapY: TLabeledEdit;
    leNRooms: TLabeledEdit;
    vle1: TValueListEditor;
    Button10: TButton;
    cbCells: TCheckBox;
    cbRooms: TCheckBox;
    cbLinks: TCheckBox;
    edSeed: TEdit;
    Timer1: TTimer;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure cbRoomsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure DrawMap;
  end;

var
  Form2: TForm2;
  TheMap: TDungeon;
  Img: TBitmap;
                       
const
  COLORS: array[TCellType] of TColor = (
  //Wall = 0, Corridor, SmallRoom, BigRoom
    clBlack, clNavy, clBlue, clRed, clOlive, clYellow);

implementation

uses Math;

{$R *.dfm}

{ TForm2 }

procedure TForm2.Button10Click(Sender: TObject);
begin
  try
    Button1Click(nil);
    TheMap.GenerateRooms;
    TheMap.OffsetRooms;
    TheMap.PickMainRooms;
    TheMap.DelaunayTriangulation;
    TheMap.MinimalTree;
    TheMap.DrawHallways;
    DrawMap;
  except on E: Exception do
  begin
    Timer1.Enabled := False;
    ShowMessage(format('x=%s, y=%s, %s, %s', [leMapX.Text, leMapY.Text, edSeed.Text, E.Message]));
  end;


  end;
end;

procedure TForm2.Button1Click(Sender: TObject);
var
  Params: TNiceDungeonGeneratorParams;
begin
  if CheckBox1.Checked then
    RandSeed := StrToIntDef(edSeed.Text, 0)
  else
    edSeed.Text := IntToStr(RandSeed);
  DecimalSeparator := '.';
  TheMap.Free;
  Img.Free;
  Params := TNiceDungeonGeneratorParams.Create;
  Params.RoomMinSize := StrToInt(vle1.Values['RoomMinSize']);
  Params.RoomMaxSize := StrToInt(vle1.Values['RoomMaxSize']);
  Params.MaxSizeRatio := StrToFloat(vle1.Values['MaxSizeRatio']);
  Params.InitialRadius := StrToFloat(vle1.Values['InitialRadius']);
  Params.RoomThreshold := StrToInt(vle1.Values['RoomThreshold']);
  Params.AdditionalLinks := StrToFloat(vle1.Values['AdditionalLinks']);
  Params.NRooms := StrToInt(leNRooms.Text);
  TheMap := TDungeon.Create(StrToInt(leMapX.Text), StrToInt(leMapY.Text), Params);
  Img := TBitmap.Create;
  Img.Width := TheMap.MapX;
  Img.Height := TheMap.MapY;
  DrawMap;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  TheMap.GenerateRooms;
  DrawMap;
end;

procedure TForm2.Button3Click(Sender: TObject);
begin
  TheMap.OffsetRooms;
  DrawMap;
end;

procedure TForm2.Button4Click(Sender: TObject);
begin
  TheMap.PickMainRooms;
  DrawMap;
end;

procedure TForm2.Button5Click(Sender: TObject);
begin
  TheMap.DelaunayTriangulation;
  DrawMap;
end;

procedure TForm2.Button6Click(Sender: TObject);
begin
  TheMap.MinimalTree;
  DrawMap;
end;

procedure TForm2.Button7Click(Sender: TObject);
begin
  TheMap.DrawHallways;
  DrawMap;
end;

procedure TForm2.cbRoomsClick(Sender: TObject);
begin
  if Assigned(TheMap) then DrawMap;
end;

procedure TForm2.DrawMap;
var
  I,J: Integer;
  DrawRect: TRect;
  Scale: Single;
begin
  Image1.Picture.Bitmap.Width := Image1.Width;
  Image1.Picture.Bitmap.Height := Image1.Height;
  Scale := Min(Image1.Width/TheMap.MapX, Image1.Height/TheMap.MapY);
  for I := 0 to TheMap.MapX-1 do
    for J := 0 to TheMap.MapY-1 do
      if cbCells.Checked then
        Img.Canvas.Pixels[I, J] := COLORS[TheMap.Cells[I,J]]
      else
        Img.Canvas.Pixels[I, J] := clBlack; 
  DrawRect := Rect(0,0,Trunc(TheMap.MapX*Scale), Trunc(TheMap.MapY*Scale));
  with Image1.Canvas do
  begin
    StretchDraw(DrawRect, Img);
    if cbRooms.Checked then
    begin
      Pen.Width := 1;
      Pen.Color := clWhite;
      for I := 0 to TheMap.NRooms-1 do
        with TheMap.Rooms[I] do
          FrameRect(Rect(
            Trunc(Scale*X),
            Trunc(Scale*Y),
            Trunc(Scale*(X+W)),
            Trunc(Scale*(Y+H))
            ));
    end;
    if cbLinks.Checked then
    begin
      Pen.Width := 3;
      for I := 0 to TheMap.NRooms-1 do
        with TheMap.Rooms[I] do
        for J := 0 to Length(Links)-1 do
        begin
          if Links[J].Removed then
            Pen.Color := clDkGray
          else
            Pen.Color := clWhite;
          MoveTo( Trunc(Scale*CenterX),Trunc(Scale*CenterY));
          LineTo( Trunc(Scale*TheMap.Rooms[TheMap.MainRooms[Links[J].Target]].CenterX),Trunc(Scale*TheMap.Rooms[TheMap.MainRooms[Links[J].Target]].CenterY));
        end;
      Pen.Width := 1;
    end;
  end;
end;

end.
