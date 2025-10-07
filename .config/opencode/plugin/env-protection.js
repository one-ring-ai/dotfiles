export const EnvProtection = async ({ client, $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "read" && output.args.filePath.endsWith("/.env")) {
        throw new Error("Do not read .env files")
      }
    }
  }
}