import multer from "multer";

const allowedImageTypes = new Set(["image/jpeg", "image/jpg", "image/png", "image/webp"]);

const productStorage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (allowedImageTypes.has(file.mimetype)) {
    cb(null, true);
    return;
  }

  cb(new Error("Only JPG, JPEG, PNG and WEBP images are allowed"));
};

const uploadProduct = multer({
  storage: productStorage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // ✅ 5MB
});

export default uploadProduct;
