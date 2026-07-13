#================  工具链  ==================
CC      := gcc
RM      := rm -rf
MKDIR   := mkdir -p

#================  目录与文件  ===============
SRCDIR  := src
INCDIR  := inc
OBJDIR  := obj

# Standalone executable target
EXE_TARGET := main.exe
# DPI-C shared library target (for QuestaSim)
DLL_TARGET := dpi_wrapper.dll

# 源文件
EXE_SRCS := $(wildcard $(SRCDIR)/*.c) main.c
DLL_SRCS := $(SRCDIR)/dpi_wrapper.c

EXE_OBJS := $(patsubst %.c,$(OBJDIR)/%.o,$(notdir $(EXE_SRCS)))
DLL_OBJS := $(patsubst %.c,$(OBJDIR)/%.o,$(notdir $(DLL_SRCS)))

#================  标志  =====================
CFLAGS  := -Wall -g
INCS    := -I$(INCDIR)

#================  默认目标  =================
all: $(DLL_TARGET) $(EXE_TARGET)
	@echo Build complete: $(DLL_TARGET) and $(EXE_TARGET)

#================  DLL (DPI-C for QuestaSim)  =================
$(DLL_TARGET): $(DLL_OBJS)
	$(CC) -shared $(CFLAGS) $^ -o $@
	@echo DPI-C DLL built: $@

#================  EXE (standalone test)  =================
$(EXE_TARGET): $(EXE_OBJS)
	$(CC) $(CFLAGS) $^ -o $@

#================  编译规则  =================
$(OBJDIR)/dpi_wrapper.o: $(SRCDIR)/dpi_wrapper.c | $(OBJDIR)
	$(CC) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/main.o: main.c | $(OBJDIR)
	$(CC) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR):
	@$(MKDIR) $(OBJDIR)

#================  运行（独立exe）  =========
run: $(EXE_TARGET)
	@.\$(EXE_TARGET)

#================  清理  ====================
clean:
	@$(RM) $(OBJDIR) $(DLL_TARGET) $(EXE_TARGET) 2>/dev/null || true

.PHONY: all run clean
