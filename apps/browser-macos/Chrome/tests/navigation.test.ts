import test from 'node:test';
import assert from 'node:assert/strict';
import { destination, search } from '../src/navigation';

test('normalizes hostnames, local fixtures and explicit HTTPS', () => {
  assert.equal(destination('example.com/docs'), 'https://example.com/docs');
  assert.equal(destination('http://127.0.0.1:5000/'), 'http://127.0.0.1:5000/');
  assert.equal(destination(' HTTPS://Example.com/#marker '), 'https://example.com/#marker');
});
test('blocks credentials, unsupported schemes and control characters', () => {
  for (const value of ['javascript:alert(1)', 'file:///tmp/secret', 'https://u:p@host.test/', 'https://exa\u0001mple.test', 'https://test\\@host.test', '']) {
    assert.equal(destination(value), undefined);
  }
});
test('generates a local suggestion and submits search through the provider', () => {
  assert.equal(search.suggestions('seaside trail')[0]?.value, 'seaside trail');
  assert.equal(destination('seaside trail'), 'https://duckduckgo.com/?q=seaside+trail');
  assert.equal(destination('sea & sun', { name: 'Test', suggestions: () => [], destination: (query) => '/search?term=' + encodeURIComponent(query) }), '/search?term=sea%20%26%20sun');
});

test('preserves HTTPS and loopback-only HTTP policy', () => {
  assert.equal(destination('http://example.com/'), undefined);
  assert.equal(destination('http://localhost:5000/'), 'http://localhost:5000/');
  assert.equal(destination('http://[::1]:5000/'), 'http://[::1]:5000/');
});
