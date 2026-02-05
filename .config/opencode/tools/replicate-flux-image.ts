import { tool } from '@opencode-ai/plugin';
import { writeFile, mkdir } from 'fs/promises';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { homedir } from 'os';

const RESOLUTION_OPTIONS = ['match_input_image', '0.5 MP', '1 MP', '2 MP', '4 MP'] as const;
const ASPECT_RATIO_OPTIONS = ['match_input_image', 'custom', '1:1', '16:9', '3:2', '2:3', '4:5', '5:4', '9:16', '3:4', '4:3'] as const;
const OUTPUT_FORMAT_OPTIONS = ['webp', 'jpg', 'png'] as const;

type ResolutionOption = typeof RESOLUTION_OPTIONS[number];
type AspectRatioOption = typeof ASPECT_RATIO_OPTIONS[number];
type OutputFormatOption = typeof OUTPUT_FORMAT_OPTIONS[number];

interface ToolArgs {
  prompt: string;
  aspect_ratio: AspectRatioOption;
  resolution: ResolutionOption;
  width?: number;
  height?: number;
  input_images: string[];
  output_format: OutputFormatOption;
  output_quality: number;
  safety_tolerance: number;
  seed?: number;
}

interface PredictionResponse {
  id: string;
  status: string;
  error?: string;
  output?: string | string[];
}

async function sleep(milliseconds: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, milliseconds));
}

function roundToMultipleOf32(value: number): number {
  return Math.round(value / 32) * 32;
}

function clampToRange(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

async function pollPredictionStatus(predictionId: string, token: string): Promise<PredictionResponse> {
  const response = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to poll prediction status: ${response.statusText}`);
  }

  return response.json();
}

async function downloadImage(url: string, filePath: string): Promise<{ size: number }> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to download image: ${response.statusText}`);
  }

  const buffer = await response.arrayBuffer();
  await mkdir(dirname(filePath), { recursive: true });
  await writeFile(filePath, Buffer.from(buffer));

  return { size: buffer.byteLength };
}

export default tool({
  name: 'replicate-flux-image',
  description: 'Generate images using Replicate flux-2-max model',
  args: {
    prompt: tool.schema.string().trim().min(1).describe('Required text prompt'),
    aspect_ratio: tool.schema.enum(ASPECT_RATIO_OPTIONS).default('1:1').describe("Aspect ratio, one of: match_input_image, custom, 1:1, 16:9, 3:2, 2:3, 4:5, 5:4, 9:16, 3:4, 4:3"),
    resolution: tool.schema.enum(RESOLUTION_OPTIONS).default('1 MP').describe('Resolution preset, one of: match_input_image, 0.5 MP, 1 MP, 2 MP, 4 MP (ignored when aspect_ratio=custom)'),
    width: tool.schema.number().int().min(256).max(2048).optional().describe('Custom width (pixels, 256-2048, int, only when aspect_ratio=custom; rounded to nearest 32)'),
    height: tool.schema.number().int().min(256).max(2048).optional().describe('Custom height (pixels, 256-2048, int, only when aspect_ratio=custom; rounded to nearest 32)'),
    input_images: tool.schema.array(tool.schema.string().url()).max(8).default([]).describe('Up to 8 image URLs (jpeg/png/gif/webp) for img2img/style'),
    output_format: tool.schema.enum(OUTPUT_FORMAT_OPTIONS).default('webp').describe('Output format: webp, jpg, or png'),
    output_quality: tool.schema.number().int().min(0).max(100).default(100).describe('Output quality 0-100 (for webp/jpg)'),
    safety_tolerance: tool.schema.number().int().min(1).max(5).default(5).describe('Safety tolerance 1-5 (1 strict, 5 permissive)'),
    seed: tool.schema.number().int().min(1).max(4294967295).optional().describe('Seed 1-4294967295 for reproducible output'),
  },
  execute: async function(args: ToolArgs, context): Promise<string> {
    const envToken = (process.env.REPLICATE_API_TOKEN ?? '').trim();
    let token = envToken;
    if (!token) {
      const keyPath = join(homedir(), '.config', 'opencode', '.secrets', 'replicate-key');
      try {
        const fileContent = readFileSync(keyPath, 'utf-8');
        token = fileContent.trim();
      } catch {
        throw new Error('REPLICATE_API_TOKEN environment variable is required');
      }
      if (!token) {
        throw new Error('REPLICATE_API_TOKEN environment variable is required');
      }
    }

    const aspectRatio = args.aspect_ratio || '1:1';
    const resolution = args.resolution || '1 MP';
    const outputFormat = args.output_format || 'webp';
    const outputQuality = args.output_quality ?? 100;
    const safetyTolerance = args.safety_tolerance ?? 5;
    const inputImages = args.input_images ?? [];

    const prompt = (args.prompt ?? '').trim();
    if (!prompt) {
      throw new Error('Prompt cannot be empty');
    }

    if (aspectRatio === 'custom') {
      if (!args.width || !args.height) {
        throw new Error('Both width and height are required when aspect_ratio is custom');
      }
    }

    const input: Record<string, any> = {
      prompt,
      aspect_ratio: aspectRatio,
      output_format: outputFormat,
      output_quality: outputQuality,
      safety_tolerance: safetyTolerance,
    };

    if (aspectRatio !== 'custom') {
      input.resolution = resolution;
    } else {
      input.width = roundToMultipleOf32(clampToRange(args.width!, 256, 2048));
      input.height = roundToMultipleOf32(clampToRange(args.height!, 256, 2048));
    }

    if (inputImages.length > 0) {
      input.input_images = inputImages;
    }

    if (args.seed !== undefined) {
      input.seed = args.seed;
    }

    const startResponse = await fetch('https://api.replicate.com/v1/models/black-forest-labs/flux-2-max/predictions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ input }),
    });

    if (!startResponse.ok) {
      const errorBody = await startResponse.json().catch(() => null);
      if (errorBody && typeof errorBody.detail === 'string') {
        throw new Error(`Failed to start prediction: ${startResponse.status} ${startResponse.statusText} - ${errorBody.detail}`);
      }
      throw new Error(`Failed to start prediction: ${startResponse.status} ${startResponse.statusText}`);
    }

    const prediction = await startResponse.json();
    const predictionId = prediction.id;
    const started = new Date().toISOString();

    let currentPrediction = prediction;
    const timeout = 300000;
    const startTime = Date.now();

    while (!['succeeded', 'failed', 'canceled'].includes(currentPrediction.status)) {
      if (Date.now() - startTime > timeout) {
        throw new Error('Prediction timed out after 5 minutes');
      }

      await sleep(2000);
      currentPrediction = await pollPredictionStatus(predictionId, token);
    }

    if (currentPrediction.status === 'failed' || currentPrediction.status === 'canceled') {
      const error = currentPrediction.error || 'Unknown error';
      throw new Error(`Prediction ${currentPrediction.status}: ${error}`);
    }

    let outputUrl: string;
    if (typeof currentPrediction.output === 'string') {
      outputUrl = currentPrediction.output;
    } else if (Array.isArray(currentPrediction.output) && currentPrediction.output.length > 0) {
      outputUrl = currentPrediction.output[0];
    } else {
      throw new Error('No output URL found in prediction response');
    }

    const baseName = predictionId ? `replicate-flux-image-${predictionId}` : `replicate-flux-image-${Date.now()}`;
    const outputFileName = `${baseName}.${outputFormat}`;
    const outputPath = join(context.directory, 'replicate-output', outputFileName);

    const { size } = await downloadImage(outputUrl, outputPath);
    const completed = new Date().toISOString();

    const result = {
      id: predictionId,
      status: currentPrediction.status,
      url: outputUrl,
      path: outputPath,
      size,
      started,
      completed,
    };

    return JSON.stringify(result);
  },
});
