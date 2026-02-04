---
name: replicate-flux-image
description: Generate images using Replicate's flux-2-max model with fixed
  parameters for consistent high-quality output
---

# Replicate Flux Image Generation Skill

This skill generates images using Replicate's flux-2-max model with optimized,
fixed parameters for consistent high-quality output.

## What It Does

Generates images from text prompts using Replicate's flux-2-max model with
predefined settings:

- Resolution: 4 MP
- Output format: WebP
- Output quality: 100
- Safety tolerance: 5

## When to Use

- When you need high-quality image generation from text descriptions
- For creating visual content, illustrations, or concept art
- When consistent output format and quality are required

## Inputs

- **prompt** (required): Text description for image generation
- **aspect_ratio** (enum only): One of '1:1','16:9','3:2','2:3','4:5','5:4',
  '9:16','3:4','4:3' (default: '1:1')

No custom parameters are supported - all other settings are fixed.

## Fixed Parameters

- Resolution: 4 MP
- Output format: webp
- Output quality: 100
- Safety tolerance: 5

## Command

```bash
python scripts/generate_image.py "your prompt here" \
  --aspect_ratio 16:9 --output ./image.webp --timeout 300
```

## Required Environment Variable

`REPLICATE_API_TOKEN` - Your Replicate API token for authentication
