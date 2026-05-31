import { ApiError } from "../utils/ApiError.js";

/**
 * Higher-order middleware to validate request data
 * @param {Function} schemaFn - A function that returns true/false or throws an error
 */
export const validate = (schemaFn) => (req, res, next) => {
  try {
    const { error, value } = schemaFn(req.body);
    if (error) {
      const errors = Array.isArray(error) ? error : String(error).split(",").map((item) => item.trim()).filter(Boolean);
      throw new ApiError(400, "Validation failed", errors);
    }
    // Replace body with validated/sanitized value
    req.body = value;
    next();
  } catch (err) {
    next(err);
  }
};
