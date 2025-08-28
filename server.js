const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const util = require('util');
const multer = require('multer');

const execPromise = util.promisify(exec);
const upload = multer({ dest: 'uploads/' });

const app = express();
// Update CORS to match your frontend URL
app.use(cors({ origin: 'https://youtube-clip-frontend.onrender.com' })); // Replace with your Vercel URL

app.use(express.json());

app.get("/", (req, res) => {
  res.send("Backend is running");
});

app.post('/api/download', upload.single('cookies'), async (req, res) => {
  const { url, startTime, endTime } = req.body;
  const cookiesFile = req.file ? req.file.path : null;

  if (!url || !startTime || !endTime) {
    return res.status(400).json({ error: 'Missing URL, startTime, or endTime' });
  }

  const timeRegex = /^\d{2}:\d{2}$/;
  if (!timeRegex.test(startTime) || !timeRegex.test(endTime)) {
    return res.status(400).json({ error: 'Invalid time format. Use MM:SS' });
  }

  const outputDir = path.join(__dirname, 'downloads');
  const outputFile = path.join(outputDir, `clip-${Date.now()}.mp4`);
  
  try {
    await fs.mkdir(outputDir, { recursive: true });
    // const downloadCommand = `yt-dlp --cookies cookies.txt --sleep-requests 2 --sleep-interval 5 -f bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4 --output temp.mp4 "${url}"`;
    const cookiesArg = cookiesFile ? `--cookies ${cookiesFile}` : "";
    const downloadCommand = `yt-dlp ${cookiesArg} -f bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4 --output temp.mp4 --retries 10 --fragment-retries 10 "${url}"`;
    await execPromise(downloadCommand);

    const trimCommand = `ffmpeg -i temp.mp4 -ss ${startTime} -to ${endTime} -c:v libx264 -c:a aac -vf "scale=1280:-2" ${outputFile}`;
    const { stdout, stderr } = await execPromise(trimCommand);
    console.log('FFmpeg stdout:', stdout);
    console.log('FFmpeg stderr:', stderr);

    res.download(outputFile, 'clip.mp4', async (err) => {
      if (err) {
        console.error('Error sending file:', err);
        res.status(500).json({ error: 'Failed to send file' });
      }
      try {
        await fs.unlink('temp.mp4').catch(() => {});
        await fs.unlink(outputFile).catch(() => {});
        if (cookiesFile) await fs.unlink(cookiesFile).catch(() => {});
      } catch (cleanupError) {
        console.error('Error cleaning up files:', cleanupError);
      }
    });
  } catch (error) {
    console.error('Error processing video:', error);
    res.status(500).json({ error: 'Failed to process video' });
    try {
      await fs.unlink('temp.mp4').catch(() => {});
      await fs.unlink(outputFile).catch(() => {});
      if (cookiesFile) await fs.unlink(cookiesFile).catch(() => {});
    } catch (cleanupError) {
      console.error('Error cleaning up files:', cleanupError);
    }
  }
});

const PORT = 5050; // Remove fallback to 5000
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);

});
