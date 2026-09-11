' Registration-only diagnostic. Does not call or modify the Canon routine.
dim fa_osd_mute_on = 0xE0079D54

private sub write_marker(name, text)
  f = OpenFileCREAT(name)
  CloseFile(f)
  f = OpenFileWR(name)
  WriteFileString(f, text)
  CloseFile(f)
end sub

private sub Initialize()
  write_marker("B:/M50REG1.TXT", "before registration\n")
  ExportToEventProcedure("m50_fa_osd_on", fa_osd_mute_on | 1)
  write_marker("B:/M50REG2.TXT", "registration returned\n")
end sub
