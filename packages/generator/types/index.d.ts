// Type declarations for @budhash/zap-sh.

export interface GenerateOptions {
  /** Template name: "basic" | "enhanced". */
  template: string;
  /** Project name; becomes {{app}}. Must match /^[a-zA-Z0-9_-]+$/. */
  project: string;
  /** Extra {{key}} substitutions. Insertion order is significant (see SPEC §4). */
  variables?: Record<string, string | number>;
  /** License code: "mit" | "apache" | "gpl" (case-insensitive). */
  license?: string;
  /** Pins {{year}}. Defaults to the current year if omitted (see SPEC §6). */
  year?: string | number;
  /** Output filename. Does not affect the generated content. */
  output?: string;
}

export interface GenerateResult {
  /** Suggested filename (`output` if given, else `<project>.sh`). */
  filename: string;
  /** The generated script, byte-for-byte identical to `zap-sh init`. */
  content: string;
}

/** Generate a zap-sh script. Throws on invalid template, project, or license. */
export function generate(opts: GenerateOptions): GenerateResult;

/** Replace each `{{key}}` with its value, in order, across the whole buffer. */
export function substitute(content: string, pairs: Array<[string, string]>): string;

/** Extract a `##( name` … `##) name` section (markers included), or null. */
export function extractSection(templateText: string, name: string): string | null;

/** Available template names. */
export function listTemplates(): string[];

/** Available license codes (lowercased, sorted). */
export function listLicenses(): string[];

declare const _default: {
  generate: typeof generate;
  substitute: typeof substitute;
  extractSection: typeof extractSection;
  listTemplates: typeof listTemplates;
  listLicenses: typeof listLicenses;
};
export default _default;
