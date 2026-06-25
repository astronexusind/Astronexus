import mongoose from "mongoose";

/**
 * Stores invalidated JWT IDs (jti) so logged-out tokens are rejected
 * even though their signature is still technically valid.
 *
 * `expiresAt` has a TTL index — MongoDB automatically deletes the
 * document once the original token would have expired anyway, so
 * this collection never grows unbounded.
 */
const blacklistedTokenSchema = new mongoose.Schema({
  jti: { type: String, required: true, unique: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, required: true },
  tokenType: { type: String, enum: ["access", "refresh", "admin"], required: true },
  expiresAt: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now },
});

// TTL index: MongoDB deletes the document automatically once expiresAt passes
blacklistedTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export default mongoose.model("BlacklistedToken", blacklistedTokenSchema);
