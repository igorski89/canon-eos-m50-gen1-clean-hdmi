' Direct HDMI/"Line" OSD mute test, M50 firmware 1.1.0.
' Trigger from Playback -> SET. Then press Playback to return to live view.
' The HDMI OSD is automatically restored after 15 seconds.
dim disp_line_mute_on  = 0xE0538114
dim disp_line_mute_off = 0xE053814E

private sub marker(name, text)
  f = OpenFileCREAT(name)
  CloseFile(f)
  f = OpenFileWR(name)
  WriteFileString(f, text)
  CloseFile(f)
end sub

private sub Initialize()
  ExportToEventProcedure("m50_line_on", disp_line_mute_on | 1)
  ExportToEventProcedure("m50_line_off", disp_line_mute_off | 1)
  marker("B:/M50LINE1.TXT", "HDMI Line mute active\n")

  m50_line_on(0x1000)
  SleepTask(15000)
  m50_line_off(0x1000)

  marker("B:/M50LINE2.TXT", "HDMI Line unmute returned\n")
end sub
