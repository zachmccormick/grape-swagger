# grape-swagger TypeScript SDK Demo

This folder contains a TypeScript SDK with React Query hooks generated from the grape-swagger OpenAPI 3.1.0 demo API using [@hey-api/openapi-ts](https://heyapi.dev/).

## Setup

```bash
npm install
```

## Generate SDK

The SDK generation is a two-step process:

### Step 1: Generate OpenAPI Spec from Rails

```bash
npm run generate:spec
```

This runs a Rails runner to generate `swagger.json` from the demo Grape API.

### Step 2: Generate TypeScript SDK

```bash
npm run generate
```

This uses `@hey-api/openapi-ts` to generate:
- TypeScript types from OpenAPI schemas
- Type-safe SDK functions for all endpoints
- TanStack React Query hooks with query options and keys

### Or run both steps together

```bash
npm run generate:all
```

## Run Tests

The tests are type-safety integration tests that verify the generated SDK compiles correctly:

```bash
npm test
```

These tests validate that:
- Generated types match the OpenAPI spec
- SDK functions are properly typed
- React Query hooks are generated correctly

### Integration Testing with Live Server

To run tests against a live server, start the Rails demo first:

```bash
cd ..
bundle exec rails s -p 3000
```

Then run the tests (enable the live request tests by removing `enabled: false` in the test file).

## Type Checking

```bash
npm run typecheck
```

## What's Generated

The `@hey-api/openapi-ts` library generates the following in `src/generated/`:

### `types.gen.ts`
TypeScript types for all schemas, including:
- **Entity types**: `V1EntitiesPet`, `V1EntitiesUser`, `V1EntitiesOrder`, etc.
- **Discriminated unions**: `V1EntitiesDog`, `V1EntitiesCat`, `V1EntitiesBird` (polymorphic pet types)
- **Request/Response types**: Properly typed path parameters, query parameters, and request bodies

### `sdk.gen.ts`
Type-safe SDK functions for all API endpoints:
```typescript
import * as sdk from "./generated/sdk.gen";

// Type-safe API calls
const pets = await sdk.getApiV1Pets({ query: { type: "dog", limit: 10 } });
const pet = await sdk.postApiV1Pets({ body: { name: "Max", pet_type: "dog", breed: "Labrador" } });
```

### `client.gen.ts`
Pre-configured fetch client that can be customized:
```typescript
import { client } from "./generated/client.gen";

client.setConfig({
  baseUrl: "http://localhost:3000",
  headers: { Authorization: "Bearer token" },
});
```

### `@tanstack/react-query.gen.ts`
React Query hooks and utilities:
```typescript
import { useQuery } from "@tanstack/react-query";
import { getApiV1PetsOptions, getApiV1PetsQueryKey } from "./generated/@tanstack/react-query.gen";

// In a React component
const { data, isLoading } = useQuery(getApiV1PetsOptions({ query: { type: "dog" } }));

// Get query key for cache invalidation
const queryKey = getApiV1PetsQueryKey({ query: { type: "dog" } });
```

## What's Demonstrated

The tests demonstrate that the generated TypeScript SDK provides:

- **Type-safe API calls**: All endpoints have properly typed request and response bodies
- **Discriminated unions**: Polymorphic types (Pet -> Dog/Cat/Bird) with proper discriminators
- **Enum types**: Pet types, order statuses, currencies, and roles are typed as string unions
- **Path parameters**: URL template parameters like `{id}` are type-checked
- **Query parameters**: Optional query parameters with proper types
- **Request body validation**: TypeScript catches missing required fields at compile time
- **React Query integration**: Auto-generated query options and cache keys

## API Coverage

The tests cover the following API groups:

- **Public endpoints**: Health check, API info, email validation
- **Pets API**: List, create (dog, cat, bird), get by ID, update, delete
- **Users API**: List, create, get current user
- **Orders API**: List, create, get by ID, update status
- **Payment Methods API**: List, add credit card
- **Files API**: Upload/download with multipart form data
- **Advanced Features API**: Cookie params, deprecated params, async jobs with callbacks, links

## Configuration

The SDK generation is configured in `openapi-ts.config.ts`:

```typescript
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
```
