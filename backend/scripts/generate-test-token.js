// backend/scripts/generate-test-token.js
//
// One-off helper for manually testing 2-way video calls. Generates a valid
// Agora RTC token for a given channel + uid, using the same App ID/
// Certificate already configured in .env — so there's no risk of typos
// when testing against Agora's web demo.
//
// Usage:
//   node scripts/generate-test-token.js <channelName> [uid]
//
// Run this from inside the backend/ folder.

import "../src/config/index.js"; // loads .env as a side effect
import { generateAgoraRtcToken, AGORA_APP_ID } from "../src/config/agora.js";

const channelName = process.argv[2];
const uid = parseInt(process.argv[3] || "99999", 10);

if (!channelName) {
  console.error("Usage: node scripts/generate-test-token.js <channelName> [uid]");
  process.exit(1);
}

const token = generateAgoraRtcToken(channelName, uid, "publisher");

console.log("");
console.log("Paste these into https://webdemo.agora.io/basicVideoCall/index.html");
console.log("─".repeat(60));
console.log("App ID:  ", AGORA_APP_ID);
console.log("Channel: ", channelName);
console.log("Token:   ", token);
console.log("User ID: ", uid);
console.log("─".repeat(60));