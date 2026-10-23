import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema({
      extend: z.object({
        product: z
          .object({
            key: z.string(),
            name: z.string(),
            status: z.string(),
            builds: z.array(z.object({ build: z.string(), em: z.string() })),
            date: z.string().optional(),
            supports: z.array(z.string()),
          })
          .optional(),
      }),
    }),
  }),
};
