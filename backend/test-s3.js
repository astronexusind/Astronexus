import dotenv from "dotenv";
dotenv.config();

import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import fs from "fs";

const bucketName = process.env.AWS_BUCKET_NAME;
const region = process.env.AWS_REGION;
const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

console.log("Bucket:", bucketName);
console.log("Region:", region);

const s3Client = new S3Client({
  region,
  credentials: {
    accessKeyId,
    secretAccessKey,
  },
});

async function run() {
  try {
    const res = await s3Client.send(new PutObjectCommand({
      Bucket: bucketName,
      Key: "test-upload.txt",
      Body: "Hello from test script",
      ContentType: "text/plain",
    }));
    console.log("Upload success:", res);
  } catch (e) {
    console.error("Upload failed:", e);
  }
}

run();
