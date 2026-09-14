' ARCHIVED FAILED PROBE — do not copy to a camera card.
' EOS M50 1.1.0 — ABI smoke test for Canon's internal power-save request.
'
' This is deliberately NOT the webcam script.  It only asks Canon to reset
' ("prolong") its power-save timer once, then returns.  Use it first to check
' that Canon Basic marshals the pointer argument correctly on this body.
' Recovery: power-cycle the camera if it asserts or becomes unresponsive.

dim prop_request_change = 0xE0559D60
dim prop_icu_auto_poweroff = 0x80030024
dim auto_poweroff_prolong = 3

private sub Initialize()
  ExportToEventProcedure("m50_prop_request", prop_request_change | 1)

  f = OpenFileCREAT("B:/M50PS-BEFORE.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50PS-BEFORE.TXT")
  WriteFileString(f, "Requesting AUTO_POWEROFF_PROLONG (3).\n")
  CloseFile(f)

  ' Canon prototype: pRequestChange(property_id, pointer_to_value, size).
  ' Canon Basic passes a numeric variable as storage when the callee wants a
  ' pointer; see the investigation notes before using the prohibit variant.
  m50_prop_request(prop_icu_auto_poweroff, auto_poweroff_prolong, 4)

  f = OpenFileCREAT("B:/M50PS-AFTER.TXT")
  CloseFile(f)
  f = OpenFileWR("B:/M50PS-AFTER.TXT")
  WriteFileString(f, "Prolong request returned.\n")
  CloseFile(f)
end sub
