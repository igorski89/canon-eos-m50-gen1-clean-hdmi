' Experimental, reversible M50.110 1.1.0 display test.
' This does not patch firmware. It temporarily calls Canon's own AF OSD
' mute/unmute wrappers, then restores the display before returning.
'
dim fa_osd_mute_on  = 0xE0079D54
dim fa_osd_mute_off = 0xE0079D8C

private sub Initialize()
    ExportToEventProcedure("m50_fa_osd_on", fa_osd_mute_on | 1)
    ExportToEventProcedure("m50_fa_osd_off", fa_osd_mute_off | 1)

    RemoveFile("B:/M50FA.TXT")
    f = OpenFileCREAT("B:/M50FA.TXT")
    CloseFile(f)
    f = OpenFileWR("B:/M50FA.TXT")
    WriteFileString(f, "Calling FA_OSDMuteOn at 0x%08X\n", fa_osd_mute_on)
    CloseFile(f)

    ' Keep the test short and always restore the OSD path.
    m50_fa_osd_on()
    SleepTask(5000)
    m50_fa_osd_off()

    f = OpenFileWR("B:/M50FA.TXT")
    WriteFileString(f, "FA_OSDMuteOff returned; display should be restored.\n")
    CloseFile(f)
end sub
