const express = require("express");
const cors = require("cors");
const { createProxyMiddleware } = require("http-proxy-middleware");
const app = express();
const PORT = 8080;

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
    target: "http://localhost:8081",
    changeOrigin: true,
    pathFilter: "/api/catalog",
  })
);

// Auth -> 8082
app.use(
  createProxyMiddleware({
    target: "http://localhost:8082",
    changeOrigin: true,
    pathFilter: "/api/auth",
  })
);

// Booking -> 8083
app.use(
  createProxyMiddleware({
    target: "http://localhost:8083",
    changeOrigin: true,
    pathFilter: "/api/booking",
  })
);

// AI Insight -> 8084
app.use(
  createProxyMiddleware({
    target: "http://localhost:8084",
    changeOrigin: true,
    pathFilter: "/api/analyze",
  })
);

// Analytics -> 8085
app.use(
  createProxyMiddleware({
    target: "http://localhost:8085",
    changeOrigin: true,
    pathFilter: "/api/analytics",
  })
);

app.listen(PORT, () => {
  console.log(`API Gateway listening on ${PORT}`);
});
