' HDMI-Line OSD mute, return immediately so the camera UI remains usable.
' Trigger from Playback -> SET, then press Playback to enter live view.
' Restore by powering the camera off after observing the HDMI output.
dim disp_line_mute_on = 0xE0538114

private sub Initialize()
  ExportToEventProcedure("m50_line_on", disp_line_mute_on | 1)
  f = OpenFileCREAT("B:/M50HOLD.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50HOLD.TXT")
  WriteFileString(f, "HDMI Line mute called; power-cycle to restore.\n")
  CloseFile(f)
  m50_line_on(0x1000)
end sub
