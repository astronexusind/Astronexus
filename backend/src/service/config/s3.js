import { DeleteObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { randomUUID } from "crypto";
import path from "path";

const bucketName = process.env.AWS_BUCKET_NAME;
const region = process.env.AWS_REGION;
const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

if (!bucketName || !region || !accessKeyId || !secretAccessKey) {
  console.warn("AWS S3 environment variables are not fully configured");
}

const s3Client = new S3Client({
  region,
  credentials: {
    accessKeyId,
    secretAccessKey,
  },
});

const normalizePrefix = (prefix) => prefix.replace(/^\/+|\/+$/g, "");

const encodeS3Key = (key) => key.split("/").map(segment => encodeURIComponent(segment)).join("/");

export const createS3Key = (prefix, originalName = "file") => {
  const safePrefix = normalizePrefix(prefix);
  const extension = path.extname(originalName).toLowerCase();
  return `${safePrefix}/${Date.now()}-${randomUUID()}${extension}`;
};

export const buildS3Url = (key) => {
  if (!bucketName || !region) {
    throw new Error("AWS S3 bucket configuration is missing");
  }

  return `https://${bucketName}.s3.${region}.amazonaws.com/${encodeS3Key(key)}`;
};

export const extractS3KeyFromUrl = (url) => {
  if (!url) {
    return null;
  }

  try {
    const parsedUrl = new URL(url);
    return decodeURIComponent(parsedUrl.pathname.replace(/^\/+/, ""));
  } catch {
    return null;
  }
};

export const uploadBufferToS3 = async ({ key, buffer, mimetype, acl = "public-read" }) => {
  if (!bucketName) {
    throw new Error("AWS bucket name is missing");
  }

  await s3Client.send(new PutObjectCommand({
    Bucket: bucketName,
    Key: key,
    Body: buffer,
    ContentType: mimetype,
  }));

  return {
    key,
    url: buildS3Url(key),
  };
};

export const deleteS3Object = async (key) => {
  if (!key || !bucketName) {
    return;
  }

  await s3Client.send(new DeleteObjectCommand({
    Bucket: bucketName,
    Key: key,
  }));
};

export default s3Client;