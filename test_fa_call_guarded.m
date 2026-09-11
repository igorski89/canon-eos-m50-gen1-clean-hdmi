' Guarded, reversible call test for M50 firmware 1.1.0.
dim fa_osd_mute_on  = 0xE0079D54
dim fa_osd_mute_off = 0xE0079D8C

private sub marker(name, text)
  f = OpenFileCREAT(name)
  CloseFile(f)
  f = OpenFileWR(name)
  WriteFileString(f, text)
  CloseFile(f)
end sub

private sub Initialize()
  ExportToEventProcedure("m50_fa_osd_on", fa_osd_mute_on | 1)
  ExportToEventProcedure("m50_fa_osd_off", fa_osd_mute_off | 1)
  marker("B:/M50CALL1.TXT", "registered; calling mute\n")

  m50_fa_osd_on()
  SleepTask(3000)
  m50_fa_osd_off()

  marker("B:/M50CALL2.TXT", "unmute returned\n")
end sub
