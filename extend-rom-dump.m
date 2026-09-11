' Candidate ROM export for EOS M50; named Canon function, no hardcoded addresses.
' SaveAllRomImageToFile example: lclevy/cbasic_examples/Universal/extend_dump_rom.m
' Upstream documents that routine's example as tested on R6 1.4.0 / 1.5.0.
' M50 file-writing API was verified on this camera with M50TEST.TXT.
' Full ROM export has not yet been verified on this camera.
private sub Initialize()
    f = OpenFileCREAT("B:/M50DUMP.LOG")
    CloseFile(f)
    f = OpenFileWR("B:/M50DUMP.LOG")
    WriteFileString(f, "START: requesting ROM export\n")
    CloseFile(f)

    SaveAllRomImageToFile()

    f = OpenFileCREAT("B:/M50DONE.TXT")
    CloseFile(f)
    f = OpenFileWR("B:/M50DONE.TXT")
    WriteFileString(f, "ROM export function returned; dump files still need validation.\n")
    CloseFile(f)
end sub
