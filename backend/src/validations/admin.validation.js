import validator from "validator";

export const adminCreateSchema = (data) => {
  const { email, password, setupKey } = data;
  const errors = [];

  if (!email || !validator.isEmail(email)) errors.push("Valid admin email is required");
  if (!password || password.length < 6) errors.push("Password must be at least 6 characters");
  if (!setupKey || !setupKey.trim()) errors.push("Setup key is required");

  return errors.length > 0
    ? { error: errors.join(", "), value: data }
    : { error: null, value: data };
};

export const adminLoginSchema = (data) => {
  const { email, password } = data;
  const errors = [];

  if (!email || !validator.isEmail(email)) errors.push("Valid admin email is required");
  if (!password) errors.push("Password is required");

  return errors.length > 0
    ? { error: errors.join(", "), value: data }
    : { error: null, value: data };
};

export const adminUpdatePasswordSchema = (data) => {
  const { oldPassword, newPassword } = data;
  const errors = [];

  if (!oldPassword) errors.push("Old password is required");
  if (!newPassword || newPassword.length < 6) errors.push("New password must be at least 6 characters");

  return errors.length > 0
    ? { error: errors.join(", "), value: data }
    : { error: null, value: data };
};
