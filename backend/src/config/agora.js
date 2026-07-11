// backend/src/config/agora.js
import agoraToken from "agora-token";
const { RtcTokenBuilder, RtcRole } = agoraToken;
if (!process.env.AGORA_APP_ID || !process.env.AGORA_APP_CERTIFICATE) {
  throw new Error(
    "FATAL: AGORA_APP_ID and AGORA_APP_CERTIFICATE must be set in .env"
  );
}

const AGORA_APP_ID          = process.env.AGORA_APP_ID;
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

// Tokens/privileges valid for 1 hour — plenty for a single consultation
// session. If sessions can run longer, the client should request a fresh
// token via /session/start again rather than us issuing very long-lived ones.
const TOKEN_EXPIRE_SECONDS     = 60 * 60;
const PRIVILEGE_EXPIRE_SECONDS = 60 * 60;

/**
 * Derive a stable, deterministic 32-bit unsigned Agora uid from a Mongo
 * ObjectId string. Same userId always maps to the same uid, so we don't
 * need to persist it anywhere — the client just needs to be told the uid
 * we used so it can join with the exact same one the token was signed for.
 */
export function mongoIdToAgoraUid(mongoId) {
  const hex = mongoId.toString().slice(-8); // last 8 hex chars = 4 bytes
  const uid = parseInt(hex, 16);
  // uid 0 has special "let Agora assign one" meaning — avoid colliding with it.
  return uid === 0 ? 1 : uid;
}

/**
 * Generate an RTC token for a given channel + uid.
 * @param {string} channelName
 * @param {number} uid
 * @param {"publisher"|"subscriber"} role
 */
export function generateAgoraRtcToken(channelName, uid, role = "publisher") {
  const rtcRole = role === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  return RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID,
    AGORA_APP_CERTIFICATE,
    channelName,
    uid,
    rtcRole,
    TOKEN_EXPIRE_SECONDS,
    PRIVILEGE_EXPIRE_SECONDS
  );
}

export { AGORA_APP_ID };