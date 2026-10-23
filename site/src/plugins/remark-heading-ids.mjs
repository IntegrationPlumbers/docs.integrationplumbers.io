// Supports kramdown-style custom heading IDs: "## Title {#custom-id}".
import { visit } from 'unist-util-visit';

export function remarkHeadingIds() {
  return (tree) => {
    visit(tree, 'heading', (node) => {
      const last = node.children[node.children.length - 1];
      if (!last || last.type !== 'text') return;
      const m = last.value.match(/\s*\{#([A-Za-z0-9_:.-]+)\}\s*$/);
      if (!m) return;
      last.value = last.value.slice(0, m.index);
      node.data ??= {};
      node.data.hProperties ??= {};
      node.data.hProperties.id = m[1];
    });
  };
}
