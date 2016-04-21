
typedef struct test_struct_1 {
    unsigned int a : 1;
    unsigned int b : 1;
    unsigned int c : 1;
    unsigned int d : 1;
    unsigned int e : 1;
    unsigned int f : 1;
    unsigned int g : 1;
    unsigned int h : 1;
} test_struct_1;

typedef union ts1u {
    test_struct_1 ts1s;
    unsigned int ts1v;
} ts1u;




