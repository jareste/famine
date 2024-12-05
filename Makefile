NAME = famine

#########
RM = rm -rf
CC = nasm
CFLAGS = -f elf64 -g -F dwarf
RELEASE_CFLAGS = -f elf64 -Ox
LDFLAGS = #--gc-sections -s
#########

#########
FILES = famine

SRC = $(addsuffix .s, $(FILES))

vpath %.s srcs
#########

#########
OBJ_DIR = objs
OBJ = $(addprefix $(OBJ_DIR)/, $(SRC:.s=.o))
DEP = $(addsuffix .d, $(basename $(OBJ)))
#########

#########
$(OBJ_DIR)/%.o: %.s
	@mkdir -p $(@D)
	${CC}  $(CFLAGS) $< -o $@

all: .gitignore
	$(MAKE) $(NAME)
	sh create_test.sh

$(NAME): $(OBJ) Makefile
	ld $(LDFLAGS) $(OBJ) -o $(NAME)
	@echo "EVERYTHING DONE  "

release: CFLAGS = $(RELEASE_CFLAGS)
release: re
	strip --strip-all $(NAME)
	-@upx --best --ultra-brute $(NAME) || echo "UPX compression failed or UPX not installed, continuing without compression."
	@echo "RELEASE BUILD DONE  "

debug: CFLAGS = -f elf64 -g -F dwarf
debug: LDFLAGS =
debug: fclean
	$(MAKE) $(NAME)
	@echo "DEBUG BUILD DONE  "

clean:
	$(RM) $(OBJ) $(DEP)
	$(RM) -r $(OBJ_DIR)
	@echo "OBJECTS REMOVED   "

fclean: clean
	$(RM) $(NAME)
	@echo "EVERYTHING REMOVED   "

re: fclean
	$(MAKE) all CFLAGS="$(CFLAGS)"

.gitignore:
	@if [ ! -f .gitignore ]; then \
		echo ".gitignore not found, creating it..."; \
		echo ".gitignore" >> .gitignore; \
		echo "$(NAME)" >> .gitignore; \
		echo "$(OBJ_DIR)/" >> .gitignore; \
		echo ".gitignore created and updated with entries."; \
	else \
		echo ".gitignore already exists."; \
	fi

.PHONY: all clean fclean re release debug .gitignore

-include $(DEP)
