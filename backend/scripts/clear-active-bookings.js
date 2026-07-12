// backend/scripts/clear-active-bookings.js
//
// Dev-only utility: during manual testing, a call that's ended by closing/
// refreshing the browser tab (instead of tapping the in-app end-call
// button) leaves its booking stuck at "pending"/"confirmed"/"in_progress"
// forever, which then blocks bookSession's one-active-booking-per-user
// check. Run this to mark all of a user's stuck bookings as "cancelled"
// so you can book again.
//
// Usage:
//   node scripts/clear-active-bookings.js <userEmail>
//   node scripts/clear-active-bookings.js --all     (clears for every user)

import "../src/config/index.js"; // loads .env
import mongoose from "mongoose";
import User from "../src/models/user/user.js";
import Booking from "../src/models/astrologer/Booking.model.js";

const ACTIVE_STATUSES = ["pending", "confirmed", "in_progress"];

async function main() {
  const arg = process.argv[2];
  if (!arg) {
    console.error("Usage: node scripts/clear-active-bookings.js <userEmail>|--all");
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI);

  let filter = { status: { $in: ACTIVE_STATUSES } };

  if (arg !== "--all") {
    const user = await User.findOne({ email: arg });
    if (!user) {
      console.error(`No user found with email ${arg}`);
      await mongoose.disconnect();
      process.exit(1);
    }
    filter.userId = user._id;
  }

  const result = await Booking.updateMany(filter, {
    $set: { status: "cancelled" },
  });

  console.log(`Cleared ${result.modifiedCount} stuck booking(s).`);
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});