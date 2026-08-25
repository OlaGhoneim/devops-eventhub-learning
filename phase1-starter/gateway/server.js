const express = require("express");
const cors = require("cors");
const { createProxyMiddleware } = require("http-proxy-middleware");

const app = express();

const PORT = 8080;

const CATALOG_URL = process.env.CATALOG_URL || "http://localhost:8081";
const AUTH_URL = process.env.AUTH_URL || "http://localhost:8082";
const BOOKING_URL = process.env.BOOKING_URL || "http://localhost:8083";
const AI_INSIGHT_URL =
  process.env.AI_INSIGHT_URL || "http://localhost:8084";
const ANALYTICS_URL =
  process.env.ANALYTICS_URL || "http://localhost:8085";

app.use(
  cors({
    origin: "http://localhost:3000",
  })
);

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// Catalog -> 8081
app.use(
  createProxyMiddleware({
    target: CATALOG_URL,
    changeOrigin: true,
    pathFilter: "/api/catalog",
  })
);

// Auth -> 8082
app.use(
  createProxyMiddleware({
    target: AUTH_URL,
    changeOrigin: true,
    pathFilter: "/api/auth",
  })
);

// Booking -> 8083
app.use(
  createProxyMiddleware({
    target: BOOKING_URL,
    changeOrigin: true,
    pathFilter: "/api/booking",
  })
);

// AI Insight -> 8084
app.use(
  createProxyMiddleware({
    target: AI_INSIGHT_URL,
    changeOrigin: true,
    pathFilter: "/api/analyze",
  })
);

// Analytics -> 8085
app.use(
  createProxyMiddleware({
    target: ANALYTICS_URL,
    changeOrigin: true,
    pathFilter: "/api/analytics",
  })
);

app.listen(PORT, () => {
  console.log(`API Gateway listening on ${PORT}`);
});
