#================  工具链  ==================
CC      := g++
RM      := rd /S /Q
MKDIR   := mkdir

#================  目录与文件  ===============
SRCDIR  := src
INCDIR  := inc
OBJDIR  := obj
TARGET  := main.exe

# 自动扫描源文件
SRCS    := $(wildcard $(SRCDIR)/*.cpp) main.cpp
OBJS    := $(patsubst %.cpp,$(OBJDIR)/%.o,$(notdir $(SRCS)))

#================  标志  =====================
CFLAGS  := -Wall -g
INCS    := -I$(INCDIR)

#================  默认目标  =================
all: $(TARGET)
	@$(MAKE) clean          

#================  链接  =====================
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

#================  编译  =====================
$(OBJDIR)/%.o: $(SRCDIR)/%.cpp | $(OBJDIR)
	$(CC) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/main.o: main.cpp | $(OBJDIR)
	$(CC) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR):
	@if not exist $(OBJDIR) $(MKDIR) $(OBJDIR)

#================  运行  =====================
run: all
	@.\$(TARGET)

#================  清理（含目录）  ===========
clean:
	@if exist $(OBJDIR) $(RM) $(OBJDIR)

.PHONY: all clean run