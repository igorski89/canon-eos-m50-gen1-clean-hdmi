' Trace-only version of the proven HDMI-Line OSD mute routine for EOS M50 1.1.0.
' It intentionally introduces no timing loop, property-manager call, or new
' firmware routine. Trigger from Playback -> SET, then enter live view.
'
' After testing, reinsert the SD card and inspect B:/M50TRACE.TXT.

dim disp_line_mute_on = 0xE0538114

private sub trace(text)
  f = OpenFileCREAT("B:/M50TRACE.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50TRACE.TXT")
  WriteFileString(f, text)
  CloseFile(f)
end sub

private sub Initialize()
  trace("1 Initialize entered\\n")
  ExportToEventProcedure("m50_line_on", disp_line_mute_on | 1)
  trace("2 HDMI routine exported\\n")
  m50_line_on(0x1000)
  trace("3 HDMI routine returned\\n")
end sub
