' Harmless Canon Basic execution/status check for the M50.
private sub Initialize()
    RemoveFile("B:/M50STATUS.TXT")
    f = OpenFileCREAT("B:/M50STATUS.TXT")
    CloseFile(f)
    f = OpenFileWR("B:/M50STATUS.TXT")
    WriteFileString(f, "status script reached Initialize()\n")
    CloseFile(f)
end sub
