program Project1;

{$APPTYPE CONSOLE}

uses
    SysUtils, Windows, JPEG, CCR.Exif, Graphics, Forms;

var i, FontR, FontG, FontB, BgR, BgG, BgB, f_size: byte;
    pos_x, pos_y, x, position: Integer;
    f_style: TFontStyles;
    BgTp: boolean;
    f_name, file_name, dir_name, f_mask, img_date: string;
    file_list: array of string;
    jpeg: TJPEGImage;
    bmp: TBitmap;
    ExifData: TExifData;
    choice: char;
label loadlist, processing, finished;

function StrtoFontStyle(St: string): TFontStyles;
var
  S: TFontStyles;
begin
  S  := [];
  St := UpperCase(St);
  if St = 'BOLD' then S := [fsBold]
  else if St = 'ITALIC' then S := [fsItalic]
  else if St = 'UNDERLINE' then S := [fsUnderLine]
  else if St = 'STRIKEOUT' then S := [fsStrikeOut]

  else if St = 'BOLDITALIC' then S := [fsbold, fsItalic]
  else if St = 'BOLDUNDERLINE' then S := [fsBold, fsUnderLine]
  else if St = 'BOLDSTRIKE' then S := [fsBold, fsStrikeOut]

  else if St = 'BOLDITALICUNDERLINE' then S := [fsBold..fsUnderLine]
  else if St = 'BOLDITALICSTRIKE' then S := [fsBold, fsItalic, fsStrikeOut]
  else if St = 'BOLDUNDERLINESTRIKE' then S := [fsBold, fsUnderline, fsStrikeOut]
  else if St = 'BOLDITALICUNDERLINESTRIKE' then S := [fsBold..fsStrikeOut]

  else if St = 'ITALICUNDERLINE' then S := [fsItalic, fsUnderline]
  else if St = 'ITALICSTRIKE' then S := [fsItalic, fsStrikeOut]

  else if St = 'UNDERLINESTRIKE' then S := [fsUnderLine, fsStrikeOut]
  else if St = 'ITALICUNDERLINESTRIKE' then S := [fsItalic..fsStrikeOut];

  StrtoFontStyle := S;
end;

procedure Cls;
var
    hStdOut: HWND;
    ScreenBufInfo: TConsoleScreenBufferInfo;
    Coord1: TCoord;
begin
    hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
    GetConsoleScreenBufferInfo(hStdOut, ScreenBufInfo);
    Coord1.X:=0;
    Coord1.Y:=ScreenBufInfo.dwCursorPosition.Y;
    SetConsoleCursorPosition(hStdOut, Coord1);
end;

procedure ListDir(Path, Mask: String);
{Path : string that contains start path for listing filenames and directories
 List : List box in which found filenames are going to be stored }
var
SearchRec:TsearchRec;
Result:integer;
S:string; { Used to hold current directory, GetDir(0,s) }
begin
     try {Exception handler }
        ChDir(Path);
     except on EInOutError do
            begin
                WriteLn('Error changing directory!');
                ReadLn;
                Exit;
            end;
     end;
     if length(path)<> 3 then path:=path+'\';   { Checking if path is root, if not add }
     FindFirst(path+mask,faAnyFile,SearchRec); { '\' at the end of the string         }
                                                { and then add '*.*' for all file     }
     Repeat
           If (SearchRec.Attr<>16) and //dir with ReadOnly attribute
           (SearchRec.Attr<>48) and    //dir with ReadOnly and Archive attribute
           (SearchRec.Attr<>18) and    //dir with ReadOnly and Hidden attribute
           (SearchRec.Attr<>50) and  //dir with all three parameters
           (SearchRec.Name<>'') then
           begin
                GetDir(0,s); { Get current dir of default drive }
                SetLength(file_list,Length(file_list)+1);
                file_list[High(file_list)]:=s+'\'+SearchRec.Name;
           end;
           Result:=FindNext(SearchRec);
           Application.ProcessMessages;
     until result<>0; { Found all files, go out }
     GetDir(0,s);
end;


begin
    //Initializing default file & directory name
    file_name:='';//ExtractFileDir(Application.ExeName)+'\2014-06-11 07-04-34.jpg'; //Change to '' in final compilation
    dir_name:=ExtractFileDir(Application.ExeName);
    //Initializing default file mask
    f_mask:='*.jpg';
    //Initializing default position
    pos_x:=0;
    pos_y:=0;
    //Initializing default font name
    f_name:='Arial';
    //Initializing default font size
    f_size:=12;
    //Initializing default font style
    f_style:=[fsBold];
    //Initializing red fonts
    FontR:=255;
    FontG:=0;
    FontB:=0;
    //Initializing transparent background
    BgTp:=False;
    //Initializing black background
    BgR:=0;
    BgG:=0;
    BgB:=0;
    //Loading individual file
    i:=1;
    if ParamStr(i)='f' then
    begin
        file_name:=ParamStr(i+1);
        if FileExists(file_name)=False then
        begin
            WriteLn('Specified file  not found! - '+file_name);
            ReadLn;
            GoTo finished;
        end;
        i:=i+2;
    end
    else
    //Loading directory
    if ParamStr(i)='d' then
    begin
        dir_name:=ParamStr(i+1);
        if DirectoryExists(dir_name)=False then
        begin
            WriteLn('Specified directory not found! - '+dir_name);
            ReadLn;
            GoTo finished;
        end;
        //Loading file mask
        If ParamStr(i+2)<>'' then
            f_mask:=ParamStr(i+2);
        i:=i+3;
    end;
    //skip rest of the parameters if first is not d or f
    if i=1 then
        GoTo loadlist;
    //Pos X
    if ParamStr(i)<>'' then
        pos_x:=StrToInt(ParamStr(i));
    //Pos Y
    if ParamStr(i+1)<>'' then
        pos_y:=StrToInt(ParamStr(i+1));
    //Font name,size,style
    i:=i+2;
    if ParamStr(i)<>'' then
        f_name:=ParamStr(i);
    if ParamStr(i+1)<>'' then
        f_size:=StrToInt(ParamStr(i+1));
    if ParamStr(i+2)<>'' then
        f_style:=StrToFontStyle(ParamStr(i+2));
    //Loading font color
    i:=i+3;
    if ParamStr(i)<>'' then
        FontR:=StrToInt(ParamStr(i));
    if ParamStr(i+1)<>'' then
        FontG:=StrToInt(ParamStr(i+1));
    if ParamStr(i+2)<>'' then
        FontB:=StrToInt(ParamStr(i+2));
    //Loading background transparency
    i:=i+3;
    if ParamStr(i)<>'' then
        BgTp:=StrToBool(ParamStr(i));
    //Loading background color
    i:=i+1;
    if ParamStr(i)<>'' then
        BgR:=StrToInt(ParamStr(i));
    if ParamStr(i+1)<>'' then
        BgG:=StrToInt(ParamStr(i+1));
    if ParamStr(i+2)<>'' then
        BgB:=StrToInt(ParamStr(i+2));
loadlist:
    //Loading directory listing
    if file_name<>'' then
    begin
        SetLength(file_list,1);
        file_list[0]:=file_name;
    end
    else
        ListDir(dir_name, f_mask);
    //Loading JPEG image
    if Length(file_list)>0 then
    if (file_list[0]<>'') and (ParamStr(1)='') then
    begin
        WriteLn('Process all .jpg images in current folder with default settings?');
        Write('Y/N: ');
        Read(choice);
        if UpCase(choice)='Y' then
            GoTo processing
        else
            GoTo finished;
    end;
processing:
    //Creating objects
    ExifData := TExifData.Create;
    jpeg:=TJPEGImage.Create;
    bmp:=TBitmap.Create;
    try
        for x:=0 to Length(file_list)-1 do
        begin
            //Extracting EXIF OriginalDateTime
            ExifData.LoadFromGraphic(file_list[x]); //LoadFromJPEG before v1.5.0
            img_date:=ExifData.DateTimeOriginal.AsString;  //returns an empty string if tag doesn't exist
            //loading image
            jpeg.LoadFromFile(file_list[x]);
            bmp.Assign(jpeg);
            //Setting up font style
            bmp.Canvas.Font.Name:=f_name;
            bmp.Canvas.Font.Size:=f_size;
            bmp.Canvas.Font.Style:=f_style;
            bmp.Canvas.Font.Color:=RGB(FontR,FontG,FontB);
            if BgTp then
                bmp.Canvas.Brush.Style:=bsClear
            else
            begin
                bmp.Canvas.Brush.Style:=bsSolid;
                bmp.Canvas.Brush.Color:=RGB(BgR,BgG,BgB);
            end;
            bmp.Canvas.TextOut(pos_x,pos_y,img_date);
            jpeg.Assign(bmp);
            //Saving JPEG and Exif data to a file
            jpeg.SaveToFile(file_list[x]);
            ExifData.SaveToGraphic(file_list[x]);
            Cls; //set console cursor back to overwrite previous progress output
            Write('Progress: '+IntToStr(round((x+1)/Length(file_list)*100))+'%');
        end;
    finally
        ExifData.Free;
        bmp.free;
        jpeg.free;
    end;
finished:
end.
