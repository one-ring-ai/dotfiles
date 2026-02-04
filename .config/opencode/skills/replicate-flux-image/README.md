# Replicate Flux Image Generator

Generate images using Replicate's flux-2-max model with this Python script.

## Setup

### Store Replicate Token (Recommended)

Add your Replicate API token to `opencode.jsonc`:

```jsonc
{
  "secrets": {
    "REPLICATE_API_TOKEN": "{file:~/.config/opencode/.secrets/replicate-key}"
  }
}
```

Create the secrets file:

```bash
mkdir -p ~/.config/opencode/.secrets
echo "your_replicate_token_here" > ~/.config/opencode/.secrets/replicate-key
```

### Alternative: Export Environment Variable

```bash
export REPLICATE_API_TOKEN="your_replicate_token_here"
```

## Usage

### Unix/Linux/macOS

```bash
# Basic usage
python scripts/generate_image.py "a beautiful sunset over mountains"

# With aspect ratio and output path
python scripts/generate_image.py "a futuristic cityscape" \
  --aspect_ratio 16:9 --output ./cityscape.webp

# With custom timeout
python scripts/generate_image.py "a detailed portrait of an astronaut" \
  --aspect_ratio 4:3 --output ./portrait.webp --timeout 180
```

### PowerShell (Windows)

```powershell
# Basic usage
python scripts/generate_image.py "a beautiful sunset over mountains"

# With aspect ratio and output path
python scripts/generate_image.py "a futuristic cityscape" \
  --aspect_ratio 16:9 --output ./cityscape.webp

# With custom timeout
python scripts/generate_image.py "a detailed portrait of an astronaut" \
  --aspect_ratio 4:3 --output ./portrait.webp --timeout 180
```

## Important Notes

- **Costs**: Image generation uses Replicate credits. HTTP 402 errors indicate
  insufficient credits or billing issues.
- **Rate Limits**: HTTP 429 errors indicate rate limiting. Wait and retry if
  encountered.
- **Output Format**: All images are generated as WebP format for optimal
  quality and file size.
- **Default Path**: If no output path is specified, images save to
  `./generated-image.webp`.
- **Timeout**: Default timeout is 300 seconds (minimum 10 seconds). Adjust
  based on your needs.

## Supported Aspect Ratios

- `1:1` (default)
- `16:9`, `3:2`, `2:3`
- `4:5`, `5:4`, `9:16`
- `3:4`, `4:3`
