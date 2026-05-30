import validator from "validator";

export const userSignupSchema = (data) => {
  const { name, phone, password, confirmPassword, email } = data;
  const errors = [];

  if (!name || name.trim().length < 2) errors.push("Name must be at least 2 characters");
  
  if (!phone || !validator.isMobilePhone(phone, "any")) {
    errors.push("Invalid phone number");
  }

  if (email && !validator.isEmail(email)) {
    errors.push("Invalid email format");
  }

  if (!password || password.length < 6) {
    errors.push("Password must be at least 6 characters");
  }

  if (password !== confirmPassword) {
    errors.push("Passwords do not match");
  }

  if (errors.length > 0) {
    return { error: errors.join(", "), value: data };
  }

  return { error: null, value: data };
};

export const userLoginSchema = (data) => {
  const { email, password } = data;
  const errors = [];

  if (!email || !validator.isEmail(email)) errors.push("Valid email is required");
  if (!password) errors.push("Password is required");

  if (errors.length > 0) {
    return { error: errors.join(", "), value: data };
  }

  return { error: null, value: data };
};

export const userLoginPhoneSchema = (data) => {
  const { phone, password } = data;
  const errors = [];

  if (!phone || !validator.isMobilePhone(phone, "any")) errors.push("Valid phone number is required");
  if (!password) errors.push("Password is required");

  if (errors.length > 0) {
    return { error: errors.join(", "), value: data };
  }

  return { error: null, value: data };
};
