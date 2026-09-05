/* ==========================================================
 *  tuneplay-poly.c — "polifonía" en el PC speaker via arpegio
 *  ultrarrápido. Lee POLY.tones (hz1;hz2;hz3,ms) y dentro de
 *  cada segmento rota entre las voces activas cada ~12ms, tan
 *  rápido que el oído lo percibe como acorde. Truco clásico 80s.
 *
 *  Compilar:  cc -O2 -static -o tuneplay-poly tuneplay-poly.c
 * ========================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/kd.h>

#define CLOCK_TICK 1193180
#define ARP_MS 12          /* cada cuánto rota entre voces (ms) */

static int con;

static void set_tone(int hz) {
    if (hz > 0) ioctl(con, KIOCSOUND, CLOCK_TICK / hz);
    else        ioctl(con, KIOCSOUND, 0);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "uso: tuneplay-poly POLY.tones\n"); return 1; }
    FILE *f = fopen(argv[1], "r");
    if (!f) { perror("fopen"); return 1; }

    con = open("/dev/console", O_WRONLY);
    if (con < 0) con = open("/dev/tty0", O_WRONLY);
    if (con < 0) con = open("/dev/tty", O_WRONLY);
    if (con < 0) return 1;

    char line[128];
    while (fgets(line, sizeof(line), f)) {
        if (line[0] == '#' || line[0] == '\n') continue;
        int h1, h2, h3, ms;
        if (sscanf(line, "%d;%d;%d,%d", &h1, &h2, &h3, &ms) == 4) {
            /* voces activas (no cero) */
            int voices[3], nv = 0;
            if (h1 > 0) voices[nv++] = h1;
            if (h2 > 0) voices[nv++] = h2;
            if (h3 > 0) voices[nv++] = h3;

            if (nv == 0) {                    /* silencio */
                set_tone(0);
                usleep(ms * 1000);
            } else if (nv == 1) {             /* una sola nota: directo */
                set_tone(voices[0]);
                usleep(ms * 1000);
            } else {                          /* arpegio entre las voces */
                int elapsed = 0, idx = 0;
                while (elapsed < ms) {
                    set_tone(voices[idx % nv]);
                    int step = (ms - elapsed < ARP_MS) ? (ms - elapsed) : ARP_MS;
                    usleep(step * 1000);
                    elapsed += step;
                    idx++;
                }
            }
        }
    }
    set_tone(0);
    close(con);
    fclose(f);
    return 0;
}
