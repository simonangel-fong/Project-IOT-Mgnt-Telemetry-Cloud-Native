// test_hp_write.js
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.4/index.js";
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
import { parseNumberEnv, getDeviceForVU } from "./utils.js";
import { postTelemetry } from "./target_url.js";

// ==============================
// Environment
// ==============================
const BASE_URL = __ENV.BASE_URL || "http://localhost:8000";

// Tag to distinguish solution variants
const SOLUTION_ID = __ENV.SOLUTION_ID || "Sol-Baseline"; // e.g. Sol-Baseline / Sol-ECS / Sol-Redis
const PROFILE = "write-heavy";

// High-performance write test parameters
const RATE_START = parseNumberEnv("RATE_START", 50); // initial RPS
const RATE_TARGET = parseNumberEnv("RATE_TARGET", 1000); // peak RPS
const STAGE_RAMP = parseNumberEnv("STAGE_RAMP", 2); // minutes per ramp stage
const STAGE_PEAK = parseNumberEnv("STAGE_PEAK", 2); // minutes to hold peak

// VU pool
const VU = parseNumberEnv("VU", 50); // pre-allocated VUs
const MAX_VU = parseNumberEnv("MAX_VU", 200); // safety upper bound

// ==============================
// k6 options
// ==============================
export const options = {
  cloud: {
    name: `HP Write – ${SOLUTION_ID}`,
  },

  // Global tags applied to all metrics
  tags: {
    solution: SOLUTION_ID,
    profile: PROFILE,
  },

  // SLO:
  // "rate<0.01": Less than 1% of requests return an error.
  // "p(95)<500": 95% of requests have a response time below 500ms.
  // "p(99)<1000": 99% of requests have a response time below 1000ms.

  thresholds: {
    // Overall failure rate
    "http_req_failed{scenario:hp_write_telemetry}": [
      {
        threshold: "rate<0.01", // SLO
        abortOnFail: true, // abort when 1st failure
        delayAbortEval: "10s", // delay to collect degraded system data
      },
    ],

    // POST /telemetry
    "http_req_duration{scenario:hp_write_telemetry,endpoint:telemetry_post}": [
      { threshold: "p(95)<300" },
      { threshold: "p(99)<1000" },
    ],
  },

  scenarios: {
    hp_write_telemetry: {
      executor: "ramping-arrival-rate",
      startRate: RATE_START, // initial RPS
      timeUnit: "1s", // RPS-based

      preAllocatedVUs: VU, // initial VU pool
      maxVUs: MAX_VU, // max VUs

      // Smooth ramp to RATE_TARGET and then hold
      stages: [
        { duration: `${STAGE_RAMP}m`, target: RATE_START }, // warm-up
        { duration: `${STAGE_RAMP}m`, target: Math.round(RATE_TARGET * 0.25) },
        { duration: `${STAGE_RAMP}m`, target: Math.round(RATE_TARGET * 0.5) },
        { duration: `${STAGE_RAMP}m`, target: Math.round(RATE_TARGET * 0.75) },
        { duration: `${STAGE_RAMP}m`, target: RATE_TARGET }, // reach peak
        { duration: `${STAGE_PEAK}m`, target: RATE_TARGET }, // hold peak
      ],

      gracefulStop: "60s",
      exec: "hp_write_telemetry", // scenario function below
    },
  },
};

// ==============================
// Scenario function
// ==============================
export function hp_write_telemetry() {
  const device = getDeviceForVU();
  postTelemetry({ base_url: BASE_URL, device });
}

export default hp_write_telemetry;

// ==============================
// Summary output
// ==============================
export function handleSummary(data) {
  return {
    "hp_write_test.json": JSON.stringify(data, null, 2),
    "hp_write_test.html": htmlReport(data),
    stdout: textSummary(data, { indent: " ", enableColors: true }),
  };
}
