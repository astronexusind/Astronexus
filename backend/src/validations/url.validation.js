import validator from "validator";

export const shortUrlSchema = (data) => {
  const { url, customShortId } = data;
  const errors = [];

  if (!url || !validator.isURL(url, { require_protocol: true })) {
    errors.push("Valid URL with http:// or https:// is required");
  }

  if (customShortId && !/^[a-zA-Z0-9_-]+$/.test(customShortId)) {
    errors.push("Custom short ID can only contain letters, numbers, hyphens, and underscores");
  }

  return errors.length > 0
    ? { error: errors.join(", "), value: data }
    : { error: null, value: data };
};
