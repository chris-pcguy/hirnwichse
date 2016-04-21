
typedef struct eflagsStruct {
    unsigned int cf : 1;
    unsigned int reserved_1 : 1;
    unsigned int pf : 1;
    unsigned int reserved_3 : 1;
    unsigned int af : 1;
    unsigned int reserved_5 : 1;
    unsigned int zf : 1;
    unsigned int sf : 1;
    unsigned int tf : 1;
    unsigned int if_flag : 1;
    unsigned int df : 1;
    unsigned int of : 1;
    unsigned int iopl : 2;
    unsigned int nt : 1;
    unsigned int reserved_15 : 1;
    unsigned int rf : 1;
    unsigned int vm : 1;
    unsigned int ac : 1;
    unsigned int vif : 1;
    unsigned int vip : 1;
    unsigned int id : 1;
    unsigned int reserved_22 : 1;
    unsigned int reserved_23 : 1;
    unsigned int reserved_24 : 1;
    unsigned int reserved_25 : 1;
    unsigned int reserved_26 : 1;
    unsigned int reserved_27 : 1;
    unsigned int reserved_28 : 1;
    unsigned int reserved_29 : 1;
    unsigned int reserved_30 : 1;
    unsigned int reserved_31 : 1;
} eflagsStruct;

