' Read-only first 8 MiB of M50 ROM0, written as hex words to SD.
' Based on SRSA hex dumper, M50 thread msg227190, May 2020:
' https://www.magiclantern.fm/forum/index.php?topic=23296.msg227190
' Source copy: lclevy/cbasic_examples/Universal/extend_dump_hex.m
' Start address from magiclantern platform/M50.110/Makefile.
' Only file removed/recreated is this experiment's own M50ROM0A.TXT.
dim started = 0

private sub save_as_hex(fn,addr,size)
    RemoveFile(fn)
    f = OpenFileCREAT(fn)
    CloseFile(f)
    f = OpenFileWR(fn)
    p = addr
    do while p < (addr+size)
        p1 = *p
        p = p + 4
        p2 = *p
        p = p + 4
        p3 = *p
        p = p + 4
        p4 = *p
        p = p + 4
        p5 = *p
        p = p + 4
        p6 = *p
        p = p + 4
        p7 = *p
        p = p + 4
        p8 = *p
        p = p + 4
        WriteFileString(f,"%08x%08x%08x%08x%08x%08x%08x%08x\n",p1,p2,p3,p4,p5,p6,p7,p8)
    loop
    CloseFile(f)
end sub

private sub Initialize()
    if started = 1 then
        exit sub
    end if
    started = 1
    save_as_hex("B:/M50ROM0A.TXT",0xe0000000,0x800000)
end sub
