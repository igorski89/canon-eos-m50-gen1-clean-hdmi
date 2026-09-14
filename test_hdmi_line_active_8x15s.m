' ARCHIVED FAILED PROBE — do not copy to a camera card.
' M50 1.1.0 active Canon Basic task test: eight 15-second waits.
' Uses only the known working HDMI-Line mute call and the previously used
' SleepTask(15000) form. Recovery: power-cycle the camera.
dim disp_line_mute_on = 0xE0538114

private sub Initialize()
  ExportToEventProcedure("m50_line_on", disp_line_mute_on | 1)
  f = OpenFileCREAT("B:/M50ACTIVE1.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50ACTIVE1.TXT")
  WriteFileString(f, "Active wait started\n")
  CloseFile(f)

  m50_line_on(0x1000)
  SleepTask(15000)
  SleepTask(15000)
  SleepTask(15000)
  SleepTask(15000)
  SleepTask(15000)
  SleepTask(15000)
  SleepTask(15000)
  SleepTask(15000)

  f = OpenFileCREAT("B:/M50ACTIVE2.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50ACTIVE2.TXT")
  WriteFileString(f, "Active wait completed\n")
  CloseFile(f)
end sub
