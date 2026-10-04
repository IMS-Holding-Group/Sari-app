#include <WiFi.h>
#include <HTTPClient.h>
#include "secrets.h"

// Relay must be wired normally-open so a dead board leaves the circuit off.
const int RELAY_PIN = 26;
const int CURRENT_PIN = 34;
const int VOLTAGE_PIN = 35;
const int LEAK_PIN = 32;
const int TEMP_PIN = 33;

// Calibrate these four for the actual sensors on the board.
const float CURRENT_A_PER_COUNT = 0.0161f;
const float VOLTAGE_V_PER_COUNT = 0.0625f;
const float LEAK_A_PER_COUNT = 0.00005f;
const float TEMP_C_PER_COUNT = 0.0806f;

const float LOCAL_SHORT_A = 200.0f;
const float LOCAL_LEAK_A = 0.3f;
const unsigned long OFFLINE_LIMIT_MS = 15000;

bool cutoff = false;
unsigned long lastOk = 0;

float rms(int pin, float scale) {
  const int samples = 400;
  long sum = 0;
  long sq = 0;
  int raw[samples];
  for (int k = 0; k < samples; k++) {
    raw[k] = analogRead(pin);
    sum += raw[k];
    delayMicroseconds(100);
  }
  float mid = (float)sum / samples;
  for (int k = 0; k < samples; k++) {
    float d = raw[k] - mid;
    sq += (long)(d * d);
  }
  return sqrt((float)sq / samples) * scale;
}

void cut() {
  cutoff = true;
  digitalWrite(RELAY_PIN, LOW);
}

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  lastOk = millis();
}

void loop() {
  unsigned long started = millis();
  float current = rms(CURRENT_PIN, CURRENT_A_PER_COUNT);
  float voltage = rms(VOLTAGE_PIN, VOLTAGE_V_PER_COUNT);
  float leakage = rms(LEAK_PIN, LEAK_A_PER_COUNT);
  float temperature = analogRead(TEMP_PIN) * TEMP_C_PER_COUNT;

  if (current >= LOCAL_SHORT_A || leakage >= LOCAL_LEAK_A) cut();

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String base = String(MODEL_URL) + "/v1/";
    if (!cutoff) {
      http.begin(base + "reading");
      http.addHeader("Content-Type", "application/json");
      http.addHeader("X-Model-Token", MODEL_TOKEN);
      String body = String("{\"device_id\":\"") + DEVICE_ID + "\",\"current\":" + String(current, 3) +
                    ",\"voltage\":" + String(voltage, 2) + ",\"leakage\":" + String(leakage, 4) +
                    ",\"temperature\":" + String(temperature, 2) + "}";
      int code = http.POST(body);
      if (code == 200) {
        lastOk = millis();
        if (http.getString().indexOf("\"cutoff\":true") >= 0) cut();
      }
      http.end();
    } else {
      http.begin(base + "devices/" + DEVICE_ID + "/command");
      http.addHeader("X-Model-Token", MODEL_TOKEN);
      if (http.GET() == 200) {
        lastOk = millis();
        if (http.getString().indexOf("\"cutoff\":false") >= 0) {
          cutoff = false;
          digitalWrite(RELAY_PIN, HIGH);
        }
      }
      http.end();
    }
  }

  if (!cutoff && millis() - lastOk > OFFLINE_LIMIT_MS) Serial.println("model offline: local limits only");

  long wait = 1000 - (long)(millis() - started);
  if (wait > 0) delay(wait);
}
