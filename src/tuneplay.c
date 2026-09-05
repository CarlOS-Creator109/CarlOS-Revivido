/* ==========================================================
 *  tuneplay.c v2 — reproduce tabla de tonos por buzzer, con
 *  control de VOLUMEN simulado via PWM.
 *
 *  El PC speaker no tiene volumen real (onda cuadrada full/off).
 *  Se simula prendiendo/apagando el tono rapidisimo dentro de
 *  cada nota: menor "duty cycle" = menos energia = mas bajito.
 *
 *  Uso:  tuneplay archivo.tones [nivel_volumen 1-4]
 *        4 = full (default)  3 = medio  2 = bajo  1 = susurro
 *
 *  Compilar:  cc -O2 -static -o tuneplay tuneplay.c
 * ========================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/kd.h>

#define CLOCK_TICK 1193180

int main(int argc, char **argv){
    if(argc < 2){ fprintf(stderr,"uso: tuneplay archivo.tones [vol 1-4]\n"); return 1; }
    int vol = (argc >= 3) ? atoi(argv[2]) : 4;
    if(vol < 1) vol = 1; if(vol > 4) vol = 4;

    FILE *f = fopen(argv[1],"r");
    if(!f){ perror("fopen"); return 1; }
    int con = open("/dev/console",O_WRONLY);
    if(con<0) con=open("/dev/tty0",O_WRONLY);
    if(con<0) con=open("/dev/tty",O_WRONLY);
    if(con<0){ fprintf(stderr,"no puedo abrir consola\n"); return 1; }

    /* duty cycle segun volumen: 4=100%, 3=50%, 2=30%, 1=15% */
    int duty[5] = {0, 15, 30, 50, 100};
    int d = duty[vol];

    char line[128];
    while(fgets(line,sizeof(line),f)){
        if(line[0]=='#'||line[0]=='\n') continue;
        int hz, ms;
        if(sscanf(line,"%d,%d",&hz,&ms)==2){
            if(hz <= 0 || d >= 100){
                /* silencio, o volumen full: comportamiento normal */
                if(hz>0) ioctl(con,KIOCSOUND,CLOCK_TICK/hz);
                else     ioctl(con,KIOCSOUND,0);
                usleep(ms*1000);
            } else {
                /* PWM: ciclos de ~10ms, 'd'% encendido */
                int cycle = 10;                 /* ms por ciclo PWM */
                int on = cycle * d / 100;
                int offt = cycle - on;
                int elapsed = 0;
                while(elapsed < ms){
                    ioctl(con,KIOCSOUND,CLOCK_TICK/hz);  /* on */
                    usleep(on*1000);
                    ioctl(con,KIOCSOUND,0);              /* off */
                    usleep(offt*1000);
                    elapsed += cycle;
                }
            }
        }
    }
    ioctl(con,KIOCSOUND,0);
    close(con); fclose(f);
    return 0;
}
