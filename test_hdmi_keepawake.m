' ARCHIVED FAILED PROBE — do not copy to a camera card.
' EOS M50 1.1.0 — EXPERIMENTAL clean-HDMI + power-save prohibition.
'
' Uses Canon's own, volatile requests only; it does not modify firmware.
' It combines the already validated HDMI-Line OSD mute with the internal
' AUTO_POWEROFF_PROHIBIT request.  This must be hardware-tested before it is
' considered a replacement for test_hdmi_line_hold.m.
'
' Run from Playback -> SET, wait three seconds, then return to Live View.
' Restore normal power-save handling by power-cycling the camera.

dim disp_line_mute_on = 0xE0538114
dim prop_request_change = 0xE0559D60
dim prop_icu_auto_poweroff = 0x80030024
dim auto_poweroff_prohibit = 2

private sub Initialize()
  ExportToEventProcedure("m50_line_on", disp_line_mute_on | 1)
  ExportToEventProcedure("m50_prop_request", prop_request_change | 1)

  f = OpenFileCREAT("B:/M50KEEP-BEFORE.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50KEEP-BEFORE.TXT")
  WriteFileString(f, "Muting HDMI OSD; requesting AUTO_POWEROFF_PROHIBIT (2).\n")
  CloseFile(f)

  m50_line_on(0x1000)
  m50_prop_request(prop_icu_auto_poweroff, auto_poweroff_prohibit, 4)

  f = OpenFileCREAT("B:/M50KEEP-AFTER.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50KEEP-AFTER.TXT")
  WriteFileString(f, "Both requests returned; leave running past 30 minutes.\n")
  CloseFile(f)
end sub
