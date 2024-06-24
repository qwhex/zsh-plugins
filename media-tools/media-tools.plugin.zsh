# media-tools
# Functions for media file conversions and manipulations

# Function to convert a .mov file to an optimized .gif
# Usage: mov-to-gif input_file.mov [output_file.gif]
mov-to-gif() {
    set -e
    
    # $1: Input .mov file (required)
    local input_file=$1
    
    # $2: Output .gif file (optional, defaults to output.gif)
    local output_file=${2:-output.gif}

    # Convert .mov to .gif using ffmpeg
    # -i: input file
    # -vf: video filter for scaling (maintain aspect ratio, set height to 480px)
    # -pix_fmt: set pixel format to RGB8 for GIF compatibility
    # -r: set frame rate to 5 fps
    ffmpeg -i "$input_file" \
           -vf "scale=-1:480" \
           -pix_fmt rgb8 \
           -r 5 \
           "$output_file"

    # Optimize the resulting .gif using gifsicle
    # -O3: highest optimization level
    # -o: output file (overwrites the input file)
    gifsicle -O3 "$output_file" -o "$output_file"
}