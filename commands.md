# Useful commands

## ImageMagick

### Overlay 2 images with transparency
magick convert bottom.png \( top.png -alpha set -channel a -evaluate set 75% +channel \) -gravity center -compose over -composite out.png
magick composite -dissolve 75 -gravity Center top.png bottom.png -alpha Set out.png

### Convert all JPGs to PNG & Remove
for f in *.jpg; do magick convert "$f" -quality 100 -format png "${f/.jpg/.png}" && rm "$f"; done

### Convert all WEBPs to PNG
for f in *.webp; do magick convert "$f" "${f/.webp/.png}"; done

### Resize images
for f in *.png; do magick convert "$f" -quality 100 -filter Lanczos -resize 1080x1350 "${f/.png/-lg.png}"; done

### Crop image
magick convert input.png -crop 800x600+100+50 output.png

### Add border to image
magick convert input.png -bordercolor black -border 10x10 output.png

### Create thumbnail
magick convert input.png -thumbnail 200x200 thumb.png

### Batch rename files with counter
i=1; for f in *.png; do mv "$f" "image_$(printf %03d $i).png"; ((i++)); done

## FFmpeg

### Trim video
ffmpeg -accurate_seek -ss 00:00:07.5 -i source.mp4 -c:v copy -c:a copy out.mp4

### Split video into frames
ffmpeg -i video.mp4 -framerate 25 video/%04d.png

### Merge frames into video (muted)
ffmpeg -framerate 25 -i frames/%04d.png -c:v libx264 -crf 7 -pix_fmt yuv420p -y muted.mp4

### Copy sound from another video
ffmpeg -i muted.mp4 -i original.mp4 -c:v copy -map 0:v:0 -map 1:a:0 -y out.mp4

### Extract audio from video
ffmpeg -i video.mp4 -vn -acodec libmp3lame -q:a 2 audio.mp3

### Compress video
ffmpeg -i input.mp4 -vcodec libx264 -crf 28 output.mp4

### Rotate video 90 degrees clockwise
ffmpeg -i input.mp4 -vf "transpose=1" output.mp4

### Add watermark to video
ffmpeg -i video.mp4 -i watermark.png -filter_complex "overlay=10:10" output.mp4

## Network

### Test port connectivity
nc -zv hostname 80

### Find process using a port
lsof -i :8080

### Download file with progress
curl -L -o filename.zip https://example.com/file.zip

### Test DNS resolution
dig example.com

## System

### Find large files
find / -type f -size +100M 2>/dev/null

### Create compressed archive
tar -czf archive.tar.gz directory/

### Extract tar.gz archive
tar -xzf archive.tar.gz

### Find files modified in last 7 days
find . -type f -mtime -7

## Text Processing

### Replace text in files
sed -i 's/old/new/g' file.txt

### Extract column from CSV
awk -F',' '{print $3}' data.csv

### Count lines in file
wc -l file.txt

### Remove duplicate lines
sort file.txt | uniq

### Find and replace in multiple files
find . -type f -name "*.txt" -exec sed -i 's/old/new/g' {} +

### Merge lines with paste
paste -sd ',' file.txt

## Process Management

### Kill process by name
pkill -f process_name

### List all processes with memory usage
ps aux --sort=-%mem | head -n 10

### Run command in background
nohup command &

### List background jobs
jobs -l

## File Operations

### Find and delete files
find . -name "*.tmp" -type f -delete

### Change file permissions recursively
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;

## SSH & Remote

### Copy SSH key to server
ssh-copy-id user@hostname

### SSH tunnel (port forwarding)
ssh -L 8080:localhost:80 user@hostname

### Run command on remote server
ssh user@hostname 'command'

### SCP with compression
scp -C file.txt user@hostname:/path/
