import mongoose from "mongoose";

const wishlistSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // optional ref to User
  products: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }] // reference Product collection
}, { timestamps: true });

export default mongoose.model('Wishlist', wishlistSchema);