#!/usr/bin/env node
/**
 * quantum_json_preflight_test.ts
 * ──────────────────────────────────────────────────────────────────────────
 * TypeScript preflight test engine for the Quantum SDUI build pipeline.
 *
 * Inspired by: lib/test/generated/sdui_json_runtime_behavior_test/
 *              sdui_json_runtime_behavior_test.dart
 *
 * PURPOSE
 *   Catch the "black screen" class of Flutter rendering failures BEFORE
 *   Flutter runs by validating the JSON output produced by `npm run build:sdui`.
 *
 *   Three validation layers (matching the Dart suite's design):
 *     1. Node Shape   — every node has a valid `type`, required props, children
 *     2. Assertions   — deep path checks against expected JSON snapshots
 *     3. File Checks  — discover page files, find root route, guard meta shape
 *
 * USAGE
 *   # Run built-in test cases (no args needed):
 *   npx tsx lib/interop/typescript/quantum_json_preflight_test.ts
 *
 *   # Run against a specific project root / kernel.json:
 *   npx tsx lib/interop/typescript/quantum_json_preflight_test.ts <projectRoot> [kernelJson]
 *
 * EXIT CODES
 *   0 = all tests passed
 *   1 = one or more tests failed
 *
 * TEST CASE FORMAT
 *   {
 *     __meta: { id, title, priority?, tags?, description? },
 *     input:         SduiNode JSON — the node under test
 *     expected?:     expected serialized shape (snapshot assertion)
 *     expectError?:  { messageContains: string } — expect a validation failure
 *     assertions?:   [{ path, equals, description? }]
 *     nodeChecks?:   [{ path, hasType?, hasProps?, notEmpty? }]
 *   }
 * ──────────────────────────────────────────────────────────────────────────
 */

import fs from 'fs';
import path from 'path';

/* ============================================================
 * TYPE DEFINITIONS
 * ============================================================ */

/** All valid Quantum node types the Dart runtime can render */
type KnownSduiNodeType =
  // Catalog roots
  | 'box' | 'action' | 'field' | 'text' | 'media' | 'data' | 'portal'
  | 'hook' | 'control' | 'system' | 'canvas' | 'decoration' | 'chart'
  | 'stream' | 'collab' | 'component' | 'visual' | 'page'
  // box subtypes
  | 'box:scroll' | 'box:row' | 'box:col' | 'box:grid' | 'box:stack'
  | 'box:layer' | 'box:masonry' | 'box:matrix' | 'box:surface' | 'box:shell'
  | 'box:responsive' | 'box:viewport' | 'box:wrap' | 'box:expanded'
  | 'box:flexible' | 'box:safe' | 'box:sticky' | 'box:split' | 'box:morph'
  | 'box:measure' | 'box:aspect' | 'box:builder' | 'box:virtual_grid'
  // action subtypes
  | 'action:button' | 'action:chip' | 'action:icon_button' | 'action:link'
  | 'action:tap' | 'action:press' | 'action:long_press' | 'action:double_tap'
  | 'action:gesture' | 'action:hover' | 'action:focus' | 'action:pointer'
  | 'action:raw_pointer' | 'action:viewport'
  // text subtypes
  | 'text:h1' | 'text:h2' | 'text:h3' | 'text:label' | 'text:code' | 'text:rich'
  // field subtypes
  | 'field:text' | 'field:email' | 'field:password' | 'field:number'
  | 'field:textarea' | 'field:multiline' | 'field:search' | 'field:toggle'
  | 'field:checkbox' | 'field:radio' | 'field:slider' | 'field:rich_text'
  | 'field:tel' | 'field:url' | 'field:cell'
  // media subtypes
  | 'media:icon' | 'media:avatar' | 'media:video' | 'media:audio'
  | 'media:image' | 'media:svg_path' | 'media:path' | 'media:camera'
  | 'media:stream' | 'media:canvas_video' | 'media:webrtc' | 'media:audio_visualizer'
  // portal subtypes
  | 'portal:modal' | 'portal:drawer' | 'portal:toast' | 'portal:tooltip'
  | 'portal:dialog' | 'portal:sheet' | 'portal:overlay' | 'portal:sidebar'
  | 'portal:popover' | 'portal:menu' | 'portal:dropdown' | 'portal:alert'
  // component / template / macro
  | 'component:define' | 'component:use' | 'component:instance'
  | 'component:render' | 'component:scoped' | 'component:link'
  | 'macro'
  // custom node types (from defineNodeType)
  | 'page_shell' | 'page_section'
  // surface extensions
  | 'surface:page' | 'surface:shell' | 'surface:section' | 'surface:panel'
  | 'surface:hero' | 'surface:metric' | 'surface:feed' | 'surface:board'
  // sentinel
  | 'empty';

/** Template node types follow 'template:<name>' pattern */
type TemplateLikeType = `template:${string}`;

/** Combined valid type */
type ValidNodeType = KnownSduiNodeType | TemplateLikeType;

/** A Quantum SDUI node as it appears in JSON */
interface SduiNodeJson {
  type?: string;
  kind?: string;
  props?: Record<string, unknown>;
  children?: SduiNodeJson[];
  slots?: Record<string, SduiNodeJson>;
  style?: string;
  name?: string;
  slot?: string;
  $if?: unknown;
  $repeat?: unknown;
  $switch?: unknown;
  [key: string]: unknown;
}

/** A single path assertion */
interface PathAssertion {
  /** Dot-separated path into the node, e.g. "props.text" or "children[0].type" */
  path: string;
  /** Expected value (deep equality) */
  equals: unknown;
  description?: string;
}

/** A structural node check */
interface NodeCheck {
  /** Path to the node to check */
  path: string;
  /** Expected type string */
  hasType?: ValidNodeType | string;
  /** Props that must be present (keys) */
  hasProps?: string[];
  /** Node must have at least one child or slot */
  notEmpty?: boolean;
}

/** Meta information for a test case */
interface TestCaseMeta {
  id: string;
  title: string;
  priority?: 'critical' | 'high' | 'normal' | 'low';
  tags?: string[];
  description?: string;
}

/** A single preflight test case */
interface PreflightTestCase {
  __meta: TestCaseMeta;
  /** The SDUI node JSON to validate */
  input: SduiNodeJson;
  /** Optional snapshot: the expected serialized output after normalization */
  expected?: Record<string, unknown>;
  /** If set, the test expects validation to FAIL with this message */
  expectError?: { messageContains: string };
  /** Deep path equality assertions on the input node */
  assertions?: PathAssertion[];
  /** Structural checks on specific nodes within the tree */
  nodeChecks?: NodeCheck[];
}

/** Result of a single test case */
interface TestResult {
  id: string;
  title: string;
  passed: boolean;
  failures: string[];
  warnings: string[];
}

/** Overall test run summary */
interface TestRunSummary {
  total: number;
  passed: number;
  failed: number;
  results: TestResult[];
}

/* ============================================================
 * VALIDATION UTILITIES
 * ============================================================ */

/**
 * Container-like roots that should have children or slots to render anything.
 * Matches the Dart preflight checker's heuristics.
 */
const CONTAINER_TYPES = new Set<string>([
  'box', 'page', 'layout', 'template', 'shell', 'row', 'col', 'grid',
  'stack', 'layer', 'masonry', 'matrix', 'responsive', 'surface',
  'box:scroll', 'box:row', 'box:col', 'box:grid', 'box:stack',
  'box:layer', 'box:surface', 'box:shell', 'box:responsive', 'box:wrap',
  'box:expanded', 'box:flexible',
  'page_shell', 'page_section',
]);

/** Text-like nodes that require props.text */
const TEXT_TYPES = new Set<string>(['text', 'text:h1', 'text:h2', 'text:h3', 'text:label', 'text:code', 'text:rich']);

/**
 * Types that are explicitly valid empty containers or sentinels.
 * Don't warn about these having no children.
 */
const VALID_EMPTY_TYPES = new Set<string>([
  'empty', 'hook', 'hook:store', 'hook:slice', 'hook:atom', 'hook:bridge',
  'hook:effect', 'hook:mount', 'hook:unmount', 'hook:interval', 'hook:lifecycle',
  'hook:memo', 'hook:observable', 'hook:ref', 'hook:scope', 'hook:change',
  'hook:guard', 'hook:delegate', 'hook:error_boundary',
  'system:haptic', 'system:notification', 'system:clipboard', 'system:share',
  'system:geo', 'system:sensor', 'system:timer', 'system:ticker',
  'system:debounce', 'system:throttle',
  'component:use', 'component:link',
  'macro',
]);

/**
 * Returns true if the type string is a valid Quantum node type.
 * Template types (template:*) are always valid.
 */
function isValidNodeType(type: string): boolean {
  if (!type) return false;
  if (type.startsWith('template:')) return true;
  const KNOWN: KnownSduiNodeType[] = [
    'box', 'action', 'field', 'text', 'media', 'data', 'portal',
    'hook', 'control', 'system', 'canvas', 'decoration', 'chart',
    'stream', 'collab', 'component', 'visual', 'page',
    'box:scroll', 'box:row', 'box:col', 'box:grid', 'box:stack',
    'box:layer', 'box:masonry', 'box:matrix', 'box:surface', 'box:shell',
    'box:responsive', 'box:viewport', 'box:wrap', 'box:expanded',
    'box:flexible', 'box:safe', 'box:sticky', 'box:split', 'box:morph',
    'box:measure', 'box:aspect', 'box:builder', 'box:virtual_grid',
    'action:button', 'action:chip', 'action:icon_button', 'action:link',
    'action:tap', 'action:press', 'action:long_press', 'action:double_tap',
    'action:gesture', 'action:hover', 'action:focus', 'action:pointer',
    'action:raw_pointer', 'action:viewport',
    'text:h1', 'text:h2', 'text:h3', 'text:label', 'text:code', 'text:rich',
    'field:text', 'field:email', 'field:password', 'field:number',
    'field:textarea', 'field:multiline', 'field:search', 'field:toggle',
    'field:checkbox', 'field:radio', 'field:slider', 'field:rich_text',
    'field:tel', 'field:url', 'field:cell',
    'media:icon', 'media:avatar', 'media:video', 'media:audio',
    'media:svg_path', 'media:path', 'media:camera',
    'media:stream', 'media:canvas_video', 'media:webrtc', 'media:audio_visualizer',
    'portal:modal', 'portal:drawer', 'portal:toast', 'portal:tooltip',
    'portal:dialog', 'portal:sheet', 'portal:overlay', 'portal:sidebar',
    'portal:popover', 'portal:menu', 'portal:dropdown', 'portal:alert',
    'portal:action_sheet', 'portal:anchored_floating', 'portal:centered',
    'portal:confirm', 'portal:context_menu', 'portal:context_panel',
    'portal:docked', 'portal:edge_attached', 'portal:expandable_inline',
    'portal:flyout', 'portal:form_modal', 'portal:full_page_sheet',
    'portal:full_screen', 'portal:full_screen_surface',
    'portal:immersive_editor', 'portal:inline_details', 'portal:inline_editor',
    'portal:inspector', 'portal:lightbox', 'portal:left_panel', 'portal:menu',
    'portal:mobile_sheet', 'portal:navigation_rail', 'portal:nonModal',
    'portal:non_modal', 'portal:overlay_entry', 'portal:persistent_drawer',
    'portal:persistent_panel', 'portal:popup_modal', 'portal:right_panel',
    'portal:side_sheet', 'portal:temporary_overlay', 'portal:utility_panel',
    'portal:window',
    'hook:atom', 'hook:bridge', 'hook:change', 'hook:delegate', 'hook:effect',
    'hook:error_boundary', 'hook:guard', 'hook:interval', 'hook:lifecycle',
    'hook:memo', 'hook:mount', 'hook:observable', 'hook:ref', 'hook:scope',
    'hook:slice', 'hook:store',
    'control:accordion', 'control:architecture', 'control:flow',
    'control:form_scope', 'control:machine', 'control:optimistic',
    'control:reducer', 'control:saga', 'control:stepper', 'control:tabs', 'control:tca',
    'system:async', 'system:clipboard', 'system:data_pipe', 'system:debounce',
    'system:download', 'system:geo', 'system:haptic', 'system:kinetic_pipe',
    'system:macro', 'system:notification', 'system:omega_macro', 'system:repeater',
    'system:sensor', 'system:share', 'system:store_provider', 'system:sync_scroll',
    'system:throttle', 'system:ticker', 'system:timer', 'system:upload', 'system:worker',
    'canvas:draw', 'canvas:plot', 'canvas:shader', 'canvas:shape',
    'decoration:badge', 'decoration:blur', 'decoration:border',
    'decoration:gradient', 'decoration:rich', 'decoration:ripple',
    'decoration:shadow', 'decoration:skeleton', 'decoration:span', 'decoration:text',
    'chart:line', 'chart:bar', 'chart:area', 'chart:pie', 'chart:donut',
    'chart:radar', 'chart:scatter', 'chart:bubble', 'chart:candlestick',
    'chart:funnel', 'chart:waterfall', 'chart:histogram', 'chart:gauge',
    'chart:sparkline', 'chart:treemap', 'chart:sankey',
    'stream:ws', 'stream:sse', 'stream:tick', 'stream:ring', 'stream:multiplex',
    'collab:presence', 'collab:cursor', 'collab:awareness', 'collab:lock', 'collab:patch',
    'component:define', 'component:use', 'component:instance',
    'component:render', 'component:scoped', 'component:link',
    'macro',
    'page_shell', 'page_section',
    'surface:page', 'surface:shell', 'surface:section', 'surface:panel',
    'surface:hero', 'surface:metric', 'surface:feed', 'surface:board',
    'empty',
  ];
  return (KNOWN as string[]).includes(type);
}

/**
 * Deeply resolves a dot-bracket path into a value.
 * Supports "props.text", "children[0].type", "slots.body.type" etc.
 */
function resolvePath(obj: unknown, pathStr: string): { found: boolean; value: unknown } {
  // Empty path → return the root object itself
  if (!pathStr || pathStr === 'root' || pathStr === '.') {
    return { found: true, value: obj };
  }
  // Tokenize: split on '.' and '[n]'
  const tokens = pathStr.replace(/\[(\d+)\]/g, '.$1').split('.').filter(Boolean);
  let current: unknown = obj;
  for (const token of tokens) {
    if (current === null || current === undefined) return { found: false, value: undefined };
    if (typeof current !== 'object') return { found: false, value: undefined };
    const key = token;
    if (!(key in (current as Record<string, unknown>))) return { found: false, value: undefined };
    current = (current as Record<string, unknown>)[key];
  }
  return { found: true, value: current };
}

/**
 * Deep equality check (JSON-safe).
 */
function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a === null || b === null) return false;
  if (typeof a !== typeof b) return false;
  if (typeof a !== 'object') return false;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) return false;
    return a.every((item, i) => deepEqual(item, (b as unknown[])[i]));
  }
  const aKeys = Object.keys(a as object).sort();
  const bKeys = Object.keys(b as object).sort();
  if (aKeys.join(',') !== bKeys.join(',')) return false;
  return aKeys.every(k =>
    deepEqual(
      (a as Record<string, unknown>)[k],
      (b as Record<string, unknown>)[k],
    ),
  );
}

/* ============================================================
 * NODE VALIDATOR
 * Mirrors the heuristics of quantum_json_preflight_test.ts (original)
 * and nodeIssues() in the original preflight script.
 * ============================================================ */

interface NodeIssue {
  path: string;
  severity: 'error' | 'warning';
  message: string;
}

function validateNodeTree(
  node: unknown,
  nodePath = 'root',
  seen = new Set<string>(),
): NodeIssue[] {
  const issues: NodeIssue[] = [];

  if (node === null || node === undefined) {
    issues.push({ path: nodePath, severity: 'error', message: 'node is null or undefined' });
    return issues;
  }

  // Arrays are treated as child lists — validate each item
  if (Array.isArray(node)) {
    if (node.length === 0) {
      issues.push({ path: nodePath, severity: 'warning', message: 'empty array — nothing to render' });
    }
    node.forEach((child, i) =>
      issues.push(...validateNodeTree(child, `${nodePath}[${i}]`, seen)),
    );
    return issues;
  }

  // Primitives can appear as text payloads — allow them
  if (typeof node !== 'object') return issues;

  const n = node as SduiNodeJson;
  const type = String(n.type ?? n.kind ?? '').trim();

  // Cycle guard using JSON key
  const key = JSON.stringify({ type, propsKeys: Object.keys(n.props ?? {}).sort() });
  if (seen.has(key)) return issues;
  seen.add(key);

  // ── Rule 1: type must be present ──────────────────────────────────────────
  if (!type) {
    issues.push({
      path: nodePath,
      severity: 'error',
      message: 'missing "type" field — Dart runtime cannot render this node (will show black/empty)',
    });
    return issues; // nothing else to check without a type
  }

  // ── Rule 2: type must be a known valid type ────────────────────────────────
  if (!isValidNodeType(type)) {
    issues.push({
      path: nodePath,
      severity: 'error',
      message: `unknown type "${type}" — not in Quantum catalog. ` +
        `Dart DDC has no widget for this type and will render a black screen. ` +
        `Common mistake: using "slot" instead of "box" with a name prop.`,
    });
  }

  // ── Rule 3: text-like nodes need props.text ────────────────────────────────
  if (TEXT_TYPES.has(type)) {
    const textVal = n.props?.text ?? n.props?.value;
    if (typeof textVal !== 'string' || !textVal.trim()) {
      issues.push({
        path: nodePath,
        severity: 'error',
        message: `text node (${type}) is missing props.text — will render blank`,
      });
    }
  }

  // ── Rule 4: container nodes should have children or slots ──────────────────
  if (CONTAINER_TYPES.has(type) && !VALID_EMPTY_TYPES.has(type)) {
    const children = Array.isArray(n.children) ? n.children : [];
    const slotKeys = n.slots ? Object.keys(n.slots) : [];
    if (children.length === 0 && slotKeys.length === 0) {
      // This is a warning, not an error — an empty box is valid in layouts
      issues.push({
        path: nodePath,
        severity: 'warning',
        message: `container (${type}) has no children or slots — will render as empty space`,
      });
    }
  }

  // ── Rule 5: 'slot' type is explicitly invalid ──────────────────────────────
  if (type === 'slot') {
    issues.push({
      path: nodePath,
      severity: 'error',
      message: `"slot" is not a valid Dart-renderable node type. ` +
        `Replace with: box with props.name = "<slot_name>" and props.__slotOutlet = true`,
    });
  }

  // ── Recurse into children ──────────────────────────────────────────────────
  if (Array.isArray(n.children)) {
    n.children.forEach((child, i) =>
      issues.push(...validateNodeTree(child, `${nodePath}.children[${i}]`, seen)),
    );
  }

  // ── Recurse into slots ─────────────────────────────────────────────────────
  if (n.slots && typeof n.slots === 'object') {
    for (const [slotName, slotNode] of Object.entries(n.slots)) {
      issues.push(...validateNodeTree(slotNode, `${nodePath}.slots.${slotName}`, seen));
    }
  }

  return issues;
}

/* ============================================================
 * TEST RUNNER
 * ============================================================ */

function runTestCase(tc: PreflightTestCase): TestResult {
  const result: TestResult = {
    id: tc.__meta.id,
    title: tc.__meta.title,
    passed: true,
    failures: [],
    warnings: [],
  };

  const addFailure = (msg: string) => {
    result.passed = false;
    result.failures.push(msg);
  };
  const addWarning = (msg: string) => result.warnings.push(msg);

  // ── Layer 1: Node shape validation ────────────────────────────────────────
  const nodeIssues = validateNodeTree(tc.input);
  const errors = nodeIssues.filter(i => i.severity === 'error');
  const warnings = nodeIssues.filter(i => i.severity === 'warning');

  warnings.forEach(w => addWarning(`[${w.path}] ${w.message}`));

  if (tc.expectError) {
    // Negative test case: expect validation to produce an error
    const matched = errors.some(e =>
      e.message.toLowerCase().includes(tc.expectError!.messageContains.toLowerCase()),
    );
    if (!matched) {
      addFailure(
        `Expected a validation error containing "${tc.expectError.messageContains}" ` +
        `but got: ${errors.map(e => e.message).join(' | ') || '(no errors)'}`,
      );
    }
    // If we expected an error and got it, skip further checks
    return result;
  } else {
    // Positive test case: should have no errors
    errors.forEach(e => addFailure(`[${e.path}] ${e.message}`));
  }

  // ── Layer 2: Snapshot assertion (expected) ─────────────────────────────────
  if (tc.expected !== undefined) {
    if (!deepEqual(tc.input, tc.expected)) {
      // Find the first differing key for a helpful message
      const inputKeys = Object.keys(tc.input);
      const expKeys = Object.keys(tc.expected);
      const allKeys = new Set([...inputKeys, ...expKeys]);
      for (const k of allKeys) {
        const iv = (tc.input as Record<string, unknown>)[k];
        const ev = tc.expected[k];
        if (!deepEqual(iv, ev)) {
          addFailure(
            `Snapshot mismatch at key "${k}": ` +
            `expected ${JSON.stringify(ev)}, got ${JSON.stringify(iv)}`,
          );
        }
      }
    }
  }

  // ── Layer 3: Deep path assertions ─────────────────────────────────────────
  if (tc.assertions) {
    for (const assertion of tc.assertions) {
      const { found, value } = resolvePath(tc.input, assertion.path);
      if (!found) {
        addFailure(
          `Assertion "${assertion.description ?? assertion.path}": ` +
          `path "${assertion.path}" not found in input`,
        );
        continue;
      }
      if (!deepEqual(value, assertion.equals)) {
        addFailure(
          `Assertion "${assertion.description ?? assertion.path}": ` +
          `at path "${assertion.path}" expected ${JSON.stringify(assertion.equals)}, ` +
          `got ${JSON.stringify(value)}`,
        );
      }
    }
  }

  // ── Layer 4: Structural node checks ───────────────────────────────────────
  if (tc.nodeChecks) {
    for (const check of tc.nodeChecks) {
      const { found, value } = resolvePath(tc.input, check.path);
      if (!found) {
        addFailure(`NodeCheck at "${check.path}": path not found`);
        continue;
      }
      const node = value as SduiNodeJson | null;
      if (!node || typeof node !== 'object' || Array.isArray(node)) {
        addFailure(`NodeCheck at "${check.path}": not a node object`);
        continue;
      }

      if (check.hasType !== undefined) {
        const actualType = String(node.type ?? node.kind ?? '');
        if (actualType !== check.hasType) {
          addFailure(
            `NodeCheck at "${check.path}": expected type "${check.hasType}", got "${actualType}"`,
          );
        }
      }

      if (check.hasProps) {
        const missingProps = check.hasProps.filter(
          p => !(node.props && p in node.props),
        );
        if (missingProps.length > 0) {
          addFailure(
            `NodeCheck at "${check.path}": missing required props: ${missingProps.join(', ')}`,
          );
        }
      }

      if (check.notEmpty) {
        const childCount = Array.isArray(node.children) ? node.children.length : 0;
        const slotCount = node.slots ? Object.keys(node.slots).length : 0;
        if (childCount === 0 && slotCount === 0) {
          addFailure(`NodeCheck at "${check.path}": expected non-empty node but has no children or slots`);
        }
      }
    }
  }

  return result;
}

function runPreflightTests(cases: PreflightTestCase[]): TestRunSummary {
  const results = cases.map(tc => {
    try {
      return runTestCase(tc);
    } catch (err) {
      return {
        id: tc.__meta.id,
        title: tc.__meta.title,
        passed: false,
        failures: [`Unexpected runner error: ${(err as Error).message}`],
        warnings: [],
      } satisfies TestResult;
    }
  });

  return {
    total: results.length,
    passed: results.filter(r => r.passed).length,
    failed: results.filter(r => !r.passed).length,
    results,
  };
}

/* ============================================================
 * FILE ROUTER CHECKS
 * (validates generated assets/ directory, like the original script)
 * ============================================================ */

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === 'object' && !Array.isArray(v);
}

function normalizePath(p: string): string {
  return String(p || '').replace(/\\/g, '/').replace(/\/+/g, '/');
}

function walkFiles(dir: string, relBase = ''): Array<{ abs: string; rel: string; name: string }> {
  const out: Array<{ abs: string; rel: string; name: string }> = [];
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, entry.name);
    const rel = relBase ? path.posix.join(relBase, entry.name) : entry.name;
    if (entry.isDirectory()) out.push(...walkFiles(abs, rel));
    else out.push({ abs, rel: normalizePath(rel), name: entry.name });
  }
  return out;
}

function isPageFile(name: string): boolean {
  return /^(page|index|route)\.(json|ya?ml)$/i.test(name) || /^\[.*\]\.(json|ya?ml)$/i.test(name);
}

function isLayoutFile(name: string): boolean {
  return name === '_layout.json' || name === '_layout.yaml' || name === '_layout.yml';
}

function flatStringMapIssues(meta: unknown, prefix: string): string[] {
  const issues: string[] = [];
  if (!isPlainObject(meta)) return issues;
  for (const [k, v] of Object.entries(meta)) {
    if (k === 'custom' && isPlainObject(v)) {
      for (const [ck, cv] of Object.entries(v)) {
        if (cv !== null && typeof cv !== 'string') {
          issues.push(`${prefix}.custom.${ck} must be a flat string (Dart DDC type check)`);
        }
      }
    } else if (v !== null && typeof v !== 'string') {
      issues.push(`${prefix}.${k} should be a string (got ${typeof v})`);
    }
  }
  return issues;
}

interface FileRouterCheckResult {
  passed: boolean;
  report: string[];
  blocking: string[];
}

function runFileRouterChecks(projectRoot: string, kernelJsonPath: string): FileRouterCheckResult {
  const report: string[] = [];
  const blocking: string[] = [];

  report.push(`[FileRouter] Project root: ${projectRoot}`);
  report.push(`[FileRouter] Kernel JSON:  ${kernelJsonPath}`);

  if (!fs.existsSync(kernelJsonPath)) {
    blocking.push(`kernel.json not found at ${kernelJsonPath} — run npm run build:sdui first`);
    return { passed: false, report, blocking };
  }

  let kernelJson: Record<string, unknown>;
  try {
    kernelJson = JSON.parse(fs.readFileSync(kernelJsonPath, 'utf8'));
  } catch (e) {
    blocking.push(`kernel.json is invalid JSON: ${(e as Error).message}`);
    return { passed: false, report, blocking };
  }

  const pagesDir = String(
    (kernelJson as any)?.router?.pagesDir ??
    (kernelJson as any)?.pagesDir ??
    (kernelJson as any)?.boot?.pagesDir ??
    'pages',
  );

  const assetsRoot = path.dirname(path.dirname(kernelJsonPath));
  const expectedPagesRoot = normalizePath(path.join(assetsRoot, pagesDir));
  const altPagesRoot = normalizePath(path.join(assetsRoot, 'pages'));

  report.push(`[FileRouter] pagesDir (configured): ${pagesDir}`);
  report.push(`[FileRouter] Expected pages root:   ${expectedPagesRoot}`);

  const actualExists = fs.existsSync(expectedPagesRoot);
  const altExists = expectedPagesRoot !== altPagesRoot && fs.existsSync(altPagesRoot);

  if (!actualExists && altExists) {
    blocking.push(
      `pagesDir mismatch: runtime expects "${expectedPagesRoot}" ` +
      `but build output is at "${altPagesRoot}"`,
    );
  }
  if (!actualExists && !altExists) {
    blocking.push(
      `No pages directory found — run npm run build:sdui to generate page JSON files`,
    );
    return { passed: false, report, blocking };
  }

  const scanRoot = actualExists ? expectedPagesRoot : altPagesRoot;
  const files = walkFiles(scanRoot);
  const pageFiles = files.filter(f => isPageFile(f.name));
  const layoutFiles = files.filter(f => isLayoutFile(f.name));

  report.push(`[FileRouter] Scan root:     ${scanRoot}`);
  report.push(`[FileRouter] Page files:    ${pageFiles.length}`);
  report.push(`[FileRouter] Layout files:  ${layoutFiles.length}`);

  if (pageFiles.length === 0) {
    blocking.push(`No page files discovered under ${scanRoot}`);
    return { passed: false, report, blocking };
  }

  // Duplicate route detection
  const routes = new Map<string, string>();
  for (const f of pageFiles) {
    const rel = normalizePath(path.relative(scanRoot, f.abs));

    // Validate page JSON
    let pageJson: Record<string, unknown>;
    try {
      pageJson = JSON.parse(fs.readFileSync(f.abs, 'utf8'));
    } catch (e) {
      blocking.push(`${rel}: invalid JSON (${(e as Error).message})`);
      continue;
    }

    // Check for ui/view/template payload
    const ui = pageJson.ui ?? pageJson.view ?? pageJson.template;
    if (ui === undefined) {
      blocking.push(`${rel}: missing ui/view/template field`);
    } else {
      // Validate the node tree
      const nodeIssues = validateNodeTree(ui);
      const errors = nodeIssues.filter(i => i.severity === 'error');
      errors.forEach(e => blocking.push(`${rel} → ${e.path}: ${e.message}`));
    }

    // Check meta flat strings
    if (pageJson.meta !== undefined) {
      const metaIssues = flatStringMapIssues(pageJson.meta, `${rel}.meta`);
      metaIssues.forEach(m => blocking.push(m));
    }

    // Check guards shape
    if (pageJson.guards !== undefined && !Array.isArray(pageJson.guards)) {
      blocking.push(`${rel}.guards must be an array`);
    }
  }

  // Root route check
  const routeKeys = [...routes.keys()];
  const hasRoot = routeKeys.includes('/') || routeKeys.includes('') || pageFiles.some(f => {
    const rel = normalizePath(path.relative(scanRoot, f.abs));
    return rel === 'page.json' || rel === 'index.json';
  });

  if (!hasRoot) {
    blocking.push(`Root route "/" not found — ensure assets/pages/page.json exists`);
  }

  return {
    passed: blocking.length === 0,
    report,
    blocking,
  };
}

/* ============================================================
 * BUILT-IN TEST CASES
 *
 * These mirror the structure of the Dart test suite's JSON case files
 * (lib/test/generated/sdui_json_runtime_behavior_test/cases/).
 * Each case has __meta, input, and one or more validation layers.
 * ============================================================ */

const BUILT_IN_TEST_CASES: PreflightTestCase[] = [
  // ── TC-001: Simple box with text child ───────────────────────────────────
  {
    __meta: {
      id: 'TC-001',
      title: 'Simple box with text child renders correctly',
      priority: 'critical',
      tags: ['box', 'text', 'basic'],
      description: 'The most basic valid SDUI tree: a box containing a text node.',
    },
    input: {
      type: 'box',
      props: { direction: 'col', padding: 16 },
      children: [
        { type: 'text', props: { text: 'Hello, Quantum!' } },
      ],
    },
    expected: {
      type: 'box',
      props: { direction: 'col', padding: 16 },
      children: [
        { type: 'text', props: { text: 'Hello, Quantum!' } },
      ],
    },
    assertions: [
      { path: 'type', equals: 'box', description: 'root type is box' },
      { path: 'props.direction', equals: 'col', description: 'direction is col' },
      { path: 'children[0].type', equals: 'text', description: 'first child is text' },
      { path: 'children[0].props.text', equals: 'Hello, Quantum!', description: 'text value matches' },
    ],
    nodeChecks: [
      { path: 'children[0]', hasType: 'text', hasProps: ['text'], notEmpty: false },
    ],
  },

  // ── TC-002: Action button node ────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-002',
      title: 'Action button with intent and variant',
      priority: 'high',
      tags: ['action', 'button'],
      description: 'An action node with intent=primary and variant=solid is valid.',
    },
    input: {
      type: 'action',
      props: {
        text: 'Get Started',
        intent: 'primary',
        variant: 'solid',
      },
    },
    assertions: [
      { path: 'type', equals: 'action', description: 'type is action' },
      { path: 'props.intent', equals: 'primary' },
      { path: 'props.variant', equals: 'solid' },
      { path: 'props.text', equals: 'Get Started' },
    ],
  },

  // ── TC-003: action:button subtype ────────────────────────────────────────
  {
    __meta: {
      id: 'TC-003',
      title: 'action:button subtype node',
      priority: 'high',
      tags: ['action', 'button', 'subtype'],
    },
    input: {
      type: 'action:button',
      props: { text: 'Submit', intent: 'primary' },
    },
    assertions: [
      { path: 'type', equals: 'action:button' },
      { path: 'props.text', equals: 'Submit' },
    ],
  },

  // ── TC-004: text node variants ────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-004',
      title: 'Text node with heading variant',
      priority: 'high',
      tags: ['text', 'variant'],
    },
    input: {
      type: 'text',
      props: { text: 'Dashboard', variant: 'heading' },
    },
    assertions: [
      { path: 'type', equals: 'text' },
      { path: 'props.text', equals: 'Dashboard' },
      { path: 'props.variant', equals: 'heading' },
    ],
  },

  // ── TC-005: Nested layout (dashboard pattern) ─────────────────────────────
  {
    __meta: {
      id: 'TC-005',
      title: 'Nested box layout matches dashboard pattern',
      priority: 'critical',
      tags: ['layout', 'dashboard', 'nested'],
      description: 'A row of boxes is the primary layout pattern; all must have valid types.',
    },
    input: {
      type: 'box',
      props: { direction: 'row', gap: 16 },
      children: [
        {
          type: 'box',
          props: { direction: 'col', gap: 8, padding: 18, bg: '#ffffff' },
          children: [
            { type: 'text', props: { text: 'Users Online', variant: 'caption' } },
            { type: 'text', props: { text: '18.2K', variant: 'heading' } },
          ],
        },
        {
          type: 'box',
          props: { direction: 'col', gap: 8, padding: 18, bg: '#ffffff' },
          children: [
            { type: 'text', props: { text: 'Error Rate', variant: 'caption' } },
            { type: 'text', props: { text: '0.04%', variant: 'heading' } },
          ],
        },
      ],
    },
    assertions: [
      { path: 'type', equals: 'box' },
      { path: 'props.direction', equals: 'row' },
      { path: 'children[0].type', equals: 'box' },
      { path: 'children[0].children[0].props.text', equals: 'Users Online' },
      { path: 'children[1].children[0].props.text', equals: 'Error Rate' },
    ],
    nodeChecks: [
      { path: 'children[0]', notEmpty: true },
      { path: 'children[1]', notEmpty: true },
    ],
  },

  // ── TC-006: component:use node ────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-006',
      title: 'component:use node with props',
      priority: 'high',
      tags: ['component', 'use'],
      description: 'component:use is a valid type — tests the component system.',
    },
    input: {
      type: 'component:use',
      props: {
        component: 'page_header',
        title: 'Dashboard',
        subtitle: 'Live metrics',
      },
    },
    assertions: [
      { path: 'type', equals: 'component:use' },
      { path: 'props.component', equals: 'page_header' },
      { path: 'props.title', equals: 'Dashboard' },
    ],
  },

  // ── TC-007: template:hero node ────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-007',
      title: 'template:hero node passes as valid type',
      priority: 'high',
      tags: ['template', 'hero'],
      description: 'template:* types are always valid (dynamic template references).',
    },
    input: {
      type: 'template:hero',
      props: {
        name: 'hero',
        title: 'Build anything with one JSON graph',
        eyebrow: 'Introducing',
      },
    },
    assertions: [
      { path: 'type', equals: 'template:hero' },
      { path: 'props.name', equals: 'hero' },
    ],
  },

  // ── TC-008: custom node type (page_shell) ─────────────────────────────────
  {
    __meta: {
      id: 'TC-008',
      title: 'Custom page_shell node type is valid',
      priority: 'critical',
      tags: ['custom-node', 'page_shell', 'layout'],
      description:
        'page_shell is registered via defineNodeType — must pass type validation.',
    },
    input: {
      type: 'page_shell',
      props: {
        title: 'Public',
        compact: false,
        showSidebar: false,
        showFooter: true,
      },
      slots: {
        content: {
          type: 'box',
          props: { direction: 'col', gap: 24, padding: 24 },
          children: [{ type: 'text', props: { text: 'Content area' } }],
        },
        footer: {
          type: 'box',
          props: { padding: 24 },
          children: [{ type: 'text', props: { text: '© Quantum' } }],
        },
      },
    },
    assertions: [
      { path: 'type', equals: 'page_shell' },
      { path: 'props.title', equals: 'Public' },
      { path: 'slots.content.type', equals: 'box' },
      { path: 'slots.footer.children[0].props.text', equals: '© Quantum' },
    ],
  },

  // ── TC-009: Box with slot outlet marker (fix verification) ───────────────
  {
    __meta: {
      id: 'TC-009',
      title: 'Box with __slotOutlet marker is valid (not "slot" type)',
      priority: 'critical',
      tags: ['slot-outlet', 'fix-verification', 'black-screen'],
      description:
        'Verifies the FIX: slot outlets must use type "box" with props.name, ' +
        'NOT type "slot" which causes a black screen in Dart.',
    },
    input: {
      type: 'box',
      props: {
        name: 'action',
        __slotOutlet: true,
      },
    },
    assertions: [
      { path: 'type', equals: 'box', description: 'must be box, not slot' },
      { path: 'props.name', equals: 'action', description: 'slot name preserved as prop' },
      { path: 'props.__slotOutlet', equals: true, description: 'slot outlet marker present' },
    ],
  },

  // ── TC-010: NEGATIVE — missing type field ─────────────────────────────────
  {
    __meta: {
      id: 'TC-010',
      title: 'NEGATIVE: node without type field fails validation',
      priority: 'critical',
      tags: ['negative', 'validation', 'type'],
      description: 'A node with no type must be caught — Dart cannot render it.',
    },
    input: {
      props: { text: 'Orphan text node' },
    } as SduiNodeJson,
    expectError: {
      messageContains: 'missing "type" field',
    },
  },

  // ── TC-011: NEGATIVE — invalid "slot" type ────────────────────────────────
  {
    __meta: {
      id: 'TC-011',
      title: 'NEGATIVE: "slot" type causes black screen — detected',
      priority: 'critical',
      tags: ['negative', 'slot', 'black-screen'],
      description:
        'Using type "slot" must be flagged. This was the root cause of the black screen bug.',
    },
    input: {
      type: 'slot',
      props: { name: 'action' },
    },
    expectError: {
      messageContains: '"slot" is not a valid Dart-renderable node type',
    },
  },

  // ── TC-012: NEGATIVE — unknown random type ────────────────────────────────
  {
    __meta: {
      id: 'TC-012',
      title: 'NEGATIVE: unknown arbitrary type is flagged',
      priority: 'high',
      tags: ['negative', 'unknown-type'],
    },
    input: {
      type: 'my_custom_unknown_widget_xyz',
      props: {},
    },
    expectError: {
      messageContains: 'unknown type',
    },
  },

  // ── TC-013: NEGATIVE — text node missing props.text ──────────────────────
  {
    __meta: {
      id: 'TC-013',
      title: 'NEGATIVE: text node without props.text is flagged',
      priority: 'high',
      tags: ['negative', 'text', 'props'],
    },
    input: {
      type: 'text',
      props: { variant: 'heading' }, // missing text!
    },
    expectError: {
      messageContains: 'missing props.text',
    },
  },

  // ── TC-014: box:scroll subtype ────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-014',
      title: 'box:scroll subtype with children',
      priority: 'normal',
      tags: ['box', 'scroll', 'subtype'],
    },
    input: {
      type: 'box:scroll',
      props: { direction: 'col', padding: 16 },
      children: [
        { type: 'text', props: { text: 'Item 1' } },
        { type: 'text', props: { text: 'Item 2' } },
      ],
    },
    assertions: [
      { path: 'type', equals: 'box:scroll' },
      { path: 'children[0].props.text', equals: 'Item 1' },
      { path: 'children[1].props.text', equals: 'Item 2' },
    ],
    nodeChecks: [
      // 'root' resolves to the root node itself
      { path: 'root', notEmpty: true },
    ],
  },

  // ── TC-015: Guard redirect shape ─────────────────────────────────────────
  {
    __meta: {
      id: 'TC-015',
      title: 'Guard redirect shape is valid JSON',
      priority: 'high',
      tags: ['guard', 'auth', 'redirect'],
      description: 'Guard objects produced by the build-sdui.ts build step.',
    },
    // Guards are not SDUI nodes — they are checked directly as JSON objects
    // We use assertions on a synthetic wrapper for the test
    input: {
      type: 'hook:guard',
      props: {
        type: 'redirect',
        condition: 'auth.isAuthenticated',
        to: '/login',
      },
    },
    assertions: [
      { path: 'type', equals: 'hook:guard' },
      { path: 'props.type', equals: 'redirect' },
      { path: 'props.to', equals: '/login' },
    ],
  },

  // ── TC-016: media:icon node ────────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-016',
      title: 'media:icon node is valid',
      priority: 'normal',
      tags: ['media', 'icon'],
    },
    input: {
      type: 'media:icon',
      props: { icon: 'home', iconFamily: 'material', iconSize: 24 },
    },
    assertions: [
      { path: 'type', equals: 'media:icon' },
      { path: 'props.icon', equals: 'home' },
    ],
  },

  // ── TC-017: portal:modal node ─────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-017',
      title: 'portal:modal node with content slot',
      priority: 'normal',
      tags: ['portal', 'modal'],
    },
    input: {
      type: 'portal:modal',
      props: { title: 'Confirm Action', dismissible: true },
      slots: {
        content: {
          type: 'box',
          props: { padding: 16 },
          children: [{ type: 'text', props: { text: 'Are you sure?' } }],
        },
      },
    },
    assertions: [
      { path: 'type', equals: 'portal:modal' },
      { path: 'slots.content.type', equals: 'box' },
    ],
  },

  // ── TC-018: chart:bar node ────────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-018',
      title: 'chart:bar node is a valid catalog type',
      priority: 'normal',
      tags: ['chart', 'bar'],
    },
    input: {
      type: 'chart:bar',
      props: {
        xField: 'month',
        yField: 'revenue',
        animated: true,
        height: 300,
      },
    },
    assertions: [
      { path: 'type', equals: 'chart:bar' },
      { path: 'props.xField', equals: 'month' },
    ],
  },

  // ── TC-019: surface extension type ────────────────────────────────────────
  {
    __meta: {
      id: 'TC-019',
      title: 'surface:hero extension type is valid',
      priority: 'normal',
      tags: ['surface', 'extension'],
    },
    input: {
      type: 'surface:hero',
      props: { bg: '$colors.brand.500', padding: 32 },
      children: [
        { type: 'text', props: { text: 'Welcome', variant: 'heading' } },
      ],
    },
    assertions: [
      { path: 'type', equals: 'surface:hero' },
      { path: 'children[0].props.text', equals: 'Welcome' },
    ],
  },

  // ── TC-020: control:tabs node ─────────────────────────────────────────────
  {
    __meta: {
      id: 'TC-020',
      title: 'control:tabs with tab definitions',
      priority: 'normal',
      tags: ['control', 'tabs'],
    },
    input: {
      type: 'control:tabs',
      props: {
        tabs: [
          { label: 'Overview', value: 'overview' },
          { label: 'Reports', value: 'reports' },
        ],
        activeTab: 'overview',
        tabVariant: 'pills',
      },
    },
    assertions: [
      { path: 'type', equals: 'control:tabs' },
      { path: 'props.activeTab', equals: 'overview' },
    ],
  },

  // ── TC-021: Full page JSON shape (header + stat cards) ────────────────────
  {
    __meta: {
      id: 'TC-021',
      title: 'Full dashboard page tree is valid',
      priority: 'critical',
      tags: ['dashboard', 'full-page', 'integration'],
      description: 'Simulates the full dashboard_home fragment output shape.',
    },
    input: {
      type: 'box',
      props: { direction: 'col', gap: 24 },
      children: [
        // page header
        {
          type: 'component:use',
          props: {
            component: 'page_header',
            title: 'Dashboard',
            subtitle: 'Live metrics, activity, and drill-down pages',
          },
        },
        // section template
        {
          type: 'template:section',
          props: {
            name: 'section',
            title: 'Overview',
            description: 'Everything that matters at a glance.',
            compact: false,
          },
          slots: {
            body: {
              type: 'box',
              props: { direction: 'row', gap: 16 },
              children: [
                {
                  type: 'template:stat_card',
                  props: { name: 'stat_card', label: 'Users Online', value: '18.2K', hint: 'peak 1h' },
                },
                {
                  type: 'template:stat_card',
                  props: { name: 'stat_card', label: 'Error Rate', value: '0.04%', hint: 'healthy' },
                },
              ],
            },
          },
        },
      ],
    },
    assertions: [
      { path: 'type', equals: 'box', description: 'root is box' },
      { path: 'children[0].type', equals: 'component:use' },
      { path: 'children[0].props.component', equals: 'page_header' },
      { path: 'children[1].type', equals: 'template:section' },
      { path: 'children[1].slots.body.type', equals: 'box' },
      { path: 'children[1].slots.body.children[0].props.label', equals: 'Users Online' },
    ],
    nodeChecks: [
      { path: 'children[1].slots.body', notEmpty: true },
    ],
  },
];

/* ============================================================
 * MAIN ENTRY POINT
 * ============================================================ */

function printResult(result: TestResult): void {
  const icon = result.passed ? '✅' : '❌';
  console.log(`  ${icon} [${result.id}] ${result.title}`);
  if (result.warnings.length > 0) {
    result.warnings.forEach(w => console.log(`       ⚠️  ${w}`));
  }
  if (!result.passed) {
    result.failures.forEach(f => console.log(`       💥 ${f}`));
  }
}

function main(): void {
  const projectRoot = normalizePath(process.argv[2] || process.cwd());
  const kernelJsonPath = normalizePath(
    process.argv[3] || path.join(projectRoot, 'assets', 'config', 'kernel.json'),
  );

  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(' Quantum JSON Preflight Test Engine');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // ── Phase 1: Built-in test cases ──────────────────────────────────────────
  console.log('');
  console.log('Phase 1: Node validation test cases');
  console.log('─────────────────────────────────────');

  const summary = runPreflightTests(BUILT_IN_TEST_CASES);
  summary.results.forEach(printResult);

  console.log('');
  console.log(`  Result: ${summary.passed}/${summary.total} passed, ${summary.failed} failed`);

  // ── Phase 2: File router checks ───────────────────────────────────────────
  console.log('');
  console.log('Phase 2: File router / build output checks');
  console.log('─────────────────────────────────────────────');

  const fileCheck = runFileRouterChecks(projectRoot, kernelJsonPath);
  fileCheck.report.forEach(line => console.log(`  ${line}`));

  if (fileCheck.blocking.length > 0) {
    console.log('');
    console.log('  ❌ Blocking issues:');
    fileCheck.blocking.forEach(b => console.log(`     💥 ${b}`));
  } else {
    console.log('  ✅ File router checks passed');
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  const allPassed = summary.failed === 0 && fileCheck.passed;

  if (allPassed) {
    console.log(' ✅ All Quantum preflight checks passed.');
    console.log('    Safe to launch Flutter — no black-screen risks detected.');
  } else {
    console.log(' ❌ Quantum preflight checks FAILED.');
    if (summary.failed > 0) {
      console.log(`    ${summary.failed} node validation test(s) failed.`);
    }
    if (!fileCheck.passed) {
      console.log(`    ${fileCheck.blocking.length} file router issue(s) found.`);
    }
    console.log('');
    console.log('    Fix the issues above, then re-run:');
    console.log('      npm run build:sdui');
    console.log('      npx tsx lib/interop/typescript/quantum_json_preflight_test.ts');
  }

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');

  // Write report file
  const reportLines = [
    `Quantum preflight run: ${new Date().toISOString()}`,
    `Tests: ${summary.total} total, ${summary.passed} passed, ${summary.failed} failed`,
    '',
    '== Node Validation ==',
    ...summary.results.map(r =>
      `[${r.passed ? 'PASS' : 'FAIL'}] ${r.id}: ${r.title}` +
      (r.failures.length ? '\n  Failures:\n' + r.failures.map(f => `    - ${f}`).join('\n') : ''),
    ),
    '',
    '== File Router ==',
    ...fileCheck.report,
    ...(fileCheck.blocking.length > 0
      ? ['', 'Blocking issues:', ...fileCheck.blocking.map(b => `  - ${b}`)]
      : ['', 'No blocking issues.']),
  ];

  const reportPath = path.join(projectRoot, 'quantum_json_preflight_report.txt');
  try {
    fs.writeFileSync(reportPath, reportLines.join('\n') + '\n', 'utf8');
    console.log(`  Report written to: ${reportPath}`);
  } catch {
    // Non-fatal — report write failure doesn't block the exit code
  }

  process.exit(allPassed ? 0 : 1);
}

// Allow importing as a module (for unit testing this file itself)
if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(__filename)) {
  main();
}

export {
  type KnownSduiNodeType,
  type SduiNodeJson,
  type PreflightTestCase,
  type PathAssertion,
  type NodeCheck,
  type TestResult,
  type TestRunSummary,
  type FileRouterCheckResult,
  validateNodeTree,
  runPreflightTests,
  runFileRouterChecks,
  isValidNodeType,
  resolvePath,
  deepEqual,
  BUILT_IN_TEST_CASES,
};
