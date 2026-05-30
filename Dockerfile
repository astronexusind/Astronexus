# Use a Debian-based Node.js image to easily install Python and system dependencies
FROM node:20-bullseye-slim

# Install system dependencies for 'canvas' and 'python3'
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the entire project
COPY . .

# --- SETUP BACKEND ---
WORKDIR /app/backend
RUN npm ci --only=production

# --- SETUP INTERNAL NODE SERVICES ---
WORKDIR /app/Python/horoscope/astronexus-horoscope
RUN npm ci --only=production

WORKDIR /app/Python/mati/astro-bot
RUN npm ci --only=production

# --- SETUP INTERNAL PYTHON SERVICE ---
WORKDIR /app/Python/birth_chart/astro-nexus-backend
RUN python3 -m venv .venv && \
    .venv/bin/pip install --upgrade pip && \
    .venv/bin/pip install -r requirements.txt

# --- FINAL SETUP ---
WORKDIR /app/backend

# Expose the main port
EXPOSE 8001

# Environment variables (Defaults - should be overridden at runtime)
ENV NODE_ENV=production
ENV PORT=8001
ENV UNIFIED_AUTOSTART=true

# Start the main server
CMD ["node", "src/server.js"]
