const express = require("express");
const cors = require("cors");
const { spawn } = require("child_process");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const upload = multer({ dest: "/tmp" }); // Render free tier writable
const app = express();

// Frontend URL
app.use(cors({ origin: "http://localhost:5173" }));
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

    // Use /tmp for output
    const outputFile = path.join("/tmp", `clip-${Date.now()}.mp4`);

    const args = [
      ...(cookiesFile ? ["--cookies", cookiesFile] : []),
      "-f", "bestvideo+bestaudio",
      "--merge-output-format", "mp4",
      "--download-sections", `*${startSeconds}-${endSeconds}`,
      "--force-keyframes-at-cuts",
      "-o", outputFile, // write to file instead of stdout
      url
    ];

    console.log("Running yt-dlp:", args.join(" "));
    const ytdlp = spawn("yt-dlp", args);

    ytdlp.stderr.on("data", (data) => {
      console.error("yt-dlp stderr:", data.toString());
    });

    ytdlp.on("close", (code) => {
      console.log(`yt-dlp exited with code ${code}`);
      if (code === 0) {
        // Send file to frontend
        res.download(outputFile, "clip.mp4", (err) => {
          // Cleanup
          fs.unlink(outputFile, () => {});
          if (cookiesFile) fs.unlink(cookiesFile, () => {});
          if (err) console.error("Error sending file:", err);
        });
      } else {
        res.status(500).json({ error: "Failed to download video" });
        if (cookiesFile) fs.unlink(cookiesFile, () => {});
      }
    });
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ error: "Failed to process video" });
  }
});

const PORT = process.env.PORT || 5050;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
