const express = require("express");
const cors = require("cors");
const { spawn } = require("child_process");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const os = require("os");

const upload = multer({ dest: "/tmp" }); // for cookies if needed
const app = express();

// Middleware
app.use(cors({ origin: "https://youtube-clip-frontend.onrender.com" }));
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Backend is running");
});

// Convert HH:MM:SS or MM:SS or SS to seconds
function timeToSeconds(timeStr) {
  const parts = timeStr.split(":").map(Number);
  if (parts.length === 1) return parts[0];                // SS
  if (parts.length === 2) return parts[0] * 60 + parts[1]; // MM:SS
  if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2]; // HH:MM:SS
  return NaN;
}

/**
 * Old endpoint: download a clipped video
 * Body: { url, startTime, endTime }, optional cookies file
 */
app.post("/api/download", upload.single("cookies"), async (req, res) => {
  try {
    const { url, startTime, endTime } = req.body;
    const cookiesFile = req.file ? req.file.path : null;

    if (!url || !startTime || !endTime) {
      return res.status(400).json({ error: "Missing URL, startTime, or endTime" });
    }

    const startSeconds = timeToSeconds(startTime);
    const endSeconds = timeToSeconds(endTime);

    if (isNaN(startSeconds) || isNaN(endSeconds)) {
      return res.status(400).json({ error: "Invalid time format. Use MM:SS or HH:MM:SS" });
    }

    // Set headers to stream as downloadable clip
    res.setHeader("Content-Disposition", "attachment; filename=clip.mp4");
    res.setHeader("Content-Type", "video/mp4");

    const args = [
      ...(cookiesFile ? ["--cookies", cookiesFile] : []),
      "-f", "bestvideo+bestaudio",
      "--merge-output-format", "mp4",
      "--download-sections", `*${startSeconds}-${endSeconds}`,
      "--force-keyframes-at-cuts",
      "-o", "-", // output to stdout
      url
    ];

    console.log("Running yt-dlp (clipped):", args.join(" "));
    const ytdlp = spawn("yt-dlp", args);

    ytdlp.stdout.pipe(res);

    ytdlp.stderr.on("data", (data) => {
      console.error("yt-dlp stderr:", data.toString());
    });

    ytdlp.on("close", (code) => {
      if (code !== 0) {
        console.error(`yt-dlp exited with code ${code}`);
        if (!res.headersSent) res.status(500).json({ error: "Failed to download clip" });
      }
      if (cookiesFile) fs.unlink(cookiesFile, () => {}); // cleanup cookies
    });

  } catch (err) {
    console.error("Error:", err);
    if (!res.headersSent) res.status(500).json({ error: "Failed to process clip" });
  }
});


/**
 * Youtube Full Video Downaloder
 * Body: { url }, optional cookies file
 */
app.post("/api/ytdownload", upload.single("cookies"), async (req, res) => {
  try {
    const { url } = req.body;
    const cookiesFile = req.file ? req.file.path : null;
    if (!url) return res.status(400).json({ error: "Missing URL" });

    
    // Set headers to prompt file download
    res.setHeader("Content-Disposition", "attachment; filename=video.mp4");
    res.setHeader("Content-Type", "video/mp4"); // works for mp4 or mkv, browser will handle

    const args = [
      ...(cookiesFile ? ["--cookies", cookiesFile] : []),
       "-f", "bestvideo+bestaudio/best",   // best video+audio merged
      "--merge-output-format", "mp4",     // force mp4 if needed
      "-o", "-",                           // output to stdout
      url,
    ];

    console.log("Running yt-dlp (full video YT):", args.join(" "));
    const ytdlp = spawn("yt-dlp", args);

    ytdlp.stdout.pipe(res);

    ytdlp.stderr.on("data", (data) => {
      console.error("yt-dlp stderr:", data.toString());
    });

    ytdlp.on("close", (code) => {
      if (code !== 0) {
        console.error(`yt-dlp exited with code ${code}`);
        if (!res.headersSent) res.status(500).json({ error: "Failed to download full video" });
      }
      if (cookiesFile) fs.unlink(cookiesFile, () => {}); // cleanup cookies
    });

  } catch (err) {
    console.error("Error:", err);
    if (!res.headersSent) res.status(500).json({ error: "Failed to process YT full video" });
  }
});




/**
 * New endpoint: download full video only by URL
 * Body: { url }
 */
app.post("/api/video-download", async (req, res) =>  {
  try {
    const { url } = req.body;
    if (!url) return res.status(400).json({ error: "Missing URL" });

    res.setHeader("Content-Disposition", "attachment; filename=video.mp4");
    res.setHeader("Content-Type", "video/mp4");

    const args = ["-f", "best", "-o", "-", url];
    console.log("Running yt-dlp (all-in-one):", args.join(" "));

    const ytdlp = spawn("yt-dlp", args);

    ytdlp.stdout.pipe(res);

    ytdlp.stderr.on("data", data =>
      console.error("yt-dlp stderr:", data.toString())
    );

    ytdlp.on("close", code => {
      if (code !== 0 && !res.headersSent) {
        console.error(`yt-dlp exited with code ${code}`);
        res.status(500).json({ error: "Download failed" });
      }
    });
  } catch (err) {
    console.error("Error:", err);
    if (!res.headersSent)
      res.status(500).json({ error: "Failed to process video" });
  }
});






app.get("/api/allin-download-proxy", async (req, res) => {
  const { url } = req.query;
  if (!url) return res.status(400).json({ error: "Missing URL" });

  res.setHeader("Content-Disposition", "attachment; filename=video.mp4");
  res.setHeader("Content-Type", "video/mp4");

  const args = ["-f", "best", "-o", "-", url];
  console.log("Running yt-dlp (proxy):", args.join(" "));

  const ytdlp = spawn("yt-dlp", args);

  ytdlp.stdout.pipe(res);

  ytdlp.stderr.on("data", (data) => console.error("yt-dlp stderr:", data.toString()));

  ytdlp.on("close", (code) => {
    if (code !== 0 && !res.headersSent) {
      res.status(500).json({ error: "Download failed" });
    }
  });
});




 
const PORT = process.env.PORT || 5050;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
