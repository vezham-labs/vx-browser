export type Suggestion = { label: string; value: string };
export interface SearchProvider {
  name: string;
  destination(query: string): string;
  suggestions(query: string): readonly Suggestion[];
}

export const search: SearchProvider = {
  name: 'DuckDuckGo',
  destination: (query) => `https://duckduckgo.com/?${new URLSearchParams({ q: query })}`,
  suggestions: (query) => query.trim() ? [{ label: 'Search DuckDuckGo', value: query.trim() }] : [],
};

export const destination = (value: string, provider: SearchProvider = search): string | undefined => {
  const input = value.trim();
  const containsControl = Array.from(input).some(character => {
    const code = character.charCodeAt(0);
    return code < 32 || code === 127;
  });
  if (!input || input.length > 2048 || containsControl) return;
  const hostLike = /^(?:localhost|\[[0-9a-f:]+\]|[^\s/@:]+\.[^\s/@:]+)(?=[:/?#]|$)/iu.test(input);
  const hasScheme = /^[a-z][a-z\d+.-]*:/iu.test(input) && !hostLike;
  if (!hasScheme && (!hostLike || /\s/u.test(input))) return provider.destination(input);
  if (/\s|\\/u.test(input)) return;
  try {
    const url = new URL(hasScheme ? input : `https://${input}`);
    if (['https:', 'http:'].includes(url.protocol) && url.hostname && !url.username && !url.password) {
      if (url.protocol === 'http:' && !['localhost', '127.0.0.1', '[::1]'].includes(url.hostname)) return;
      return url.href;
    }
  } catch {
    return;
  }
}
