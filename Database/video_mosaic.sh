#!/usr/bin/bash

# This script makes a mosaic of frames from a given video.
# The frames are at equidistant periods between the start and end of the video.
# The mosaic frames crop square regions of the video.
# This is meant to produce atlases of sprites for thumbnails of a video.

IN_PATH=${1:-"videos/input.mp4"}
OUT_PATH=${2:-"thumbnails/output.png"}

TILES=${4:-"9"}  # Amount of frames in a mosaic
WIDE=${3:-"192"}  # The thumbnails are squares with this width

# Get the notation for the number of frames wide and high of the mosaic
MOSAIC_SIZE=$(python -c "from math import ceil, sqrt; print( ceil(sqrt(${TILES})) )")
MOSAIC_SIZE=${MOSAIC_SIZE}x${MOSAIC_SIZE}

# Get number of frames in video, then the distance between frames we want to select for the mosaic.
# We add 1 to the number of tiles so the last frame in the mosaic is not the last frame in the video.
LENG=$(ffprobe ${IN_PATH} -select_streams v:0 -show_entries stream=nb_frames -of default=nk=1:nw=1 -v quiet)
LENG=$(python -c "from math import floor; print( floor(${LENG} / (${TILES} + 1)) )")

# Filter crop captures the square region at the center of the video frame.
# Filter scale resizes that square region to thumbnail size.
# Filter setsar keeps the video pixels square.
# Filter select captures frames in a sequence given by an expression in brackets
# Filter tile makes mosaic from selected frames
# frames:v 1 defines how we only want one output picture
# «-fps_mode vfr» Keeps framerate constant by dropping frames if necessary
# «-y» overwrites an output file if it already exists
# «-q:v 24» is the quality of compression, where 31 is the worst.
ffmpeg -i ${IN_PATH} \
	-filter:v "\
		crop=w='min(iw\,ih)':h='min(iw\,ih)', \
		scale=${WIDE}:${WIDE}, \
		setsar=1, \
		select=( gte(n\,$LENG)*not(mod(n\,$LENG)) ), \
		tile=$MOSAIC_SIZE" \
	-frames:v 1 -fps_mode vfr -y -q:v 18 \
	${OUT_PATH}
