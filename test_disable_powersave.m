' ARCHIVED FAILED PROBE — do not copy to a camera card.
' EOS M50 1.1.0 - narrow DisablePowerSave event-procedure test.
'
' No raw firmware address and no pointer arguments are used here. The Canon
' event procedure is called by name, so a missing registration returns -1
' rather than calling an arbitrary address. This script intentionally does
' not mute HDMI OSD; it tests only whether Display off is inhibited.
'
' Trigger from Playback -> SET, return to live view, then wait past the
' configured Display off time. Power-cycle restores the normal state.

private sub Initialize()
  f = OpenFileCREAT("B:/M50DPS-BEFORE.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50DPS-BEFORE.TXT")
  WriteFileString(f, "Calling DisablePowerSave event procedure.\n")
  CloseFile(f)

  result = ExecuteEventProcedure("DisablePowerSave")

  f = OpenFileCREAT("B:/M50DPS-AFTER.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50DPS-AFTER.TXT")
  WriteFileString(f, "DisablePowerSave returned %d.\n", result)
  CloseFile(f)
end sub
