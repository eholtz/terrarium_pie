#include <fstream>
#include <iostream>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <ctime>
#include <unistd.h>
#include <csignal>
#include <cstring>

using namespace std;

const double PI = 3.141592653589793238463;
const double TODEG = 180.0 / PI;
const double TORAD = PI / 180.0;
const double HSTEP = 1.0 / 24;
const double MSTEP = 1.0 / 1440;
const double SSTEP = 1.0 / 86400;
const double RISEDURATION = SSTEP * 5400;

// Global flag for graceful shutdown
volatile sig_atomic_t shutdown_flag = 0;

struct Location {
    string name;
    double latitude;
    double longitude;
    double timezone; // Stunden von UTC
    double elevation; // Meter über Meeresspiegel
};

const Location LOCATIONS[] = {
    {"Velpke", 52.40667, 10.94147, 1.0, 80.0},  // Elevation ~55m
    {"MadagascarEquivalent", 23.3500, 10.94147, 1.0, 80.0} // Elevation ~50m
};

struct SunTimes {
    double sunrise;
    double sunset;
    double dawn;
    double dusk;
};

// Signal handler for graceful shutdown
void signal_handler(int signal) {
    shutdown_flag = 1;
}

string j2h(double jd) {
    int hr, mn;
    char buffer[10];
    hr = static_cast<int>(jd * 24);
    mn = static_cast<int>(((jd * 24) - static_cast<double>(hr)) * 60);
    snprintf(buffer, sizeof(buffer), "%02d:%02d", hr, mn);
    return buffer;
}

bool write_to_file(const string& filename, const string& content) {
    ofstream filehandler(filename.c_str());
    if (!filehandler.is_open()) {
        cerr << "ERROR: could not write to " << filename << endl;
        return false;
    }
    filehandler << content;
    filehandler.close();
    return true;
}

void setlights(double dayhour, double dawn, double rise, double set, double dusk) {
    bool lights = false;
    bool riseordawn = false;
    
    const double riseduration_red = RISEDURATION;
    const double riseduration_green = RISEDURATION * 0.8;
    const double riseduration_blue = RISEDURATION * 0.6;
    
    const double rperc = 1 / riseduration_red;
    const double gperc = 1 / riseduration_green;
    const double bperc = 1 / riseduration_blue;
    
    double red = 0.0, green = 0.0, blue = 0.0;

    // Determine if main lights should be on or off
    lights = (dayhour >= rise) && (dayhour <= set);

    // Handle sunrise/sunset transitions
    if ((dayhour >= dawn) && (dayhour <= (rise + MSTEP))) {
        // Sunrise
        riseordawn = true;
        red = (dayhour - dawn) * rperc;
        
        if (dayhour >= (dawn + (riseduration_red - riseduration_green))) {
            green = (dayhour - (dawn + (riseduration_red - riseduration_green))) * gperc;
        }
        if (dayhour >= (dawn + (riseduration_red - riseduration_blue))) {
            blue = (dayhour - (dawn + (riseduration_red - riseduration_blue))) * bperc;
        }
    } else if ((dayhour >= (set - MSTEP)) && (dayhour <= dusk)) {
        // Sunset
        riseordawn = true;
        red = 1 - ((dayhour - (dusk - riseduration_red)) * rperc);
        green = 1 - ((dayhour - (dusk - riseduration_red)) * gperc);
        blue = 1 - ((dayhour - (dusk - riseduration_red)) * bperc);
    }

    // Clamp values to [0, 1]
    red = max(0.0, min(1.0, red));
    green = max(0.0, min(1.0, green));
    blue = max(0.0, min(1.0, blue));

    // Write values to system
    // links
    write_to_file("/dev/shm/pin_8", to_string(static_cast<int>(lights)));
    // mitte
    write_to_file("/dev/shm/pin_0", to_string(static_cast<int>(lights)));
    // rechts
    write_to_file("/dev/shm/pin_2", to_string(static_cast<int>(lights)));

    // Write to pi-blaster if needed
    if ((red > 0) && (red < 1)) {
        ofstream filehandler("/dev/pi-blaster");
        if (filehandler.is_open()) {
            filehandler << "14=" << red << endl;
            filehandler << "15=" << green << endl;
            filehandler << "18=" << blue << endl;
        } else {
            cerr << "ERROR: could not write to /dev/pi-blaster" << endl;
        }
    }
}

// NREL SPA Algorithmus - vereinfachte Version für Sonnenauf-/untergang
double calculate_solar_declination(double jd) {
    // Tageszahl seit J2000.0
    double n = jd - 2451545.0;
    
    // Mittlere ekliptikale Länge (Grad)
    double L = fmod(280.460 + 0.9856474 * n, 360.0);
    if (L < 0) L += 360.0;
    
    // Mittlere Anomalie (Grad)
    double g = fmod(357.528 + 0.9856003 * n, 360.0) * TORAD;
    if (g < 0) g += 2 * PI;
    
    // Ekliptikale Länge (Grad)
    double lambda = L + 1.915 * sin(g) + 0.020 * sin(2 * g);
    
    // Schiefe der Ekliptik (Grad)
    double epsilon = 23.439 - 0.0000004 * n;
    
    // Deklination (Grad)
    double delta = asin(sin(epsilon * TORAD) * sin(lambda * TORAD)) * TODEG;
    
    return delta;
}

double calculate_equation_of_time(double jd) {
    // Tageszahl seit J2000.0
    double n = jd - 2451545.0;
    
    // Mittlere ekliptikale Länge (Grad)
    double L = fmod(280.460 + 0.9856474 * n, 360.0);
    if (L < 0) L += 360.0;
    
    // Mittlere Anomalie (Grad)
    double g = fmod(357.528 + 0.9856003 * n, 360.0) * TORAD;
    if (g < 0) g += 2 * PI;
    
    // Ekliptikale Länge (Grad)
    double lambda = L + 1.915 * sin(g) + 0.020 * sin(2 * g);
    
    // Rektaszension (Grad)
    double epsilon = 23.439 - 0.0000004 * n;
    double alpha = atan2(cos(epsilon * TORAD) * sin(lambda * TORAD), 
                        cos(lambda * TORAD)) * TODEG;
    if (alpha < 0) alpha += 360.0;
    
    // Zeitgleichung (Minuten)
    double eot = 4.0 * (L - alpha); // Minuten
    
    return eot;
}

// Berechnung des Sonnenauf- und untergangs nach NREL SPA
SunTimes calculate_sun_times_nrel(time_t t, const Location& loc) {
    struct tm* utc_time = gmtime(&t);
    if (!utc_time) {
        cerr << "ERROR: Could not convert time" << endl;
        return {0, 0, 0, 0};
    }

    int year = utc_time->tm_year + 1900;
    int month = utc_time->tm_mon + 1;
    int day = utc_time->tm_mday;
    
    // Julianisches Datum für Mittag
    int a = (14 - month) / 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;
    
    double jd = day + (153 * m + 2) / 5.0 + 365.0 * y + y / 4.0 - y / 100.0 + y / 400.0 - 32045.5;
    
    // Sonnendeklination für diesen Tag
    double delta = calculate_solar_declination(jd) * TORAD;
    
    // Zeitgleichung (in Stunden umrechnen)
    double eot_hours = calculate_equation_of_time(jd) / 60.0;
    
    double lat_rad = loc.latitude * TORAD;
    
    // Sonnenwinkel für verschiedene Ereignisse (in Grad)
    double sunrise_angle = -0.833;  // Sonnenaufgang (mit Refraktion)
    double civil_twilight = -6.0;   // Zivile Dämmerung
    
    // Berechnung des Stundenwinkels für jedes Ereignis
    auto calculate_hour_angle = [&](double sun_angle_deg) -> double {
        double sun_angle_rad = sun_angle_deg * TORAD;
        double cos_ha = (sin(sun_angle_rad) - sin(lat_rad) * sin(delta)) / 
                       (cos(lat_rad) * cos(delta));
        
        // Überprüfung auf Polartag/Polarnacht
        if (cos_ha <= -1.0) return PI;      // Polarnacht
        if (cos_ha >= 1.0) return 0.0;      // Polartag
        
        return acos(cos_ha);
    };
    
    // Stundenwinkel berechnen
    double ha_sunrise = calculate_hour_angle(sunrise_angle);
    double ha_civil = calculate_hour_angle(civil_twilight);
    
    // Umrechnung in Stunden
    double ha_sunrise_hours = ha_sunrise * TODEG / 15.0;
    double ha_civil_hours = ha_civil * TODEG / 15.0;
    
    // Lokale Sonnenzeit für Ereignisse
    double solar_noon = 12.0 - (loc.longitude / 15.0) - eot_hours;
    
    // UTC-Zeiten für Ereignisse
    double sunrise_utc = solar_noon - ha_sunrise_hours;
    double sunset_utc = solar_noon + ha_sunrise_hours;
    double dawn_utc = solar_noon - ha_civil_hours;
    double dusk_utc = solar_noon + ha_civil_hours;
    
    // Auf lokale Zeit umrechnen und normalisieren
    auto normalize_time = [](double time) -> double {
        while (time < 0) time += 24.0;
        while (time >= 24.0) time -= 24.0;
        return time / 24.0;
    };
    
    double sunrise_local = normalize_time(sunrise_utc + loc.timezone);
    double sunset_local = normalize_time(sunset_utc + loc.timezone);
    double dawn_local = normalize_time(dawn_utc + loc.timezone);
    double dusk_local = normalize_time(dusk_utc + loc.timezone);
    
    return {sunrise_local, sunset_local, dawn_local, dusk_local};
}

Location get_location_from_env() {
    const char* env_location = getenv("TERRARIUM_LOCATION");
    
    if (env_location != nullptr) {
        string location_str(env_location);
        if (location_str == "MadagascarEquivalent" || location_str == "MadagascarEquivalent" || location_str == "2") {
            cout << "Using MadagascarEquivalent location from environment variable" << endl;
            return LOCATIONS[1];
        }
    }
    
    // Default to Velpke
    cout << "Using default location: Velpke" << endl;
    cout << "Set TERRARIUM_LOCATION environment variable to 'MadagascarEquivalent' to change location" << endl;
    return LOCATIONS[0];
}

void cleanup() {
    cout << "Performing cleanup..." << endl;
    // Turn off all lights on shutdown
    write_to_file("/dev/shm/pin_8", "0");
    write_to_file("/dev/shm/pin_0", "0");
    write_to_file("/dev/shm/pin_2", "0");
    
    // Turn off pi-blaster outputs
    ofstream filehandler("/dev/pi-blaster");
    if (filehandler.is_open()) {
        filehandler << "14=0" << endl;
        filehandler << "15=0" << endl;
        filehandler << "18=0" << endl;
    }
    
    cout << "Cleanup completed. Goodbye!" << endl;
}

int main() {
    cout << "Starting Terrarium Light Daemon ..." << endl;
    
    // Setup signal handlers for graceful shutdown
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = signal_handler;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    
    // Get location from environment variable
    Location current_location = get_location_from_env();
    cout << "Location: " << current_location.name << endl;
    cout << "Latitude: " << current_location.latitude << ", Longitude: " << current_location.longitude;
    cout << ", Timezone: UTC" << (current_location.timezone >= 0 ? "+" : "") << current_location.timezone;
    cout << ", Elevation: " << current_location.elevation << "m" << endl;

    time_t now = time(0);
    if (now == -1) {
        cerr << "ERROR: Could not get current time" << endl;
        return 1;
    }

    struct tm* nowt = localtime(&now);
    if (!nowt) {
        cerr << "ERROR: Could not convert local time" << endl;
        return 1;
    }

    int nowd = nowt->tm_yday;
    int curd = nowd + 1; // Force calculation on first run

    SunTimes sun_times;
    double lightson, lightsoff;

    // Set output precision
    cout.setf(ios_base::fixed, ios_base::floatfield);
    cout.precision(6);

    // Main loop
    while (!shutdown_flag) {
        now = time(0);
        nowt = localtime(&now);
        if (!nowt) {
            cerr << "ERROR: Could not convert local time in main loop" << endl;
            usleep(5000000);
            continue;
        }

        nowd = nowt->tm_yday;
        if (nowd != curd) {
            cout << "New day detected for " << current_location.name << endl;
            curd = nowd;
            
            sun_times = calculate_sun_times_nrel(now, current_location);

            // Calculate light times
            lightson = sun_times.sunrise + RISEDURATION / 2;
            lightsoff = sun_times.sunset - RISEDURATION / 2;

            // Log times
            cout << "=== Daily Sun Times ===" << endl;
            cout << "Civil dawn:    " << j2h(sun_times.dawn) << endl;
            cout << "Sunrise:       " << j2h(sun_times.sunrise) << endl;
            cout << "Lights on:     " << j2h(lightson) << endl;
            cout << "Lights off:    " << j2h(lightsoff) << endl;
            cout << "Sunset:        " << j2h(sun_times.sunset) << endl;
            cout << "Civil dusk:    " << j2h(sun_times.dusk) << endl;
            cout << "=======================" << endl;

            // Write times to file
            ofstream filehandler("/dev/shm/terrarium_times");
            if (filehandler.is_open()) {
                filehandler << "civil_dawn " << sun_times.dawn << " " << j2h(sun_times.dawn) << endl;
                filehandler << "sunrise " << sun_times.sunrise << " " << j2h(sun_times.sunrise) << endl;
                filehandler << "lights_on " << lightson << " " << j2h(lightson) << endl;
                filehandler << "lights_off " << lightsoff << " " << j2h(lightsoff) << endl;
                filehandler << "sunset " << sun_times.sunset << " " << j2h(sun_times.sunset) << endl;
                filehandler << "civil_dusk " << sun_times.dusk << " " << j2h(sun_times.dusk) << endl;
            } else {
                cerr << "ERROR: Could not write to /dev/shm/terrarium_times" << endl;
            }
        }

        // Set lights based on current time
        double dayhour = nowt->tm_hour * HSTEP + nowt->tm_min * MSTEP + nowt->tm_sec * SSTEP;
        setlights(dayhour, sun_times.dawn, lightson, lightsoff, sun_times.dusk);
        
        // Sleep with interruption check
        for (int i = 0; i < 50 && !shutdown_flag; i++) {
            usleep(100000); // 100ms
        }
    }

    // Graceful shutdown
    cleanup();
    return 0;
}