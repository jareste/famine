#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <elf.h>


/*UTILS*/

char	*ft_strjoin(char const *s1, char const *s2)
{
	char	*str;
	size_t	i;
	size_t	c;

	str = (char *)malloc(sizeof(char) * (strlen(s1) + strlen(s2) + 2));
	if (!str)
		return (0);
	i = 0;
	while (s1[i])
	{
		str[i] = s1[i];
		i++;
	}
    str[i++] = '/';
	c = 0;
	while (s2[c])
	{
		str[i + c] = s2[c];
		c++;
	}
	str[i + c] = '\0';
	return (str);
}

/*END UTILS*/

void check_dir(char *path)
{
    struct dirent *entry;
    DIR *dir = opendir(path);

    if (!dir)
    {
        perror("opendir");
        return ;
    }

    while ((entry = readdir(dir)) != NULL)
    {
        if (entry->d_name == "." || entry->d_name == "..")
            continue ;
        char *path_and_name = ft_strjoin(path, entry->d_name);
        if (!path_and_name)
        {
            perror("malloc");
            closedir(dir);
            return;
        }

        printf("RUTA COMPLETA DEL FILE: |%s|\n", path_and_name);
        free(path_and_name);
    }
    closedir(dir);
}

int main()
{
    check_dir("/tmp/test");
    return 0;
}



/* CONTENIDO STRUCT STAT

struct stat {
    dev_t     st_dev;     ID del dispositivo 
    ino_t     st_ino;     Número de inodo 
    mode_t    st_mode;    Modo (tipo de archivo y permisos) 
    nlink_t   st_nlink;   Número de enlaces duros
    uid_t     st_uid;     ID del propietario 
    gid_t     st_gid;     ID del grupo
    dev_t     st_rdev;    ID del dispositivo (si es un archivo especial) 
    off_t     st_size;    Tamaño total en bytes
    blksize_t st_blksize; Tamaño de bloque para el sistema de archivos 
    blkcnt_t  st_blocks;   Número de bloques asignados 
    time_t    st_atime;   Tiempo de última acceso 
    time_t    st_mtime;   Tiempo de última modificación
    time_t    st_ctime;   Tiempo de última modificación de metadatos 
};

*/


/* CONTENIDO STRUCT DIRENT
struct dirent {
    ino_t          d_ino;       // Número de inodo
    off_t          d_off;       // Desplazamiento al próximo `dirent`
    unsigned short d_reclen;    // Longitud de este `dirent`
    unsigned char  d_type;      // Tipo de archivo (DT_REG, DT_DIR, etc.)
    char           d_name[256]; // Nombre del archivo (null-terminated)
};
*/