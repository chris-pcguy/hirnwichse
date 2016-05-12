
typedef struct GdtEntry {
    unsigned char accessByte;
    unsigned char flags;
    unsigned char segSize;
    unsigned char segPresent;
    unsigned char segIsCodeSeg;
    unsigned char segIsRW;
    unsigned char segIsConforming;
    unsigned char segIsNormal;
    unsigned char segUse4K;
    unsigned char segDPL;
    unsigned char anotherLimit;
    unsigned int base;
    unsigned int limit;
} GdtEntry;

typedef struct Segment {
    GdtEntry gdtEntry;
    unsigned char isValid;
    unsigned char useGDT;
    unsigned char readChecked;
    unsigned char writeChecked;
    unsigned char segIsGDTandNormal;
    unsigned short segmentIndex;
    unsigned short segId;
} Segment;

typedef struct IdtEntry {
    unsigned char entryType;
    unsigned char entrySize;
    unsigned char entryNeededDPL;
    unsigned char entryPresent;
    unsigned short entrySegment;
    unsigned int entryEip;
} IdtEntry;


