CC = mpicc
CFLAGS = -O3 -Wall
INCLUDES = -I/hdd/hdd1/kejeong/sprng2.0/include
LDFLAGS = -L/hdd/hdd1/kejeong/sprng2.0/lib
LIBS = -lsprng -lm

TARGET = 1D_CaseA
SRCS = 1D_CaseA.c

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(INCLUDES) $(SRCS) -o $(TARGET) $(LDFLAGS) $(LIBS)

clean:
	rm -f $(TARGET)
