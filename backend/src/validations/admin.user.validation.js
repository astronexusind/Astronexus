import validator from "validator";

export const adminAstrologyUserSchema = (data) => {
  const {
    name,
    phone,
    password,
    confirmPassword,
    email,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
  } = data;

  const errors = [];

  if (!name || name.trim().length < 2) errors.push("Name must be at least 2 characters");
  if (!phone || !validator.isMobilePhone(phone, "any")) errors.push("Valid phone number is required");
  if (email && !validator.isEmail(email)) errors.push("Invalid email format");
  if (!password || password.length < 6) errors.push("Password must be at least 6 characters");
  if (password !== confirmPassword) errors.push("Passwords do not match");
  if (!dateOfBirth) errors.push("dateOfBirth is required");
  if (!timeOfBirth) errors.push("timeOfBirth is required");
  if (!placeOfBirth) errors.push("placeOfBirth is required");

  return errors.length > 0
    ? { error: errors.join(", "), value: data }
    : { error: null, value: data };
};
