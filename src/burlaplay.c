/* ==========================================================
 *  burlaplay.c — motor de burla ESCALABLE para el buzzer.
 *
 *  Recibe un "nivel de burla" (0-10) y toca la melodia
 *  distorsionandola cada vez mas: mas velocidad, mas
 *  alternancia caotica entre voces, mas desafinacion.
 *  Todo en C para que las alternancias rapidas sean fluidas.
 *
 *  Uso:  burlaplay POLY.tones <nivel>
 *        nivel 0 = normal   nivel 10 = risa histerica
 *
 *  O modo dinamico: lee el nivel de un archivo que el juego
 *  actualiza en vivo:
 *        burlaplay POLY.tones --file /tmp/burla.level
 *
 *  Compilar:  cc -O2 -static -o burlaplay burlaplay.c
 * ========================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/kd.h>

#define CLOCK_TICK 1193180

static int con;
static void tone(int hz){ ioctl(con, KIOCSOUND, hz>0 ? CLOCK_TICK/hz : 0); }

/* lee el nivel de burla desde archivo (modo dinamico) */
static int read_level(const char *path){
    FILE *f = fopen(path, "r");
    if(!f) return 0;
    int lvl = 0;
    if (fscanf(f, "%d", &lvl) != 1) lvl = 0;
    fclose(f);
    if(lvl<0) lvl=0; if(lvl>10) lvl=10;
    return lvl;
}

/* estructura: cada linea POLY = hasta 3 voces + duracion */
typedef struct { int v[3]; int nv; int ms; } Chord;

int main(int argc, char **argv){
    if(argc < 2){ fprintf(stderr,"uso: burlaplay POLY.tones [nivel|--file ruta]\n"); return 1; }

    int fixed_level = 0;
    const char *level_file = NULL;
    if(argc >= 3){
        if(strcmp(argv[2],"--file")==0 && argc>=4) level_file = argv[3];
        else fixed_level = atoi(argv[2]);
    }

    /* cargar toda la tabla POLY a memoria */
    FILE *f = fopen(argv[1],"r");
    if(!f){ perror("fopen"); return 1; }
    Chord *song = malloc(sizeof(Chord)*8192);
    int n=0;
    char line[128];
    while(fgets(line,sizeof(line),f) && n<8192){
        if(line[0]=='#'||line[0]=='\n') continue;
        int h1,h2,h3,ms;
        if(sscanf(line,"%d;%d;%d,%d",&h1,&h2,&h3,&ms)==4){
            Chord c={{0,0,0},0,ms};
            if(h1>0)c.v[c.nv++]=h1;
            if(h2>0)c.v[c.nv++]=h2;
            if(h3>0)c.v[c.nv++]=h3;
            song[n++]=c;
        }
    }
    fclose(f);

    con = open("/dev/console",O_WRONLY);
    if(con<0) con=open("/dev/tty0",O_WRONLY);
    if(con<0) con=open("/dev/tty",O_WRONLY);
    if(con<0){ free(song); return 1; }

    /* loop infinito de la cancion */
    int pos=0;
    unsigned seed=12345;
    while(1){
        int level = level_file ? read_level(level_file) : fixed_level;

        Chord c = song[pos];
        pos = (pos+1) % n;

        /* --- MODULACION segun el nivel de burla --- */
        /* velocidad: a mas nivel, mas rapido (menos ms) */
        int ms = c.ms * (100 - level*7) / 100;   /* nivel 10 -> 30% del tiempo */
        if(ms < 12) ms = 12;

        if(c.nv==0){ tone(0); usleep(ms*1000); continue; }

        /* arpegio: a mas nivel, mas rapido el salto entre voces */
        int arp = 14 - level;         /* nivel 10 -> salto cada 4ms (caotico) */
        if(arp < 3) arp = 3;

        /* desafinacion: a mas nivel, mas "bend" aleatorio */
        int elapsed=0, idx=0;
        while(elapsed < ms){
            int hz = c.v[idx % c.nv];
            /* burla: desafinar aleatoriamente segun nivel */
            if(level > 3){
                seed = seed*1103515245 + 12345;
                int wob = ((seed>>16) % (level*2)) - level;  /* +-nivel% */
                hz = hz * (100 + wob) / 100;
            }
            tone(hz);
            int step = (ms-elapsed < arp) ? (ms-elapsed) : arp;
            usleep(step*1000);
            elapsed += step; idx++;
        }
    }
    tone(0); close(con); free(song);
    return 0;
}
