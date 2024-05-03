program ute(input,output);

var	ic: integer;
	c,d	: char;

procedure print(n:integer);
var i:integer;
	c:char;
begin	for i:= 1 to n do 
	begin	read(c); write(ord(c):5);end;
end;

begin

repeat	read(c); ic:=ord(c);
	if ic > 31 then write(c) else
	case ic of 
	0:	writeln(ic:5,'null');
	1:	begin read(c); writeln(ic:5,ord(c):5,'char to printer') end;
	2:	writeln(ic:5,' printer on');
	3:	writeln(ic:5,' printer off');
	4:	writeln(ic:5,' text to text cursor');
	5:	writeln(ic:5,' text to graphics cursor');
	6:	writeln(ic:5,' non destructive space');
	7:	writeln(ic:5,' bell');
	8:	writeln(ic:5,' backspace');
	9:	writeln(ic:5,' tab');
	10:	writeln(ic:5,' down line');
	11:	writeln(ic:5,' up line');
	12:	writeln(ic:5,' clear screen and home');
	13:	writeln(ic:5,' return');
	14:	writeln(ic:5,' open line');
	15:	writeln(ic:5,' delete line');
	16:	writeln(ic:5,' clear graphics area');
	17:	begin 	read(c);
			writeln(ic:5,ord(c),' set text fg logical colour') 
		end;
	18:	begin	read(c,d);
		   	writeln(ic:5,ord(c):5,ord(d):5,
			'set graphics fg logical colour')
		end;
	19:	begin	writeln(ic:5,ord(c):5,ord(d):5,
			'set real-logical colour assignment');
		end;
	20:	writeln(ic:5,' restore default colours');
	21:	writeln(ic:5,' delete to end of line');
	22:	begin	read(c);
			writeln(ic:5,ord(c):5,'set screen mode' );
		end;
	23:	begin	write(ic:5); 
			print(9); 
			writeln(' reprogram character');
		end;
	24:	begin	writeln(ic:5);
			print(8);
			writeln(' define graphics window');
		end;
	25:	begin	write(ic:5);
			print(5);
			writeln(' plot');
		end;
	26:	writeln(ic:5,' restore default windows');
	27:	begin	write('ESC ');
			read(c); ic:=ord(c); write(c:3);
		end;
	28:	begin	write(ic:5);
			print(4);
			writeln(' define text window');
		end;
	29:	begin	write(ic:5);
			print(4);
			writeln(' define graphics origin');
		end;
	30:	writeln(ic:5,' home text cursor');
	31:	begin	write(ic:5);
			print(2);
			writeln(' position text cursor');
		end;
	end;


until c='z'


end.
