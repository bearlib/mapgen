{****************************************************************************
  Разработчик Коновод Андрей
  Модифицирован: 3 февраля 2008

Модуль содержит функции разбора строк
  TokenStr - выделяет одно слово из строки (отделенное пробелом или табуляцией)
  TokenStrS - то же самое, но отделенное заданным символом
  TokenStrL - аналогично TokenStr, но выделяет последнее слово
  TokenStrI - аналогично TokenStr, но слово может быть отделено любым символом, кроме букв и цифр

  CharsToInt - выделяет число, закодированное побайтно в строке
  IntToChars - кодирует число побайтно в строку из четырех символов
  WordToChars - аналогично предыдущему , для 2 байт
****************************************************************************}
unit MyToken;
{Version 2.2 off}

interface

uses Windows, Math, SysUtils;

function TokenStr(var s:string):string;
function TokenStrS(var s:string;c:char):string;
function TokenStrL(var s:string):string;
function TokenStrI(var s:string):string;

function CharsToInt(AString: string): Integer;
function IntToChars(Value: integer): string;
//function WordToChars(Value: integer): string;

function CharsToReal(AString: string): Real;
function RealToChars(Value: Real): string;
function TokenReal(var s:string): Real;
procedure AddReal(var s:string; i:real);

function TokenInt(var s:string): integer;
procedure AddInt(var s:string; i:integer);
procedure AddBinStr(var s:string; s1:string);
function Var2String(const Data; Size: Integer): string;
procedure String2Var(s: string; var Data; Size: Integer);
procedure TokenVar(var s: string; var Data; Size: Integer);
function TokenBinStr(var s:string): string;

function IncNumber(const s: string): string;

function ReplaceAll(const s: string; ReplFrom, ReplTo: string): string;

implementation


function TokenStr(var s:string):string;
var n,i,j:integer;

begin
n:=length(s);
i:=pos(' ',s);
if i=0 then i:=n+1;
j:=pos(#9,s);
if (j>0)and(j<i)then i:=j;

if i=0 then
 begin
 result:=s;
 s:=''
 end
else
 begin
 result:=copy(s,1,i-1);
 repeat
  inc(i)
 until (i>n)or((s[i]<>' ')and(s[i]<>#9));
 delete(s,1,i-1)
 end
end;

function TokenStrS(var s:string;c:char):string;
var i:integer;
begin
i:=pos(c,s);
if i=0 then
 begin
 result:=s;
 s:=''
 end
else
 begin
 result:=copy(s,1,i-1);
// repeat
  inc(i);
// until (i>l)or((i<=l) and (s[i]<>' '));
 delete(s,1,i-1)
 end
end;

function TokenStrL(var s:string):string;
var i,j,l:integer;
begin
i:=0;
l:=Length(s);
for j:=l downto 1 do
 if s[j]=' ' then
  begin
  i:=j;break
  end;
if i=0 then
 begin
 result:=s;
 s:=''
 end
else
 begin
 result:=copy(s,i+1,l);
 repeat
  dec(i)
 until (i=0)or(s[i]<>' ');
 delete(s,i+1,l)
 end
end;

function TokenStrI(var s:string):string;
var
  i,j,l:integer;
  c:char;

  function IsIDChar(c:char):boolean;
  begin
    result:=((c<'a')or(c>'z'))and((c<'A')or(c>'Z'))
                  and((c<'0')or(c>'9'))
                  and((c<'а')or(c>'я'))
                  and((c<'А')or(c>'Я'))and(c<>'_');
  end;            

begin
  i:=0;
  l:=Length(s);
  for j:=1 to l do
  begin
    c:=s[j];
    if IsIDChar(c) then
    begin
      i:=j;break
    end
  end;
  if i=0 then
  begin
    result:=s;
    s:=''
  end
  else
  begin
    result:=copy(s,1,i-1);
    l:=length(s);
    while (i<l)and((s[i]=' ')or(s[i]=#9))do inc(i);
    delete(s,1,i-1)
  end
end;

function WordToChars(Value: integer): string;
begin
  Result:=Char(Hi(Loword(cardinal(Value))))+ Char(Lo(cardinal(Value)));
end;


function IntToChars(Value: integer): string;
begin
  Result:=Char(Hi(HiWord(cardinal(Value))))+ Char(Lo(HiWord(cardinal(Value))))
          +Char(Hi(Loword(cardinal(Value))))+ Char(Lo(cardinal(Value)));
end;

function CharsToInt(AString: string): Integer;
var
  Len, I: integer;
begin
  Result:=0;
  Len:= Length(AString);
  for I := 1 to Len  do
    Result:=Result + byte(AString[I]) shl (8* (Len - I));
end;

function TokenInt(var s:string): integer;
var
  I: integer;
begin
  Result:=0;
  if s<>'' then
  begin
    for I := 1 to min(4,Length(s))  do
      Result:=(Result shl 8) + ord(s[I]);
    delete(s,1,4);
  end;
end;

function TokenReal(var s:string): Real;
begin
  Result:=0;
  if s<>'' then
  begin
    Result := CharsToReal(Copy(s, 1, SizeOf(Real)));
    delete(s, 1, SizeOf(Real));
  end;
end;

procedure AddInt(var s:string; i:integer);
begin
  s := s + IntToChars(i)
end;

procedure AddReal(var s:string; i:real);
begin
  s := s + RealToChars(i)
end;

function Var2String(const Data; Size: Integer): string;
begin
  Result := StringOfChar(' ', Size);
  CopyMemory(pointer(Result), @Data, Size);
end;

procedure String2Var(s: string; var Data; Size: Integer);
begin
  if length(s) >= Size then
    CopyMemory(@Data, pointer(s), Size)
  else
    FillMemory(@Data, Size, 0);
end;

procedure TokenVar(var s: string; var Data; Size: Integer);
begin
  String2Var(copy(s, 1, Size), Data, Size);
  Delete(s, 1, Size);
end;

function CharsToReal(AString: string): Real;
begin
  String2Var(AString, Result, SizeOf(Real));
end;

function RealToChars(Value: Real): string;
var
  r: Real;
begin
  r := Value;
  Result := Var2String(r, SizeOf(Real));
end;

function TokenBinStr(var s:string): string;
var
  I: Integer;
begin
  I := TokenInt(s);
  Result := Copy(s, 1, I);
  Delete(s, 1, I);
end;

procedure AddBinStr(var s:string; s1:string);
begin
  s := s+IntToChars(length(s1))+s1;
end;

function IncNumber(const s: string): string;
var
  I: Integer;
  s1: string;
begin
  I := Length(s);
  while (i > 0) and (s[I] in ['0'..'9']) do
    Dec(I);
  s1 := copy(s, I+1, MAXINT);
  if s1 = '' then
    s1 := '1'
  else
    s1 := IntToStr(StrToInt(s1)+1);
  Result := Copy(s, 1, I)+s1;
end;

function ReplaceAll(const s: string; ReplFrom, ReplTo: string): string;
var
  I: Integer;
begin
  Result := S;
  repeat
    I := Pos(ReplFrom, Result);
    if I <= 0 then exit;
    Result := Copy(Result, 1, I-1)+ReplTo+Copy(Result, I+Length(ReplFrom), MAXINT);
  until false;
end;

end.
