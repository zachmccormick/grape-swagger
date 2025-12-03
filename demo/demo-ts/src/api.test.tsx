/**
 * Integration tests for the generated hey-api SDK and React Query hooks
 *
 * These tests verify:
 * 1. Type-safe SDK functions work correctly
 * 2. React Query hooks are properly generated
 * 3. The OpenAPI spec produces valid TypeScript types
 */
import { describe, it, expect, beforeAll } from "vitest";
import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider, useQuery } from "@tanstack/react-query";
import React from "react";

// Import generated SDK and types
import { client } from "./generated/client.gen";
import * as sdk from "./generated/sdk.gen";
import type * as types from "./generated/types.gen";

// Import generated React Query options
import {
  getApiV1PetsOptions,
  getApiV1PetsQueryKey,
  getApiV1UsersOptions,
  getApiV1OrdersOptions,
  getApiV1PublicHealthOptions,
  getApiV1PublicInfoOptions,
} from "./generated/@tanstack/react-query.gen";

const API_BASE_URL = "http://localhost:3000";

// Create a wrapper with QueryClient for testing hooks
function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    );
  };
}

describe("Generated SDK", () => {
  beforeAll(() => {
    // Configure the client with the base URL
    client.setConfig({
      baseUrl: API_BASE_URL,
    });
  });

  describe("Type Safety", () => {
    it("generates proper types for Pet entity", () => {
      // This is a compile-time check - if types are wrong, TypeScript will error
      const pet: types.V1EntitiesPet = {
        id: 1,
        name: "Buddy",
        pet_type: "dog",
        birth_date: "2020-01-15",
        weight: 25.5,
        created_at: "2024-01-01T00:00:00Z",
        updated_at: "2024-01-01T00:00:00Z",
      };

      expect(pet.name).toBe("Buddy");
      expect(pet.pet_type).toBe("dog");
    });

    it("generates proper types for Dog subtype with breed", () => {
      // V1EntitiesDog extends V1EntitiesPet with dog-specific fields
      const dog: types.V1EntitiesDog = {
        id: 1,
        name: "Buddy",
        pet_type: "dog",
        birth_date: null,
        weight: 25.5,
        created_at: "2024-01-01T00:00:00Z",
        updated_at: "2024-01-01T00:00:00Z",
        breed: "Golden Retriever",
        is_trained: true,
        favorite_toy: "tennis ball",
      };

      expect(dog.breed).toBe("Golden Retriever");
      expect(dog.is_trained).toBe(true);
    });

    it("generates proper types for User entity", () => {
      const user: types.V1EntitiesUser = {
        id: 1,
        email: "test@example.com",
        name: "Test User",
        role: "user",
        is_active: true,
        avatar_url: null,
        bio: null,
        created_at: "2024-01-01T00:00:00Z",
      };

      expect(user.email).toBe("test@example.com");
      expect(user.role).toBe("user");
    });

    it("generates proper types for Order entity", () => {
      const order: types.V1EntitiesOrder = {
        id: 1,
        order_number: "ORD-001",
        status: "pending",
        total_cents: 4999,
        currency: "USD",
        customer: { id: 1, name: "John Doe", email: "john@example.com" },
        items: [
          { id: 1, product_name: "Widget", quantity: 2, unit_price_cents: 2499, sku: null },
        ],
        shipping_address: "123 Main St",
        notes: null,
        created_at: "2024-01-01T00:00:00Z",
        updated_at: "2024-01-01T00:00:00Z",
      };

      expect(order.status).toBe("pending");
      expect(order.currency).toBe("USD");
    });

    it("generates enum types for pet_type", () => {
      // Pet type should be a union of allowed values
      const dogType: types.V1EntitiesPet["pet_type"] = "dog";
      const catType: types.V1EntitiesPet["pet_type"] = "cat";
      const birdType: types.V1EntitiesPet["pet_type"] = "bird";

      expect(["dog", "cat", "bird"]).toContain(dogType);
      expect(["dog", "cat", "bird"]).toContain(catType);
      expect(["dog", "cat", "bird"]).toContain(birdType);
    });

    it("generates enum types for order status", () => {
      const statuses: types.V1EntitiesOrder["status"][] = [
        "pending",
        "confirmed",
        "processing",
        "shipped",
        "delivered",
        "cancelled",
      ];

      expect(statuses).toHaveLength(6);
    });
  });

  describe("SDK Functions", () => {
    it("exports SDK functions for all endpoints", () => {
      // Verify key SDK functions exist
      expect(sdk.getApiV1Pets).toBeDefined();
      expect(sdk.postApiV1Pets).toBeDefined();
      expect(sdk.getApiV1PetsId).toBeDefined();
      expect(sdk.getApiV1Users).toBeDefined();
      expect(sdk.postApiV1Users).toBeDefined();
      expect(sdk.getApiV1Orders).toBeDefined();
      expect(sdk.postApiV1Orders).toBeDefined();
      expect(sdk.getApiV1PublicHealth).toBeDefined();
      expect(sdk.getApiV1PaymentMethods).toBeDefined();
    });
  });

  describe("React Query Options", () => {
    it("generates query options for GET endpoints", () => {
      const petsOptions = getApiV1PetsOptions();
      expect(petsOptions.queryKey).toBeDefined();
      expect(petsOptions.queryFn).toBeDefined();

      const usersOptions = getApiV1UsersOptions();
      expect(usersOptions.queryKey).toBeDefined();

      const ordersOptions = getApiV1OrdersOptions();
      expect(ordersOptions.queryKey).toBeDefined();
    });

    it("generates proper query keys", () => {
      const key = getApiV1PetsQueryKey();
      expect(key).toHaveLength(1);
      expect(key[0]._id).toBe("getApiV1Pets");
    });

    it("includes query params in query key", () => {
      const key = getApiV1PetsQueryKey({
        query: { type: "dog", limit: 10 },
      });
      expect(key[0].query).toEqual({ type: "dog", limit: 10 });
    });
  });
});

describe("React Query Integration", () => {
  beforeAll(() => {
    client.setConfig({
      baseUrl: API_BASE_URL,
    });
  });

  it("can use query options with useQuery", async () => {
    // This test verifies the hook structure is correct
    // In a real integration test, you would mock or run against a live server
    const wrapper = createWrapper();

    const { result } = renderHook(
      () =>
        useQuery({
          ...getApiV1PublicHealthOptions(),
          enabled: false, // Don't actually make the request
        }),
      { wrapper }
    );

    expect(result.current.isLoading).toBe(false);
    expect(result.current.isFetching).toBe(false);
    expect(result.current.data).toBeUndefined();
  });
});

describe("Request Body Types", () => {
  it("generates proper request body types for POST endpoints", () => {
    // Verify the request body type for creating a pet
    const createPetRequest: types.PostApiV1PetsData["body"] = {
      name: "Max",
      pet_type: "dog",
      breed: "Labrador",
    };

    expect(createPetRequest.name).toBe("Max");
    expect(createPetRequest.pet_type).toBe("dog");
  });

  it("generates proper request body types for creating users", () => {
    const createUserRequest: types.PostApiV1UsersData["body"] = {
      email: "new@example.com",
      name: "New User",
      password: "secret123",
      role: "user",
    };

    expect(createUserRequest.email).toBe("new@example.com");
    expect(createUserRequest.role).toBe("user");
  });
});

describe("Path Parameter Types", () => {
  it("generates proper path parameter types", () => {
    const pathParams: types.GetApiV1PetsIdData["path"] = {
      id: 123,
    };

    expect(pathParams.id).toBe(123);
  });
});

describe("Query Parameter Types", () => {
  it("generates proper query parameter types for pets", () => {
    const queryParams: types.GetApiV1PetsData["query"] = {
      type: "dog",
      limit: 20,
      offset: 0,
    };

    expect(queryParams.type).toBe("dog");
    expect(queryParams.limit).toBe(20);
  });

  it("generates proper query parameter types for users", () => {
    const queryParams: types.GetApiV1UsersData["query"] = {
      role: "admin",
      active_only: true,
      limit: 50,
    };

    expect(queryParams.role).toBe("admin");
    expect(queryParams.active_only).toBe(true);
  });
});
