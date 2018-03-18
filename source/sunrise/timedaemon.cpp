/*
 * daemonize.c
 * This example daemonizes a process, writes a few log messages,
 * sleeps 20 seconds and terminates afterwards.
 */

#include <fstream>
#include <iostream>
#include <math.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

using namespace std;

double pi = 3.141592653589793238463;
double todeg = 180.0 / pi;
double torad = pi / 180.0;
double mstep = 1.0 / 1440;
double sstep = 1.0 / 86400;

double riseduration = mstep * 90;

struct julian
{
    double jrise;
    double jset;
};

julian calcjtimes(time_t t)
{
    struct tm *current_time = localtime(&t);
    // longitude west of magdeburg
    double low = -11.6322;
    // latitude of magdeburg
    double lam = 52.1243;
    // latitude of madagascar (if it were on northern hemishpere)
    // double lam=22.5;

    // calculate julian day number based on https://de.wikipedia.org/wiki/Julianisches_Datum
    int m = current_time->tm_mon + 1;
    int y = current_time->tm_year + 1900;
    if (m <= 2)
    {
        m += 12;
        y--;
    }
    int d = current_time->tm_mday;
    int a = floor((y) / 100);
    double b = 2 - a + floor(a / 4);
    double jd = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5;

    // calculation of sunrise based on https://en.wikipedia.org/wiki/Sunrise_equation
    // current julian day
    double n = jd - 2451545 + 0.0008;
    // mean solar noon
    double js = low / 360 + n;
    // mean anomaly
    double ma = fmod((357.5291 + 0.98560028 * js), 360);
    // equation of the center
    double c = 1.9148 * sin(ma * torad) + 0.02 * sin(2 * ma * torad) + 0.0003 * sin(3 * ma * torad);
    // ecliptic longitude
    double l = fmod((ma + c + 180 + 102.9372), 360);
    // solar transit - it seems they have forgotten the 2451545.5 on the wikipedia page. or i did not understand correctly.
    double jt = 2451545.5 + js + 0.0053 * sin(ma * torad) - 0.0069 * sin(2 * l * torad);
    // declination of the sun
    double de = asin(sin(l * torad) * sin(23.44 * torad)) * todeg;
    // hour angle
    double w = acos((sin(-0.83 * torad) - sin(lam * torad) * sin(de * torad)) / (cos(lam * torad) * cos(de * torad))) * todeg;

    double jset = jt + w / 360;
    double jrise = jt - w / 360;

    struct julian cjt = {jrise, jset};

    return cjt;
}

static void skeleton_daemon()
{
    pid_t pid;

    /* Fork off the parent process */
    pid = fork();

    /* An error occurred */
    if (pid < 0)
        exit(EXIT_FAILURE);

    /* Success: Let the parent terminate */
    if (pid > 0)
        exit(EXIT_SUCCESS);

    /* On success: The child process becomes session leader */
    if (setsid() < 0)
        exit(EXIT_FAILURE);

    /* Catch, ignore and handle signals */
    //TODO: Implement a working signal handler */
    signal(SIGCHLD, SIG_IGN);
    signal(SIGHUP, SIG_IGN);

    /* Fork off for the second time*/
    pid = fork();

    /* An error occurred */
    if (pid < 0)
        exit(EXIT_FAILURE);

    /* Success: Let the parent terminate */
    if (pid > 0)
        exit(EXIT_SUCCESS);

    /* Set new file permissions */
    umask(0);

    /* Change the working directory to the root directory */
    /* or another appropriated directory */
    chdir("/");

    /* Close all open file descriptors */
    int x;
    for (x = sysconf(_SC_OPEN_MAX); x >= 0; x--)
    {
        close(x);
    }

    /* Open the log file */
    openlog("lightcontroldaemon", LOG_PID, LOG_DAEMON);
}

int main()
{
    //skeleton_daemon();

    time_t t = time(0);
    struct tm *today_time = new tm;
    struct tm *current_time;
    struct julian jt;
    double riseduration_red = riseduration;
    double riseduration_green = riseduration * 0.8;
    double riseduration_blue = riseduration * 0.6;
    double rperc = 1 / riseduration_red;
    double gperc = 1 / riseduration_green;
    double bperc = 1 / riseduration_blue;
    double red, green, blue, new_red, new_green, new_blue;
    bool riseordawn;
    double sunrise, sunset, lightson, lightsoff, dawn, dusk;
    double current_julian_time;

    cout << "starting up" << endl;

    while (1)
    {
        t = time(0);
        current_time = localtime(&t);
        if (current_time->tm_mday != today_time->tm_mday)
        {
            today_time = current_time;
            jt = calcjtimes(t);
            sunrise = (jt.jrise - .5 - floor(jt.jrise - .5)) + mstep * 60;
            sunset = (jt.jset - .5 - floor(jt.jset - .5)) + mstep * 60;
            lightson = sunrise + riseduration / 2;
            lightsoff = sunset - riseduration / 2;
            dawn = sunrise - riseduration / 2; // dawn = the start of the first light
            dusk = sunset + riseduration / 2;  // dusk = the end of the last light
        }

        current_julian_time = (current_time->tm_hour * 3600 + current_time->tm_min * 60 + current_time->tm_sec) * sstep;

        if ((current_julian_time > lightson) && (current_julian_time < lightsoff))
        {
            cout << "Lights should be on" << endl;
            //syslog(LOG_NOTICE,"lights should be on");
        }
        else
        {
            cout << "Lights should be off" << endl;
            //syslog(LOG_NOTICE,"lights should be off");
        }

        if ((current_julian_time >= dawn) && (current_julian_time <= lightson))
        {
            // we are in dawn mode
            cout << "Turn dawn lights on" << endl;
            riseordawn = 1;
            red = (current_julian_time - dawn) * rperc;
            if (current_julian_time >= (dawn + (riseduration_red - riseduration_green)))
            {
                green = (current_julian_time - (dawn + (riseduration_red - riseduration_green))) * gperc;
            }
            if (current_julian_time >= (dawn + (riseduration_red - riseduration_blue)))
            {
                blue = (current_julian_time - (dawn + (riseduration_red - riseduration_blue))) * bperc;
            }
        }
        else if ((current_julian_time <= dusk) && (current_julian_time >= lightsoff))
        {
            // we are in dusk mode
            cout << "Turn dusk lights on" << endl;
            riseordawn = 1;
            red = 1 - ((current_julian_time - (dusk - riseduration_red)) * rperc);
            green = 1 - ((current_julian_time - (dusk - riseduration_red)) * gperc);
            blue = 1 - ((current_julian_time - (dusk - riseduration_red)) * bperc);
        }
        else
        {
            cout << "Turn dawn/dusk lights off" << endl;
            riseordawn = 0;
        }
        if (red > 1)
            red = 1;
        if (red < 0)
            red = 0;
        if (green > 1)
            green = 1;
        if (green < 0)
            green = 0;
        if (blue > 1)
            blue = 1;
        if (blue < 0)
            blue = 0;
        if (riseordawn)
        {
            cout << "Setting r/g/b to " << red << "/" << green << "/" << blue << endl;
        }

        //syslog(LOG_NOTICE, "Light control daemon started.");
        sleep(10);
    }

    //syslog(LOG_NOTICE, "Light control daemon terminated.");
    //closelog();

    return EXIT_SUCCESS;
}
