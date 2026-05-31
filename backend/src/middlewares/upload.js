import multer from "multer";

const allowedImageTypes = new Set(["image/jpeg", "image/jpg", "image/png", "image/webp"]);

const uploadProfileStorage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (allowedImageTypes.has(file.mimetype)) {
    cb(null, true);
    return;
  }

  cb(new Error("Only JPG, JPEG, PNG and WEBP images are allowed"));
};

const uploadProfile = multer({
  storage: uploadProfileStorage,
  fileFilter,
  limits: { fileSize: 2 * 1024 * 1024 }, // 2MB
});

export default uploadProfile;
