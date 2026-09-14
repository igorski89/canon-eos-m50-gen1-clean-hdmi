' ARCHIVED FAILED PROBE — do not copy to a camera card.
' EOS M50 1.1.0 - display-sleep reset-property smoke test.
'
' Derived from GuiUtilTftPowerSaveController's PROP_POWER_SAVE_TIMER_RESET
' table entry (0x80020048). Canon Basic rejects unsigned literals with the
' high bit set, so the same 32-bit property ID is written as signed decimal.
' This makes ONE reset request only; it is an ABI/safety test, not a solution
' for periodic keep-awake. Recovery: power-cycle if the camera becomes stuck.

dim prop_request_change = 0xE0559D60
dim prop_power_save_timer_reset = -2147352504
dim power_save_timer_reset = 1

private sub Initialize()
  ExportToEventProcedure("m50_prop_request", prop_request_change | 1)

  f = OpenFileCREAT("B:/M50RESET1.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50RESET1.TXT")
  WriteFileString(f, "Calling PROP_POWER_SAVE_TIMER_RESET.\n")
  CloseFile(f)

  m50_prop_request(prop_power_save_timer_reset, power_save_timer_reset, 4)

  f = OpenFileCREAT("B:/M50RESET2.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50RESET2.TXT")
  WriteFileString(f, "Power-save timer reset call returned.\n")
  CloseFile(f)
end sub
