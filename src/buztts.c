/* ==========================================================
 *  buztts.c v2 — TTS por buzzer, MAS entendible.
 *
 *  Mejoras para inteligibilidad:
 *   · Vocales con "barrido" de formantes (no un tono plano):
 *     el buzzer mono no puede 2 formantes juntos, pero alternar
 *     rapido entre F1 y F2 de cada vocal la hace mas reconocible.
 *   · Consonantes diferenciadas por TIPO (no todas iguales):
 *     - sibilantes (s,z,f) -> ruido agudo mas largo
 *     - oclusivas (p,t,k,b,d,g) -> click seco muy corto
 *     - nasales (m,n) -> zumbido grave
 *     - liquidas (l,r) -> tono medio deslizado
 *   · Duraciones mas parecidas al habla real.
 *   · Subtitulo mas claro, palabra por palabra.
 *
 *  Uso:  buztts [-q] "texto"    (-q = solo subtitulos)
 *  Compilar:  cc -O2 -static -o buztts buztts.c
 * ========================================================== */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/kd.h>

#define CLOCK_TICK 1193180
static int con;
static void tone(int hz){ if(con>=0) ioctl(con, KIOCSOUND, hz>0?CLOCK_TICK/hz:0); }
static void off(int ms){ tone(0); usleep(ms*1000); }

/* Formantes F1 y F2 de cada vocal (Hz). Alternar entre ambos
 * da una "textura" mas vocal que un solo tono. */
static int f1(char c){ switch(tolower((unsigned char)c)){
    case 'a':return 730; case 'e':return 530; case 'i':return 270;
    case 'o':return 570; case 'u':return 300; default:return 0;} }
static int f2(char c){ switch(tolower((unsigned char)c)){
    case 'a':return 1090; case 'e':return 1840; case 'i':return 2290;
    case 'o':return 840;  case 'u':return 870;  default:return 0;} }

/* alternar F1/F2 rapido durante 'ms' para "colorear" la vocal */
static void say_vowel(char c, int ms){
    int a=f1(c), b=f2(c);
    int t=0;
    while(t<ms){
        tone(a); usleep(9000);
        tone(b); usleep(9000);
        t+=18;
    }
}

/* clasificar consonante para darle un sonido distintivo */
static void say_cons(char c){
    char l=tolower((unsigned char)c);
    if(strchr("szfxj",l)){            /* sibilante: ruido agudo tremolante */
        for(int i=0;i<5;i++){ tone(2600+(i%2)*400); usleep(14000); }
        tone(0);
    } else if(strchr("ptkc",l)){      /* oclusiva sorda: click seco */
        tone(1800); usleep(12000); tone(0);
    } else if(strchr("bdgq",l)){      /* oclusiva sonora: click mas grave */
        tone(700); usleep(16000); tone(0);
    } else if(strchr("mn",l)){        /* nasal: zumbido grave sostenido */
        tone(250); usleep(70000); tone(0);
    } else if(strchr("lr",l)){        /* liquida: deslizado medio */
        tone(420); usleep(30000); tone(500); usleep(30000); tone(0);
    } else if(l=='h'){                /* aspirada: soplo (silencio corto) */
        off(35);
    } else {                          /* resto: click neutro */
        tone(1200); usleep(20000); tone(0);
    }
}

static void speak(const char *text, int quiet);  /* fwd */

int main(int argc, char **argv){
    int quiet=0;
    const char *fname=NULL;
    int argi=1;

    /* parsear flags */
    while(argi<argc && argv[argi][0]=='-'){
        if(strcmp(argv[argi],"-q")==0) quiet=1;
        else if(strcmp(argv[argi],"-f")==0 && argi+1<argc){ fname=argv[++argi]; }
        else if(strcmp(argv[argi],"-h")==0){
            printf("buztts — TTS por buzzer con subtitulos\n");
            printf("uso:\n");
            printf("  buztts \"texto\"          hablar el texto\n");
            printf("  echo hola | buztts       leer de stdin\n");
            printf("  buztts -f archivo.txt    leer de un archivo\n");
            printf("  buztts -q \"texto\"       solo subtitulos (sin sonido)\n");
            return 0;
        }
        argi++;
    }

    char text[4096]="";

    if(fname){
        /* leer de archivo */
        FILE *ff=fopen(fname,"r");
        if(!ff){ perror("buztts"); return 1; }
        size_t n=fread(text,1,sizeof(text)-1,ff); text[n]='\0';
        fclose(ff);
    } else if(argi<argc){
        /* leer de argumentos */
        for(int i=argi;i<argc;i++){
            strncat(text,argv[i],sizeof(text)-strlen(text)-2);
            if(i<argc-1) strncat(text," ",2);
        }
    } else if(!isatty(0)){
        /* leer de stdin (pipe) */
        size_t n=fread(text,1,sizeof(text)-1,stdin); text[n]='\0';
        /* quitar newline final */
        size_t l=strlen(text);
        while(l>0 && (text[l-1]=='\n'||text[l-1]=='\r')) text[--l]='\0';
    } else {
        fprintf(stderr,"uso: buztts [-q] [-f archivo] \"texto\"  (o pipe)\n");
        return 1;
    }

    speak(text, quiet);
    return 0;
}

static void speak(const char *text, int quiet){

    if(!quiet){
        con=open("/dev/console",O_WRONLY);
        if(con<0)con=open("/dev/tty0",O_WRONLY);
        if(con<0)con=open("/dev/tty",O_WRONLY);
    } else con=-1;

    printf("\r\n\033[48;5;236m\033[97m  RuTux \033[38;5;196m>\033[97m ");
    fflush(stdout);

    for(size_t i=0; text[i]; i++){
        char c=text[i];
        putchar(c); fflush(stdout);
        if(f1(c)>0){                 /* vocal: mas larga y con formantes */
            say_vowel(c,150);
            off(15);
        } else if(c==' '){           /* espacio: respiro entre palabras */
            off(140);
        } else if(isalpha((unsigned char)c)){
            say_cons(c);
            off(18);
        } else if(isdigit((unsigned char)c)){
            tone(900+(c-'0')*90); usleep(60000); tone(0); off(20);
        } else {                     /* puntuacion: pausa */
            off(90);
        }
    }
    tone(0);
    printf(" \033[0m\r\n");
    if(con>=0) close(con);
}
