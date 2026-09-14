' ARCHIVED FAILED PROBE — do not copy to a camera card.
' EOS M50 1.1.0 - active Canon Basic task test.
'
' Uses only the known-good HDMI Line OSD mute call and SleepTask, which was
' previously used successfully in test_hdmi_line.m. It deliberately remains
' active for two minutes. With Display off set to 15 sec, HDMI surviving the
' full interval shows whether an active Canon Basic task suppresses sleep.
' The camera may not accept controls while this script is running.
'
' Recovery: power-cycle. The HDMI OSD mute is runtime-only.

dim disp_line_mute_on = 0xE0538114

private sub Initialize()
  ExportToEventProcedure("m50_line_on", disp_line_mute_on | 1)

  f = OpenFileCREAT("B:/M50ACTIVE-BEFORE.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50ACTIVE-BEFORE.TXT")
  WriteFileString(f, "HDMI Line mute active; holding Canon Basic task for 120 sec.\n")
  CloseFile(f)

  m50_line_on(0x1000)
  SleepTask(120000)

  f = OpenFileCREAT("B:/M50ACTIVE-AFTER.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50ACTIVE-AFTER.TXT")
  WriteFileString(f, "Active task completed 120 sec wait.\n")
  CloseFile(f)
end sub
