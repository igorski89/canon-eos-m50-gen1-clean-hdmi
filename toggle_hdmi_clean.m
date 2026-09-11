' EOS M50 1.1.0: toggle HDMI OSD visibility.
' Playback -> SET once: mute HDMI OSD (clean feed).
' Playback -> SET again: restore HDMI OSD.
dim disp_line_mute_on  = 0xE0538114
dim disp_line_mute_off = 0xE053814E

private sub log(text)
  f = OpenFileCREAT("B:/M50TOGGLE.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50TOGGLE.TXT")
  WriteFileString(f, text)
  CloseFile(f)
end sub

private sub Initialize()
  ExportToEventProcedure("m50_line_on", disp_line_mute_on | 1)
  ExportToEventProcedure("m50_line_off", disp_line_mute_off | 1)

  state = OpenFileRD("B:/M50MUTED.STATE")
  if state >= 0 then
    CloseFile(state)
    m50_line_off(0x1000)
    RemoveFile("B:/M50MUTED.STATE")
    log("HDMI OSD restored\n")
  else
    m50_line_on(0x1000)
    f = OpenFileCREAT("B:/M50MUTED.STATE")
    CloseFile(f)
    log("HDMI OSD muted; invoke again to restore\n")
  end if
end sub
