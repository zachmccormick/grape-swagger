import { defineConfig } from "@hey-api/openapi-ts";

export default defineConfig({
  input: "./swagger.json",
  output: {
    path: "./src/generated",
    format: "prettier",
  },
  plugins: [
    "@hey-api/typescript",
    "@hey-api/client-fetch",
    "@hey-api/sdk",
    {
      name: "@tanstack/react-query",
      queryOptions: true,
      queryKeys: true,
    },
  ],
});
