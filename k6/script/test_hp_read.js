// test_hp_read.js
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.4/index.js";
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
import { parseNumberEnv, getDeviceForVU } from "./utils.js";
import { getTelemetryLatest } from "./target_url.js";

// ==============================
// Environment
// ==============================
const BASE_URL = __ENV.BASE_URL || "http://localhost:8000";

// Tag to distinguish solution variants
const SOLUTION_ID = __ENV.SOLUTION_ID || "Sol-Baseline";
const PROFILE = "read-heavy";

// High-performance read test parameters
const RATE_START = parseNumberEnv("RATE_START", 50);     // initial RPS
const RATE_TARGET = parseNumberEnv("RATE_TARGET", 1000); // peak RPS
const STAGE_RAMP = parseNumberEnv("STAGE_RAMP", 5);      // minutes per ramp stage
const STAGE_PEAK = parseNumberEnv("STAGE_PEAK", 5);      // minutes to hold peak

// VU pool
const VU = parseNumberEnv("VU", 50);      // pre-allocated VUs
const MAX_VU = parseNumberEnv("MAX_VU", 200); // max VUs

// ==============================
// k6 options
// ==============================
export const options = {
  cloud: {
    name: `HP Read – ${SOLUTION_ID}`,
  },
  // Global tags for all metrics
  tags: {
    solution: SOLUTION_ID,
    profile: PROFILE,
  },

  thresholds: {
    // Overall failure rate
    "http_req_failed{scenario:hp_read_telemetry}": [
      "rate<0.05", // less than 5% failures allowed under HP load
    ],

    // GET /telemetry/latest
    "http_req_duration{scenario:hp_read_telemetry,endpoint:telemetry_get_latest}": [
      "p(50)<150", // median
      "p(95)<400", // p95 under 400ms at high load
      "p(99)<800", // p99 under 800ms
    ],
  },

  scenarios: {
    hp_read_telemetry: {
      executor: "ramping-arrival-rate",
      startRate: RATE_START, // initial RPS
      timeUnit: "1s",        // RPS-based

      preAllocatedVUs: VU,   // initial VU pool
      maxVUs: MAX_VU,        // safety upper bound

      // Smooth ramp up to RATE_TARGET and then hold
      stages: [
        { duration: `${STAGE_RAMP}m`, target: RATE_START },                          // warm-up
        { duration: `${STAGE_RAMP}m`, target: Math.round(RATE_TARGET * 0.25) },
        { duration: `${STAGE_RAMP}m`, target: Math.round(RATE_TARGET * 0.5) },
        { duration: `${STAGE_RAMP}m`, target: Math.round(RATE_TARGET * 0.75) },
        { duration: `${STAGE_RAMP}m`, target: RATE_TARGET },                         // reach peak
        { duration: `${STAGE_PEAK}m`, target: RATE_TARGET },                         // hold peak
      ],

      gracefulStop: "60s",
      exec: "hp_read_telemetry",
    },
  },
};

// ==============================
// Scenario function
// ==============================
export function hp_read_telemetry() {
  const device = getDeviceForVU();
  getTelemetryLatest({ base_url: BASE_URL, device });
}

export default hp_read_telemetry;

// ==============================
// Summary output
// ==============================
export function handleSummary(data) {
  return {
    "hp_read_test.json": JSON.stringify(data, null, 2),
    "hp_read_test.html": htmlReport(data),
    stdout: textSummary(data, { indent: " ", enableColors: true }),
  };
}
