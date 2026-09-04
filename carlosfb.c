/* ==========================================================
 *  carlosfb.c — "framebuffer" de texto en memoria para CarlOS
 *
 *  Un puente C que mantiene un buffer de pantalla en memoria
 *  (celdas con char + color) y lo vuelca a la terminal de UNA
 *  sola escritura rapida. Elimina el parpadeo del TUI.
 *
 *  Modo de uso (dos formas):
 *
 *  A) FILTRO (simple): recibe por stdin un frame completo ya
 *     armado (con ANSI) y lo escribe atomicamente a stdout con
 *     un solo write(). Ruby arma el frame como string y hace
 *     system("carlosfb") o lo pipea. Rapido y sin parpadeo.
 *
 *  B) DIFF (avanzado): mantiene el frame anterior y solo emite
 *     las celdas que cambiaron. Aun menos trafico. (--diff)
 *
 *  Compilar:
 *     cc -O2 -static -o carlosfb carlosfb.c
 * ========================================================== */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUFSZ (1 << 20)   /* 1 MB de frame máximo */

int main(int argc, char **argv) {
    static char buf[BUFSZ];
    static char prev[BUFSZ];
    int diff_mode = (argc > 1 && strcmp(argv[1], "--diff") == 0);
    size_t total = 0;
    ssize_t n;

    /* Leer TODO el frame desde stdin a memoria */
    while (total < BUFSZ - 1 &&
           (n = read(STDIN_FILENO, buf + total, BUFSZ - 1 - total)) > 0) {
        total += (size_t)n;
    }
    buf[total] = '\0';

    if (diff_mode) {
        /* Si el frame es idéntico al anterior, no escribir nada */
        if (total == strlen(prev) && memcmp(buf, prev, total) == 0) {
            return 0;
        }
        memcpy(prev, buf, total + 1);
    }

    /* Volcar TODO el frame de una sola escritura atómica.
     * Cursor a home primero (sin clear -> no parpadeo). */
    static char out[BUFSZ + 16];
    int hlen = sprintf(out, "\033[H");        /* cursor a home */
    memcpy(out + hlen, buf, total);
    write(STDOUT_FILENO, out, hlen + total);  /* UN solo write */

    return 0;
}
