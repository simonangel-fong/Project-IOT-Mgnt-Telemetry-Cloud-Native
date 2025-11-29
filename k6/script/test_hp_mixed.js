// test_hp_mixed.js
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.4/index.js";
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
import { parseNumberEnv, getDeviceForVU } from "./utils.js";
import { getTelemetryLatest, postTelemetry } from "./target_url.js";

// ==============================
// Environment
// ==============================
const BASE_URL = __ENV.BASE_URL || "http://localhost:8000";

// Tag to distinguish solution variants
const SOLUTION_ID = __ENV.SOLUTION_ID || "Sol-Baseline";
const PROFILE = "mixed"; // Mixed profile

// -------- Write (POST) parameters --------
const W_RATE_START = parseNumberEnv("W_RATE_START", 50); // initial write RPS
const W_RATE_TARGET = parseNumberEnv("W_RATE_TARGET", 500); // peak write RPS
const W_STAGE_RAMP = parseNumberEnv("W_STAGE_RAMP", 5); // minutes per write ramp stage
const W_STAGE_PEAK = parseNumberEnv("W_STAGE_PEAK", 10); // minutes to hold peak write RPS

const W_VU = parseNumberEnv("W_VU", 50); // pre-allocated VUs for write
const W_MAX_VU = parseNumberEnv("W_MAX_VU", 800); // max VUs for write scenario

// -------- Background Read (GET) parameters --------
const R_RATE_START = parseNumberEnv("R_RATE_START", 50);
const R_RATE_TARGET = parseNumberEnv("R_RATE_TARGET", 150); // background read RPS
const R_STAGE_RAMP = parseNumberEnv("R_STAGE_RAMP", 5); // minutes per read ramp stage
const R_STAGE_PEAK = parseNumberEnv("R_STAGE_PEAK", 10); // minutes to hold peak read RPS

const R_VU = parseNumberEnv("R_VU", 50); // pre-allocated VUs for read
const R_MAX_VU = parseNumberEnv("R_MAX_VU", 400); // max VUs for read scenario

// ==============================
// k6 options
// ==============================
export const options = {
  cloud: {
    name: `HP Mixed – ${SOLUTION_ID}`,
  },

  // Global tags applied to all metrics
  tags: {
    solution: SOLUTION_ID,
    profile: PROFILE,
  },

  thresholds: {
    // Overall failure rates
    "http_req_failed{scenario:hp_write_telemetry}": ["rate<0.05"],
    "http_req_failed{scenario:hp_read_telemetry}": ["rate<0.05"],

    // Write performance (POST /telemetry)
    "http_req_duration{scenario:hp_write_telemetry,endpoint:telemetry_post}": [
      "p(50)<150",
      "p(95)<400",
      "p(99)<800",
    ],

    // Read performance (GET /telemetry/latest)
    "http_req_duration{scenario:hp_read_telemetry,endpoint:telemetry_get_latest}":
      ["p(50)<200", "p(95)<500", "p(99)<900"],
  },

  scenarios: {
    // ==========================
    // Write (POST)
    // ==========================
    hp_write_telemetry: {
      executor: "ramping-arrival-rate",
      startRate: W_RATE_START,
      timeUnit: "1s",

      preAllocatedVUs: W_VU,
      maxVUs: W_MAX_VU,

      stages: [
        // Warm-up at start rate
        { duration: `${W_STAGE_RAMP}m`, target: W_RATE_START },
        // Ramp up to target
        {
          duration: `${W_STAGE_RAMP}m`,
          target: Math.round(W_RATE_TARGET * 0.25),
        },
        {
          duration: `${W_STAGE_RAMP}m`,
          target: Math.round(W_RATE_TARGET * 0.5),
        },
        {
          duration: `${W_STAGE_RAMP}m`,
          target: Math.round(W_RATE_TARGET * 0.75),
        },
        { duration: `${W_STAGE_RAMP}m`, target: W_RATE_TARGET },
        // Hold the peak RPS
        { duration: `${W_STAGE_PEAK}m`, target: W_RATE_TARGET },
      ],

      gracefulStop: "60s",
      exec: "hp_write_telemetry",
      tags: {
        role: "write", 
      },
    },

    // ==========================
    // Read (GET)
    // ==========================
    hp_read_telemetry: {
      executor: "ramping-arrival-rate",
      startRate: R_RATE_START,
      timeUnit: "1s",

      preAllocatedVUs: R_VU,
      maxVUs: R_MAX_VU,

      stages: [
        { duration: `${R_STAGE_RAMP}m`, target: R_RATE_START },
        {
          duration: `${R_STAGE_RAMP}m`,
          target: Math.round(R_RATE_TARGET * 0.5),
        },
        { duration: `${R_STAGE_RAMP}m`, target: R_RATE_TARGET },
        // Hold constant background read load
        { duration: `${R_STAGE_PEAK}m`, target: R_RATE_TARGET },
      ],

      gracefulStop: "60s",
      exec: "hp_read_telemetry",
      tags: {
        role: "read",
      },
    },
  },
};

// ==============================
// Scenario functions
// ==============================
export function hp_write_telemetry() {
  const device = getDeviceForVU();
  postTelemetry({ base_url: BASE_URL, device });
}

export function hp_read_telemetry() {
  const device = getDeviceForVU();
  getTelemetryLatest({ base_url: BASE_URL, device });
}

export default hp_write_telemetry;

// ==============================
// Summary output
// ==============================
export function handleSummary(data) {
  return {
    "hp_mixed_test.json": JSON.stringify(data, null, 2),
    "hp_mixed_test.html": htmlReport(data),
    stdout: textSummary(data, { indent: " ", enableColors: true }),
  };
}
