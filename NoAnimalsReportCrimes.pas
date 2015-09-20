{
  No Animals Aginst Crimes autopatcher
  by hishy
  
  Simply put, this script is automatically edit the flags of specific factions to make
    the NPCs belonging to that faction ignore crimes.
  How it works is by OR-ing a known number and the current flags.
}
unit NoAnimalsReportCrimes;

uses mteFunctions;

const
  cVer='1.00';
  cRequired_xEdit_Ver='03010200';
  cDashes='---------------------------------------------------------------------------';
  cPatchFileName='NARC.esp';
  cIniFile=ScriptsPath+'NoAnimalsReportCrimes.ini';
  
var
  slGeneralFactions, slSpecialFactions: TStringList;
  cGeneralFlags: Cardinal;
  iPatchFile: IInterface;
  
procedure InitialChecks;
begin
  iPatchFile := FileByName(cPatchFileName);//Load the PatchFile's IInterface
  AddMessage('The current Script Version is: '+cVer);//Print the Script version
  AddMessage(cDashes);//Dashes
  
  if StrToInt('$'+cRequired_xEdit_Ver) < StrToInt(wbVersionNumber) then 
  begin //Check xEdit version
    raise Exception.Create('Your xEdit application is out-of-date. Please update, terminating script now.');
  end;
  
  if wbAppName <> 'TES5' then 
  begin //Check for Skyrim
    raise Exception.Create('This is a Skyrim only script, terminating script now.');
  end;
  
  if GetFileName(iPatchFile) = '' then 
  begin //Check for Patch File
    raise Exception.Create('You are missing '+cPatchFile+'. Please reinstal Vivid Snow, terminating script now.');
  end;
  
  if HasGroup(iPatchFile, 'FACT') then 
  begin//Checks for FormID Lists
    raise Exception.Create('Found previously patched weathers. Please reinstal Vivid Snow, terminating script now.');
  end;
  
  if not FileExists(cIniFile) then 
  begin //Check for INI File
    raise Exception.Create('You are missing '+cIniFile+'. Please reinstal the "Edit Scripts" folder from the mod archive, terminating script now.');
  end;
end;

procedure Startup;
var
  iniFile: TMemIniFile;
begin
  slGeneralFactions := TStringList.Create;
  slSpecialFactions := TStringList.Create;
  iniFile := TMemIniFile.Create(cIniFile);
  
  slGeneralFactions.CommaText := iniFile.ReadString('Generic', 'GenericFactions', '');
  cGeneralFlags := StrToInt(iniFile.ReadString('Generic', 'GenericFlagValue', '0'));
  iniFile.ReadSectionValues('Special', slSpecialFactions);

  iniFile.Free;
end;

procedure ProcessFaction(e: IInterface; slMasters: TStringList);
var
  sEdid: string;
  cDesiredFlags, cCurrentFlags, cNewFlags: Cardinal;
  rec: IInterface;
begin
  sEdid := EditorID(e);
  if slGeneralFactions.IndexOf(sEdid) <> -1 then
    cDesiredFlags := cGeneralFlags
  else if slSpecialFactions.Values[sEdid] <> '' then 
    cDesiredFlags := StrToInt(slSpecialFactions.Values[sEdid])
  else
    exit;
    
  AddMastersToList(GetFile(e), slMasters);
  AddMastersToFile(iPatchFile, slMasters, True);
  
  try
    rec := wbCopyElementToFile(e, iPatchFile, False, True);
    cCurrentFlags := genv(rec, 'DATA\Flags');
    cNewFlags := cCurrentFlags OR cDesiredFlags;
    senv(rec, 'DATA\Flags', cNewFlags);
  except
		on x: exception do 
    begin
			AddMessage(x.Message);
      AddMessage(cDashes);
      Check(e);
    end;
  end;
end;

procedure FindFactions;
var
  f,g,e: IInterface;
  iFileIndex, iElementIndex: int;
  sFileName: string;
  slMasters: TStringList;
begin
  slMasters := TStringList.Create;
  for iFileIndex := Pred(GetLoadOrder(iPatchFile)) DownTo 0 do
  begin
    f := FileByIndex(iFileIndex);
    sFileName := GetFileName(f);
    if StrEndsWith(sFileName, '.dat') then
      continue;
    g := GroupBySignature(f, 'FACT');
    for iElementIndex := 0 to Pred(ElementCount(g)) do
    begin
      e := ElementByIndex(g,iElementIndex);
      ProcessFaction(e, slMasters);
    end;
  end;
  slMasters.Free;
end;
  
procedure FreeMemory;
begin
  slGeneralFactions.Free;
  slSpecialFactions.Free;
end;
  
function Initialize: integer;
begin
  InitialChecks;
  Startup;
  FindFactions;
  FreeMemory;
end;

end.
